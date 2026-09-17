import BackgroundTasks
import Foundation
import os.log

/// Extends the rolling schedule in the background.
///
/// This is the outermost of four layers that keep blocking alive, and the only
/// best-effort one:
///
/// 1. The monitor extension re-arms whenever a window closes.
/// 2. Opening the app rebuilds everything.
/// 3. A prayer notification brings the user back into the app.
/// 4. This task, when iOS feels like granting it.
///
/// It exists for the user this app is actually for — the one who sets it up and
/// then stops opening it. Without it, blocking would quietly lapse once the
/// fourteen-day cache ran out. Nothing is fetched over the network; the "fetch"
/// background mode is simply the one BGAppRefreshTask requires.
public enum BackgroundRefreshService {

    public static let taskIdentifier = "com.salahfirst.app.refreshSchedule"

    private static let log = Logger(subsystem: "com.salahfirst.app", category: "BackgroundRefresh")

    /// Must be called before the app finishes launching, or `BGTaskScheduler`
    /// raises an exception when the task fires.
    public static func register(rebuild: @escaping @Sendable () async -> Void) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            handle(task, rebuild: rebuild)
        }
    }

    public static func scheduleNext() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        // Roughly daily. iOS treats this as "not before", never as a promise.
        request.earliestBeginDate = Date().addingTimeInterval(12 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Submission fails on the Simulator and when the user has disabled
            // Background App Refresh. Neither is worth surfacing: the other
            // three layers still work.
            log.info("Could not submit background refresh: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func handle(_ task: BGTask, rebuild: @escaping @Sendable () async -> Void) {
        // Queue the next one first: if this run is cut short, the chain
        // continues regardless.
        scheduleNext()

        let work = Task {
            await rebuild()
            task.setTaskCompleted(success: true)
        }

        task.expirationHandler = {
            work.cancel()
            task.setTaskCompleted(success: false)
        }
    }
}
