import SwiftUI

/// The five prayers with a switch each. Used in onboarding and in Settings.
struct PrayerToggleList: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ForEach(Prayer.allCases) { prayer in
            Toggle(isOn: binding(for: prayer)) {
                HStack(spacing: Theme.Spacing.s) {
                    Image(systemName: prayer.symbolName)
                        .foregroundStyle(Theme.Palette.tertiary)
                        .frame(width: 22)
                    Text(L10n.prayerName(prayer))
                }
            }
            .tint(Theme.Palette.accent)
        }
    }

    private func binding(for prayer: Prayer) -> Binding<Bool> {
        Binding(
            get: { model.blocking.enabledPrayers.contains(prayer) },
            set: { isOn in
                Task {
                    await model.updateBlocking { settings in
                        if isOn {
                            settings.enabledPrayers.insert(prayer)
                        } else {
                            settings.enabledPrayers.remove(prayer)
                        }
                    }
                }
            }
        )
    }
}
