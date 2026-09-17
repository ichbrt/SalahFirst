import SwiftUI

/// Shown while a prayer window is open.
///
/// One statement and one action. The escape hatch is present and reachable, but
/// quiet — the user is never trapped, and never told off for using it.
struct PrayerWindowView: View {
    @Environment(AppModel.self) private var model
    let active: ActiveWindow.Resolved

    @State private var isConfirmingSkip = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.l) {
                Image(systemName: active.prayer.symbolName)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Theme.Palette.accent)
                    .accessibilityHidden(true)

                VStack(spacing: Theme.Spacing.s) {
                    Text(L10n.prayerTitle(active.prayer))
                        .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.Palette.primary)
                        .multilineTextAlignment(.center)

                    Text(L10n.string("window.waiting.generic"))
                        .font(.title3)
                        .foregroundStyle(Theme.Palette.secondary)
                        .multilineTextAlignment(.center)

                    Text(L10n.string("window.instruction"))
                        .font(.title3)
                        .foregroundStyle(Theme.Palette.secondary)
                        .multilineTextAlignment(.center)
                }
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)

                if let remaining {
                    Text(L10n.string("window.remaining", Format.countdown(remaining)))
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.tertiary)
                        .accessibilityLabel(
                            L10n.string("window.remaining", Format.countdownAccessible(remaining))
                        )
                }
            }
            .padding(.horizontal, Theme.Spacing.l)

            Spacer(minLength: Theme.Spacing.xl)

            VStack(spacing: Theme.Spacing.xs) {
                SFPrimaryButton(L10n.string("window.completed.action")) {
                    Task { await model.complete(active.prayer, on: active.day) }
                }

                // Deliberately a plain text button, below the fold of attention.
                // Findable without being an invitation.
                SFSecondaryButton(L10n.string("window.skip.action")) {
                    isConfirmingSkip = true
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .screenBackground()
        .confirmationDialog(
            L10n.string("window.skip.title"),
            isPresented: $isConfirmingSkip,
            titleVisibility: .visible
        ) {
            Button(L10n.string("window.skip.confirm")) {
                Task { await model.skip(active.prayer, on: active.day) }
            }
            Button(L10n.string("common.cancel"), role: .cancel) {}
        } message: {
            Text(L10n.string("window.skip.body"))
        }
    }

    /// `nil` when the schedule cache was rebuilt since this window opened; the
    /// screen still works, it just does not claim to know the end time.
    private var remaining: TimeInterval? {
        guard let endsAt = active.endsAt else { return nil }
        let interval = endsAt.timeIntervalSince(model.now)
        return interval > 0 ? interval : nil
    }
}
