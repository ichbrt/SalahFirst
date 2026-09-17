import Foundation

/// Preferences that only the app needs — anything the extensions read lives in
/// `SharedStore` instead.
///
/// Backed by `UserDefaults` in the App Group container so that a future
/// extension could read it without a migration, but written only here.
@MainActor
@Observable
public final class AppPreferences {

    private enum Key {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let prayerConfiguration = "prayerConfiguration"
        static let notificationsEnabled = "notificationsEnabled"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        self.defaults = defaults
            ?? UserDefaults(suiteName: AppGroup.identifier)
            ?? .standard
        _hasCompletedOnboarding = self.defaults.bool(forKey: Key.hasCompletedOnboarding)
        _notificationsEnabled = self.defaults.object(forKey: Key.notificationsEnabled) as? Bool ?? true
        _prayerConfiguration = Self.loadConfiguration(from: self.defaults)
    }

    private var _hasCompletedOnboarding: Bool
    public var hasCompletedOnboarding: Bool {
        get { _hasCompletedOnboarding }
        set {
            _hasCompletedOnboarding = newValue
            defaults.set(newValue, forKey: Key.hasCompletedOnboarding)
        }
    }

    private var _notificationsEnabled: Bool
    public var notificationsEnabled: Bool {
        get { _notificationsEnabled }
        set {
            _notificationsEnabled = newValue
            defaults.set(newValue, forKey: Key.notificationsEnabled)
        }
    }

    private var _prayerConfiguration: PrayerConfiguration
    public var prayerConfiguration: PrayerConfiguration {
        get { _prayerConfiguration }
        set {
            _prayerConfiguration = newValue
            if let data = try? JSONEncoder.shared.encode(newValue) {
                defaults.set(data, forKey: Key.prayerConfiguration)
            }
        }
    }

    private static func loadConfiguration(from defaults: UserDefaults) -> PrayerConfiguration {
        guard let data = defaults.data(forKey: Key.prayerConfiguration),
              let decoded = try? JSONDecoder.shared.decode(PrayerConfiguration.self, from: data) else {
            return PrayerConfiguration()
        }
        return decoded
    }

    /// Wipes everything this app has stored on the device.
    public func reset() {
        for key in [Key.hasCompletedOnboarding, Key.prayerConfiguration, Key.notificationsEnabled] {
            defaults.removeObject(forKey: key)
        }
        _hasCompletedOnboarding = false
        _notificationsEnabled = true
        _prayerConfiguration = PrayerConfiguration()
    }
}
