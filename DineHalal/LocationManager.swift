//
//  LocationManager.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
/// edited/updated - Joana 

import CoreLocation
///import Combine
import GoogleMaps

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var userLocation: CLLocationCoordinate2D?
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
        locationManager.requestLocation()
    }
    
    // FIXED: Removed duplicate method.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        DispatchQueue.main.async {
            self.userLocation = location.coordinate
            // Post notification when location is updated - not entirely needed but oh well.
            NotificationCenter.default.post(name: NSNotification.Name("LocationUpdated"), object: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Failed to get location: \(error.localizedDescription)"
        }
    }
}
