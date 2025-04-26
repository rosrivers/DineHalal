
///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.
/// Edited by Chelsea on 4/5/25.

import SwiftUI
import MapKit

struct RestaurantDetails: View {
    let restaurant: Restaurant

    @State private var region: MKCoordinateRegion
    @State private var rating: Int = 0
    @State private var review: String = ""
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var favorites: Favorites
    @ObservedObject var verificationService: VerificationService
    @State private var showingVerificationDetails = false
    @State private var verificationResult: VerificationResult?
    
    init(restaurant: Restaurant, verificationService: VerificationService) {
        self.restaurant = restaurant
        self.verificationService = verificationService
        
        // Pre-check the verification status
        _verificationResult = State(initialValue: verificationService.verifyRestaurant(restaurant))
        
        // Initialize region
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.01,
                longitudeDelta: 0.01
            )
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Restaurant photo - use photoReference directly
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
                
                // Restaurant info
                VStack(alignment: .leading, spacing: 8) {
                    // Name and action buttons row
                    HStack {
                        Text(restaurant.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            
                        Spacer()
                        
                        // Get Directions button
                        Button(action: {
                            openInGoogleMaps()
                        }) {
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
                        
                        // Favorites button
                        Button(action: {
                            favorites.toggleFavorite(restaurant)
                        }) {
                            Image(systemName: favorites.isFavorite(restaurant) ? "heart.fill" : "heart")
                                .foregroundColor(favorites.isFavorite(restaurant) ? .red : .gray)
                                .font(.title2)
                        }
                    }
                    
                    // Rating
                    HStack {
                        StarRatingView(rating: restaurant.rating)
                        Text("\(restaurant.rating, specifier: "%.1f")")
                            .foregroundColor(.gray)
                        Text("(\(restaurant.numberOfRatings) reviews)")
                            .foregroundColor(.gray)
                    }
                    
                    // Verification badge - MOVED HERE (replacing $$ signs)
                    // This is where the $ price indicator used to be
                    if let result = verificationResult, result.isVerified {
                        Button(action: {
                            showingVerificationDetails = true
                        }) {
                            HStack(spacing: 4) {
                                if result.source == .communityVerified {
                                    // Orange for community verification
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.orange)
                                    Text("Community Verified")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                } else {
                                    // Green for official verification
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Verified Halal")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .sheet(isPresented: $showingVerificationDetails) {
                            VerificationDetailsSheet(result: result, restaurant: restaurant)
                        }
                    }
                    
                    // Address with icon
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(restaurant.vicinity)
                            .foregroundColor(.gray)
                    }
                    
                    // Opening hours with icon
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                        Text(restaurant.isOpenNow ? "Open Now" : "Closed")
                            .foregroundColor(restaurant.isOpenNow ? .green : .red)
                    }
                    
                    Divider()
                    
                    // Map
                    Text("Location")
                        .font(.headline)
                    
                    // Show map
                    RestaurantMapView(latitude: restaurant.latitude,
                                     longitude: restaurant.longitude,
                                     name: restaurant.name)
                        .frame(height: 200)
                        .cornerRadius(12)
                    
                    /// Verification section
                    if let result = verificationResult {
                        Divider()
                        
                        Text("Halal Verification")
                            .font(.headline)
                        
                        if result.isVerified {
                            HStack {
                                // Use different icon and color based on verification source
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
                                
                                // Community verification buttons
                                HStack {
                                    Button(action: {
                                        verificationService.upvoteRestaurant(restaurant)
                                        // Update verification result
                                        verificationResult = verificationService.verifyRestaurant(restaurant)
                                    }) {
                                        Image(systemName: "hand.thumbsup.fill")
                                            .foregroundColor(.green)
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Button(action: {
                                        verificationService.downvoteRestaurant(restaurant)
                                        // Update verification result
                                        verificationResult = verificationService.verifyRestaurant(restaurant)
                                    }) {
                                        Image(systemName: "hand.thumbsdown.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            
                            // Show current votes if any
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
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            placesService.fetchNearbyRestaurants(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude,
                filter: nil
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

// Renamed to avoid conflict with existing VerificationDetailsView
struct VerificationDetailsSheet: View {
    let result: VerificationResult
    let restaurant: Restaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Halal Verification Details")
                .font(.headline)
            
            if result.isVerified {
                HStack {
                    // Use different icon and color based on verification source
                    if result.source == .communityVerified {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.orange)
                        Text("\(restaurant.name) is community verified as halal")
                            .foregroundColor(.orange)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("\(restaurant.name) is verified as halal")
                            .foregroundColor(.green)
                    }
                }
                
                Divider()
                
                if result.source == .officialRegistry, let establishment = result.establishment {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Official Registry Information")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        
                        Text("Registry Name: \(establishment.name)")
                        Text("Registry Address: \(establishment.address)")
                        Text("Certification: \(establishment.certificationType)")
                        Text("Registration: \(establishment.registrationNumber)")
                        
                        // Match confidence
                        HStack {
                            Text("Match Confidence:")
                            
                            switch result.matchConfidence {
                            case .high:
                                Text("High")
                                    .foregroundColor(.green)
                            case .medium:
                                Text("Medium")
                                    .foregroundColor(.orange)
                            case .low:
                                Text("Low")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } else if result.source == .communityVerified, let voteData = result.voteData {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Community Verification")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("This restaurant has been verified as halal by community votes")
                        
                        HStack {
                            Text("Upvotes: \(voteData.upvotes)")
                                .foregroundColor(.green)
                            Spacer()
                            Text("Downvotes: \(voteData.downvotes)")
                                .foregroundColor(.red)
                        }
                        
                        let approvalRate = Double(voteData.upvotes) / Double(voteData.upvotes + voteData.downvotes) * 100
                        Text("Approval Rate: \(Int(approvalRate))%")
                            .foregroundColor(approvalRate > 80 ? .green : .orange)
                    }
                }
            } else {
                Text("Not Verified")
                    .foregroundColor(.orange)
                Text("This restaurant has not been verified as halal.")
                
                if let voteData = result.voteData {
                    Divider()
                    
                    Text("Community Votes")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Upvotes: \(voteData.upvotes)")
                            .foregroundColor(.green)
                        Spacer()
                        Text("Downvotes: \(voteData.downvotes)")
                            .foregroundColor(.red)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
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
        if Double(index) <= rating {
            return "star.fill"
        } else if Double(index) - rating < 1 {
            return "star.leadinghalf.fill"
        } else {
            return "star"
        }
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

struct GooglePlaceImage: View {
    let photoReference: String
    
    var body: some View {
        AsyncImage(url: GoogleMapConfig.getPhotoURL(photoReference: photoReference)) { phase in
            switch phase {
            case .empty:
                ProgressView()
            case .success(let image):
                image
                    .resizable()
            case .failure:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            @unknown default:
                EmptyView()
            }
        }
    }
}
