
///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.
///

import SwiftUI
import MapKit
import GoogleMaps

struct RestaurantDetails: View {
    let restaurant: Restaurant
    @State private var region: MKCoordinateRegion
    @State private var rating: Int = 0
    @State private var review: String = ""
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var favorites: Favorites
    
    init(restaurant: Restaurant) {
        self.restaurant = restaurant
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Restaurant Image
                if let photoReference = restaurant.photoReference {
                    AsyncImage(url: getPhotoURL(photoReference: photoReference)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 200)
                    .clipped()
                }
                
                // Restaurant Info
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(restaurant.name)
                            .font(.title)
                            .fontWeight(.bold)
                                            
                            Spacer()
                        // favorites button added
                        Button(action: {
                            favorites.toggleFavorite(restaurant)
                        }) {
                            Image(systemName: favorites.isFavorite(restaurant) ? "heart.fill" : "heart")
                                .foregroundColor(favorites.isFavorite(restaurant) ? .red : .gray)
                                .font(.title2)
                            }
                        }
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= Int(restaurant.rating) ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                        }
                        Text("(\(restaurant.numberOfRatings) reviews)")
                            .foregroundColor(.gray)
                    }
                    
                    Text(restaurant.vicinity)
                        .foregroundColor(.gray)
                    
                    if restaurant.isOpenNow {
                        Text("Open Now")
                            .foregroundColor(.green)
                    } else {
                        Text("Closed")
                            .foregroundColor(.red)
                    }
                }
                .padding()
                
                // Map View
                Map(coordinateRegion: $region, annotationItems: [restaurant]) { place in
                    MapMarker(coordinate: CLLocationCoordinate2D(
                        latitude: place.latitude,
                        longitude: place.longitude
                    ))
                }
                .frame(height: 200)
                .cornerRadius(10)
                
                // Nearby Restaurants Section
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
                
                // Review Section
                VStack(alignment: .leading, spacing: 10) {
                    Text("Write a Review")
                        .font(.headline)
                    
                    HStack {
                        ForEach(1...5, id: \.self) { index in
                            Image(systemName: index <= rating ? "star.fill" : "star")
                                .foregroundColor(.yellow)
                                .onTapGesture {
                                    rating = index
                                }
                        }
                    }
                    
                    TextEditor(text: $review)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3))
                        )
                    
                    Button("Submit Review") {
                        submitReview()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
              // async call
              await placesService.fetchNearbyRestaurants(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
              )
            }
    }
    
    private func getPhotoURL(photoReference: String) -> URL? {
        return GoogleMapConfig.getPhotoURL(photoReference: photoReference)
    }
    
    private func submitReview() {
        print("Submitting review: Rating: \(rating), Review: \(review)")
    }
}
