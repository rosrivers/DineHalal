//
//  LocationManager.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
/// edited/updated - Joana
/// edited by Rosa

import CoreLocation
import GoogleMaps

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    /// Published whenever a new coord arrives
    @Published var userLocation: CLLocationCoordinate2D?
    /// Published when permission changes or we hit an error
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func getLocation() {
        startUpdatingLocation()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: – CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            self.authorizationStatus = status

            switch status {
            case .authorizedAlways, .authorizedWhenInUse:
                self.getLocation()
            case .denied, .restricted:
                self.errorMessage = "Location permission denied—using default location."
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }

        DispatchQueue.main.async {
            self.userLocation = loc.coordinate
            manager.stopUpdatingLocation()

            /// Post a notification if other parts of the app still use this
            NotificationCenter.default.post(name: .init("LocationUpdated"), object: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
}
