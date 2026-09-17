import Combine
import FamilyControls
import Foundation
import os.log

/// Owns the Screen Time (Family Controls) authorization.
///
/// Salah First asks for `.individual`, not `.child`: the user is restricting
/// their own device, so no Apple ID password or Family Sharing setup is
/// involved. `.child` would put the app behind a parent's passcode and is the
/// wrong model entirely.
@MainActor
@Observable
public final class ScreenTimeService {

    public private(set) var status: AuthorizationStatus
    /// Set when a request fails, so the UI can say what went wrong instead of
    /// silently doing nothing.
    public private(set) var lastErrorMessage: String?

    private let center = AuthorizationCenter.shared
    private var cancellable: AnyCancellable?
    private let log = Logger(subsystem: "com.salahfirst.app", category: "ScreenTime")

    /// Screen Time APIs are not implemented in the Simulator: authorization
    /// always fails there. The UI checks this so it can explain that rather
    /// than presenting a broken permission loop.
    public static var isSupportedOnThisDevice: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    public init() {
        status = center.authorizationStatus
        cancellable = center.$authorizationStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in
                guard let self else { return }
                let previous = self.status
                self.status = newStatus
                self.handleTransition(from: previous, to: newStatus)
            }
    }

    public var isApproved: Bool { status == .approved }

    @discardableResult
    public func requestAuthorization() async -> Bool {
        lastErrorMessage = nil

        guard Self.isSupportedOnThisDevice else {
            lastErrorMessage = L10n.string("status.simulator.body")
            return false
        }

        do {
            try await center.requestAuthorization(for: .individual)
            status = center.authorizationStatus
            log.info("Authorization approved")
            return status == .approved
        } catch {
            status = center.authorizationStatus
            lastErrorMessage = Self.message(for: error)
            log.error("Authorization failed: \(String(describing: error), privacy: .public)")
            return false
        }
    }

    /// Called when the user revokes Screen Time access from iOS Settings while
    /// windows are still armed. Without this the app would keep believing it
    /// can shield apps, and the user would see a schedule that does nothing.
    private func handleTransition(from previous: AuthorizationStatus,
                                  to current: AuthorizationStatus) {
        guard previous == .approved, current != .approved else { return }
        log.info("Authorization revoked; disarming")
        DeviceActivityScheduler.disarm()
    }

    private static func message(for error: Error) -> String {
        guard let familyError = error as? FamilyControlsError else {
            return error.localizedDescription
        }
        switch familyError {
        case .authorizationCanceled:
            // The user dismissed the sheet. Not an error worth showing.
            return ""
        case .restricted:
            return L10n.string("status.screentime.denied.body")
        case .invalidAccountType:
            return L10n.string("status.screentime.denied.body")
        default:
            return familyError.errorDescription ?? L10n.string("status.screentime.denied.body")
        }
    }
}
