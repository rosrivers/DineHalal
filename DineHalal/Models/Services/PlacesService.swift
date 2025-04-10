//
//  PlacesService.swift
//  DineHalal
///  Created by Joanne on 4/1/25.
///  Edited by Chelsea on 4/5/25.

import Foundation
import CoreLocation

/// Define PlacesResponse structure
struct PlacesResponse: Codable {
    let results: [Restaurant]
    let status: String
    let nextPageToken: String?
}

class PlacesService: ObservableObject {
    @Published var recommendedRestaurants: [Restaurant] = []
    @Published var popularRestaurants: [Restaurant] = []
    @Published var recentlyVerified: [Restaurant] = []
    @Published var allRestaurants: [Restaurant] = [] /// Added to track all restaurants
    @Published var isLoading = false
    @Published var error: Error?
    
    /// Added for pagination
    private var nextPageToken: String?
    private var isFetchingNextPage = false
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double) {
        isLoading = true
        /// Reset state for new search
        allRestaurants = []
        nextPageToken = nil
        
        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            isLoading = false
            return
        }
        
        fetchRestaurants(from: url)
    }
    
    /// Added new method to load more restaurants
    func loadMoreRestaurants(latitude: Double, longitude: Double) {
        guard let pageToken = nextPageToken, !isFetchingNextPage else {
            return
        }
        
        isFetchingNextPage = true
        
        /// Create next page URL
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")
        urlComponents?.queryItems = [
            URLQueryItem(name: "pagetoken", value: pageToken),
            URLQueryItem(name: "key", value: GoogleMapConfig.placesKey)
        ]
        
        guard let url = urlComponents?.url else {
            isFetchingNextPage = false
            return
        }
        
        fetchRestaurants(from: url)
    }
    
    /// Helper method for fetching from URL
    private func fetchRestaurants(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingNextPage = false
                
                if let error = error {
                    self?.error = error
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    /// Store next page token
                    self?.nextPageToken = response.nextPageToken
                    
                    let newRestaurants = response.results
                    
                    /// Add to all restaurants
                    if let existingRestaurants = self?.allRestaurants {
                        self?.allRestaurants = existingRestaurants + newRestaurants
                    } else {
                        self?.allRestaurants = newRestaurants
                    }
                    
                    /// Update categorized lists
                    if let allRestaurants = self?.allRestaurants {
                        self?.recommendedRestaurants = Array(allRestaurants.filter { $0.rating >= 4.5 }.prefix(10))
                        self?.popularRestaurants = Array(allRestaurants.filter { $0.numberOfRatings > 200 }.prefix(10))
                        self?.recentlyVerified = Array(allRestaurants.suffix(10))
                    }
                    
                } catch {
                    self?.error = error
                }
            }
        }.resume()
    }
    
    /// Helper property to check if more results are available
    var hasMorePages: Bool {
        return nextPageToken != nil
    }
    
    var isLoadingMore: Bool {
        return isFetchingNextPage
    }
}
