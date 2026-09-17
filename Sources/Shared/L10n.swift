import Foundation

/// Localized string lookup that works identically in the app and in the
/// extensions.
///
/// Extensions have their own bundle, so `Bundle.main` resolves to the extension
/// when called from one — which is why the `.lproj` folders are copied into the
/// shield targets as well. No user-facing string is ever written inline; adding
/// a language means adding a folder and nothing else.
public enum L10n {
    public static func string(_ key: String) -> String {
        Bundle.main.localizedString(forKey: key, value: key, table: nil)
    }

    public static func string(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), locale: .current, arguments: arguments)
    }

    /// "Maghrib" — the short name used in lists.
    public static func prayerName(_ prayer: Prayer) -> String {
        string(prayer.nameKey)
    }

    /// "Maghrib Prayer" — the long form used as a heading.
    public static func prayerTitle(_ prayer: Prayer) -> String {
        string("\(prayer.nameKey).full")
    }
}
