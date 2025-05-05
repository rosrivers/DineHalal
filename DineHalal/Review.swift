//  Review.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/11/25.
/// updated - Joana
/// Updated by Chelsea Bhuiyan 04/27/2025

import Foundation

struct Review: Identifiable, Decodable, Equatable {
    var id: String
    var userId: String
    var restaurantId: String
    var restaurantName: String  // ← Add this line
    var rating: Int
    var comment: String
    var date: Date
    var username: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, restaurantId, restaurantName, rating, comment, date, username
    }

    static func == (lhs: Review, rhs: Review) -> Bool {
        lhs.id == rhs.id
    }
}
