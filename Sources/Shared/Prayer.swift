import Foundation

/// The five daily prayers, in the order they occur.
///
/// `rawValue` is persisted in the App Group and encoded into
/// `DeviceActivityName`s, so these strings must stay stable across releases.
public enum Prayer: String, Codable, CaseIterable, Sendable, Identifiable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    public var id: String { rawValue }

    /// Key into `Localizable.strings`. Never show `rawValue` in the UI.
    public var nameKey: String { "prayer.\(rawValue)" }

    /// SF Symbol used on the home screen and the shield.
    public var symbolName: String {
        switch self {
        case .fajr:    return "sunrise"
        case .dhuhr:   return "sun.max"
        case .asr:     return "sun.min"
        case .maghrib: return "sunset"
        case .isha:    return "moon.stars"
        }
    }
}
