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

    /// Call once up-front (e.g. in onAppear)
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Old single‐shot alias, so existing calls still work
    func getLocation() {
        startUpdatingLocation()
    }

    /// Begin continuous updates; you’ll get delegate callbacks until you call stopUpdating()
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    /// Stop the updates once you’ve got what you need
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
                // immediately fire off a one‐shot if you like
                manager.requestLocation()
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
            // if you’re in continuous mode you might want to stop here:
            manager.stopUpdatingLocation()
            // notify any observers
            NotificationCenter.default.post(name: .init("LocationUpdated"), object: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
}
