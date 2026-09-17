import Foundation
import UserNotifications
import os.log

/// Local notifications at prayer times. There is no push infrastructure behind
/// this app and never will be: every notification is scheduled on the device
/// from times the device calculated.
@MainActor
@Observable
public final class NotificationService {

    /// iOS keeps at most 64 pending local notifications per app and silently
    /// drops the rest. Staying under it means the ones we do schedule are the
    /// soonest ones, rather than an arbitrary subset.
    private static let maximumPending = 60

    private static let identifierPrefix = "prayer."

    public private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()
    private let log = Logger(subsystem: "com.salahfirst.app", category: "Notifications")

    public init() {}

    public func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    @discardableResult
    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            isAuthorized = granted
            return granted
        } catch {
            log.error("Notification authorization failed: \(error.localizedDescription, privacy: .public)")
            isAuthorized = false
            return false
        }
    }

    /// Replaces every prayer notification with ones matching the current
    /// schedule. Called whenever the schedule is rebuilt, so notifications can
    /// never drift away from the windows they announce.
    public func reschedule(for schedule: PrayerSchedule, enabled: Bool, now: Date = Date()) async {
        await removeAll()

        guard enabled else { return }
        await refreshAuthorization()
        guard isAuthorized else { return }

        let calendar = PrayerTimesEngine.gregorianCalendar()
        let upcoming = schedule.windows
            .filter { $0.start > now }
            .sorted { $0.start < $1.start }
            .prefix(Self.maximumPending)

        for window in upcoming {
            let content = UNMutableNotificationContent()
            content.title = L10n.string("notification.prayer.title", L10n.prayerName(window.prayer))
            content.body = L10n.string("notification.prayer.body")
            content.sound = .default
            // Not time-sensitive: the point of this app is to be quieter than
            // the apps it pauses, and a prayer time is not an emergency.
            content.interruptionLevel = .active

            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                     from: window.start)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.identifierPrefix + window.id,
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
            } catch {
                log.error("Could not schedule \(window.id, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }

        log.info("Scheduled \(upcoming.count) prayer notifications")
    }

    /// Removes only this app's prayer notifications, leaving anything else the
    /// system has pending untouched.
    public func removeAll() async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.map(\.identifier).filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }
}
