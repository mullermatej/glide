import CoreLocation
import MapKit

@MainActor
@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    var currentLocation: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isResolving = false

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            await reverseGeocode(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                manager.requestLocation()
            }
        }
    }

    private func reverseGeocode(_ location: CLLocation) async {
        isResolving = true
        do {
            guard let request = MKReverseGeocodingRequest(location: location),
                  let mapItem = try await request.mapItems.first else {
                locationName = nil
                isResolving = false
                return
            }
            let parts = [mapItem.name, mapItem.address?.shortAddress].compactMap { $0 }
            locationName = parts.joined(separator: ", ")
        } catch {
            locationName = nil
        }
        isResolving = false
    }
}
