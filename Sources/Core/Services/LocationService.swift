import CoreLocation
import Foundation
import os.log

/// One-shot location lookup for prayer time calculation.
///
/// Deliberately minimal: `requestLocation()` rather than continuous updates, so
/// the app never runs the GPS in the background, and no reverse geocoding —
/// resolving a coordinate to a city name would send that coordinate to Apple's
/// servers, which would break the promise that nothing leaves the device. The
/// user who wants a named place picks one from the bundled city list instead.
@MainActor
@Observable
public final class LocationService: NSObject {

    public private(set) var authorizationStatus: CLAuthorizationStatus
    public private(set) var isResolving = false

    private let manager = CLLocationManager()
    private var continuations: [CheckedContinuation<CLLocation?, Never>] = []
    private let log = Logger(subsystem: "com.salahfirst.app", category: "Location")

    public override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        // Prayer times shift by under a minute across tens of kilometres, so
        // coarse accuracy is plenty and costs far less battery.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    public var isDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    public var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    /// Asks for permission if needed, then resolves a single fix.
    /// Returns `nil` if permission is refused or the fix fails.
    public func requestLocation() async -> CLLocation? {
        if authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            // Give the delegate a moment to report the user's choice.
            for _ in 0..<40 where authorizationStatus == .notDetermined {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        guard isAuthorized else { return nil }

        isResolving = true
        defer { isResolving = false }

        return await withCheckedContinuation { continuation in
            continuations.append(continuation)
            manager.requestLocation()
        }
    }

    private func finish(with location: CLLocation?) {
        let pending = continuations
        continuations.removeAll()
        pending.forEach { $0.resume(returning: location) }
    }
}

extension LocationService: CLLocationManagerDelegate {

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .denied || status == .restricted {
                self.finish(with: nil)
            }
        }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager,
                                            didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        Task { @MainActor in self.finish(with: location) }
    }

    nonisolated public func locationManager(_ manager: CLLocationManager,
                                            didFailWithError error: Error) {
        Task { @MainActor in
            self.log.error("Location failed: \(error.localizedDescription, privacy: .public)")
            self.finish(with: nil)
        }
    }
}
