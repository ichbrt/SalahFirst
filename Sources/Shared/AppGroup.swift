import Foundation

/// Resolves the App Group container shared by the app and its three extensions.
///
/// The identifier is declared once, in `project.yml`, and injected into every
/// bundle's Info.plist as `SFAppGroupIdentifier`. Reading it back at runtime
/// means changing the App Group never requires touching Swift code.
public enum AppGroup {

    /// The App Group identifier for whichever bundle is asking (app or extension).
    public static let identifier: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "SFAppGroupIdentifier") as? String,
           value.isEmpty == false,
           value.hasPrefix("$") == false {
            return value
        }
        // Only reachable if the Info.plist was edited by hand and the key removed.
        assertionFailure("SFAppGroupIdentifier is missing from Info.plist")
        return "group.com.salahfirst.app"
    }()

    /// Directory that holds every file the app and its extensions share.
    ///
    /// Returns `nil` when the App Group is not provisioned — which happens on
    /// the Simulator without a signing team, and in unit tests. Callers treat
    /// that as "no shared state" rather than crashing.
    public static var containerURL: URL? {
        guard let root = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: identifier) else {
            return nil
        }
        let directory = root.appendingPathComponent("SalahFirst", isDirectory: true)
        if FileManager.default.fileExists(atPath: directory.path) == false {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory
    }

    /// Name shared by the app and extensions so they all mutate the same
    /// `ManagedSettingsStore`. Using a named store (rather than `.default`)
    /// keeps Salah First's restrictions separate from any other app's.
    public static let managedSettingsStoreName = "SalahFirst"
}
