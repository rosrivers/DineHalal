//
//  PlacesService.swift
//  DineHalal
//
//  Created by Joanne on 4/1/25.
//

import Foundation
import CoreLocation
import ObjectiveC

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
    
    @Published var isLoadingMore: Bool = false
    
    private var nextPageToken: String?
    private var isFetchingNextPage = false
    private var verifiedRestaurantIDs: Set<String> = []
    
    var hasMorePages: Bool {
        return nextPageToken != nil
    }
    
    init(verificationService: VerificationService? = nil) {
        if let savedIDs = UserDefaults.standard.stringArray(forKey: "verifiedRestaurantIDs") {
            verifiedRestaurantIDs = Set(savedIDs)
        }
        
        if let service = verificationService {
            objc_setAssociatedObject(self, &PlacesService.verificationServiceKey, service, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    //accepts completion handler
    func fetchNearbyRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria? = nil, completion: (() -> Void)? = nil) {
        isLoading = true
        allRestaurants = []
        nextPageToken = nil

        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(
            userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            filter: filter) else {
            isLoading = false
            completion?()
            return
        }

        fetchRestaurants(from: url, using: filter, completion: completion)
    }

    // passes completion through
    private func fetchRestaurants(from url: URL, using filter: FilterCriteria?, completion: (() -> Void)? = nil) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingNextPage = false
                self?.isLoadingMore = false
                
                defer {
                    completion?() // Always call completion when done
                }
                
                if let error = error {
                    self?.error = error
                    return
                }

                guard let data = data else { return }

                do {
                    let decoder = JSONDecoder()
                    let response = try decoder.decode(PlacesResponse.self, from: data)
                    self?.nextPageToken = response.nextPageToken

                    let newRestaurants = response.results
                    
                    let fiveStars = newRestaurants.filter { $0.rating == 5.0 }
                    print(" Found \(fiveStars.count) 5-star restaurants:")
                    fiveStars.forEach { print("→ \( $0.name)") }

                    var filteredRestaurants = newRestaurants
                    if let filter = filter {
                        filteredRestaurants = newRestaurants.filter { $0.rating >= filter.rating }
                    }

                    if let existing = self?.allRestaurants {
                        self?.allRestaurants = existing + filteredRestaurants
                    } else {
                        self?.allRestaurants = filteredRestaurants
                    }
                    
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
                        
                        self?.findVerifiedRestaurants(from: allRestaurants)
                    }

                } catch {
                    self?.error = error
                }
            }
        }.resume()
    }
    
    private func findVerifiedRestaurants(from restaurants: [Restaurant]) {
        Task {
            let verifiedRestaurantsLocal = await findVerifiedRestaurantsAsync(from: restaurants)
            
            await MainActor.run {
                self.recentlyVerified = verifiedRestaurantsLocal
            }
        }
    }

    private func findVerifiedRestaurantsAsync(from restaurants: [Restaurant]) async -> [Restaurant] {
        var verifiedRestaurants: [Restaurant] = []
        
        for restaurant in restaurants {
            if verifiedRestaurantIDs.contains(restaurant.id) {
                verifiedRestaurants.append(restaurant)
            }
        }
        
        for restaurant in restaurants {
            if !verifiedRestaurantIDs.contains(restaurant.id) {
                let result = verificationService.verifyRestaurant(restaurant)
                if result.isVerified {
                    verifiedRestaurants.append(restaurant)
                    verifiedRestaurantIDs.insert(restaurant.id)
                    UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
                }
            }
        }
        
        return verifiedRestaurants
    }
}
