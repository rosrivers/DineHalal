
///  VerificationBadge.swift
/// DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI

struct VerificationBadge: View {
    /// The verification result (for backward compatibility)
    private let result: VerificationResult?
    
    /// For the new approach (optional)
    private let placesService: PlacesService?
    private let restaurant: Restaurant?
    
    let showDetails: Bool
    
    /// Original initializer (backward compatibility)
    init(result: VerificationResult?, showDetails: Bool = false) {
        self.result = result
        self.placesService = nil
        self.restaurant = nil
        self.showDetails = showDetails
    }
    
    /// New initializer
    init(placesService: PlacesService, restaurant: Restaurant, showDetails: Bool = false) {
        self.placesService = placesService
        self.restaurant = restaurant
        self.result = nil
        self.showDetails = showDetails
    }
    
    var body: some View {
        /// Determine which result to use
        let effectiveResult: VerificationResult? = {
            if let result = result {
                return result
            } else if let service = placesService, let restaurant = restaurant {
                return service.getVerificationResult(for: restaurant)
            }
            return nil
        }()
        
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let result = effectiveResult, result.isVerified {
                    switch result.source {
                    case .officialRegistry:
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        
                        Text("Halal Verified")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.green)
                        
                    case .communityVerified:
                        Image(systemName: "hand.thumbsup.fill")
                            .foregroundColor(.blue)
                        
                        Text("Community Verified")
                            .font(.caption)
                            .bold()
                            .foregroundColor(.blue)
                        
                    default:
                        EmptyView()
                    }
                } else {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                    
                    Text("Halal Status Unknown")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            if showDetails, let result = effectiveResult {
                if result.isVerified {
                    switch result.source {
                    case .officialRegistry:
                        Text("✓ Official NY State Halal Registry")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            
                    case .communityVerified:
                        if let votes = result.voteData {
                            Text("✓ Community verified: \(votes.upvotes) of \(votes.upvotes + votes.downvotes) users")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    default:
                        EmptyView()
                    }
                }
                
                if let establishment = result.establishment {
                    Text("Cert #: \(establishment.registrationNumber)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
