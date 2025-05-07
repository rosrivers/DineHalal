
//  GoogleMapConfig+boroughtesting.swift
//  DineHalal
//  Created by Joanne on 5/2/25.
//  for testing.
/*
import Foundation
import CoreLocation

// Add this extension to your existing GoogleMapConfig
extension GoogleMapConfig {
    // Predefined coordinates for NYC boroughs
    enum NYCBorough {
        case manhattan
        case brooklyn
        case queens
        case bronx
        case statenIsland
        
        // Central coordinates for each borough
        var coordinates: CLLocationCoordinate2D {
            switch self {
            case .manhattan:
                return CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712) // Midtown
            case .brooklyn:
                return CLLocationCoordinate2D(latitude: 40.6782, longitude: -73.9442) // Downtown Brooklyn
            case .queens:
                return CLLocationCoordinate2D(latitude: 40.7282, longitude: -73.7949) // Jackson Heights
            case .bronx:
                return CLLocationCoordinate2D(latitude: 40.8448, longitude: -73.8648) // Near Fordham
            case .statenIsland:
                return CLLocationCoordinate2D(latitude: 40.5795, longitude: -74.1502) // St. George
            }
        }
        
        var name: String {
            switch self {
            case .manhattan: return "Manhattan"
            case .brooklyn: return "Brooklyn"
            case .queens: return "Queens"
            case .bronx: return "Bronx"
            case .statenIsland: return "Staten Island"
            }
        }
    }
    
    // New method that accepts a borough instead of user location
    static func getNearbyRestaurantsURLForBorough(_ borough: NYCBorough, filter: FilterCriteria?) -> URL? {
        return getNearbyRestaurantsURL(userLocation: borough.coordinates, filter: filter)
    }
}
*/
