import SwiftUI

/// Searchable list of the bundled cities.
struct CityPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    let onSelect: (City) -> Void

    private var results: [City] { CityDirectory.search(query) }

    var body: some View {
        NavigationStack {
            List(results) { city in
                Button {
                    onSelect(city)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.name)
                            .foregroundStyle(Theme.Palette.primary)
                        Text(city.country)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.secondary)
                    }
                }
                .accessibilityLabel(city.displayName)
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: L10n.string("city.search"))
            .navigationTitle(L10n.string("city.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) { dismiss() }
                }
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
        .tint(Theme.Palette.accent)
    }
}
