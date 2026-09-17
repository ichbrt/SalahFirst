import UIKit

/// Colors for the shield, which cannot read the app's asset catalog.
///
/// The shield is drawn by a separate process, on top of whichever app the user
/// just opened, so it carries its own small palette defined in code.
///
/// The palette stays dark in both appearances on purpose: the shield sits over
/// an arbitrary app's last frame, and a light panel over a dark app (or the
/// reverse) reads as a glitch. A dark, deliberate panel reads as a pause.
///
/// Every value here is opaque. Translucent colors would composite against the
/// background at draw time, which means `ContrastTests` — reading raw
/// components — would measure a color that is never actually shown.
public enum ShieldPalette {

    /// Tints the dark material the shield is drawn on.
    ///
    /// This is a tint, not a fill: the blur material supplies the surface and
    /// this colour shifts it. Saturated well past what the final result looks
    /// like, because the material desaturates whatever is underneath.
    public static let background = UIColor(red: 0.020, green: 0.125, blue: 0.133, alpha: 1.0)

    public static let primaryText = UIColor(red: 0.980, green: 0.980, blue: 0.973, alpha: 1.0)

    /// Dimmer than the title, with a slight cool cast, so the two read as a
    /// hierarchy rather than two headlines. 6.2:1 on `background`.
    public static let secondaryText = UIColor(red: 0.541, green: 0.594, blue: 0.598, alpha: 1.0)

    /// Muted teal used for the single emphasised control and the icon.
    public static let accent = UIColor(red: 0.42, green: 0.78, blue: 0.73, alpha: 1.0)

    /// Text drawn on top of `accent`. Comfortably past WCAG AA.
    public static let accentText = UIColor(red: 0.04, green: 0.10, blue: 0.12, alpha: 1.0)

    /// Label for the secondary button.
    ///
    /// iOS draws that button on a light capsule of its own choosing — the
    /// shield API exposes no background color for it — so this has to be dark.
    /// The near-white `secondaryText` used here originally was unreadable on
    /// device and made the button look disabled.
    public static let secondaryButtonText = UIColor(red: 0.07, green: 0.11, blue: 0.13, alpha: 1.0)
}
