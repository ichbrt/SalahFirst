import SwiftUI

/// The privacy policy, in the app, in plain language.
///
/// Short enough to read, because a promise nobody reads is not a promise. Each
/// line describes something the code actually does — there is no analytics SDK,
/// no crash reporter and no network client anywhere in this project.
struct PrivacyView: View {

    private let points = [
        "privacy.point.noAccount",
        "privacy.point.noServer",
        "privacy.point.location",
        "privacy.point.apps",
        "privacy.point.history",
        "privacy.point.noMoney",
        "privacy.point.delete"
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text(L10n.string("privacy.intro"))
                    .font(.body)
                    .foregroundStyle(Theme.Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    ForEach(points, id: \.self) { key in
                        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                            Image(systemName: "checkmark")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.Palette.accent)
                                .accessibilityHidden(true)
                            Text(L10n.string(key))
                                .font(.callout)
                                .foregroundStyle(Theme.Palette.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .screenBackground()
        .navigationTitle(L10n.string("settings.privacy"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
