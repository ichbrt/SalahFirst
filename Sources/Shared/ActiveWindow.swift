import Foundation

/// Answers "which prayer window is the user in right now?" for every target.
///
/// The shield extension needs it to title the shield, and the app needs it to
/// decide whether to show the prayer screen instead of the home screen.
public enum ActiveWindow {

    public struct Resolved: Sendable, Equatable {
        public let prayer: Prayer
        public let day: String
        /// `nil` if the schedule cache was rebuilt since the window opened;
        /// the shield still works, it just cannot show a countdown.
        public let window: PlannedWindow?

        public var endsAt: Date? { window?.end }
    }

    /// The open, unresolved prayer window, if there is one.
    ///
    /// When windows overlap, the one that started most recently wins — that is
    /// the prayer the user is actually being asked about.
    public static func current(now: Date = Date()) -> Resolved? {
        let state = SharedStore.shieldState.read()
        guard state.openWindowIDs.isEmpty == false else { return nil }

        let journal = SharedStore.journal.read()
        let schedule = SharedStore.schedule.read()

        let candidates: [Resolved] = state.openWindowIDs.compactMap { rawID in
            guard let id = ActivityID(rawValue: rawID),
                  case let .prayer(prayer, day) = id,
                  journal.isResolved(prayer, on: day) == false else { return nil }
            return Resolved(prayer: prayer, day: day, window: schedule.window(withID: rawID))
        }

        return candidates.max { lhs, rhs in
            (lhs.window?.start ?? .distantPast) < (rhs.window?.start ?? .distantPast)
        }
    }
}
