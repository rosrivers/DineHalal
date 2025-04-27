//
//  RestaurantReviewView.swift
//  DineHalal
//
//  Created by Chelsea Bhuiyan on 4/27/25.

//  Shows all user-submitted reviews for a restaurant. Allows deleting own reviews with confirmation.

import SwiftUI
import FirebaseAuth
struct RestaurantReviewView: View {
    let restaurantId: String
    @Binding var isPresented: Bool
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    @State private var reviewToDelete: Review?
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading reviews...")
                } else if reviews.isEmpty {
                    Text("No reviews yet. Be the first to leave one!")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List {
                        ForEach(reviews) { review in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \ .self) { index in
                                        Image(systemName: index <= review.rating ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                    }
                                }
                                Text(review.comment)
                                    .font(.body)
                                Text(review.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                if review.userId == Auth.auth().currentUser?.uid {
                                    Button(role: .destructive) {
                                        reviewToDelete = review
                                        showDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .alert("Delete Review", isPresented: $showDeleteAlert, presenting: reviewToDelete) { review in
                Button("Delete", role: .destructive) {
                    deleteReview(review)
                }
                Button("Cancel", role: .cancel) {}
            } message: { review in
                Text("Are you sure you want to delete this review?")
            }
            .onAppear(perform: loadReviews)
        }
    }
    private func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    private func loadReviews() {
        FirebaseService.shared.fetchRestaurantReviews(restaurantId: restaurantId) { reviews, error in
            if let reviews = reviews {
                self.reviews = reviews.sorted { $0.date > $1.date }
            }
            isLoading = false
        }
    }
    private func deleteReview(_ review: Review) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        FirebaseService.shared.deleteReview(restaurantId: restaurantId, reviewId: review.id, userId: userId)
        reviews.removeAll { $0.id == review.id }
    }
}
