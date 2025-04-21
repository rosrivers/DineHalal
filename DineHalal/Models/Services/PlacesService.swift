//
//  PlacesService.swift
//  DineHalal
///  Created by Joanne on 4/1/25.
///"When your application displays results to the user, you should also display any attribution included in the response. The next_page_token can be used to retrieve additional results." - Google Places API Documentation


import Foundation
import CoreLocation
import ObjectiveC

/// Define PlacesResponse structure
struct PlacesResponse: Codable {
    let results: [Restaurant]
    let status: String
    let nextPageToken: String?
}

// Create a class-level key that both class and extension can access
private var verificationServiceKey: UInt8 = 0

class PlacesService: ObservableObject {
    @Published var recommendedRestaurants: [Restaurant] = []
    @Published var popularRestaurants: [Restaurant] = []
    @Published var recentlyVerified: [Restaurant] = []
    @Published var allRestaurants: [Restaurant] = [] 
    @Published var isLoading = false
    @Published var error: Error?
    
    /// Added for loading state tracking
    @Published var isLoadingMore: Bool = false
    
    /// Added for pagination
    private var nextPageToken: String?
    private var isFetchingNextPage = false
    
    /// Added to track verified restaurant IDs persistently
    private var verifiedRestaurantIDs: Set<String> = []
    
    /// Public accessor for checking if more pages are available
    var hasMorePages: Bool {
        return nextPageToken != nil
    }
    
    // Constructor with verification service
    init(verificationService: VerificationService? = nil) {
        // Load any previously verified restaurants from UserDefaults
        if let savedIDs = UserDefaults.standard.stringArray(forKey: "verifiedRestaurantIDs") {
            verifiedRestaurantIDs = Set(savedIDs)
            print("Loaded \(verifiedRestaurantIDs.count) verified restaurant IDs from storage")
        }
        
        if let service = verificationService {
            // Use the address of the key variable as the key
            objc_setAssociatedObject(self, &PlacesService.verificationServiceKey, service, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        // Otherwise your extension creates verificationService on demand
    }
    
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
        isLoadingMore = true
        
        /// Create next page URL
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/place/nearbysearch/json")
        urlComponents?.queryItems = [
            URLQueryItem(name: "pagetoken", value: pageToken),
            URLQueryItem(name: "key", value: GoogleMapConfig.placesKey)
        ]
        
        guard let url = urlComponents?.url else {
            isFetchingNextPage = false
            isLoadingMore = false
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
                self?.isLoadingMore = false
                
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
                        
                        // Find verified restaurants
                        self?.findVerifiedRestaurants(from: allRestaurants)
                    }
                    
                } catch {
                    self?.error = error
                }
            }
        }.resume()
    }
    
    /// Find verified restaurants - updated for persistence
    private func findVerifiedRestaurants(from restaurants: [Restaurant]) {
        Task {
            var verifiedRestaurants: [Restaurant] = []
            
            // First add previously verified restaurants that still exist in the current results
            for restaurant in restaurants {
                if verifiedRestaurantIDs.contains(restaurant.id) {
                    verifiedRestaurants.append(restaurant)
                }
            }
            
            // Then check new restaurants
            for restaurant in restaurants {
                if !verifiedRestaurantIDs.contains(restaurant.id) {
                    // Access verificationService from the extension directly
                    let result = verificationService.verifyRestaurant(restaurant)
                    if result.isVerified {
                        verifiedRestaurants.append(restaurant)
                        verifiedRestaurantIDs.insert(restaurant.id)
                        
                        // Save verified IDs to UserDefaults right away
                        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
                    }
                }
            }
            
            // Update the UI on main thread
            await MainActor.run {
                self.recentlyVerified = verifiedRestaurants
                print("Found \(verifiedRestaurants.count) verified restaurants")
            }
        }
    }
    
    // Add this method to manually verify a restaurant
    func manuallyVerifyRestaurant(_ restaurant: Restaurant) {
        verifiedRestaurantIDs.insert(restaurant.id)
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
        
        // Update the recentlyVerified list
        if !recentlyVerified.contains(where: { $0.id == restaurant.id }) {
            recentlyVerified.append(restaurant)
        }
    }
    
    // Add this method to manually unverify a restaurant
    func manuallyUnverifyRestaurant(_ restaurant: Restaurant) {
        verifiedRestaurantIDs.remove(restaurant.id)
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
        
        // Update the recentlyVerified list
        recentlyVerified.removeAll(where: { $0.id == restaurant.id })
    }
}
