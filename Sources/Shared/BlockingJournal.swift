import Foundation

/// How a prayer window ended.
public enum PrayerOutcome: String, Codable, Sendable {
    /// The user tapped "I have prayed".
    case completed
    /// The user used the escape hatch. Recorded so the window is not reopened,
    /// never shown back to the user as a failure.
    case skipped
}

public struct JournalEntry: Codable, Sendable, Hashable {
    public let day: String
    public let prayer: Prayer
    public let outcome: PrayerOutcome
    public let recordedAt: Date

    public init(day: String, prayer: Prayer, outcome: PrayerOutcome, recordedAt: Date = Date()) {
        self.day = day
        self.prayer = prayer
        self.outcome = outcome
        self.recordedAt = recordedAt
    }
}

/// The only history Salah First keeps. Lives in the App Group container on this
/// device, is never uploaded, and is capped so it cannot grow without bound.
public struct BlockingJournal: Codable, Sendable {

    /// Enough to draw "this week" with room to spare; anything older is dropped.
    public static let retentionDays = 120

    public var entries: [JournalEntry]

    public init(entries: [JournalEntry] = []) {
        self.entries = entries
    }

    public func outcome(for prayer: Prayer, on day: String) -> PrayerOutcome? {
        entries.first { $0.day == day && $0.prayer == prayer }?.outcome
    }

    public func isResolved(_ prayer: Prayer, on day: String) -> Bool {
        outcome(for: prayer, on: day) != nil
    }

    /// Prayers marked `completed` on a given day. `skipped` deliberately does
    /// not count, but it is also never surfaced as a miss.
    public func completedCount(on day: String) -> Int {
        entries.filter { $0.day == day && $0.outcome == .completed }.count
    }

    public mutating func record(_ outcome: PrayerOutcome, for prayer: Prayer, on day: String) {
        entries.removeAll { $0.day == day && $0.prayer == prayer }
        entries.append(JournalEntry(day: day, prayer: prayer, outcome: outcome))
        prune()
    }

    public mutating func clear(_ prayer: Prayer, on day: String) {
        entries.removeAll { $0.day == day && $0.prayer == prayer }
    }

    private mutating func prune() {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -Self.retentionDays, to: Date()) else { return }
        entries.removeAll { $0.recordedAt < cutoff }
    }
}
