//
//  Favorites.swift
//  DineHalal
//
//  Created by Victoria Noa on 4/7/25.
//

import Foundation
import SwiftUI

class Favorites: ObservableObject {
    @Published var favorites: [Restaurant] = []
    func isFavorite(_ restaurant: Restaurant) -> Bool {
        favorites.contains { $0.id == restaurant.id }
    }

    func add(_ restaurant: Restaurant) {
        if !isFavorite(restaurant) {
            favorites.append(restaurant)
        }
    }

    func remove(_ restaurant: Restaurant) {
        favorites.removeAll { $0.id == restaurant.id }
    }

    func toggleFavorite(_ restaurant: Restaurant) {
        if isFavorite(restaurant) {
            remove(restaurant)
        } else {
            add(restaurant)
        }
    }
}

