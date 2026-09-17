import FamilyControls
import SwiftUI

/// Wraps Apple's `FamilyActivityPicker`, the only sanctioned way to let a user
/// choose apps.
///
/// The picker runs out of process and hands back opaque tokens: Salah First
/// never learns which apps are installed, or which ones were chosen. That is
/// Apple's design, and it happens to be exactly the privacy guarantee this app
/// wants to make.
struct AppSelectionSection: View {
    @Environment(AppModel.self) private var model

    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var hasLoaded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Button {
                isPickerPresented = true
            } label: {
                HStack {
                    Text(L10n.string("onboarding.apps.choose"))
                        .foregroundStyle(Theme.Palette.primary)
                    Spacer()
                    Text(summary)
                        .foregroundStyle(Theme.Palette.secondary)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.Palette.tertiary)
                }
            }
            .disabled(model.screenTime.isApproved == false)
            .accessibilityLabel("\(L10n.string("onboarding.apps.choose")), \(summary)")

            if model.screenTime.isApproved == false {
                Text(L10n.string("status.screentime.notDetermined"))
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.tertiary)
            }
        }
        .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
        .task {
            guard hasLoaded == false else { return }
            hasLoaded = true
            selection = Self.makeSelection(from: model.blocking)
        }
        .onChange(of: selection) { _, newValue in
            // Ignore the initial load, and anything that is not a real change.
            guard hasLoaded else { return }
            Task { await save(newValue) }
        }
    }

    private var summary: String {
        let count = selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
        return count == 0
            ? L10n.string("onboarding.apps.none")
            : L10n.string("onboarding.apps.count", count)
    }

    private func save(_ newValue: FamilyActivitySelection) async {
        await model.updateBlocking { settings in
            settings.applicationTokens = newValue.applicationTokens
            settings.categoryTokens = newValue.categoryTokens
            settings.webDomainTokens = newValue.webDomainTokens
            settings.includeEntireCategory = newValue.includeEntireCategory
        }
    }

    /// Rebuilds the picker's state from what we stored, so reopening it shows
    /// the user's existing choices rather than an empty list.
    static func makeSelection(from settings: BlockingSettings) -> FamilyActivitySelection {
        var selection = FamilyActivitySelection(includeEntireCategory: settings.includeEntireCategory)
        selection.applicationTokens = settings.applicationTokens
        selection.categoryTokens = settings.categoryTokens
        selection.webDomainTokens = settings.webDomainTokens
        return selection
    }
}
