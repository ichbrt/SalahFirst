import Adhan
import Foundation

/// The five times for one local day.
public struct DailyPrayerTimes: Equatable, Sendable {
    /// Local day key, `yyyy-MM-dd`.
    public let day: String
    public let sunrise: Date
    private let times: [Prayer: Date]

    init(day: String, sunrise: Date, times: [Prayer: Date]) {
        self.day = day
        self.sunrise = sunrise
        self.times = times
    }

    public func time(for prayer: Prayer) -> Date? { times[prayer] }

    /// The five prayers in the order they occur.
    public var ordered: [(prayer: Prayer, time: Date)] {
        Prayer.allCases.compactMap { prayer in
            times[prayer].map { (prayer, $0) }
        }
        .sorted { $0.time < $1.time }
    }
}

public struct UpcomingPrayer: Equatable, Sendable {
    public let prayer: Prayer
    public let time: Date
    public let day: String

    public func interval(from now: Date = Date()) -> TimeInterval {
        max(0, time.timeIntervalSince(now))
    }
}

/// Turns a `PrayerConfiguration` into times, entirely on device.
///
/// Wraps Adhan (MIT), which implements the standard astronomical calculation.
/// No network call is made here or anywhere else in the app — prayer times work
/// in airplane mode, in a tunnel, and on a phone that has never had a SIM.
public struct PrayerTimesEngine {

    public let configuration: PrayerConfiguration
    private let calendar: Calendar

    /// A Gregorian calendar in the given time zone.
    ///
    /// Explicitly Gregorian rather than `Calendar.current`: a user whose device
    /// calendar is set to Hijri or Buddhist would otherwise produce day
    /// components Adhan cannot interpret, and day keys that jump around.
    public static func gregorianCalendar(timeZone: TimeZone = .current) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    public init(configuration: PrayerConfiguration, timeZone: TimeZone = .current) {
        self.configuration = configuration
        self.calendar = Self.gregorianCalendar(timeZone: timeZone)
    }

    /// Times for the local day containing `date`.
    ///
    /// Returns `nil` when no location is set, or when the sun neither rises nor
    /// sets that day — which really happens above the Arctic Circle, and is a
    /// state the UI has to show rather than crash on.
    public func times(on date: Date) -> DailyPrayerTimes? {
        guard let parameters = configuration.adhanParameters,
              let location = configuration.location else { return nil }

        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let prayers = Adhan.PrayerTimes(coordinates: location.coordinates,
                                              date: components,
                                              calculationParameters: parameters) else {
            return nil
        }

        return DailyPrayerTimes(
            day: DayKey.string(for: date, calendar: calendar),
            sunrise: prayers.sunrise,
            times: [
                .fajr: prayers.fajr,
                .dhuhr: prayers.dhuhr,
                .asr: prayers.asr,
                .maghrib: prayers.maghrib,
                .isha: prayers.isha
            ]
        )
    }

    /// `count` consecutive local days starting with the one containing `date`.
    public func days(from date: Date, count: Int) -> [DailyPrayerTimes] {
        (0..<max(0, count)).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: date) else { return nil }
            return times(on: day)
        }
    }

    /// The next prayer strictly after `date`.
    ///
    /// Looks two days ahead so that the answer after Isha is tomorrow's Fajr,
    /// and so a day with no valid times does not end the search.
    public func next(after date: Date = Date()) -> UpcomingPrayer? {
        for dayOffset in 0...2 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: date),
                  let daily = times(on: dayDate) else { continue }
            if let match = daily.ordered.first(where: { $0.time > date }) {
                return UpcomingPrayer(prayer: match.prayer, time: match.time, day: daily.day)
            }
        }
        return nil
    }

    /// The prayer whose time has most recently passed, if it was today.
    public func current(at date: Date = Date()) -> UpcomingPrayer? {
        guard let daily = times(on: date) else { return nil }
        guard let match = daily.ordered.last(where: { $0.time <= date }) else { return nil }
        return UpcomingPrayer(prayer: match.prayer, time: match.time, day: daily.day)
    }
}
