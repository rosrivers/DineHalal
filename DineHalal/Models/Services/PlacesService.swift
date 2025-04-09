//
//  PlacesService.swift
//  DineHalal
///  Created by Joanne on 4/1/25.
///  Edited by Chelsea on 4/5/25.

import Foundation
import CoreLocation

struct PlacesResponse: Codable {
    let results: [Restaurant]
    let status: String
}

class PlacesService: ObservableObject {
    @Published var recommendedRestaurants: [Restaurant] = []
    @Published var popularRestaurants: [Restaurant] = []
    @Published var recentlyVerified: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria?) {
        isLoading = true
        print("Fetching restaurants for coordinates: \(latitude), \(longitude) with filter: \(String(describing: filter))")
        
        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(
            userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            filter: filter
        ) else {
            isLoading = false
            print("Invalid URL formed")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error
                    print("Network error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                do {
                    // Debug print of raw response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw API Response: \(jsonString)")
                    }
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    let restaurants = response.results
                    print("Successfully decoded \(restaurants.count) restaurants")
                    
                    self?.recommendedRestaurants = Array(restaurants.filter { $0.rating >= 4.5 }.prefix(5))
                    self?.popularRestaurants = Array(restaurants.filter { $0.numberOfRatings > 200 }.prefix(5))
                    self?.recentlyVerified = Array(restaurants.suffix(5))
                    
                    print("Updated lists - Recommended: \(self?.recommendedRestaurants.count ?? 0), Popular: \(self?.popularRestaurants.count ?? 0), Recent: \(self?.recentlyVerified.count ?? 0)")
                    
                } catch {
                    self?.error = error
                    print("Decoding error: \(error)")
                }
            }
        }.resume()
    }
}
