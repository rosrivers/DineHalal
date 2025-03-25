//
//  Review.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/11/25.
///updated - Joana



import Firebase
import FirebaseFirestore

struct Review: Codable, Identifiable {
    @DocumentID var id: String?
    let restaurantId: String
    let userId: String
    let rating: Int
    let comment: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case restaurantId
        case userId
        case rating
        case comment
        case timestamp
    }
}
