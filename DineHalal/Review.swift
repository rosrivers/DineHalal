//
//  Review.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/11/25.
/// updated - Joana 


import Foundation

struct Review: Identifiable, Decodable {
    var id: UUID
    var userId: String
    var restaurantId: String
    var rating: Int
    var comment: String
    var date: Date
    
    /// Add CodingKeys enum if needed to map JSON keys to struct properties
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case restaurantId
        case rating
        case comment
        case date
    }
}
