// restaurantdetails.swift
// created by iman and jo
// modified by victoria and rosa

import SwiftUI
import MapKit
import FirebaseFirestore



struct RestaurantDetails: View {
    var restaurant: Restaurant
    @State private var verificationResult: VerificationResult?
    @State private var reviews: [Review] = []
    @Environment(\.dismiss) private var dismiss

    // Map region setup
    @State private var region: MKCoordinateRegion

    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Map section
                Map(coordinateRegion: $region, annotationItems: [restaurant]) { item in
                    MapMarker(coordinate: CLLocationCoordinate2D(latitude: item.latitude, longitude: item.longitude))
                }
                .frame(height: 200)

                // Buttons section
                HStack(spacing: 16) {
                    Button("Add to Favorites") {
                        // Add favorite logic
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.brown)
                    .cornerRadius(8)

                    Button("Get Directions") {
                        // Open Maps logic
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.brown)
                    .cornerRadius(8)
                }

                // Detail card section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Restaurant Name: \(restaurant.name)")
                        .font(.headline)
                    if let verificationResult = verificationResult {
                        Text(verificationResult.isVerified ? "✅ Verified Halal" : "❌ Not Verified")
                            .fontWeight(.semibold)
                            .foregroundColor(verificationResult.isVerified ? .green : .red)
                    }
                    Text("Rating & Reviews: \(averageRatingString()) • \(reviews.count) reviews")
                    Text("Cuisine Type & Price Range: \(restaurant.cuisine) • \(restaurant.priceRange)")
                    Text("Business Hours:")
                        .font(.headline)
                    VStack(alignment: .leading, spacing: 2) {
                        // Hardcoded example; replace with actual data
                        Text("Sunday 10 AM – 12 AM")
                        Text("Monday 10 AM – 12 AM")
                        Text("Tuesday 10 AM – 12 AM")
                        Text("Wednesday 10 AM – 12 AM")
                        Text("Thursday 10 AM – 12 AM")
                        Text("Friday 10 AM – 12 AM")
                        Text("Saturday 10 AM – 12 AM")
                    }
                }
                .padding()
                .background(Color(red: 0.85, green: 0.73, blue: 0.60))
                .cornerRadius(12)
                .foregroundColor(.black)
                .padding(.horizontal)

                // Image section
                if let urlString = restaurant.imageUrl,
                   let url = URL(string: urlString), !urlString.isEmpty {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Reviews section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reviews")
                        .font(.title2)
                        .fontWeight(.bold)
                    if reviews.isEmpty {
                        Text("No reviews yet.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(reviews) { review in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("⭐️ \(review.rating) – User ID: \(review.userId)")
                                    Spacer()
                                    Text(review.timestamp.formatted(.dateTime.month().day().year()))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Text("“\(review.comment)”")
                            }
                            .padding()
                            .background(Color(red: 0.95, green: 0.90, blue: 0.85))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(red: 0.85, green: 0.73, blue: 0.60))
                .cornerRadius(12)
                .foregroundColor(.black)
                .padding(.horizontal)
            }
            .padding(.top)
        }
        .background(Color(red: 0.96, green: 0.91, blue: 0.86).ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                await verifyRestaurant()
                fetchReviews()
            }
        }
    }

    // Rating calculation
    private func averageRatingString() -> String {
        if reviews.isEmpty { return "N/A" }
        let avg = Double(reviews.map { $0.rating }.reduce(0, +)) / Double(reviews.count)
        return String(format: "%.1f", avg)
    }

    // Verification logic
    func verifyRestaurant() async {
        let verificationService = VerificationService()
        verificationResult = await verificationService.verifyRestaurant(
            name: restaurant.name,
            address: restaurant.address
        )
    }

    // Fetch reviews from Firestore
    func fetchReviews() {
        let db = Firestore.firestore()
        db.collection("reviews")
            .whereField("restaurantId", isEqualTo: restaurant.id.uuidString)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.reviews = documents.compactMap { doc in
                    let data = doc.data()
                    guard
                        let userId = data["userId"] as? String,
                        let rating = data["rating"] as? Int,
                        let comment = data["comment"] as? String,
                        let timestamp = data["timestamp"] as? Timestamp,
                        let restaurantId = data["restaurantId"] as? String
                    else {
                        return nil
                    }
                    return Review(
                        id: doc.documentID,
                        restaurantId: restaurantId,
                        userId: userId,
                        rating: rating,
                        comment: comment,
                        timestamp: timestamp.dateValue()
                    )
                }
            }
    }
}
