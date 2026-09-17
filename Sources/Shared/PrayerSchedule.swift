import Foundation

/// One prayer window that has been handed to `DeviceActivityCenter`.
public struct PlannedWindow: Codable, Sendable, Hashable, Identifiable {
    /// `ActivityID.rawValue` — the string the monitor extension is woken with.
    public let id: String
    public let prayer: Prayer
    /// Local day key (`yyyy-MM-dd`) the window belongs to.
    public let day: String
    /// The prayer time itself; the window opens here.
    public let start: Date
    public let end: Date

    public init(id: String, prayer: Prayer, day: String, start: Date, end: Date) {
        self.id = id
        self.prayer = prayer
        self.day = day
        self.start = start
        self.end = end
    }

    public var activityID: ActivityID? { ActivityID(rawValue: id) }

    public func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

/// The rolling set of windows currently registered with the system.
///
/// The app writes this; the monitor extension reads it so that it can re-arm
/// the next days without recomputing prayer times itself. Astronomy stays in
/// the app, where there is memory to spare.
public struct PrayerSchedule: Codable, Sendable {
    public var windows: [PlannedWindow]
    public var generatedAt: Date
    /// Time zone the windows were computed in. A mismatch with the current time
    /// zone means the user travelled and the schedule must be rebuilt.
    public var timeZoneIdentifier: String

    public init(windows: [PlannedWindow] = [],
                generatedAt: Date = .distantPast,
                timeZoneIdentifier: String = TimeZone.current.identifier) {
        self.windows = windows
        self.generatedAt = generatedAt
        self.timeZoneIdentifier = timeZoneIdentifier
    }

    public func window(withID id: String) -> PlannedWindow? {
        windows.first { $0.id == id }
    }

    public func windows(on day: String) -> [PlannedWindow] {
        windows.filter { $0.day == day }.sorted { $0.start < $1.start }
    }

    /// Windows that have not finished yet, soonest first.
    public func upcoming(from date: Date = Date()) -> [PlannedWindow] {
        windows.filter { $0.end > date }.sorted { $0.start < $1.start }
    }
}
