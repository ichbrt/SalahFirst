import DeviceActivity
import Foundation
import os.log

/// Applies and lifts the shield at prayer window boundaries.
///
/// This runs whether or not Salah First is open — including after a reboot,
/// because `DeviceActivityCenter` registrations survive one. It is the reason
/// blocking is reliable rather than best-effort, and it is also the tightest
/// place in the app: the system gives this extension a few megabytes and a few
/// seconds. It therefore does no astronomy, no networking and no UI work; it
/// reads two small JSON files and writes one.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let log = Logger(subsystem: "com.salahfirst.app", category: "Monitor")

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard let id = ActivityID(rawValue: activity.rawValue) else {
            log.error("Unrecognised activity \(activity.rawValue, privacy: .public)")
            return
        }
        log.info("Window opened: \(activity.rawValue, privacy: .public)")
        ShieldEngine.openWindow(id)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard let id = ActivityID(rawValue: activity.rawValue) else { return }
        log.info("Window closed: \(activity.rawValue, privacy: .public)")
        ShieldEngine.closeWindow(id)

        // A finished window frees a monitoring slot. Re-arm from the cached
        // schedule so the horizon keeps rolling forward even if the user never
        // opens the app.
        DeviceActivityScheduler.arm()
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }
}
