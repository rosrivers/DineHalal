
///  PlacesService.swift
///  DineHalal
///  Created by Joanne on 4/1/25.
///  Edited by Chelsea on 4/5/25.
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


class PlacesService: ObservableObject {
    static var verificationServiceKey: UInt8 = 0
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
        }
        
        if let service = verificationService {
              objc_setAssociatedObject(self, &PlacesService.verificationServiceKey, service, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
          }
        /// Otherwise your extension creates verificationService on demand - note.
    }
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria? = nil) {
        isLoading = true
        allRestaurants = []
        nextPageToken = nil

        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(
            userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            filter: filter) else {
            isLoading = false
            return
        }

        //  Pass filter into helper
        fetchRestaurants(from: url, using: filter)
    }

    /// Added new method to load more restaurants
    func loadMoreRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria?) {
        guard let pageToken = nextPageToken, !isFetchingNextPage else { return }

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

        fetchRestaurants(from: url, using: filter)
    }

    private func fetchRestaurants(from url: URL, using filter: FilterCriteria?) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingNextPage = false
                self?.isLoadingMore = false
                
                if let error = error {
                    self?.error = error
                    return
                }

                guard let data = data else { return }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    self?.nextPageToken = response.nextPageToken /// Store next page token

                    let newRestaurants = response.results
                    
                    let fiveStars = newRestaurants.filter { $0.rating == 5.0 }
                    print(" Found \(fiveStars.count) 5-star restaurants:")
                    fiveStars.forEach { print("→ \( $0.name)") }
                    

                    // Apply rating filter
                    var filteredRestaurants = newRestaurants
                    if let filter = filter {
                        filteredRestaurants = newRestaurants.filter {
                            $0.rating >= filter.rating
                        }
                    }

                    // Merge with previous pages
                    if let existing = self?.allRestaurants {
                        self?.allRestaurants = existing + filteredRestaurants
                    } else {
                        self?.allRestaurants = filteredRestaurants
                    }
                    
                    // Update categorized lists
                    if let allRestaurants = self?.allRestaurants {
                        let minRating = filter?.rating ?? 0.0
                        
                        self?.recommendedRestaurants = Array(allRestaurants
                            .filter { $0.rating >= minRating }
                            .sorted(by: { $0.rating > $1.rating })
                            .prefix(10))
                        
                        self?.popularRestaurants = Array(allRestaurants
                            .filter { $0.rating >= minRating && $0.numberOfRatings > 200 }
                            .sorted(by: { $0.numberOfRatings > $1.numberOfRatings })
                            .prefix(10))
                        
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
            let verifiedRestaurantsLocal = await findVerifiedRestaurantsAsync(from: restaurants)
            
            // Update the UI on main thread
            await MainActor.run {
                self.recentlyVerified = verifiedRestaurantsLocal
            }
        }
    }

    // Add this helper method to handle the concurrent execution
    private func findVerifiedRestaurantsAsync(from restaurants: [Restaurant]) async -> [Restaurant] {
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
        
        return verifiedRestaurants
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
