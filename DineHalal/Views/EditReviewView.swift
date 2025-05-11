//  EditReviewView.swift
//  DineHalal
//
// Created by Chelsea to allows users to edit a previously submitted review.

import SwiftUI

struct EditReviewView: View {
    let restaurantId: String
    let review: Review
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var reviewText: String
    @State private var reviewRating: Int
    @State private var isSubmitting = false

    init(restaurantId: String, review: Review, onSave: @escaping () -> Void) {
        self.restaurantId = restaurantId
        self.review = review
        self.onSave = onSave
        _reviewText = State(initialValue: review.comment)
        _reviewRating = State(initialValue: review.rating)
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Rating Picker
                Text("Rating")
                    .font(.subheadline)
                Picker("Rating", selection: $reviewRating) {
                    ForEach(1...5, id: \.self) { star in
                        Text("\(star) \(star == 1 ? "star" : "stars")")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // Comment Field
                TextEditor(text: $reviewText)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                // Submit Button
                Button(action: {
                    guard !isSubmitting else { return }
                    isSubmitting = true

                    var updatedReview = review
                    updatedReview.comment = reviewText
                    updatedReview.rating = reviewRating

                    FirebaseService.shared.updateReview(
                        restaurantId: restaurantId,
                        review: updatedReview
                    ) { success in
                        isSubmitting = false
                        if success {
                            onSave()
                            dismiss()
                        }
                    }
                }) {
                    Text(isSubmitting ? "Saving..." : "Save Changes")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isSubmitting)

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Review")
            .navigationBarItems(trailing: Button("Cancel") {
                dismiss()
            })
        }
    }
}
