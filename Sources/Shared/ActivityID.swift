import Foundation

/// Identifies one monitored window, round-tripping through the string
/// `DeviceActivityName` that `DeviceActivity` hands back to the extension.
///
/// The extension is woken with nothing but this name, so everything it needs to
/// know — which prayer, which day — is encoded here.
///
/// Format: `prayer.maghrib.2026-09-16` or `focus.manual`.
public enum ActivityID: Hashable, Sendable {
    case prayer(Prayer, day: String)
    case manualFocus

    public var rawValue: String {
        switch self {
        case let .prayer(prayer, day): return "prayer.\(prayer.rawValue).\(day)"
        case .manualFocus:             return "focus.manual"
        }
    }

    public init?(rawValue: String) {
        if rawValue == "focus.manual" {
            self = .manualFocus
            return
        }
        let parts = rawValue.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count == 3,
              parts[0] == "prayer",
              let prayer = Prayer(rawValue: String(parts[1])) else { return nil }
        self = .prayer(prayer, day: String(parts[2]))
    }

    /// The prayer this window belongs to, or `nil` for a manual focus session.
    public var prayer: Prayer? {
        if case let .prayer(prayer, _) = self { return prayer }
        return nil
    }
}

/// Formats and parses the `yyyy-MM-dd` day keys used in `ActivityID` and in the
/// daily completion journal.
///
/// Always evaluated in the current calendar and time zone: a day key means
/// "the user's local day", which is exactly what "did I pray Maghrib today"
/// should mean, including after crossing a time zone.
public enum DayKey {

    /// Gregorian, in the current time zone. Never `Calendar.current`: a device
    /// set to the Hijri calendar would otherwise produce day keys that neither
    /// sort nor match across app launches.
    public static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    public static func string(for date: Date, calendar: Calendar? = nil) -> String {
        let calendar = calendar ?? Self.calendar
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d",
                      components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    public static func today(calendar: Calendar? = nil) -> String {
        string(for: Date(), calendar: calendar)
    }
}
