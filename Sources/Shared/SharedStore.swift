import Foundation

/// The three JSON documents that make up the shared state, in one place.
///
/// Each concern gets its own file so that writers rarely collide: the app owns
/// settings and the schedule, the monitor extension owns the open-window set,
/// and the journal is the only file two processes both write.
public enum SharedStore {

    public static let settings = SharedFileStore<BlockingSettings>(
        fileName: "settings.json",
        defaultValue: BlockingSettings()
    )

    public static let schedule = SharedFileStore<PrayerSchedule>(
        fileName: "schedule.json",
        defaultValue: PrayerSchedule()
    )

    public static let journal = SharedFileStore<BlockingJournal>(
        fileName: "journal.json",
        defaultValue: BlockingJournal()
    )

    public static let shieldState = SharedFileStore<ShieldState>(
        fileName: "shield-state.json",
        defaultValue: ShieldState()
    )
}

#if DEBUG
public extension SharedStore {
    /// Restores every shared document to its default. Test-only: the App Group
    /// container is unavailable under XCTest, so the stores fall back to their
    /// in-memory values and would otherwise leak state between test cases.
    static func resetForTesting() {
        settings.write(BlockingSettings())
        schedule.write(PrayerSchedule())
        journal.write(BlockingJournal())
        shieldState.write(ShieldState())
    }
}
#endif
