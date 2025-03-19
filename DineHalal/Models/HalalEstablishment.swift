
///  HalalEstablishment.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.

import Foundation

struct HalalEstablishment: Identifiable, Codable {
    let id: UUID
    let name: String
    let address: String
    let certificationType: String
    let verificationDate: Date
    let registrationNumber: String
    /// Add other fields from the NY State PDF...check later
}

