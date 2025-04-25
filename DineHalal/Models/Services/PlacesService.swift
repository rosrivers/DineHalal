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
    @Published var allRestaurants: [Restaurant] = []
    @Published var isLoading = false
    @Published var error: Error?

    /// Added for pagination
    private var nextPageToken: String?
    private var isFetchingNextPage = false

    func fetchNearbyRestaurants(latitude: Double, longitude: Double, filter: FilterCriteria?) {
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

        fetchRestaurants(from: url, using: filter)
    }

    private func fetchRestaurants(from url: URL, using filter: FilterCriteria?) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.isFetchingNextPage = false

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

                    // Update 3 display sections
                    if let all = self?.allRestaurants {
                        let minRating = filter?.rating ?? 0.0

                        self?.recommendedRestaurants = Array(all
                            .filter { $0.rating >= minRating }
                            .sorted(by: { $0.rating > $1.rating })
                            .prefix(10))

                        self?.popularRestaurants = Array(all
                            .filter { $0.rating >= minRating && $0.numberOfRatings > 200 }
                            .sorted(by: { $0.numberOfRatings > $1.numberOfRatings })
                            .prefix(10))

                        self?.recentlyVerified = Array(all
                            .filter { $0.rating >= minRating }
                            .sorted(by: { $0.numberOfRatings < $1.numberOfRatings })
                            .prefix(10))
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
