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
    
    private func saveFavoritesToFirestore() {
            guard let userId = Auth.auth().currentUser?.uid else { return }

            let data = favorites.map { try? JSONEncoder().encode($0) }
                                .compactMap { $0 }
                                .map { String(data: $0, encoding: .utf8) ?? "" }

            db.collection("users").document(userId).setData(["favorites": data])
        }
}

