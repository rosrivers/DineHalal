
///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.


import SwiftUI
import MapKit

struct RestaurantDetails: View {
    let restaurant: Restaurant
    @ObservedObject var verificationService: VerificationService
    @State private var showingVerificationDetails = false
    @State private var verificationResult: VerificationResult?
    
    init(restaurant: Restaurant, verificationService: VerificationService) {
        self.restaurant = restaurant
        self.verificationService = verificationService
        
        // Pre-check the verification status
        _verificationResult = State(initialValue: verificationService.verifyRestaurant(restaurant))
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
                    HStack {
                        Text(restaurant.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        // Verification badge
                        if let result = verificationResult, result.isVerified {
                            Button(action: {
                                showingVerificationDetails = true
                            }) {
                                HStack {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.green)
                                    Text("Verified")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .sheet(isPresented: $showingVerificationDetails) {
                                VerificationDetailsSheet(result: result, restaurant: restaurant)
                            }
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
                    
                    // Price level
                    if let priceLevel = restaurant.priceLevel {
                        Text(String(repeating: "$", count: priceLevel))
                            .foregroundColor(.gray)
                    }
                    
                    // Address
                    HStack {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(.red)
                        Text(restaurant.vicinity)
                            .foregroundColor(.gray)
                    }
                    
                    // Add more details as needed
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
                    
                    // Verification section
                    if let result = verificationResult {
                        Divider()
                        
                        Text("Halal Verification")
                            .font(.headline)
                        
                        if result.isVerified {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading) {
                                    Text("This restaurant is halal verified")
                                        .foregroundColor(.green)
                                    
                                    if result.source == .officialRegistry {
                                        Text("Verified by official registry")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    } else if result.source == .communityVerified {
                                        Text("Verified by community votes")
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
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("\(restaurant.name) is verified as halal")
                        .foregroundColor(.green)
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
