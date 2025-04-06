//
//  PlacesService.swift
//  DineHalal
///  Created by Joanne on 4/1/25.

import Foundation
import CoreLocation

// Define PlacesResponse structure
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
    
    func fetchNearbyRestaurants(latitude: Double, longitude: Double) async {
        isLoading = true
        defer { isLoading = false }

        guard let url = GoogleMapConfig.getNearbyRestaurantsURL(
          userLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        ) else {
          print("Invalid URL formed")
          return
        }

        do {
          let (data, _) = try await URLSession.shared.data(from: url)
          if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw API Response: \(jsonString)")
          }

          let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
          let all = response.results

          // categorize
          let recs = all.filter { $0.rating >= 4.5 }
          let pops = all.filter { $0.numberOfRatings > 200 }
          let recents = Array(all.suffix(5))

          // publish on main thread
          await MainActor.run {
            self.recommendedRestaurants = Array(recs.prefix(5))
            self.popularRestaurants    = Array(pops.prefix(5))
            self.recentlyVerified      = recents
          }

          print("Updated lists – Rec: \(recs.count), Pop: \(pops.count), Recent: \(recents.count)")
        } catch {
          await MainActor.run { self.error = error }
          print("Error fetching or decoding: \(error)")
        }
      }
}
