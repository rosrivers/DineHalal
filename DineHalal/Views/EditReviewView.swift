//  EditReviewView.swift
//  DineHalal
//
//  Allows users to edit a previously submitted review.

import SwiftUI

struct EditReviewView: View {
    let restaurantId: String
    @State var review: Review
    var onSave: () -> Void
    @Environment(\.dismiss) var dismiss

    @State private var isSubmitting = false

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Edit Your Review")
                    .font(.headline)

                // Rating Picker
                Text("Rating")
                    .font(.subheadline)
                Picker("Rating", selection: $review.rating) {
                    ForEach(1...5, id: \.self) { star in
                        Text("\(star) \(star == 1 ? "star" : "stars")")
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                // Comment Field
                TextEditor(text: $review.comment)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                // Submit Button
                Button(action: {
                    guard !isSubmitting else { return }
                    isSubmitting = true

                    FirebaseService.shared.updateReview(
                        restaurantId: restaurantId,
                        review: review
                    )

                    onSave()
                    dismiss()
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
