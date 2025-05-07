///  GoogleMapConfig.swift
///  DineHalal
///  Maps API configuration is done here securely and removed from homescreen.
/// Created by Joanne on 3/25/25.
/// Edited by Chelsea on 4/5/25.

import Foundation
import CoreLocation
import GoogleMaps

struct GoogleMapConfig {
    static let apiKey = APIKeys.mapsKey
    static let placesKey = APIKeys.placesKey
    
    static func getNearbyRestaurantsURL(userLocation: CLLocationCoordinate2D, filter: FilterCriteria?) -> URL? {
        let baseURLString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "location", value: "\(userLocation.latitude),\(userLocation.longitude)"),
            URLQueryItem(name: "radius", value: "5000"),
            URLQueryItem(name: "type", value: "restaurant"),
            URLQueryItem(name: "key", value: placesKey)
        ]
        
        // Build keyword starting with "halal" then add additional cuisine filters if enabled.
        var keyword = "halal"
        
        // Add city/zip to the keyword if provided
        if let filter = filter, !filter.cityZip.isEmpty {
            keyword += " " + filter.cityZip
        }
        
        // Add cuisine filters
        if let filter = filter {
            if filter.middleEastern { keyword += " middle eastern" }
            if filter.mediterranean { keyword += " mediterranean" }
            if filter.southAsian { keyword += " south asian" }
            if filter.american { keyword += " american" }
        }
        queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        
        // Example: Price filtering using Places API parameters
        if let filter = filter {
            if filter.priceBudget && !filter.priceModerate && !filter.priceExpensive {
                queryItems.append(URLQueryItem(name: "maxprice", value: "1"))
            } else if filter.priceModerate && !filter.priceBudget && !filter.priceExpensive {
                queryItems.append(URLQueryItem(name: "minprice", value: "2"))
                queryItems.append(URLQueryItem(name: "maxprice", value: "2"))
            } else if filter.priceExpensive && !filter.priceBudget && !filter.priceModerate {
                queryItems.append(URLQueryItem(name: "minprice", value: "3"))
            }
        }
        
        var components = URLComponents(string: baseURLString)
        components?.queryItems = queryItems
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
    
    // For Google Reviews
    static func getPlaceDetailsURL(placeId: String) -> URL? {
        let baseURLString = "https://maps.googleapis.com/maps/api/place/details/json"
        
        var components = URLComponents(string: baseURLString)
        components?.queryItems = [
            URLQueryItem(name: "placeid", value: placeId),
            URLQueryItem(name: "key", value: placesKey)
        ]
        
        return components?.url
    }
}
