import UIKit
import XCTest
@testable import SalahFirst

/// Holds the palette to WCAG AA.
///
/// These numbers are easy to break by eye — the dark-mode accent in particular
/// looks fine with white text and measures 2.4:1 — so they are asserted rather
/// than trusted. Every pair here is one the app actually draws.
final class ContrastTests: XCTestCase {

    /// WCAG 2.1 AA for body text.
    private let minimumBodyContrast = 4.5
    /// AA for text at 18pt or above, and for UI component boundaries.
    private let minimumLargeTextContrast = 3.0

    // MARK: - Asset catalogue

    func testTextColoursClearAAInBothAppearances() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let card = try! resolve("SurfaceCard", style)
            let background = try! resolve("SurfaceBackground", style)

            for name in ["TextPrimary", "TextSecondary", "TextTertiary"] {
                let text = try! resolve(name, style)
                assertContrast(text, card, atLeast: minimumBodyContrast,
                               "\(name) on SurfaceCard (\(describe(style)))")
                assertContrast(text, background, atLeast: minimumBodyContrast,
                               "\(name) on SurfaceBackground (\(describe(style)))")
            }
        }
    }

    /// The primary button: one fill, one label colour, in two appearances.
    func testPrimaryButtonLabelClearsAAOnTheAccentFill() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let accent = try! resolve("AccentColor", style)
            let onAccent = try! resolve("OnAccent", style)
            assertContrast(onAccent, accent, atLeast: minimumBodyContrast,
                           "OnAccent on AccentColor (\(describe(style)))")
        }
    }

    /// The accent is also used on its own for glyphs and the completed-prayer
    /// tick, where the 3:1 component threshold applies.
    func testAccentIsDistinguishableAgainstTheSurfacesItSitsOn() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let accent = try! resolve("AccentColor", style)
            let card = try! resolve("SurfaceCard", style)
            assertContrast(accent, card, atLeast: minimumLargeTextContrast,
                           "AccentColor on SurfaceCard (\(describe(style)))")
        }
    }

    // MARK: - Shield

    /// The shield draws in its own process and cannot read the asset catalogue,
    /// so its palette is defined in code and checked separately.
    func testShieldPaletteClearsAA() {
        assertContrast(ShieldPalette.primaryText, ShieldPalette.background,
                       atLeast: minimumBodyContrast, "Shield title")
        assertContrast(ShieldPalette.secondaryText, ShieldPalette.background,
                       atLeast: minimumBodyContrast, "Shield subtitle")
        assertContrast(ShieldPalette.accentText, ShieldPalette.accent,
                       atLeast: minimumBodyContrast, "Shield primary button label")
    }

    /// The shield's secondary button is drawn by iOS on a light capsule of its
    /// own — the API exposes no background colour for it — so its label must be
    /// dark. Shipping the near-white `secondaryText` here made the button look
    /// disabled on device; this pins the fix.
    func testShieldSecondaryButtonLabelIsReadableOnAlightCapsule() {
        // Approximates the capsule iOS draws behind that button.
        let systemCapsule = UIColor(white: 0.78, alpha: 1.0)
        assertContrast(ShieldPalette.secondaryButtonText, systemCapsule,
                       atLeast: minimumBodyContrast, "Shield secondary button label")

        // Guards the specific regression. A dark colour contrasts strongly with
        // white; the near-white label that shipped would score close to 1:1 here
        // and fail.
        XCTAssertGreaterThan(
            Self.contrastRatio(ShieldPalette.secondaryButtonText, .white), 4.5,
            "The secondary label must be dark — a light one is invisible on the capsule iOS draws"
        )
    }

    // MARK: - Helpers

    private func resolve(_ name: String, _ style: UIUserInterfaceStyle) throws -> UIColor {
        let color = try XCTUnwrap(UIColor(named: name), "Missing colour set: \(name)")
        return color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    private func describe(_ style: UIUserInterfaceStyle) -> String {
        style == .dark ? "dark" : "light"
    }

    private func assertContrast(_ foreground: UIColor,
                                _ background: UIColor,
                                atLeast minimum: Double,
                                _ label: String,
                                file: StaticString = #filePath,
                                line: UInt = #line) {
        let value = Self.contrastRatio(foreground, background)
        XCTAssertGreaterThanOrEqual(
            value, minimum,
            String(format: "%@ is %.2f:1, below the %.1f:1 required", label, value, minimum),
            file: file, line: line
        )
    }

    /// WCAG 2.1 relative luminance and contrast ratio.
    static func contrastRatio(_ a: UIColor, _ b: UIColor) -> Double {
        let (high, low) = {
            let la = luminance(a), lb = luminance(b)
            return (max(la, lb), min(la, lb))
        }()
        return (high + 0.05) / (low + 0.05)
    }

    private static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)

        func channel(_ value: CGFloat) -> Double {
            let v = Double(value)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    /// Sanity check on the maths itself, against the two ratios everyone knows.
    func testContrastFormulaMatchesKnownValues() {
        XCTAssertEqual(Self.contrastRatio(.white, .black), 21, accuracy: 0.01)
        XCTAssertEqual(Self.contrastRatio(.white, .white), 1, accuracy: 0.01)
    }
}
