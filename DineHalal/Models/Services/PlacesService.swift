
//  PlacesService.swift
//  DineHalal
///  Created by Joanne on 4/1/25.

///"When your application displays results to the user, you should also display any attribution included in the response. The next_page_token can be used to retrieve additional results." - Google Places API Documentation

import Foundation
import CoreLocation

// Define PlacesResponse structure
struct PlacesResponse: Codable {
    let results: [Restaurant]
    let status: String
    let nextPageToken: String?
}

class PlacesService: ObservableObject {
    @Published var recommendedRestaurants: [Restaurant] = []
    @Published var popularRestaurants: [Restaurant] = []
    @Published var recentlyVerified: [Restaurant] = []
    @Published var allRestaurants: [Restaurant] = [] // Added to track all restaurants
    @Published var isLoading = false
    @Published var error: Error?
    
    // Added for pagination
    private var nextPageToken: String?
    private var isFetchingNextPage = false
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double) {
        isLoading = true
        // Reset state for new search
        allRestaurants = []
        nextPageToken = nil
        
        print("Fetching restaurants for coordinates: \(latitude), \(longitude)")
        
        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)) else {
            isLoading = false
            print("Invalid URL formed")
            return
        }
        
        fetchRestaurants(from: url)
    }
    
    // Added new method to load more restaurants
    func loadMoreRestaurants(latitude: Double, longitude: Double) {
        guard let pageToken = nextPageToken, !isFetchingNextPage else {
            print("No more pages or already fetching")
            return
        }
        
        isFetchingNextPage = true
        
        guard let url = GoogleMapConfig.getNextPageURL(pageToken: pageToken) else {
            isFetchingNextPage = false
            print("Invalid next page URL")
            return
        }
        
        fetchRestaurants(from: url)
    }
    
    // Helper method for fetching from URL
    private func fetchRestaurants(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingNextPage = false
                
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
                    // Print raw response for debugging
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw API Response: \(jsonString)")
                    }
                    
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    // Store next page token
                    self?.nextPageToken = response.nextPageToken
                    
                    let newRestaurants = response.results
                    print("Successfully decoded \(newRestaurants.count) restaurants")
                    
                    // Add to all restaurants
                    if let existingRestaurants = self?.allRestaurants {
                        self?.allRestaurants = existingRestaurants + newRestaurants
                    } else {
                        self?.allRestaurants = newRestaurants
                    }
                    
                    // Update categorized lists
                    if let allRestaurants = self?.allRestaurants {
                        self?.recommendedRestaurants = Array(allRestaurants.filter { $0.rating >= 4.5 }.prefix(10))
                        self?.popularRestaurants = Array(allRestaurants.filter { $0.numberOfRatings > 200 }.prefix(10))
                        self?.recentlyVerified = Array(allRestaurants.suffix(10))
                    }
                    
                    print("Updated lists - Recommended: \(self?.recommendedRestaurants.count ?? 0), Popular: \(self?.popularRestaurants.count ?? 0), Recent: \(self?.recentlyVerified.count ?? 0)")
                    print("Total restaurants: \(self?.allRestaurants.count ?? 0)")
                    print("Has more pages: \(self?.hasMorePages ?? false)")
                    
                } catch {
                    self?.error = error
                    print("Decoding error: \(error)")
                    
                    // Print more detailed decoding error
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("Key '\(key)' not found: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Value of type '\(type)' not found: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("Type '\(type)' mismatch: \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
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
