
///  GoogleMapConfig.swift
///  DineHalal
///  Maps API configuration is done here securely  and removed from homescreen.
/// Created by Joanne on 3/25/25.

import Foundation
import CoreLocation
import GoogleMaps

struct GoogleMapConfig {
    static let apiKey = APIKeys.mapsKey
    static let placesKey = APIKeys.placesKey
    
    static func getNearbyRestaurantsURL(userLocation: CLLocationCoordinate2D) -> URL? {
        let baseURLString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        
        var components = URLComponents(string: baseURLString)
        components?.queryItems = [
            URLQueryItem(name: "location", value: "\(userLocation.latitude),\(userLocation.longitude)"),
            URLQueryItem(name: "radius", value: "5000"),
            URLQueryItem(name: "type", value: "restaurant"),
            URLQueryItem(name: "keyword", value: "halal"),
            URLQueryItem(name: "key", value: placesKey)
        ]
        
        return components?.url
    }
    
    static func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        let baseURLString = "https://maps.googleapis.com/maps/api/place/photo"
        
        var components = URLComponents(string: baseURLString)
        components?.queryItems = [
            URLQueryItem(name: "maxwidth", value: "\(maxWidth)"),
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "key", value: placesKey)
        ]
        
        return components?.url
    }
}
