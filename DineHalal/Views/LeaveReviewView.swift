//
//  LeaveReviewView.swift
//  DineHalal
//
//  Created by Chelsea Bhuiyan on 4/27/25.
//
// Allows users to submit a review for a restaurant

import SwiftUI
import FirebaseAuth
struct LeaveReviewView: View {
    let restaurantId: String
    let restaurantName: String // Added this to store restaurant name
    @Environment(\.presentationMode) var presentationMode
    @State private var reviewRating = 0
    @State private var reviewText = ""
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Leave a Review for")
                    .font(.headline)
                Text(restaurantName)
                    .font(.title2)
                    .bold()
                // Rating Picker
                Picker("Rating", selection: $reviewRating) {
                    ForEach(1...5, id: \.self) { star in
                        Text("\(star) \(star == 1 ? "star" : "stars")")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                // Text Area
                TextEditor(text: $reviewText)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )
                    .padding(.bottom)
                // Submit Button
                Button(action: submitReview) {
                    Text("Submit Review")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(reviewRating > 0 && !reviewText.isEmpty ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(reviewRating == 0 || reviewText.isEmpty)
                Spacer()
            }
            .padding()
            .navigationTitle("New Review")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    private func submitReview() {
        guard reviewRating > 0, !reviewText.isEmpty else { return }
        FirebaseService.shared.addReview(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            rating: reviewRating,
            comment: reviewText
        )
        presentationMode.wrappedValue.dismiss()
    }
}
