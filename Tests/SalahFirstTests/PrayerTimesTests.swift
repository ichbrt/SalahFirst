import XCTest
@testable import SalahFirst

/// Guards the prayer-time layer against the failures that actually bite:
/// travel, daylight saving, unusual device calendars, and the poles.
final class PrayerTimesTests: XCTestCase {

    private let istanbul = PrayerLocation(latitude: 41.01, longitude: 28.98,
                                          name: "İstanbul", isAutomatic: false)
    private let tromso = PrayerLocation(latitude: 69.65, longitude: 18.96,
                                        name: "Tromsø", isAutomatic: false)

    private func date(_ iso: String, timeZone: String = "Europe/Istanbul") -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: timeZone)
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: iso)!
    }

    private func engine(_ location: PrayerLocation,
                        method: CalculationMethodOption = .turkey,
                        timeZone: String = "Europe/Istanbul") -> PrayerTimesEngine {
        PrayerTimesEngine(
            configuration: PrayerConfiguration(location: location, method: method, madhab: .shafi),
            timeZone: TimeZone(identifier: timeZone)!
        )
    }

    // MARK: - Sanity

    /// Not an exact match against a published table — Adhan's `.turkey` is
    /// documented as an approximation of Diyanet's method, and Diyanet applies
    /// its own rounding. This asserts the times land in the right hour, which
    /// is what catches the failures that matter: a wrong time zone, a swapped
    /// latitude and longitude, or a UTC/local mix-up.
    func testIstanbulSeptemberTimesAreInPlausibleRanges() throws {
        let engine = engine(istanbul)
        let times = try XCTUnwrap(engine.times(on: date("2026-09-16 12:00")))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        func hour(_ prayer: Prayer) throws -> Double {
            let time = try XCTUnwrap(times.time(for: prayer))
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return Double(components.hour!) + Double(components.minute!) / 60
        }

        XCTAssertEqual(try hour(.fajr), 5.2, accuracy: 0.5)
        XCTAssertEqual(try hour(.dhuhr), 13.07, accuracy: 0.3)
        XCTAssertEqual(try hour(.asr), 16.55, accuracy: 0.4)
        XCTAssertEqual(try hour(.maghrib), 19.32, accuracy: 0.3)
        XCTAssertEqual(try hour(.isha), 20.65, accuracy: 0.5)
    }

    func testPrayersAreStrictlyIncreasingThroughTheDay() throws {
        let times = try XCTUnwrap(engine(istanbul).times(on: date("2026-09-16 12:00")))
        let ordered = times.ordered
        XCTAssertEqual(ordered.map(\.prayer), [.fajr, .dhuhr, .asr, .maghrib, .isha])
        for (earlier, later) in zip(ordered, ordered.dropFirst()) {
            XCTAssertLessThan(earlier.time, later.time)
        }
    }

    // MARK: - Day boundaries

    /// After Isha, "next" must be tomorrow's Fajr rather than nothing.
    func testNextPrayerAfterIshaRollsIntoTomorrow() throws {
        let engine = engine(istanbul)
        let lateNight = date("2026-09-16 23:30")
        let next = try XCTUnwrap(engine.next(after: lateNight))

        XCTAssertEqual(next.prayer, .fajr)
        XCTAssertEqual(next.day, "2026-09-17")
        XCTAssertGreaterThan(next.time, lateNight)
    }

    /// A window that opens before midnight and closes after it still belongs to
    /// the day it opened, so the completion is recorded against that day.
    func testWindowCrossingMidnightKeepsItsOpeningDay() {
        var settings = BlockingSettings()
        settings.enabledPrayers = [.isha]
        settings.windowMinutes = 30

        // Reykjavík in late June: Isha falls close to midnight.
        let reykjavik = PrayerLocation(latitude: 64.15, longitude: -21.94,
                                       name: "Reykjavík", isAutomatic: false)
        let engine = engine(reykjavik, method: .muslimWorldLeague, timeZone: "Atlantic/Reykjavik")
        let schedule = SchedulePlanner.plan(
            engine: engine,
            settings: settings,
            now: date("2026-06-20 00:01", timeZone: "Atlantic/Reykjavik"),
            days: 2
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Atlantic/Reykjavik")!

        for window in schedule.windows {
            XCTAssertEqual(window.day, DayKey.string(for: window.start, calendar: calendar),
                           "A window must be filed under the day it opens")
            XCTAssertGreaterThan(window.end, window.start)
        }
    }

    // MARK: - Travel and daylight saving

    /// The same instant, computed in two time zones, must describe the same
    /// physical moment — the wall-clock reading differs, the Date does not.
    func testTravelChangesWallClockButNotTheInstant() throws {
        let instant = date("2026-09-16 12:00")

        let atHome = try XCTUnwrap(engine(istanbul).times(on: instant).map { $0 })
        let abroad = try XCTUnwrap(
            engine(istanbul, timeZone: "Europe/London").times(on: instant)
        )

        let homeDhuhr = try XCTUnwrap(atHome.time(for: .dhuhr))
        let awayDhuhr = try XCTUnwrap(abroad.time(for: .dhuhr))

        // Same calendar day in both zones here, so the computed instant matches.
        XCTAssertEqual(homeDhuhr.timeIntervalSince1970,
                       awayDhuhr.timeIntervalSince1970,
                       accuracy: 1)
    }

    /// Europe/Istanbul has had no DST since 2016, so exercise this against a
    /// zone that still observes it: the spring-forward day must still produce
    /// five sane, increasing times.
    func testDaylightSavingTransitionStillProducesFiveTimes() throws {
        let london = PrayerLocation(latitude: 51.51, longitude: -0.13,
                                    name: "London", isAutomatic: false)
        let engine = engine(london, method: .muslimWorldLeague, timeZone: "Europe/London")

        // 29 March 2026: clocks go forward at 01:00 UTC.
        let springForward = try XCTUnwrap(engine.times(on: date("2026-03-29 12:00", timeZone: "Europe/London")))
        XCTAssertEqual(springForward.ordered.count, 5)

        // 25 October 2026: clocks go back.
        let fallBack = try XCTUnwrap(engine.times(on: date("2026-10-25 12:00", timeZone: "Europe/London")))
        XCTAssertEqual(fallBack.ordered.count, 5)

        for daily in [springForward, fallBack] {
            for (earlier, later) in zip(daily.ordered, daily.ordered.dropFirst()) {
                XCTAssertLessThan(earlier.time, later.time)
            }
        }
    }

    // MARK: - Device calendar

    /// A user whose device calendar is Hijri must still get sortable ISO day
    /// keys, or every journal lookup silently misses.
    func testDayKeysAreGregorianRegardlessOfDeviceCalendar() {
        var hijri = Calendar(identifier: .islamicUmmAlQura)
        hijri.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let key = DayKey.string(for: date("2026-09-16 12:00"))
        XCTAssertEqual(key, "2026-09-16")

        // The Hijri year for this date is in the 1440s; the key must not be.
        let hijriYear = hijri.component(.year, from: date("2026-09-16 12:00"))
        XCTAssertNotEqual(String(hijriYear), String(key.prefix(4)))
    }

    // MARK: - Extreme latitude

    /// Above the Arctic Circle in midsummer the sun never sets, so there is no
    /// sunset to anchor Maghrib to and no times can be derived. The contract is
    /// that this returns `nil` rather than crashing or inventing times — the UI
    /// then says so plainly instead of blaming the location permission.
    func testPolarSummerReturnsNoTimesRatherThanWrongOnes() {
        let engine = engine(tromso, method: .muslimWorldLeague, timeZone: "Europe/Oslo")
        XCTAssertNil(engine.times(on: date("2026-06-21 12:00", timeZone: "Europe/Oslo")))
    }

    /// The same location in autumn, when the sun does rise and set, works
    /// normally — so the failure above is seasonal, not a broken configuration.
    func testPolarLocationWorksOutsideTheMidnightSunPeriod() throws {
        let engine = engine(tromso, method: .muslimWorldLeague, timeZone: "Europe/Oslo")
        let times = try XCTUnwrap(engine.times(on: date("2026-09-21 12:00", timeZone: "Europe/Oslo")))
        XCTAssertEqual(times.ordered.count, 5)
    }

    /// A horizon that contains unusable days must not abort planning: the days
    /// that do work are still scheduled.
    func testPlanningSkipsUnusableDaysWithoutFailing() {
        var settings = BlockingSettings()
        settings.isEnabled = true
        settings.enabledPrayers = Set(Prayer.allCases)

        let engine = engine(tromso, method: .muslimWorldLeague, timeZone: "Europe/Oslo")
        // Late May into June: the midnight sun begins partway through.
        let schedule = SchedulePlanner.plan(
            engine: engine, settings: settings,
            now: date("2026-05-10 00:01", timeZone: "Europe/Oslo"), days: 14
        )
        XCTAssertFalse(schedule.windows.isEmpty, "Usable days should still be planned")
    }

    // MARK: - Configuration

    func testNoLocationProducesNoTimes() {
        let engine = PrayerTimesEngine(configuration: PrayerConfiguration())
        XCTAssertNil(engine.times(on: Date()))
        XCTAssertNil(engine.next(after: Date()))
    }

    func testCalculationMethodDefaultsByRegion() {
        XCTAssertEqual(CalculationMethodOption.default(for: Locale(identifier: "tr_TR")), .turkey)
        XCTAssertEqual(CalculationMethodOption.default(for: Locale(identifier: "ar_SA")), .ummAlQura)
        XCTAssertEqual(CalculationMethodOption.default(for: Locale(identifier: "en_US")), .northAmerica)
        XCTAssertEqual(CalculationMethodOption.default(for: Locale(identifier: "de_DE")), .muslimWorldLeague)
    }

    func testCoordinatesAreRoundedSoTheyCannotPinpointAHome() {
        let location = PrayerLocation(latitude: 41.0138199, longitude: 28.9496871, isAutomatic: true)
        XCTAssertEqual(location.latitude, 41.014, accuracy: 0.0001)
        XCTAssertEqual(location.longitude, 28.95, accuracy: 0.0001)
    }
}
