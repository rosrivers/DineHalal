
///  VerificationDetailsView.swift
///  DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI

struct VerificationDetailsView: View {
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Halal Verification Details")
                .font(.headline)
                .padding(.bottom, 4)
            
            if let result = restaurant.verificationResult, result.isVerified {
                switch result.source {
                case .officialRegistry:
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Verified in Official NY State Halal Registry")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        if let establishment = result.establishment {
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
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("View Registry Document")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                            }
                            .padding(.top, 4)
                        }
                    }
                case .communityVerified:
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.green)
                            Text("Verified by Community Members")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                        
                        if let voteData = result.voteData {
                            Text("\(voteData.upvotes) out of \(voteData.upvotes + voteData.downvotes) users have confirmed seeing a Halal certificate at this restaurant.")
                                .font(.caption)
                        }
                    }
                default:
                    EmptyView()
                }
            } else {
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.orange)
                    Text("Not Verified")
                        .font(.subheadline)
                        .foregroundColor(.orange)
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

