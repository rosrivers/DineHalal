
///  VerificationService.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.
///

import Foundation

/// Service responsible for verifying if a restaurant is halal certified
class VerificationService {
    private var halalData: [HalalEstablishment] = []
    private var yelpData: [Restaurant] = [] /// Placeholder for Yelp data subject to change
    
    /// Initialize the service and load halal data from the PDF
    init() {
        Task {
            do {
                let pdfParserService = PDFParserService()
                self.halalData = try await pdfParserService.downloadAndParsePDF()
            } catch {
                print("Error loading halal data: \(error)") /// Handle errors appropriately
            }
        }
    }
    
    /// Function to verify if a restaurant is halal certified
    func verifyRestaurant(name: String, address: String) async -> VerificationResult {
        
        /// Load Yelp data (to be implemented by teammate)
        await loadYelpData(name: name, address: address)
        
        /// Check if the restaurant is in the halal data
        if let establishment = matchEstablishment(name: name, address: address) {
            return VerificationResult(isVerified: true, establishment: establishment)
        } else {
            return VerificationResult(isVerified: false, establishment: nil)
        }
    }
    
    /// Function to match a restaurant with the halal data
    private func matchEstablishment(name: String, address: String) -> HalalEstablishment? {
        return halalData.first { establishment in
            establishment.name.lowercased() == name.lowercased() &&
            establishment.address.lowercased() == address.lowercased()
        }
    }
    
    /// Function to load Yelp data (to be implemented by teammate)
    private func loadYelpData(name: String, address: String) async {
        /// Placeholder for loading Yelp data
        /// Teammate please  implement API call to Yelp Fusion API and update yelpData array
        /// Heres an  example to help please disregard the example after looking at it:
        // let yelpService = YelpService()
        // self.yelpData = try await yelpService.fetchRestaurantData(name: name, address: address)
    }
}


/// Result of the verification process
struct VerificationResult {
    let isVerified: Bool               /// Indication/indicates if the restaurant is verified
    let establishment: HalalEstablishment? /// Matched halal establishment, if any
}
