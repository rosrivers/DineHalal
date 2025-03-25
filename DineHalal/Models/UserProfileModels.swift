
///  UserProfileModels.swift
///  DineHalal
///  Created by Joanne on 3/25/25.

import Foundation

struct UserReview {
    let restaurantName: String
    let rating: Int
    let reviewText: String
    let date: Date
}

struct FavoriteRestaurant {
    let id: String
    let name: String
    let imageURL: String?
}
