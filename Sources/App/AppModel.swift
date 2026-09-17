import Combine
import FamilyControls
import Foundation
import SwiftUI
import os.log

/// The app's single source of truth, and the only place that writes to
/// `SharedStore` from the app side.
///
/// Everything the UI shows is derived state recomputed by `refresh()`, so the
/// screens stay simple and there is exactly one path from "something changed"
/// to "the system knows about it": `rebuildSchedule()`.
@MainActor
@Observable
public final class AppModel {

    public let preferences: AppPreferences
    public let screenTime: ScreenTimeService
    public let location: LocationService
    public let notifications: NotificationService

    // MARK: Derived state

    public private(set) var blocking: BlockingSettings
    public private(set) var journal: BlockingJournal
    public private(set) var today: DailyPrayerTimes?
    public private(set) var next: UpcomingPrayer?
    public private(set) var activeWindow: ActiveWindow.Resolved?
    public private(set) var lastScheduleError: String?

    /// Ticks once a minute so the countdown stays honest without redrawing
    /// sixty times a second.
    public private(set) var now = Date()

    private var timerCancellable: AnyCancellable?
    private let observers = ObserverTokens()
    private let log = Logger(subsystem: "com.salahfirst.app", category: "AppModel")

    /// Dependencies are optional rather than defaulted: a default argument on a
    /// `@MainActor` initialiser is evaluated outside the actor, which these
    /// main-actor services cannot be.
    public init(preferences: AppPreferences? = nil,
                screenTime: ScreenTimeService? = nil,
                location: LocationService? = nil,
                notifications: NotificationService? = nil) {
        self.preferences = preferences ?? AppPreferences()
        self.screenTime = screenTime ?? ScreenTimeService()
        self.location = location ?? LocationService()
        self.notifications = notifications ?? NotificationService()
        self.blocking = SharedStore.settings.read()
        self.journal = SharedStore.journal.read()

        refresh()
        startTimer()
        observeSystemChanges()
    }

    // MARK: - Derived values

    public var engine: PrayerTimesEngine {
        PrayerTimesEngine(configuration: preferences.prayerConfiguration)
    }

    public var isConfigured: Bool {
        preferences.prayerConfiguration.isComplete
    }

    /// True when everything blocking needs is in place.
    public var isReadyToBlock: Bool {
        isConfigured && screenTime.isApproved && blocking.hasSelection
    }

    public var todayKey: String { DayKey.string(for: now) }

    public var completedToday: Int {
        journal.completedCount(on: todayKey)
    }

    public var enabledPrayerCount: Int {
        max(blocking.enabledPrayers.count, 1)
    }

    /// Completed prayers over the last seven days, against the number of
    /// enabled prayers in that span. Shown as a plain ratio — never as a streak
    /// that can be "lost".
    public var weekProgress: (completed: Int, total: Int) {
        let calendar = DayKey.calendar
        var completed = 0
        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            completed += journal.completedCount(on: DayKey.string(for: day))
        }
        return (completed, blocking.enabledPrayers.count * 7)
    }

    public func status(for prayer: Prayer) -> PrayerDayStatus {
        if let outcome = journal.outcome(for: prayer, on: todayKey) {
            return outcome == .completed ? .completed : .skipped
        }
        guard let time = today?.time(for: prayer) else { return .upcoming }
        return time <= now ? .passed : .upcoming
    }

    // MARK: - Refresh

    /// Recomputes everything the UI reads. Cheap, and safe to call often.
    public func refresh() {
        now = Date()
        blocking = SharedStore.settings.read()
        journal = SharedStore.journal.read()
        activeWindow = ActiveWindow.current(now: now)

        guard isConfigured else {
            today = nil
            next = nil
            return
        }
        let engine = engine
        today = engine.times(on: now)
        next = engine.next(after: now)
    }

    // MARK: - Mutations

    public func updateBlocking(_ transform: (inout BlockingSettings) -> Void) async {
        var settings = blocking
        transform(&settings)
        settings.windowMinutes = settings.clampedWindowMinutes
        SharedStore.settings.write(settings)
        blocking = settings
        await rebuildSchedule()
    }

    public func updateConfiguration(_ transform: (inout PrayerConfiguration) -> Void) async {
        var configuration = preferences.prayerConfiguration
        transform(&configuration)
        preferences.prayerConfiguration = configuration
        await rebuildSchedule()
    }

    /// Recomputes the schedule, hands it to the system, and refreshes
    /// notifications. Every change funnels through here.
    public func rebuildSchedule() async {
        refresh()
        lastScheduleError = nil

        guard isConfigured else {
            DeviceActivityScheduler.disarm()
            await notifications.reschedule(for: PrayerSchedule(), enabled: false)
            return
        }

        let schedule = SchedulePlanner.plan(engine: engine, settings: blocking, now: Date())
        SharedStore.schedule.write(schedule)

        if blocking.isActionable && screenTime.isApproved {
            switch DeviceActivityScheduler.arm() {
            case .unauthorized:
                lastScheduleError = L10n.string("status.screentime.denied.body")
            case .armed, .nothingToDo:
                break
            }
        } else {
            DeviceActivityScheduler.disarm()
        }

        await notifications.reschedule(for: schedule, enabled: preferences.notificationsEnabled)

        // Bring the shield back in line with the rebuilt state — for instance
        // after the user disabled the prayer whose window is open right now.
        ShieldEngine.reconcile()
        refresh()
    }

    /// Resolves a prayer against a specific day.
    ///
    /// Callers pass the *window's* day rather than today's: a window that opened
    /// at 23:50 is still that day's prayer when the user finishes it at 00:05,
    /// and recording it under the new day would leave the shield up.
    public func complete(_ prayer: Prayer, on day: String? = nil) async {
        ShieldEngine.resolve(prayer, on: day ?? todayKey, outcome: .completed)
        await rebuildSchedule()
    }

    public func skip(_ prayer: Prayer, on day: String? = nil) async {
        ShieldEngine.resolve(prayer, on: day ?? todayKey, outcome: .skipped)
        await rebuildSchedule()
    }

    /// Undo, for the user who tapped "I have prayed" by mistake. Only offered
    /// for today, and only while the window is still open.
    public func clearOutcome(_ prayer: Prayer) async {
        SharedStore.journal.mutate { $0.clear(prayer, on: todayKey) }
        await rebuildSchedule()
    }

    public func resetEverything() async {
        DeviceActivityScheduler.disarm()
        await notifications.removeAll()
        SharedStore.settings.write(BlockingSettings())
        SharedStore.schedule.write(PrayerSchedule())
        SharedStore.journal.write(BlockingJournal())
        SharedStore.shieldState.write(ShieldState())
        preferences.reset()
        refresh()
    }

    // MARK: - System changes

    private func startTimer() {
        timerCancellable = Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    /// Travel, daylight saving, and the phone simply being asleep past midnight
    /// all invalidate a schedule built from wall-clock times. Each of these
    /// notifications means "recompute from scratch".
    private func observeSystemChanges() {
        let names: [Notification.Name] = [
            .NSSystemTimeZoneDidChange,
            UIApplication.significantTimeChangeNotification
        ]
        observers.tokens = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.log.info("System time context changed; rebuilding schedule")
                    await self.rebuildSchedule()
                }
            }
        }
    }

    /// Called when the app comes to the foreground.
    ///
    /// Re-arms the rolling horizon and reconciles the shield, which is what
    /// makes opening the app a reliable way to recover from anything the
    /// background path missed.
    public func handleForeground() async {
        await screenTime_refreshIfNeeded()
        await notifications.refreshAuthorization()
        ShieldEngine.reconcile()
        await rebuildSchedule()
    }

    private func screenTime_refreshIfNeeded() async {
        // Authorization can be revoked in iOS Settings while the app is
        // suspended; `ScreenTimeService` observes it, but reading it here makes
        // the foreground path deterministic.
        if screenTime.isApproved == false && blocking.isEnabled {
            await updateBlocking { $0.isEnabled = false }
        }
    }
}

/// Holds notification observer tokens and unregisters them when the model goes
/// away. A separate object because `deinit` on a `@MainActor` type runs outside
/// the actor and so cannot touch the model's own stored properties.
private final class ObserverTokens: @unchecked Sendable {
    var tokens: [NSObjectProtocol] = []
    deinit { tokens.forEach(NotificationCenter.default.removeObserver) }
}

public enum PrayerDayStatus {
    case completed
    case skipped
    /// Its time has come and gone without the user resolving it. Shown
    /// neutrally — never as a failure.
    case passed
    case upcoming
}
