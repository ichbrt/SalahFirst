import DeviceActivity
import XCTest
@testable import SalahFirst

/// The scheduling layer sits between prayer times and Apple's hard limits:
/// twenty monitored activities, and nothing shorter than fifteen minutes.
/// These tests hold that boundary.
final class SchedulingTests: XCTestCase {

    private let istanbul = PrayerLocation(latitude: 41.01, longitude: 28.98,
                                          name: "İstanbul", isAutomatic: false)

    private func date(_ iso: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Europe/Istanbul")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: iso)!
    }

    private var engine: PrayerTimesEngine {
        PrayerTimesEngine(
            configuration: PrayerConfiguration(location: istanbul, method: .turkey, madhab: .shafi),
            timeZone: TimeZone(identifier: "Europe/Istanbul")!
        )
    }

    private func settings(windowMinutes: Int = 20,
                          prayers: Set<Prayer> = Set(Prayer.allCases)) -> BlockingSettings {
        var settings = BlockingSettings()
        settings.isEnabled = true
        settings.includeEntireCategory = true
        settings.enabledPrayers = prayers
        settings.windowMinutes = windowMinutes
        return settings
    }

    // MARK: - Planning

    func testPlanCoversTheWholeHorizonForEveryEnabledPrayer() {
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 00:01"), days: 3)
        // Five prayers a day for three days, minus none since we start at 00:01.
        XCTAssertEqual(schedule.windows.count, 15)
        XCTAssertEqual(Set(schedule.windows.map(\.day)).count, 3)
    }

    func testDisabledPrayersAreNotScheduled() {
        let schedule = SchedulePlanner.plan(
            engine: engine,
            settings: settings(prayers: [.maghrib, .isha]),
            now: date("2026-09-16 00:01"),
            days: 2
        )
        XCTAssertEqual(Set(schedule.windows.map(\.prayer)), [.maghrib, .isha])
        XCTAssertEqual(schedule.windows.count, 4)
    }

    func testWindowsAlreadyFinishedAreLeftOut() {
        // 20:00 on the 16th: Fajr, Dhuhr, Asr and Maghrib windows have closed.
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 20:00"), days: 1)
        let sameDay = schedule.windows.filter { $0.day == "2026-09-16" }
        XCTAssertEqual(sameDay.map(\.prayer), [.isha])
    }

    func testWindowNeverRunsPastTheFollowingPrayer() {
        // An hour-long window would swallow the next prayer on most days.
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(windowMinutes: 60),
                                            now: date("2026-09-16 00:01"), days: 2)
        let sorted = schedule.windows.sorted { $0.start < $1.start }

        for (window, following) in zip(sorted, sorted.dropFirst()) {
            // Either the window ends by the next prayer, or it was stretched to
            // the fifteen-minute floor the system insists on.
            let isClamped = window.end <= following.start
            let isAtFloor = window.end == window.start
                .addingTimeInterval(TimeInterval(BlockingSettings.minimumWindowMinutes * 60))
            XCTAssertTrue(isClamped || isAtFloor,
                          "\(window.id) ends at \(window.end) but \(following.id) starts at \(following.start)")
        }
    }

    func testEveryPlannedWindowMeetsTheSystemMinimum() {
        // Five minutes is below the floor and must be raised, not passed along.
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(windowMinutes: 5),
                                            now: date("2026-09-16 00:01"), days: 2)
        let floor = TimeInterval(BlockingSettings.minimumWindowMinutes * 60)

        for window in schedule.windows {
            XCTAssertGreaterThanOrEqual(window.end.timeIntervalSince(window.start), floor,
                                        "\(window.id) is shorter than the system allows")
        }
    }

    func testPlanRecordsTheTimeZoneItWasBuiltIn() {
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 00:01"), days: 1)
        XCTAssertEqual(schedule.timeZoneIdentifier, TimeZone.current.identifier)
    }

    func testCacheHorizonStaysWithinWhatTheSystemCanMonitor() {
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 00:01"))
        // The cache is intentionally larger than the monitoring limit: the
        // extension re-arms from it as windows are consumed.
        XCTAssertGreaterThan(schedule.windows.count, DeviceActivityScheduler.maxMonitoredActivities)
        XCTAssertLessThanOrEqual(DeviceActivityScheduler.maxMonitoredActivities, 20,
                                 "Apple allows at most 20 activities per app and its extensions")
    }

    // MARK: - DeviceActivitySchedule construction

    func testScheduleCarriesFullDateComponentsSoItCannotDrift() throws {
        let window = PlannedWindow(
            id: ActivityID.prayer(.maghrib, day: "2026-09-16").rawValue,
            prayer: .maghrib, day: "2026-09-16",
            start: date("2026-09-16 19:19"),
            end: date("2026-09-16 19:39")
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let schedule = try XCTUnwrap(
            DeviceActivityScheduler.makeSchedule(for: window, now: date("2026-09-16 12:00"), calendar: calendar)
        )

        // A repeating schedule would only carry hour and minute, and would
        // drift away from the real prayer times within days.
        XCTAssertFalse(schedule.repeats)
        XCTAssertEqual(schedule.intervalStart.year, 2026)
        XCTAssertEqual(schedule.intervalStart.month, 9)
        XCTAssertEqual(schedule.intervalStart.day, 16)
        XCTAssertEqual(schedule.intervalStart.hour, 19)
        XCTAssertEqual(schedule.intervalStart.minute, 19)
        XCTAssertEqual(schedule.intervalEnd.minute, 39)
    }

    func testShortWindowIsStretchedToTheSystemMinimum() throws {
        let window = PlannedWindow(
            id: ActivityID.prayer(.asr, day: "2026-09-16").rawValue,
            prayer: .asr, day: "2026-09-16",
            start: date("2026-09-16 16:33"),
            end: date("2026-09-16 16:38")   // only five minutes
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Istanbul")!

        let schedule = try XCTUnwrap(
            DeviceActivityScheduler.makeSchedule(for: window, now: date("2026-09-16 12:00"), calendar: calendar)
        )
        // 16:33 + 15 minutes = 16:48, not the 16:38 that would be rejected.
        XCTAssertEqual(schedule.intervalEnd.hour, 16)
        XCTAssertEqual(schedule.intervalEnd.minute, 48)
    }

    func testFinishedWindowsAreNotHandedToTheSystem() {
        let window = PlannedWindow(
            id: ActivityID.prayer(.fajr, day: "2026-09-16").rawValue,
            prayer: .fajr, day: "2026-09-16",
            start: date("2026-09-16 05:12"),
            end: date("2026-09-16 05:32")
        )
        XCTAssertNil(
            DeviceActivityScheduler.makeSchedule(for: window, now: date("2026-09-16 12:00")),
            "A window that already closed must not be scheduled"
        )
    }

    // MARK: - Schedule queries

    func testUpcomingIncludesTheWindowWeAreCurrentlyInside() {
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 00:01"), days: 1)
        let maghrib = schedule.windows.first { $0.prayer == .maghrib }!
        let midWindow = maghrib.start.addingTimeInterval(60)

        XCTAssertTrue(maghrib.contains(midWindow))
        XCTAssertTrue(schedule.upcoming(from: midWindow).contains { $0.id == maghrib.id },
                      "An open window must stay in the armed set, or the shield would drop")
    }

    func testWindowLookupByIdentifier() {
        let schedule = SchedulePlanner.plan(engine: engine, settings: settings(),
                                            now: date("2026-09-16 00:01"), days: 1)
        let id = ActivityID.prayer(.dhuhr, day: "2026-09-16").rawValue
        XCTAssertEqual(schedule.window(withID: id)?.prayer, .dhuhr)
        XCTAssertNil(schedule.window(withID: "nope"))
    }
}
