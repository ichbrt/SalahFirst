import SwiftUI

/// The default screen: what is next, how today has gone, and nothing else.
struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.l) {
                    NextPrayerCard()
                    TodayCard()
                    WeekCard()
                    BlockingStatusCard()
                }
                .padding(.horizontal, Theme.Spacing.m)
                .padding(.vertical, Theme.Spacing.l)
            }
            .patternedBackground()
            .navigationTitle(L10n.string("app.name"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(L10n.string("settings.title"))
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
        .tint(Theme.Palette.accent)
    }
}

// MARK: - Next prayer

private struct NextPrayerCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SFCard {
            if let next = model.next {
                HStack(alignment: .top, spacing: Theme.Spacing.m) {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(L10n.string("home.next"))
                            .font(.caption.weight(.semibold))
                            .tracking(0.8)
                            .foregroundStyle(Theme.Palette.tertiary)
                            .textCase(.uppercase)

                        Text(L10n.prayerName(next.prayer))
                            .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.Palette.primary)

                        HStack(spacing: Theme.Spacing.xs) {
                            Text(Format.countdown(next.interval(from: model.now)))
                                .font(.title3)
                                .foregroundStyle(Theme.Palette.secondary)
                            Text("·")
                                .foregroundStyle(Theme.Palette.tertiary)
                            Text(Format.time(next.time))
                                .font(.title3.monospacedDigit())
                                .foregroundStyle(Theme.Palette.secondary)
                        }
                    }

                    Spacer(minLength: 0)

                    Image(systemName: next.prayer.symbolName)
                        .font(.system(size: 42, weight: .light))
                        .foregroundStyle(Theme.Palette.accent)
                        .opacity(0.55)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "\(L10n.string("home.next")): \(L10n.prayerName(next.prayer)), "
                    + Format.countdownAccessible(next.interval(from: model.now))
                )
            } else {
                UnavailableTimesContent()
            }
        }
    }
}

/// Two different reasons produce an empty schedule, and conflating them would
/// send the user to the wrong setting.
private struct UnavailableTimesContent: View {
    @Environment(AppModel.self) private var model
    @State private var isShowingSettings = false

    /// A location is set, but the sun neither rises nor sets there at this time
    /// of year, so Maghrib has nothing to anchor to. Real above roughly 66°.
    private var isPolarBlackout: Bool { model.isConfigured }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(L10n.string(isPolarBlackout
                             ? "status.times.unavailable.title"
                             : "status.location.denied.title"))
                .font(.headline)
                .foregroundStyle(Theme.Palette.primary)
            Text(L10n.string(isPolarBlackout
                             ? "status.times.unavailable.body"
                             : "status.location.denied.body"))
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.string("settings.location")) { isShowingSettings = true }
                .font(.subheadline.weight(.medium))
                .padding(.top, Theme.Spacing.xxs)
        }
        .sheet(isPresented: $isShowingSettings) { SettingsView() }
    }
}

// MARK: - Today

private struct TodayCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        SFCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    Text(L10n.string("home.today"))
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.primary)
                    Spacer()
                    Text(L10n.string("home.progress", model.completedToday, model.blocking.enabledPrayers.count))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.Palette.secondary)
                        .accessibilityLabel(
                            "\(model.completedToday) / \(model.blocking.enabledPrayers.count)"
                        )
                }

                VStack(spacing: 0) {
                    ForEach(Array(Prayer.allCases.enumerated()), id: \.element) { index, prayer in
                        PrayerRow(prayer: prayer)
                        if index < Prayer.allCases.count - 1 {
                            Divider().overlay(Theme.Palette.separator)
                        }
                    }
                }
            }
        }
    }
}

private struct PrayerRow: View {
    @Environment(AppModel.self) private var model
    let prayer: Prayer

    private var isEnabled: Bool { model.blocking.enabledPrayers.contains(prayer) }
    private var status: PrayerDayStatus { model.status(for: prayer) }
    private var time: Date? { model.today?.time(for: prayer) }

    var body: some View {
        HStack(spacing: Theme.Spacing.s) {
            Image(systemName: statusSymbol)
                .font(.body)
                .foregroundStyle(statusColor)
                .frame(width: 22)

            Text(L10n.prayerName(prayer))
                .font(.body)
                .foregroundStyle(isEnabled ? Theme.Palette.primary : Theme.Palette.tertiary)

            Spacer()

            if let time {
                Text(Format.time(time))
                    .font(.body.monospacedDigit())
                    .foregroundStyle(Theme.Palette.secondary)
            }
        }
        .padding(.vertical, Theme.Spacing.s)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var statusSymbol: String {
        switch status {
        case .completed: return "checkmark.circle.fill"
        case .skipped:   return "circle.dashed"
        case .passed:    return "circle"
        case .upcoming:  return "circle"
        }
    }

    private var statusColor: Color {
        switch status {
        case .completed: return Theme.Palette.accent
        // A passed-but-unresolved prayer looks exactly like an upcoming one.
        // There is no red state anywhere in this app.
        case .skipped, .passed, .upcoming: return Theme.Palette.tertiary
        }
    }

    private var accessibilityLabel: String {
        var parts = [L10n.prayerName(prayer)]
        if let time { parts.append(Format.time(time)) }
        switch status {
        case .completed: parts.append(L10n.string("home.status.completed"))
        case .skipped:   parts.append(L10n.string("home.status.skipped"))
        case .passed, .upcoming: parts.append(L10n.string("home.status.upcoming"))
        }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Week

private struct WeekCard: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let progress = model.weekProgress
        SFCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                HStack {
                    Text(L10n.string("home.week"))
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.secondary)
                    Spacer()
                    Text(L10n.string("home.weekProgress", progress.completed, progress.total))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.Palette.primary)
                }
                // Without this line the denominator reads like a quota — "you
                // get 35" — rather than "35 prayer times occurred". It says
                // what is being counted and over what span.
                Text(L10n.string("home.week.caption"))
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.tertiary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                L10n.string("home.week.accessibility", progress.completed, progress.total)
            )
        }
    }
}

// MARK: - Blocking status

private struct BlockingStatusCard: View {
    @Environment(AppModel.self) private var model
    @State private var isShowingSettings = false

    var body: some View {
        SFCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: model.blocking.isActionable ? "lock.fill" : "lock.open")
                        .foregroundStyle(model.blocking.isActionable ? Theme.Palette.accent : Theme.Palette.tertiary)
                    Text(model.blocking.isActionable
                         ? L10n.string("home.blocking.on")
                         : L10n.string("home.blocking.off"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Theme.Palette.primary)
                    Spacer()
                }

                if model.blocking.isActionable == false {
                    Text(reason)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(L10n.string("home.setup.needed")) { isShowingSettings = true }
                        .font(.subheadline.weight(.medium))
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) { SettingsView() }
    }

    private var reason: String {
        if model.screenTime.isApproved == false {
            return L10n.string("status.screentime.notDetermined")
        }
        if model.blocking.hasSelection == false {
            return L10n.string("status.noSelection.body")
        }
        return L10n.string("settings.blocking.footer")
    }
}
