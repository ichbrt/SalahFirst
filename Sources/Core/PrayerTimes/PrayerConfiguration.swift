import Adhan
import Foundation

/// Where the user is, as far as prayer times are concerned.
///
/// Stored on the device and nowhere else. Coordinates are rounded to three
/// decimal places — about 100 metres — which is far more precision than prayer
/// times need and far less than is needed to identify a home address.
public struct PrayerLocation: Codable, Equatable, Sendable {
    public var latitude: Double
    public var longitude: Double
    /// Shown in Settings so the user can tell at a glance what is in use.
    public var name: String?
    /// `true` when it came from Core Location, `false` when picked from the city list.
    public var isAutomatic: Bool

    public init(latitude: Double, longitude: Double, name: String? = nil, isAutomatic: Bool) {
        self.latitude = (latitude * 1000).rounded() / 1000
        self.longitude = (longitude * 1000).rounded() / 1000
        self.name = name
        self.isAutomatic = isAutomatic
    }

    var coordinates: Coordinates {
        Coordinates(latitude: latitude, longitude: longitude)
    }
}

/// The calculation methods offered in Settings.
///
/// A curated subset of Adhan's list — every entry here is one an actual
/// authority publishes, so the user is choosing between real conventions rather
/// than reading a menu of angles.
public enum CalculationMethodOption: String, Codable, CaseIterable, Sendable, Identifiable {
    case turkey
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case qatar
    case kuwait
    case singapore
    case northAmerica
    case moonsightingCommittee
    case tehran

    public var id: String { rawValue }

    /// Names of official bodies, not UI copy, so they are intentionally not
    /// localized — "Diyanet" is "Diyanet" in every language.
    public var displayName: String {
        switch self {
        // Kept short: these are shown inline in a settings row, where the long
        // official titles truncated to things like "Diyanet...şkanlığı".
        case .turkey:               return "Diyanet"
        case .muslimWorldLeague:    return "Muslim World League"
        case .egyptian:             return "Egyptian Authority"
        case .karachi:              return "Karachi"
        case .ummAlQura:            return "Umm al-Qura"
        case .dubai:                return "Dubai"
        case .qatar:                return "Qatar"
        case .kuwait:               return "Kuwait"
        case .singapore:            return "Singapore"
        case .northAmerica:         return "ISNA"
        case .moonsightingCommittee: return "Moonsighting"
        case .tehran:               return "Tehran"
        }
    }

    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .turkey:               return .turkey
        case .muslimWorldLeague:    return .muslimWorldLeague
        case .egyptian:             return .egyptian
        case .karachi:              return .karachi
        case .ummAlQura:            return .ummAlQura
        case .dubai:                return .dubai
        case .qatar:                return .qatar
        case .kuwait:               return .kuwait
        case .singapore:            return .singapore
        case .northAmerica:         return .northAmerica
        case .moonsightingCommittee: return .moonsightingCommittee
        case .tehran:               return .tehran
        }
    }

    /// Picks a sensible default from the device's region rather than asking the
    /// user a question they probably cannot answer on first launch.
    public static func `default`(for locale: Locale = .current) -> CalculationMethodOption {
        switch locale.region?.identifier {
        case "TR":                              return .turkey
        case "SA":                              return .ummAlQura
        case "AE":                              return .dubai
        case "QA":                              return .qatar
        case "KW":                              return .kuwait
        case "EG":                              return .egyptian
        case "PK", "IN", "BD", "AF":            return .karachi
        case "SG", "MY", "ID", "BN":            return .singapore
        case "US", "CA":                        return .northAmerica
        case "IR":                              return .tehran
        default:                                return .muslimWorldLeague
        }
    }
}

/// Which shadow length defines Asr.
public enum MadhabOption: String, Codable, CaseIterable, Sendable, Identifiable {
    /// Also used for Maliki, Hanbali and Jafari.
    case shafi
    case hanafi

    public var id: String { rawValue }
    public var nameKey: String { "settings.madhab.\(rawValue)" }

    var adhanMadhab: Adhan.Madhab {
        switch self {
        case .shafi:  return .shafi
        case .hanafi: return .hanafi
        }
    }
}

/// Everything needed to turn a date into five times.
public struct PrayerConfiguration: Codable, Equatable, Sendable {
    public var location: PrayerLocation?
    public var method: CalculationMethodOption
    public var madhab: MadhabOption

    public init(location: PrayerLocation? = nil,
                method: CalculationMethodOption = .default(),
                madhab: MadhabOption = .shafi) {
        self.location = location
        self.method = method
        self.madhab = madhab
    }

    public var isComplete: Bool { location != nil }

    var adhanParameters: CalculationParameters? {
        guard let location else { return nil }
        var parameters = method.adhanMethod.params
        parameters.madhab = madhab.adhanMadhab
        // Above roughly 48° latitude, Fajr and Isha angles stop being reachable
        // for part of the year and the calculation returns nothing usable.
        // Adhan's rule fills those nights in; without it a user in Scandinavia
        // would see an empty schedule all summer.
        parameters.highLatitudeRule = .recommended(for: location.coordinates)
        return parameters
    }
}
