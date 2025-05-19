//
//  Favorites.swift
//  DineHalal
//
//  Created by Victoria Noa on 4/7/25.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class Favorites: ObservableObject {
    @Published var favorites: [Restaurant] = []
    private let db = Firestore.firestore()
    
    func isFavorite(_ restaurant: Restaurant) -> Bool {
        favorites.contains { $0.id == restaurant.id }
    }
    
    func add(_ restaurant: Restaurant) {
        if !isFavorite(restaurant) {
            favorites.append(restaurant)
            saveFavoritesToFirestore()
        }
    }
    
    func remove(_ restaurant: Restaurant) {
        favorites.removeAll { $0.id == restaurant.id }
        saveFavoritesToFirestore()
    }
    
    func toggleFavorite(_ restaurant: Restaurant) {
        if isFavorite(restaurant) {
            remove(restaurant)
        } else {
            add(restaurant)
        }
    }
    
    func saveFavoritesToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        let favoritesData: [[String: Any]] = favorites.map { restaurant in
            return [
                "id": restaurant.id,
                "name": restaurant.name,
                "rating": restaurant.rating,
                "numberOfRatings": restaurant.numberOfRatings,
                "priceLevel": restaurant.priceLevel as Any,
                "vicinity": restaurant.vicinity,
                "isOpenNow": restaurant.isOpenNow,
                "openUntilTime": restaurant.openUntilTime as Any,
                "photoReference": restaurant.photoReference as Any,
                "placeId": restaurant.placeId,
                "latitude": restaurant.latitude,
                "longitude": restaurant.longitude,
                "address": restaurant.address
            ]
        }

        db.collection("users").document(userId).setData(["favorites": favoritesData])
        
    }
    
    func loadFavoritesFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(userId).getDocument { snapshot, error in
            guard let data = snapshot?.data(),
                  let favoritesData = data["favorites"] as? [[String: Any]] else {
                self.favorites = []
                return
            }

            self.favorites = favoritesData.compactMap { dict in
                guard let id = dict["id"] as? String,
                      let name = dict["name"] as? String,
                      let rating = dict["rating"] as? Double,
                      let numberOfRatings = dict["numberOfRatings"] as? Int,
                      let vicinity = dict["vicinity"] as? String,
                      let isOpenNow = dict["isOpenNow"] as? Bool,
                      let placeId = dict["placeId"] as? String,
                      let latitude = dict["latitude"] as? Double,
                      let longitude = dict["longitude"] as? Double,
                      let address = dict["address"] as? String
                else {
                    return nil
                }

                let priceLevel = dict["priceLevel"] as? Int
                let openUntilTime = dict["openUntilTime"] as? String
                let photoRef = (dict["photoReference"] as? String).flatMap { $0.isEmpty ? nil : $0 }


                return Restaurant(
                    id: id,
                    name: name,
                    rating: rating,
                    numberOfRatings: numberOfRatings,
                    priceLevel: priceLevel,
                    vicinity: vicinity,
                    isOpenNow: isOpenNow,
                    openUntilTime: openUntilTime,
                    photoReference: photoRef,
                    placeId: placeId,
                    latitude: latitude,
                    longitude: longitude,
                    address: address
                )
            }
        }
    }
}
