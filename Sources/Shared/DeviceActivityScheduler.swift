import DeviceActivity
import Foundation
import os.log

/// Registers prayer windows with the system so they fire even when Salah First
/// is not running.
///
/// Two horizons, because the system's limits and our data are different sizes:
///
/// * `maxMonitoredActivities` windows are handed to `DeviceActivityCenter` at a
///   time. The system allows twenty per app *including its extensions*; we stay
///   under that so a future manual-focus session always has room.
/// * `cacheHorizonDays` days of windows are written to the shared schedule file.
///   The monitor extension cannot compute prayer times — it has neither the
///   memory budget nor a location — so it re-arms from this cache as windows
///   are consumed. Two weeks of cover for a user who never opens the app.
public enum DeviceActivityScheduler {

    /// The system's hard ceiling is 20 for the app and its extensions combined.
    public static let maxMonitoredActivities = 15
    public static let cacheHorizonDays = 14

    private static let log = Logger(subsystem: "com.salahfirst.app", category: "Scheduler")

    public enum ArmResult {
        case armed(started: Int, stopped: Int)
        case nothingToDo
        case unauthorized
    }

    /// Brings the set of monitored activities in line with the cached schedule.
    ///
    /// Only the difference is applied: windows already being monitored are left
    /// alone. That matters because a window can be *open* right now, and
    /// stopping it would drop the shield out from under the user.
    @discardableResult
    public static func arm(now: Date = Date()) -> ArmResult {
        let settings = SharedStore.settings.read()
        let center = DeviceActivityCenter()

        guard settings.isActionable else {
            let existing = center.activities
            if existing.isEmpty == false {
                center.stopMonitoring(existing)
                log.info("Blocking is off; stopped \(existing.count) activities")
            }
            ShieldEngine.clearEverything()
            return .nothingToDo
        }

        let schedule = SharedStore.schedule.read()
        let journal = SharedStore.journal.read()

        // Windows still ahead of us, skipping ones the user already resolved,
        // capped at what the system will accept.
        let desired = schedule.upcoming(from: now)
            .filter { settings.enabledPrayers.contains($0.prayer) }
            .filter { journal.isResolved($0.prayer, on: $0.day) == false }
            .prefix(maxMonitoredActivities)

        let desiredIDs = Set(desired.map(\.id))
        let existingIDs = Set(center.activities.map(\.rawValue))

        let toStop = existingIDs.subtracting(desiredIDs)
        let toStart = desired.filter { existingIDs.contains($0.id) == false }

        if toStop.isEmpty == false {
            center.stopMonitoring(toStop.map { DeviceActivityName($0) })
        }

        var started = 0
        for window in toStart {
            guard let activitySchedule = makeSchedule(for: window, now: now) else { continue }
            do {
                try center.startMonitoring(DeviceActivityName(window.id), during: activitySchedule)
                started += 1
            } catch {
                log.error("startMonitoring failed for \(window.id, privacy: .public): \(describe(error), privacy: .public)")
                if let monitoringError = error as? DeviceActivityCenter.MonitoringError,
                   monitoringError == .unauthorized {
                    return .unauthorized
                }
            }
        }

        log.info("Armed \(started) window(s), stopped \(toStop.count)")
        return .armed(started: started, stopped: toStop.count)
    }

    /// Stops every window and drops any active shield. The user's way out.
    public static func disarm() {
        let center = DeviceActivityCenter()
        center.stopMonitoring(center.activities)
        ShieldEngine.clearEverything()
        log.info("Disarmed all activities")
    }

    // MARK: - Schedule construction

    /// Builds a one-shot schedule pinned to a specific calendar date.
    ///
    /// Prayer times move by a few minutes every day, so a repeating schedule —
    /// which carries only an hour and a minute — would drift away from the real
    /// times within a week. Full date components with `repeats: false` keep each
    /// window exact, at the cost of having to re-arm as they are consumed.
    static func makeSchedule(for window: PlannedWindow,
                             now: Date = Date(),
                             calendar: Calendar = .current) -> DeviceActivitySchedule? {
        // The system rejects anything shorter than fifteen minutes with
        // `MonitoringError.intervalTooShort`.
        let minimumEnd = window.start.addingTimeInterval(
            TimeInterval(BlockingSettings.minimumWindowMinutes * 60)
        )
        let end = max(window.end, minimumEnd)

        guard end > now else { return nil }

        let fields: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute]
        return DeviceActivitySchedule(
            intervalStart: calendar.dateComponents(fields, from: window.start),
            intervalEnd: calendar.dateComponents(fields, from: end),
            repeats: false
        )
    }

    private static func describe(_ error: Error) -> String {
        guard let monitoringError = error as? DeviceActivityCenter.MonitoringError else {
            return error.localizedDescription
        }
        switch monitoringError {
        case .excessiveActivities:  return "excessiveActivities (more than 20 monitored)"
        case .intervalTooLong:      return "intervalTooLong (longer than a week)"
        case .intervalTooShort:     return "intervalTooShort (shorter than 15 minutes)"
        case .invalidDateComponents: return "invalidDateComponents"
        case .unauthorized:         return "unauthorized (Screen Time permission missing)"
        @unknown default:           return "unknown MonitoringError"
        }
    }
}
