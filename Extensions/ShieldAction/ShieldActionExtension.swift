import Foundation
import ManagedSettings
import os.log

/// Handles the two buttons on the shield.
///
/// The primary button simply dismisses — the point of the shield is the pause,
/// not a trap. The secondary button is "I have prayed": it resolves the window
/// straight from the shield, so finishing never requires hunting for the app.
final class ShieldActionExtension: ShieldActionDelegate {

    private let log = Logger(subsystem: "com.salahfirst.app", category: "ShieldAction")

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction,
                         for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(respond(to: action))
    }

    private func respond(to action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            // "Close" — leave the shield in place and return the user home.
            return .close

        case .secondaryButtonPressed:
            guard let active = ActiveWindow.current() else {
                // No window open; nothing to resolve. Defer so the system
                // re-evaluates and lets the user through.
                log.info("Secondary pressed with no open window")
                return .defer
            }
            log.info("Prayer completed from shield: \(active.prayer.rawValue, privacy: .public)")
            ShieldEngine.resolve(active.prayer, on: active.day, outcome: .completed)
            return .defer

        @unknown default:
            return .close
        }
    }
}
