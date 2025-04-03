
///  Restaurant.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.

import Foundation

struct Restaurant: Identifiable {
    let id: UUID
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let cuisine: String
    let priceRange: String
    let isOpen: Bool
    let imageUrl: String?
}
    /// Add any other restaurant-related properties if needed
    /// dummy
    ///
}

