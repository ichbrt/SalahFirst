import Foundation
import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the screen the user sees instead of the app they just opened.
///
/// Tone is the whole point here. It names the prayer, says the app will still
/// be there afterwards, and stops. No streak counter, no guilt, no red.
final class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfiguration(appName: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfiguration(appName: webDomain.domain)
    }

    // MARK: -

    private func makeConfiguration(appName: String?) -> ShieldConfiguration {
        let active = ActiveWindow.current()

        let title = active.map { L10n.prayerTitle($0.prayer) }
            ?? L10n.string("shield.title.generic")

        // "Instagram will still be here." — naming the app makes the promise
        // concrete. Falls back to a neutral line when the system does not give
        // us a display name.
        let subtitle: String
        if let appName, appName.isEmpty == false {
            subtitle = L10n.string("shield.subtitle.named", appName)
        } else {
            subtitle = L10n.string("shield.subtitle.generic")
        }

        return ShieldConfiguration(
            // The blur style is what actually paints the surface here;
            // `backgroundColor` only tints it. Passing `nil` does not give a
            // solid colour — it drops the shield onto the system's own light
            // background, which left this near-white title unreadable on
            // device. A dark material is therefore load-bearing, not decoration.
            backgroundBlurStyle: .systemThickMaterialDark,
            backgroundColor: ShieldPalette.background,
            icon: icon(for: active?.prayer),
            title: ShieldConfiguration.Label(text: title, color: ShieldPalette.primaryText),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: ShieldPalette.secondaryText),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: L10n.string("shield.button.close"),
                color: ShieldPalette.accentText
            ),
            primaryButtonBackgroundColor: ShieldPalette.accent,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: L10n.string("shield.button.completed"),
                color: ShieldPalette.secondaryButtonText
            )
        )
    }

    private func icon(for prayer: Prayer?) -> UIImage? {
        let symbolName = prayer?.symbolName ?? "moon.stars"
        // Larger and a touch heavier than the original: at `.light` weight and
        // 44pt the symbol read as faint rather than calm.
        let configuration = UIImage.SymbolConfiguration(pointSize: 56, weight: .regular)
            .applying(UIImage.SymbolConfiguration(paletteColors: [ShieldPalette.accent]))
        return UIImage(systemName: symbolName, withConfiguration: configuration)
    }
}
