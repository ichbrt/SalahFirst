import Foundation

/// Turns prayer times into the concrete windows the system will monitor.
///
/// Lives in the app, not the extension: it needs a location, Adhan, and enough
/// memory to do astronomy. The result is written to the shared schedule file,
/// which is all the monitor extension ever reads.
public enum SchedulePlanner {

    /// Builds the rolling schedule.
    ///
    /// - Parameters:
    ///   - now: windows that have already finished are left out.
    ///   - days: how far ahead to plan. The monitor extension can only re-arm
    ///     from what is in this cache, so this is how long blocking survives
    ///     without the app being opened.
    public static func plan(engine: PrayerTimesEngine,
                            settings: BlockingSettings,
                            now: Date = Date(),
                            days: Int = DeviceActivityScheduler.cacheHorizonDays) -> PrayerSchedule {

        let windowLength = TimeInterval(settings.clampedWindowMinutes * 60)
        let minimumLength = TimeInterval(BlockingSettings.minimumWindowMinutes * 60)

        let dailyTimes = engine.days(from: now, count: days)

        // Flattened and sorted so each window can see the prayer that follows
        // it, even across a day boundary (Isha's successor is tomorrow's Fajr).
        //
        // The day key comes from the prayer's own instant, not from the day it
        // was computed for. At high latitude, Isha calculated for 20 June can
        // fall at 00:30 on the 21st; filing it under the 20th would mean the
        // completion the user records at 00:31 — on the 21st — never matches
        // the window, and the shield would stay up.
        let calendar = DayKey.calendar
        let allPrayers: [(prayer: Prayer, time: Date, day: String)] = dailyTimes
            .flatMap { daily in
                daily.ordered.map {
                    (prayer: $0.prayer, time: $0.time, day: DayKey.string(for: $0.time, calendar: calendar))
                }
            }
            .sorted { $0.time < $1.time }

        var windows: [PlannedWindow] = []

        for (index, entry) in allPrayers.enumerated() {
            guard settings.enabledPrayers.contains(entry.prayer) else { continue }

            let start = entry.time
            var end = start.addingTimeInterval(windowLength)

            // Do not let one window run past the next prayer: being shielded
            // for Maghrib when it is already Isha would be confusing, and the
            // Isha window is about to take over anyway.
            if index + 1 < allPrayers.count {
                end = min(end, allPrayers[index + 1].time)
            }

            // The system refuses anything under fifteen minutes. When prayers
            // fall closer together than that — which happens at high latitude
            // in midsummer — the windows are allowed to overlap instead, and
            // `ShieldEngine` lifts the shield only once both have closed.
            end = max(end, start.addingTimeInterval(minimumLength))

            guard end > now else { continue }

            windows.append(
                PlannedWindow(
                    id: ActivityID.prayer(entry.prayer, day: entry.day).rawValue,
                    prayer: entry.prayer,
                    day: entry.day,
                    start: start,
                    end: end
                )
            )
        }

        return PrayerSchedule(
            windows: windows,
            generatedAt: now,
            timeZoneIdentifier: TimeZone.current.identifier
        )
    }
}
