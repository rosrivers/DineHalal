
///  PlacesService.swift
///  DineHalal
///  Created by Joanne on 4/1/25.
///  Edited by Chelsea on 4/5/25.
///"When your application displays results to the user, you should also display any attribution included in the response. The next_page_token can be used to retrieve additional results." - Google Places API Documentation

import Foundation
import CoreLocation
import ObjectiveC
import FirebaseFirestore

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
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria) {
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
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            // Handle errors
            if let error = error {
                print("Error fetching restaurants: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.isLoadingMore = false
                }
                return
            }
            
            // Process data
            if let data = data {
                do {
                    // Parse JSON
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    
                    // Save next page token
                    self.nextPageToken = response.nextPageToken
                    
                    // Process results - fixed method
                    let newRestaurants = self.processRestaurants(places: response.results, filter: filter)
                    
                    DispatchQueue.main.async {
                        if self.isFetchingNextPage {
                            // Add to existing results for pagination
                            self.allRestaurants.append(contentsOf: newRestaurants)
                        } else {
                            // Replace results for new search
                            self.allRestaurants = newRestaurants
                        }
                        
                        // Process different categories
                        self.processCategories()
                        
                        // Update verification status
                        self.updateVerificationStatus()
                        
                        // Reset loading states
                        self.isLoading = false
                        self.isFetchingNextPage = false
                        self.isLoadingMore = false
                        
                        // IMPORTANT: Store restaurants in Firebase
                        self.storeRestaurantsInFirebase()
                    }
                } catch {
                    print("Error decoding restaurant data: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.isFetchingNextPage = false
                        self.isLoadingMore = false
                    }
                }
            }
        }
        task.resume()
    }
    
    // ADDED MISSING METHOD: Process results
    func processRestaurants(places: [Restaurant], filter: FilterCriteria?) -> [Restaurant] {
        var filteredPlaces = places
        
        if let filter = filter {
            // Apply rating filter if specified
            filteredPlaces = filteredPlaces.filter { $0.rating >= filter.rating }
        }
        
        return filteredPlaces
    }
    
    // ADDED MISSING METHOD: Process categories
    func processCategories() {
        // Sort by rating for popular and recommended restaurants
        popularRestaurants = allRestaurants
            .filter { $0.numberOfRatings > 200 }
            .sorted(by: { $0.rating > $1.rating })
            .prefix(10)
            .map { $0 }
        
        recommendedRestaurants = allRestaurants
            .sorted(by: { $0.rating > $1.rating })
            .prefix(10)
            .map { $0 }
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
    
    // Updated to re-verify all restaurants to prevent stale verification data
    private func findVerifiedRestaurantsAsync(from restaurants: [Restaurant]) async -> [Restaurant] {
        var verifiedRestaurants: [Restaurant] = []
        var updatedVerifiedIDs: Set<String> = []
        
        // Check each restaurant's current verification status
        for restaurant in restaurants {
            // Always verify the restaurant against our verification criteria
            let result = verificationService.verifyRestaurant(restaurant)
            
            if result.isVerified {
                verifiedRestaurants.append(restaurant)
                updatedVerifiedIDs.insert(restaurant.id)
            }
        }
        
        // Update the saved IDs with only currently verified restaurants
        verifiedRestaurantIDs = updatedVerifiedIDs
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
        
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
        
        // Update the Verified list
        recentlyVerified.removeAll(where: { $0.id == restaurant.id })
    }
}
