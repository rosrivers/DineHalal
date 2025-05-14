//
//  PlacesService.swift
//  DineHalal
//
//  Created by Joanne on 4/1/25.
//  Edited by Iman Ikram on 4/28/2025
//  Edited by Rosa on 05/05/25 to preload full opening-hours
//

import Foundation
import CoreLocation
import ObjectiveC
import FirebaseFirestore

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
    
    func fetchNearbyRestaurants(
        latitude: Double,
        longitude: Double,
        filter: FilterCriteria,
        completion: (() -> Void)? = nil
    ) {
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
    
    func loadMoreRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria?) {
        guard let pageToken = nextPageToken, !isFetchingNextPage else { return }
        
        isFetchingNextPage = true
        isLoadingMore = true
        
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

    private func fetchRestaurants(
        from url: URL,
        using filter: FilterCriteria?,
        completion: (() -> Void)? = nil
    ) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.isLoadingMore = false
                    completion?()
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.isLoadingMore = false
                    completion?()
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(PlacesResponse.self, from: data)
                
                var newRestaurants = response.results
                if let filter = filter {
                    newRestaurants = newRestaurants.filter { $0.rating >= filter.rating }
                }

                DispatchQueue.main.async {
                    self.nextPageToken = response.nextPageToken
                    if self.isFetchingNextPage {
                        self.allRestaurants.append(contentsOf: newRestaurants)
                    } else {
                        self.allRestaurants = newRestaurants
                    }

                    self.updateVerificationStatus()
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.isLoadingMore = false
                    self.storeRestaurantsInFirebase()
                    completion?()
                }

                // per-place detail loading (non-blocking)
                let limitedRestaurants = newRestaurants.prefix(10)

                for stub in limitedRestaurants {
                    self.fetchPlaceDetails(for: stub.placeId) { result in
                        if case .success(let full) = result {
                            DispatchQueue.main.async {
                                if let idx = self.allRestaurants.firstIndex(where: { $0.id == full.id }) {
                                    self.allRestaurants[idx] = full
                                }
                                self.processCategories(filter: filter)
                            }
                        }
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    self.error = error
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.isLoadingMore = false
                    completion?()
                }
            }
        }

        task.resume()
    }
    
    func processCategories(filter: FilterCriteria? = nil) {
        let currentList = self.allRestaurants
        let minRating = filter?.rating ?? 4.5
        
        self.popularRestaurants = Array(
            currentList
                .filter { $0.rating >= minRating && $0.numberOfRatings > 200 }
                .sorted(by: { $0.numberOfRatings > $1.numberOfRatings })
                .prefix(10)
        )
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
        var updatedVerifiedIDs: Set<String> = []

        for restaurant in restaurants {
            let result = verificationService.verifyRestaurant(restaurant)
            if result.isVerified {
                verifiedRestaurants.append(restaurant)
                updatedVerifiedIDs.insert(restaurant.id)
            }
        }

        verifiedRestaurantIDs = updatedVerifiedIDs
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
        
        return verifiedRestaurants
    }
    
    func manuallyVerifyRestaurant(_ restaurant: Restaurant) {
        verifiedRestaurantIDs.insert(restaurant.id)
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")

        if !recentlyVerified.contains(where: { $0.id == restaurant.id }) {
            recentlyVerified.append(restaurant)
        }
    }
    
    func manuallyUnverifyRestaurant(_ restaurant: Restaurant) {
        verifiedRestaurantIDs.remove(restaurant.id)
        UserDefaults.standard.set(Array(verifiedRestaurantIDs), forKey: "verifiedRestaurantIDs")
        recentlyVerified.removeAll(where: { $0.id == restaurant.id })
    }
    
    // MARK: - Google Reviews

    func fetchGoogleReviews(for placeID: String, completion: @escaping (Result<[GoogleReview], Error>) -> Void) {
        guard let url = GoogleMapConfig.getPlaceDetailsURL(placeId: placeID) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }

            do {
                let response = try JSONDecoder().decode(GooglePlaceDetailsResponse.self, from: data)
                let reviews = response.result.reviews ?? []
                DispatchQueue.main.async {
                    completion(.success(reviews))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    struct GooglePlaceDetailsResponse: Codable {
        let result: GooglePlaceDetailsResult
    }

    struct GooglePlaceDetailsResult: Codable {
        let reviews: [GoogleReview]?
    }

    struct GoogleReview: Codable, Identifiable {
        var id: String { authorName + (relativeTimeDescription ?? UUID().uuidString) }

        let authorName: String
        let rating: Int
        let text: String
        let time: Int
        let relativeTimeDescription: String?

        enum CodingKeys: String, CodingKey {
            case authorName = "author_name"
            case rating
            case text
            case time
            case relativeTimeDescription = "relative_time_description"
        }
    }
    
    // MARK: - Fetch Place Details

    func fetchPlaceDetails(
        for placeID: String,
        completion: @escaping (Result<Restaurant, Error>) -> Void
    ) {
        guard let url = GoogleMapConfig.getPlaceDetailsURL(placeId: placeID) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }

            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(GooglePlaceDetailsRestaurantResponse.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(response.result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    private struct GooglePlaceDetailsRestaurantResponse: Codable {
        let result: Restaurant
    }
}
