import Combine
import CoreLocation

struct LocationFix: Sendable {
    var latitude: Double
    var longitude: Double
    var accuracy: Double
}

extension LocationFix {
    init(_ location: CLLocation) {
        self.init(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            accuracy: location.horizontalAccuracy
        )
    }
}

@MainActor
final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    @Published private(set) var status: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var waiting: [CheckedContinuation<LocationFix?, Never>] = []

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        status = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        status == .authorizedAlways || status == .authorizedWhenInUse
    }

    var statusText: String {
        switch status {
        case .notDetermined: return "Not set up yet"
        case .restricted, .denied: return "Off"
        case .authorizedWhenInUse: return "While using the app"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }

    func requestPermissionIfNeeded() {
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestAlways() {
        manager.requestAlwaysAuthorization()
    }

    /// One location reading, or nil if access is off or nothing arrives in time.
    func currentFix(timeout: Double = 6) async -> LocationFix? {
        status = manager.authorizationStatus
        guard isAuthorized else { return nil }

        if let recent = manager.location,
           recent.timestamp.timeIntervalSinceNow > -10,
           recent.horizontalAccuracy >= 0, recent.horizontalAccuracy <= 50 {
            return LocationFix(recent)
        }

        return await withCheckedContinuation { continuation in
            waiting.append(continuation)
            manager.requestLocation()
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(timeout))
                self?.finish(self?.manager.location)
            }
        }
    }

    private func finish(_ location: CLLocation?) {
        guard !waiting.isEmpty else { return }
        let fix = location.map { LocationFix($0) }
        let pending = waiting
        waiting.removeAll()
        for continuation in pending {
            continuation.resume(returning: fix)
        }
    }

    // CLLocationManager calls back on the thread that created it, which is the main thread.

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let latest = locations.last
        MainActor.assumeIsolated {
            finish(latest)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let lastKnown = manager.location
        MainActor.assumeIsolated {
            finish(lastKnown)
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus
        MainActor.assumeIsolated {
            status = newStatus
        }
    }
}
