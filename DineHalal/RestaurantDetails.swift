///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.
///  Edited by Chelsea on 4/5/25.
///  Further Edited by Chelsea on 4/27/25 to add Leave Review feature and clickable reviews count
///  Edited by Rosa to add in closing / opening correctly

import SwiftUI
import MapKit
import FirebaseAuth

struct RestaurantDetails: View {
    @State var restaurant: Restaurant
    @State private var region: MKCoordinateRegion
    @State private var rating: Int = 0
    @State private var review: String = ""
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var favorites: Favorites
    @ObservedObject var verificationService: VerificationService
    @State private var showingVerificationDetails = false
    @State private var verificationResult: VerificationResult?
    @State private var showLeaveReviewSheet = false
    @State private var showAllReviews = false

    init(restaurant: Restaurant, verificationService: VerificationService) {
        _restaurant = State(initialValue: restaurant)
        self.verificationService = verificationService
        _verificationResult = State(initialValue: verificationService.verifyRestaurant(restaurant))
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let photoRef = restaurant.photoReference {
                    GooglePlaceImage(photoReference: photoRef)
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(restaurant.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        Spacer()
                        Button(action: { openInGoogleMaps() }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Get Directions")
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.mud)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        Button(action: { favorites.toggleFavorite(restaurant) }) {
                            Image(systemName: favorites.isFavorite(restaurant) ? "heart.fill" : "heart")
                                .foregroundColor(favorites.isFavorite(restaurant) ? .red : .gray)
                                .font(.title2)
                        }
                    }

                    HStack {
                        StarRatingView(rating: restaurant.rating)
                        Text("\(restaurant.rating, specifier: "%.1f")")
                            .foregroundColor(.gray)
                        Button(action: { showAllReviews.toggle() }) {
                            Text("(\(restaurant.numberOfRatings) reviews)")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .sheet(isPresented: $showAllReviews) {
                            RestaurantReviewView(restaurantId: restaurant.id, isPresented: $showAllReviews)
                        }
                    }

                    if let result = verificationResult, result.isVerified {
                        Button(action: { showingVerificationDetails = true }) {
                            HStack(spacing: 4) {
                                if result.source == .communityVerified {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.orange)
                                    Text("Community Verified")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                } else {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Verified Halal")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                        }
                        .sheet(isPresented: $showingVerificationDetails) {
                            VerificationDetailsSheet(result: result, restaurant: restaurant)
                        }
                    }

                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(restaurant.vicinity)
                            .foregroundColor(.gray)
                    }

                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        if restaurant.isOpenNow, let untilTime = restaurant.openUntilTime {
                            Text("Open until \(untilTime)")
                                .foregroundColor(.green)
                        } else if restaurant.isOpenNow {
                            Text("Open Now")
                                .foregroundColor(.green)
                        } else {
                            Text("Closed")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                Text("Location")
                    .font(.headline)
                    .padding(.horizontal)

                RestaurantMapView(latitude: restaurant.latitude, longitude: restaurant.longitude, name: restaurant.name)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                if let result = verificationResult {
                    Divider()
                        .padding(.horizontal)
                    Text("Halal Verification")
                        .font(.headline)
                        .padding(.horizontal)
                    if result.isVerified {
                        HStack {
                            if result.source == .communityVerified {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading) {
                                    Text("This restaurant is halal verified")
                                        .foregroundColor(.orange)
                                    Text("Verified by community votes")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            } else {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("This restaurant is halal verified")
                                        .foregroundColor(.green)
                                    Text("Verified by official registry")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            Spacer()
                            Button("Details") {
                                showingVerificationDetails = true
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal)
                    } else {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Not verified as halal")
                                    .foregroundColor(.orange)
                                Text("Help others by verifying this restaurant")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            HStack {
                                Button(action: {
                                    verificationService.upvoteRestaurant(restaurant)
                                    verificationResult = verificationService.verifyRestaurant(restaurant)
                                }) {
                                    Image(systemName: "hand.thumbsup.fill")
                                        .foregroundColor(.green)
                                }
                                .buttonStyle(.bordered)
                                Button(action: {
                                    verificationService.downvoteRestaurant(restaurant)
                                    verificationResult = verificationService.verifyRestaurant(restaurant)
                                }) {
                                    Image(systemName: "hand.thumbsdown.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(.horizontal)
                        if let voteData = result.voteData, voteData.upvotes > 0 || voteData.downvotes > 0 {
                            HStack {
                                Text("Community votes:")
                                    .font(.caption)
                                Text("\(voteData.upvotes) 👍")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("\(voteData.downvotes) 👎")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                Divider()

                Button(action: { showLeaveReviewSheet.toggle() }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Leave a Review")
                    }
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.mud)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .sheet(isPresented: $showLeaveReviewSheet) {
                    LeaveReviewView(restaurantId: restaurant.id, restaurantName: restaurant.name)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Nearby Halal Restaurants")
                        .font(.headline)
                        .padding(.leading)

                    if placesService.isLoading {
                        ProgressView("Fetching restaurants...")
                    } else if let error = placesService.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(placesService.recommendedRestaurants) { nearbyRestaurant in
                                    RestaurantCard(
                                        name: nearbyRestaurant.name,
                                        rating: nearbyRestaurant.rating,
                                        photoReference: nearbyRestaurant.photoReference
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
                // Fetch place details (for open/close times)
                placesService.fetchPlaceDetails(for: restaurant.placeId) { result in
                    switch result {
                    case .success(let updatedRestaurant):
                        self.restaurant = updatedRestaurant
                    case .failure(let error):
                        print("Error fetching place details: \(error)")
                    }
                }
                
                placesService.fetchNearbyRestaurants(
                    latitude: restaurant.latitude,
                    longitude: restaurant.longitude
                )
            }
    }

    private func openInGoogleMaps() {
        let destination = "\(restaurant.latitude),\(restaurant.longitude)"
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(destination)&travelmode=driving") {
            UIApplication.shared.open(url)
        }
    }
}
struct GooglePlaceImage: View {
    let photoReference: String
    var body: some View {
        AsyncImage(url: GoogleMapConfig.getPhotoURL(photoReference: photoReference)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image.resizable()
            case .failure:
                Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}
struct StarRatingView: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                Image(systemName: self.starType(for: index))
                    .foregroundColor(.yellow)
            }
        }
    }
    private func starType(for index: Int) -> String {
        if Double(index) <= rating { return "star.fill" }
        else if Double(index) - rating < 1 { return "star.leadinghalf.fill" }
        else { return "star" }
    }
}
struct VerificationDetailsSheet: View {
    let result: VerificationResult
    let restaurant: Restaurant
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Halal Verification Details").font(.headline)
            if result.isVerified {
                if result.source == .communityVerified {
                    Label("\(restaurant.name) is community verified as halal", systemImage: "person.2.fill")
                        .foregroundColor(.orange)
                } else {
                    Label("\(restaurant.name) is verified as halal", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                }
                if result.source == .officialRegistry, let establishment = result.establishment {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Official Registry Information").font(.subheadline).fontWeight(.bold)
                        Text("Registry Name: \(establishment.name)")
                        Text("Registry Address: \(establishment.address)")
                        Text("Certification: \(establishment.certificationType)")
                        Text("Registration: \(establishment.registrationNumber)")
                        HStack {
                            Text("Match Confidence:")
                            switch result.matchConfidence {
                            case .high: Text("High").foregroundColor(.green)
                            case .medium: Text("Medium").foregroundColor(.orange)
                            case .low: Text("Low").foregroundColor(.red)
                            }
                        }
                    }
                }
            } else {
                Text("Not Verified").foregroundColor(.orange)
                Text("This restaurant has not been verified as halal.")
            }
            Spacer()
        }.padding()
    }
}
struct RestaurantMapView: View {
    let latitude: Double
    let longitude: Double
    let name: String
    var body: some View {
        Map(initialPosition: .region(region)) {
            Marker(name, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
        }
    }
    private var region: MKCoordinateRegion {
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        return MKCoordinateRegion(center: center, span: span)
    }
}
