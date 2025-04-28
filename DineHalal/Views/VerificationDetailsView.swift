
///  VerificationDetailsView.swift
///  DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI

struct VerificationDetailsView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Halal Verification")
                .font(.headline)
                .padding(.bottom, 4)
            
            if let result = restaurant.verificationResult, result.isVerified {
                HStack(spacing: 4) {
                    // Verification icon varies by source
                    switch result.source {
                    case .officialRegistry:
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    case .communityVerified:
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                    default:
                        EmptyView()
                    }
                    
                    // Verification text
                    Text("This restaurant is halal verified")
                        .font(.subheadline)
                        .foregroundColor(result.source == .officialRegistry ? .green : .orange)
                }
                
                switch result.source {
                case .officialRegistry:
                    if let establishment = result.establishment {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Certificate Type: \(establishment.certificationType)")
                                .font(.caption)
                            
                            Text("Registration #: \(establishment.registrationNumber)")
                                .font(.caption)
                            
                            Button(action: {
                                /// Open PDF or proof
                                if let url = URL(string: "https://agriculture.ny.gov/system/files/documents/2025/03/halalestablishmentregistrations.pdf") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Details")
                                    .font(.caption)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.top, 4)
                        }
                    }
                case .communityVerified:
                    if let voteData = result.voteData {
                        Text("\(voteData.upvotes) out of \(voteData.upvotes + voteData.downvotes) users have confirmed seeing a Halal certificate at this restaurant.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                default:
                    EmptyView()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                    Text("Not Verified")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                Text("This restaurant has not been verified in the official NY State Halal registry or by enough community members.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}
