
///  VotingView.swift
///  DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI

struct VotingView: View {
    let restaurant: Restaurant
    let placesService: PlacesService
    
    var body: some View {
        let result = placesService.getVerificationResult(for: restaurant)
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Is this restaurant halal?")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text("Help other Muslims find halal food by verifying this restaurant.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: {
                    placesService.upvoteRestaurant(restaurant)
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Yes, it's Halal")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(8)
                }
                
                Button(action: {
                    placesService.downvoteRestaurant(restaurant)
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("Not Halal")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                }
            }
            
            if let voteData = result.voteData {
                let totalVotes = voteData.upvotes + voteData.downvotes
                if totalVotes > 0 {
                    Text("Community verification: \(voteData.upvotes) out of \(totalVotes) users say it's halal")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}
