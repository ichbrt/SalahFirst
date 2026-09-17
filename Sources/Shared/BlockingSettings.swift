import Foundation
@preconcurrency import ManagedSettings

/// Everything the extensions need in order to decide *what* to shield.
///
/// Written only by the app; read by all three extensions. Deliberately holds
/// raw `ManagedSettings` tokens rather than a `FamilyControls`
/// `FamilyActivitySelection`, so the extensions never have to link
/// FamilyControls (and, through it, SwiftUI and UIKit). That matters most for
/// the Device Activity monitor, which runs under a very small memory budget.
public struct BlockingSettings: Codable, Sendable, Equatable {

    /// Shortest window the system will accept. `DeviceActivityCenter` throws
    /// `MonitoringError.intervalTooShort` below this.
    public static let minimumWindowMinutes = 15
    public static let maximumWindowMinutes = 60
    public static let defaultWindowMinutes = 20

    /// Master switch. Turning this off stops monitoring entirely and is the
    /// user's guaranteed way out.
    public var isEnabled: Bool

    /// Which of the five prayers should start a window.
    public var enabledPrayers: Set<Prayer>

    /// How long apps stay shielded once a prayer time arrives, unless the user
    /// finishes early. Clamped to the system's accepted range.
    public var windowMinutes: Int

    public var applicationTokens: Set<ApplicationToken>
    public var categoryTokens: Set<ActivityCategoryToken>
    public var webDomainTokens: Set<WebDomainToken>

    /// Mirrors `FamilyActivitySelection.includeEntireCategory` so the picker
    /// can be rebuilt exactly as the user left it.
    public var includeEntireCategory: Bool

    public init(
        isEnabled: Bool = false,
        enabledPrayers: Set<Prayer> = Set(Prayer.allCases),
        windowMinutes: Int = BlockingSettings.defaultWindowMinutes,
        applicationTokens: Set<ApplicationToken> = [],
        categoryTokens: Set<ActivityCategoryToken> = [],
        webDomainTokens: Set<WebDomainToken> = [],
        includeEntireCategory: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.enabledPrayers = enabledPrayers
        self.windowMinutes = windowMinutes
        self.applicationTokens = applicationTokens
        self.categoryTokens = categoryTokens
        self.webDomainTokens = webDomainTokens
        self.includeEntireCategory = includeEntireCategory
    }

    /// True when the user has picked at least one thing to block. With an empty
    /// selection there is nothing to shield, so monitoring is pointless.
    public var hasSelection: Bool {
        applicationTokens.isEmpty == false
            || categoryTokens.isEmpty == false
            || webDomainTokens.isEmpty == false
    }

    /// Blocking only runs when the user turned it on, picked something to
    /// block, and left at least one prayer enabled.
    public var isActionable: Bool {
        isEnabled && hasSelection && enabledPrayers.isEmpty == false
    }

    public var clampedWindowMinutes: Int {
        min(max(windowMinutes, Self.minimumWindowMinutes), Self.maximumWindowMinutes)
    }

    // Older builds may not have written every key; decode defensively so a
    // model change never leaves the user with a corrupt settings file.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? false
        enabledPrayers = try container.decodeIfPresent(Set<Prayer>.self, forKey: .enabledPrayers) ?? Set(Prayer.allCases)
        windowMinutes = try container.decodeIfPresent(Int.self, forKey: .windowMinutes) ?? Self.defaultWindowMinutes
        applicationTokens = try container.decodeIfPresent(Set<ApplicationToken>.self, forKey: .applicationTokens) ?? []
        categoryTokens = try container.decodeIfPresent(Set<ActivityCategoryToken>.self, forKey: .categoryTokens) ?? []
        webDomainTokens = try container.decodeIfPresent(Set<WebDomainToken>.self, forKey: .webDomainTokens) ?? []
        includeEntireCategory = try container.decodeIfPresent(Bool.self, forKey: .includeEntireCategory) ?? false
    }
}
