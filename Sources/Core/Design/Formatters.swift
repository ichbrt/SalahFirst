import Foundation

/// Date and duration formatting, in one place so every screen agrees.
public enum Format {

    /// Respects the user's 12/24-hour setting rather than forcing either.
    public static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.setLocalizedDateFormatFromTemplate("j:mm")
        return formatter.string(from: date)
    }

    /// "1h 22m", "14 min", or "any moment" under a minute.
    ///
    /// Deliberately coarse: a second-by-second countdown to a prayer time would
    /// create exactly the low-grade urgency this app exists to reduce.
    public static func countdown(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        if totalMinutes < 1 {
            return L10n.string("home.countdown.soon")
        }
        if totalMinutes < 60 {
            return L10n.string("home.countdown.minutes", totalMinutes)
        }
        return L10n.string("home.countdown.hoursMinutes", totalMinutes / 60, totalMinutes % 60)
    }

    /// Spoken form for VoiceOver, where "1h 22m" reads badly.
    public static func countdownAccessible(_ interval: TimeInterval) -> String {
        let totalMinutes = Int(interval / 60)
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.allowedUnits = totalMinutes < 60 ? [.minute] : [.hour, .minute]
        return formatter.string(from: interval) ?? countdown(interval)
    }
}
