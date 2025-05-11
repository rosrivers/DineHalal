//  RestaurantReviewView.swift
//  DineHalal
//
//  Created by Chelsea Bhuiyan on 4/27/25.

//  Shows all user-submitted reviews for a restaurant. Allows deleting own reviews with confirmation.

//  Edited by Iman Ikram on 4/28/2025 to add Google Reviews Section

//Updated by Chelsea Bhuiyan to display username and date on the review

import SwiftUI
import FirebaseAuth

struct RestaurantReviewView: View {
    let restaurantId: String
    @Binding var isPresented: Bool
    var onDelete: (() -> Void)? = nil
    @State private var reviews: [Review] = []
    @State private var isLoading = true
    @State private var showDeleteAlert = false
    @State private var reviewToDelete: Review?
    @State private var googleReviews: [PlacesService.GoogleReview] = []

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading reviews...")
                } else {
                    List {
                        // User Reviews
                        Section(header: Text("User Reviews").font(.headline)) {
                            if reviews.isEmpty {
                                Text("No reviews yet. Be the first to leave one!")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(reviews) { review in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { index in
                                                Image(systemName: index <= review.rating ? "star.fill" : "star")
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        Text(displayedUsername(for: review))
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(review.comment)
                                            .font(.body)

                                        if review.userId == Auth.auth().currentUser?.uid {
                                            Button(role: .destructive) {
                                                reviewToDelete = review
                                                showDeleteAlert = true
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                            .padding(.top, 4)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        // Google Reviews
                        Section(header: Text("Google Reviews").font(.headline)) {
                            if googleReviews.isEmpty {
                                Text("No Google reviews available.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(googleReviews) { review in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack(spacing: 2) {
                                            ForEach(1...5, id: \.self) { index in
                                                Image(systemName: index <= review.rating ? "star.fill" : "star")
                                                    .foregroundColor(.yellow)
                                            }
                                        }
                                        Text(review.authorName)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(review.text)
                                            .font(.body)
                                        Text(review.relativeTimeDescription ?? "")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
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
            } message: { _ in
                Text("Are you sure you want to delete this review?")
            }
            .onAppear {
                loadReviews()
                fetchGoogleReviews()
            }
        }
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
        onDelete?()
    }

    private func fetchGoogleReviews() {
        let placesService = PlacesService()
        placesService.fetchGoogleReviews(for: restaurantId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let googleReviews):
                    self.googleReviews = googleReviews
                case .failure(let error):
                    print("Error fetching Google reviews: \(error)")
                }
            }
        }
    }

    private func displayedUsername(for review: Review) -> String {
        if let googleName = Auth.auth().currentUser?.displayName, !googleName.isEmpty {
            return googleName
        } else if let name = review.username, !name.isEmpty {
            return name
        } else {
            return "Anonymous"
        }
    }
}
