import SwiftUI

/// The app's visual vocabulary, kept small on purpose.
///
/// Every font here is a system text style, so Dynamic Type works everywhere
/// without per-view handling, and the layout is built from a single spacing
/// scale rather than ad-hoc numbers.
public enum Theme {

    public enum Palette {
        public static let background = Color("SurfaceBackground")
        public static let card = Color("SurfaceCard")
        public static let primary = Color("TextPrimary")
        public static let secondary = Color("TextSecondary")
        public static let tertiary = Color("TextTertiary")
        public static let separator = Color("Separator")
        public static let accent = Color("AccentColor")
        /// Text and glyphs drawn on top of `accent`. White reads well over the
        /// darker light-mode teal but gives only 2.4:1 over the lighter dark-mode
        /// one, so this flips to near-black in dark mode. Both directions clear
        /// WCAG AA; `ContrastTests` holds that line.
        public static let onAccent = Color("OnAccent")
    }

    /// A 4-point scale. Generous by default — the whole app is meant to feel
    /// unhurried, and whitespace is most of how that reads.
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }

    public enum Radius {
        public static let card: CGFloat = 18
        public static let control: CGFloat = 14
    }
}

public extension View {
    /// Standard page padding and background.
    func screenBackground() -> some View {
        self.background(Theme.Palette.background.ignoresSafeArea())
    }
}

/// A grouped block of content. Used instead of `List` wherever the content is
/// display rather than navigation, so spacing stays under our control.
public struct SFCard<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.m)
            .background(Theme.Palette.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// The one emphasised control on a screen. There is never more than one.
public struct SFPrimaryButton: View {
    private let title: String
    private let isEnabled: Bool
    private let action: () -> Void

    public init(_ title: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.m)
        }
        .background(isEnabled ? Theme.Palette.accent : Theme.Palette.separator)
        .foregroundStyle(isEnabled ? Theme.Palette.onAccent : Theme.Palette.tertiary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
        .disabled(isEnabled == false)
    }
}

/// A quieter control. Used for escape hatches, which should be findable but
/// never compete with the primary action.
public struct SFSecondaryButton: View {
    private let title: String
    private let role: ButtonRole?
    private let action: () -> Void

    public init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.s)
        }
        .foregroundStyle(role == .destructive ? Color.red : Theme.Palette.secondary)
    }
}

/// Screen heading plus supporting copy, used by every onboarding step so the
/// rhythm is identical across them.
public struct SFHeader: View {
    private let title: String
    private let subtitle: String?

    public init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Theme.Palette.primary)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(Theme.Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
