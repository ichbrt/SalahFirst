import Foundation

/// Which windows are currently open, from the system's point of view.
///
/// Written by the Device Activity monitor extension at interval boundaries, and
/// by the app when the user resolves a window early. Kept separate from
/// `BlockingSettings` so the app and the extension almost never write the same
/// file.
public struct ShieldState: Codable, Sendable, Equatable {
    /// `ActivityID.rawValue`s whose interval has started and not yet ended.
    ///
    /// A set rather than a single value because two windows can overlap — near
    /// the summer solstice at high latitude, Maghrib and Isha can fall less
    /// than a window apart. Shields lift only when the set empties.
    public var openWindowIDs: Set<String>
    public var updatedAt: Date

    public init(openWindowIDs: Set<String> = [], updatedAt: Date = .distantPast) {
        self.openWindowIDs = openWindowIDs
        self.updatedAt = updatedAt
    }
}
