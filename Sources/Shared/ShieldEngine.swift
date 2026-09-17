import Foundation
@preconcurrency import ManagedSettings
import os.log

/// The one place that decides whether apps are shielded right now.
///
/// Shared by the monitor extension (interval boundaries), the shield-action
/// extension (buttons on the shield) and the app (the "I have prayed" button),
/// because all three can change the answer and all three must reach the same
/// conclusion. Every mutation funnels through `reconcile()`, which recomputes
/// the shield from scratch — making the operations idempotent and safe to
/// repeat after a crash, a reboot, or an extension relaunch.
public enum ShieldEngine {

    private static let log = Logger(subsystem: "com.salahfirst.app", category: "ShieldEngine")

    private static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: ManagedSettingsStore.Name(AppGroup.managedSettingsStoreName))
    }

    // MARK: - Interval boundaries

    /// A prayer window just opened. Called from `intervalDidStart`.
    public static func openWindow(_ id: ActivityID) {
        SharedStore.shieldState.mutate { state in
            state.openWindowIDs.insert(id.rawValue)
            state.updatedAt = Date()
        }
        reconcile()
    }

    /// A prayer window just closed. Called from `intervalDidEnd`.
    public static func closeWindow(_ id: ActivityID) {
        SharedStore.shieldState.mutate { state in
            state.openWindowIDs.remove(id.rawValue)
            state.updatedAt = Date()
        }
        reconcile()
    }

    // MARK: - User decisions

    /// The user finished the prayer, or chose to skip this one.
    ///
    /// Records the outcome and lifts the shield for that window. The system
    /// keeps the interval running until its scheduled end; `reconcile()` simply
    /// stops treating it as a reason to shield.
    public static func resolve(_ prayer: Prayer, on day: String, outcome: PrayerOutcome) {
        SharedStore.journal.mutate { journal in
            journal.record(outcome, for: prayer, on: day)
        }
        SharedStore.shieldState.mutate { state in
            state.openWindowIDs.remove(ActivityID.prayer(prayer, day: day).rawValue)
            state.updatedAt = Date()
        }
        reconcile()
    }

    // MARK: - Reconciliation

    /// Recomputes the shield from the current shared state.
    ///
    /// Safe to call at any time from any target. This is what makes the system
    /// self-healing: if an extension was killed mid-update, the next call puts
    /// the device back into the state the data describes.
    public static func reconcile() {
        let settings = SharedStore.settings.read()
        let journal = SharedStore.journal.read()
        let state = SharedStore.shieldState.read()

        if shouldShield(settings: settings, journal: journal, state: state) {
            apply(settings)
        } else {
            clear()
        }
    }

    /// The whole blocking decision, as a pure function.
    ///
    /// Split out from `reconcile()` so it can be tested without a provisioned
    /// `ManagedSettingsStore` — and because "are we blocking right now?" is the
    /// single most important question in this app, and it deserves to be
    /// readable in one screen.
    public static func shouldShield(settings: BlockingSettings,
                                    journal: BlockingJournal,
                                    state: ShieldState) -> Bool {
        shouldShield(isActionable: settings.isActionable, journal: journal, state: state)
    }

    /// The same decision, with the precondition passed in directly.
    ///
    /// `ApplicationToken` values can only come from Apple's picker and cannot be
    /// constructed in a test, so this overload keeps the window logic reachable
    /// without them. `BlockingSettings.isActionable` is covered on its own.
    public static func shouldShield(isActionable: Bool,
                                    journal: BlockingJournal,
                                    state: ShieldState) -> Bool {
        guard isActionable else { return false }

        return state.openWindowIDs.contains { rawID in
            guard let id = ActivityID(rawValue: rawID) else { return false }
            switch id {
            case let .prayer(prayer, day):
                // An already-resolved prayer stops shielding even though its
                // interval is still running — this covers the user who prayed
                // before the window opened, and the one who used the escape
                // hatch.
                return journal.isResolved(prayer, on: day) == false
            case .manualFocus:
                return true
            }
        }
    }

    /// Removes every restriction this app has applied. Used when the user turns
    /// blocking off, revokes authorization, or deletes their selection.
    public static func clearEverything() {
        SharedStore.shieldState.write(ShieldState(openWindowIDs: [], updatedAt: Date()))
        clear()
    }

    // MARK: - ManagedSettings

    private static func apply(_ settings: BlockingSettings) {
        let store = store
        store.shield.applications = settings.applicationTokens.isEmpty ? nil : settings.applicationTokens
        store.shield.applicationCategories = settings.categoryTokens.isEmpty
            ? nil
            : .specific(settings.categoryTokens)
        store.shield.webDomainCategories = settings.categoryTokens.isEmpty
            ? nil
            : .specific(settings.categoryTokens)
        log.info("Shield applied: \(settings.applicationTokens.count) apps, \(settings.categoryTokens.count) categories")
    }

    private static func clear() {
        let store = store
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil
        log.info("Shield cleared")
    }
}
