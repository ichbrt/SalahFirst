import XCTest
@testable import SalahFirst

/// Covers the states the blocking system can be found in, including the ones
/// that only happen to real users: permission revoked mid-use, an extension
/// relaunched halfway through a window, two windows overlapping, and a prayer
/// finished before its window even opened.
final class BlockingTests: XCTestCase {

    private let today = "2026-09-16"

    /// `isActionable` stands in for "the user turned blocking on, picked at
    /// least one app, and left at least one prayer enabled" — the token-backed
    /// half of which is covered by the `BlockingSettings` tests below.
    private let actionable = true

    // MARK: - Preconditions

    func testBlockingIsInactiveWithoutAnySelection() {
        var settings = BlockingSettings()
        settings.isEnabled = true
        XCTAssertFalse(settings.hasSelection)
        XCTAssertFalse(settings.isActionable, "Nothing selected means nothing to block")
    }

    func testBlockingIsInactiveWhenNoPrayersAreEnabled() {
        var settings = BlockingSettings()
        settings.isEnabled = true
        settings.enabledPrayers = []
        XCTAssertFalse(settings.isActionable)
    }

    func testBlockingIsInactiveWhenTurnedOff() {
        var settings = BlockingSettings()
        settings.isEnabled = false
        settings.enabledPrayers = Set(Prayer.allCases)
        XCTAssertFalse(settings.isActionable)
    }

    /// Screen Time permission refused or revoked: even with a window open and a
    /// full selection, nothing is shielded.
    func testRevokedAuthorisationIsRepresentedByDisablingBlocking() {
        let state = ShieldState(openWindowIDs: [ActivityID.prayer(.maghrib, day: today).rawValue])
        XCTAssertTrue(ShieldEngine.shouldShield(isActionable: true, journal: BlockingJournal(), state: state))

        // `AppModel` flips blocking off when authorisation is lost, which makes
        // the settings inactionable and drops the shield.
        XCTAssertFalse(ShieldEngine.shouldShield(isActionable: false, journal: BlockingJournal(), state: state))
    }

    // MARK: - Window lifecycle

    func testOpenWindowShieldsAndClosedWindowDoesNot() {
        let id = ActivityID.prayer(.maghrib, day: today).rawValue

        XCTAssertTrue(ShieldEngine.shouldShield(
            isActionable: actionable, journal: BlockingJournal(),
            state: ShieldState(openWindowIDs: [id])
        ))
        XCTAssertFalse(ShieldEngine.shouldShield(
            isActionable: actionable, journal: BlockingJournal(),
            state: ShieldState(openWindowIDs: [])
        ))
    }

    func testCompletingAPrayerLiftsTheShieldWhileTheIntervalIsStillRunning() {
        let state = ShieldState(openWindowIDs: [ActivityID.prayer(.maghrib, day: today).rawValue])

        var journal = BlockingJournal()
        journal.record(.completed, for: .maghrib, on: today)

        XCTAssertFalse(ShieldEngine.shouldShield(isActionable: actionable, journal: journal, state: state))
    }

    /// The escape hatch must work exactly like completion as far as the shield
    /// is concerned — the difference is only in what we count, never in what we
    /// let the user do.
    func testSkippingLiftsTheShieldToo() {
        let state = ShieldState(openWindowIDs: [ActivityID.prayer(.maghrib, day: today).rawValue])

        var journal = BlockingJournal()
        journal.record(.skipped, for: .maghrib, on: today)

        XCTAssertFalse(ShieldEngine.shouldShield(isActionable: actionable, journal: journal, state: state))
    }

    /// Prayed before the window opened: the monitor extension still fires
    /// `intervalDidStart`, and must not shield.
    func testPrayerCompletedEarlyIsNotShieldedWhenItsWindowOpens() {
        var journal = BlockingJournal()
        journal.record(.completed, for: .maghrib, on: today)

        let state = ShieldState(openWindowIDs: [ActivityID.prayer(.maghrib, day: today).rawValue])
        XCTAssertFalse(ShieldEngine.shouldShield(isActionable: actionable, journal: journal, state: state))
    }

    /// Maghrib finished, Isha has begun: closing Maghrib's interval must not
    /// drop the shield that Isha is holding up.
    func testOverlappingWindowsKeepTheShieldUntilTheLastOneCloses() {
        let maghrib = ActivityID.prayer(.maghrib, day: today).rawValue
        let isha = ActivityID.prayer(.isha, day: today).rawValue

        var journal = BlockingJournal()
        journal.record(.completed, for: .maghrib, on: today)

        // Both intervals are open; Maghrib is resolved but Isha is not.
        XCTAssertTrue(ShieldEngine.shouldShield(
            isActionable: actionable, journal: journal,
            state: ShieldState(openWindowIDs: [maghrib, isha])
        ))

        journal.record(.completed, for: .isha, on: today)
        XCTAssertFalse(ShieldEngine.shouldShield(
            isActionable: actionable, journal: journal,
            state: ShieldState(openWindowIDs: [maghrib, isha])
        ))
    }

    /// The monitor extension can be relaunched and replay a boundary. Opening
    /// the same window twice must not change the outcome.
    func testRepeatedIntervalStartsAreIdempotent() {
        var state = ShieldState()
        let id = ActivityID.prayer(.asr, day: today).rawValue
        state.openWindowIDs.insert(id)
        state.openWindowIDs.insert(id)
        XCTAssertEqual(state.openWindowIDs.count, 1)
    }

    /// A day that is no longer today must not keep the shield up — a stale
    /// entry from a crashed extension should not trap the user tomorrow.
    func testUnparseableActivityIDsNeverShield() {
        let state = ShieldState(openWindowIDs: ["garbage", "prayer.notAPrayer.2026-09-16"])
        XCTAssertFalse(ShieldEngine.shouldShield(isActionable: actionable, journal: BlockingJournal(), state: state))
    }

    // MARK: - ActivityID

    func testActivityIDRoundTrips() {
        for prayer in Prayer.allCases {
            let id = ActivityID.prayer(prayer, day: today)
            let decoded = ActivityID(rawValue: id.rawValue)
            XCTAssertEqual(decoded, id)
            XCTAssertEqual(decoded?.prayer, prayer)
        }
        XCTAssertEqual(ActivityID(rawValue: "focus.manual"), .manualFocus)
        XCTAssertNil(ActivityID(rawValue: "prayer.maghrib"))
        XCTAssertNil(ActivityID(rawValue: ""))
        XCTAssertNil(ActivityID(rawValue: "prayer.zuhr.2026-09-16"))
    }

    // MARK: - Journal

    func testJournalReplacesRatherThanDuplicatesAnOutcome() {
        var journal = BlockingJournal()
        journal.record(.skipped, for: .fajr, on: today)
        journal.record(.completed, for: .fajr, on: today)

        XCTAssertEqual(journal.entries.filter { $0.prayer == .fajr && $0.day == today }.count, 1)
        XCTAssertEqual(journal.outcome(for: .fajr, on: today), .completed)
        XCTAssertEqual(journal.completedCount(on: today), 1)
    }

    func testSkippedDoesNotCountAsCompleted() {
        var journal = BlockingJournal()
        journal.record(.skipped, for: .fajr, on: today)
        journal.record(.completed, for: .dhuhr, on: today)

        XCTAssertEqual(journal.completedCount(on: today), 1)
        XCTAssertTrue(journal.isResolved(.fajr, on: today), "Skipped still counts as resolved")
    }

    func testJournalPrunesBeyondRetention() {
        var journal = BlockingJournal()
        let ancient = Calendar.current.date(byAdding: .day, value: -400, to: Date())!
        journal.entries = [JournalEntry(day: "2025-01-01", prayer: .fajr,
                                        outcome: .completed, recordedAt: ancient)]
        journal.record(.completed, for: .dhuhr, on: today)

        XCTAssertEqual(journal.entries.count, 1)
        XCTAssertEqual(journal.entries.first?.prayer, .dhuhr)
    }

    // MARK: - Settings decoding

    /// A settings file written by an older build must not wipe the user's
    /// configuration when a new key is added.
    func testSettingsDecodeFromAPartialDocument() throws {
        let json = Data(#"{"isEnabled":true,"windowMinutes":25}"#.utf8)
        let settings = try JSONDecoder.shared.decode(BlockingSettings.self, from: json)

        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.windowMinutes, 25)
        XCTAssertEqual(settings.enabledPrayers, Set(Prayer.allCases), "Missing key falls back to the default")
        XCTAssertTrue(settings.applicationTokens.isEmpty)
    }

    func testWindowLengthIsClampedToWhatTheSystemAccepts() {
        var settings = BlockingSettings()
        settings.windowMinutes = 3
        XCTAssertEqual(settings.clampedWindowMinutes, BlockingSettings.minimumWindowMinutes)

        settings.windowMinutes = 600
        XCTAssertEqual(settings.clampedWindowMinutes, BlockingSettings.maximumWindowMinutes)
    }

    // MARK: - City search

    func testCitySearchIgnoresDiacriticsAndTurkishDottedI() {
        XCTAssertTrue(CityDirectory.search("istanbul").contains { $0.name == "İstanbul" })
        XCTAssertTrue(CityDirectory.search("İSTANBUL").contains { $0.name == "İstanbul" })
        XCTAssertTrue(CityDirectory.search("sanliurfa").contains { $0.name == "Şanlıurfa" })
        XCTAssertTrue(CityDirectory.search("diyarbakir").contains { $0.name == "Diyarbakır" })
        XCTAssertTrue(CityDirectory.search("kuala").contains { $0.name == "Kuala Lumpur" })
    }

    func testCityDirectoryCoversEveryTurkishProvince() {
        let turkish = CityDirectory.all.filter { $0.country == "Türkiye" }
        XCTAssertEqual(turkish.count, 81)
        XCTAssertEqual(Set(turkish.map(\.name)).count, 81, "No duplicates")
    }

    func testCityIdentifiersAreUnique() {
        XCTAssertEqual(Set(CityDirectory.all.map(\.id)).count, CityDirectory.all.count)
    }
}
