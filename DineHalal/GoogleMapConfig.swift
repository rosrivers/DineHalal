
///  GoogleMapConfig.swift
///  DineHalal
///  Maps API configuration is done here securely  and removed from homescreen.
/// Created by Joanne on 3/25/25.


import Foundation
import CoreLocation

struct GoogleMapConfig {
    // Store API key securely
    static let apiKey = "AIzaSyD0d33gYQ-n6wwJeCeUzPL1S4GjDD_GQbk"
    
    /// Function to get nearby restaurants URL
    static func getNearbyRestaurantsURL(userLocation: CLLocationCoordinate2D) -> URL? {
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(userLocation.latitude),\(userLocation.longitude)&radius=1500&type=restaurant&key=\(apiKey)"
        return URL(string: urlString)
    }
}
