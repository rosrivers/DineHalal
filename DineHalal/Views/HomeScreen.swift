//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
/// Edited/Modified - Joana


import FirebaseFirestore
import FirebaseCore
import FirebaseAuth
import SwiftUI
import MapKit
import CoreLocation
import GoogleMaps

struct RestaurantCard: View {
    let name: String
    let rating: Double
    let photoReference: String?
    
    var body: some View {
        VStack {
            if let photoReference = photoReference {
                AsyncImage(url: GoogleMapConfig.getPhotoURL(photoReference: photoReference)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure(_):
                        Image("food_placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .empty:
                        ProgressView()
                    @unknown default:
                        Image("food_placeholder")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 100, height: 100)
                .cornerRadius(10)
            } else {
                Image("food_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 8))
                    }
                }
            }
            .frame(width: 100)
            .padding(.vertical, 4)
        }
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}


struct HomeScreen: View {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var showFilter = false
    
    /// User data states
    @State private var userFavorites: [String] = []
    @State private var userReviews: [Review] = []
    @State private var errorMessage: String?
    
    /// Map related states
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // New York coordinates
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    
    // MARK: - Helper Methods
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).collection("favorites")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching favorites: \(error)")
                    return
                }
                self.userFavorites = snapshot?.documents.compactMap { $0.documentID } ?? []
            }
        
        db.collection("users").document(userId).collection("reviews")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error fetching reviews: \(error)")
                    return
                }
                self.userReviews = snapshot?.documents.compactMap { document -> Review? in
                    try? document.data(as: Review.self)
                } ?? []
            }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack {
                        GoogleMapView(region: $region, annotations: annotations)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: UIScreen.main.bounds.height * 0.4)
                                    .edgesIgnoringSafeArea(.top)
                        
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showFilter.toggle()
                                }) {
                                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.beige)
                                        .background(.mud)
                                        .clipShape(Circle())
                                        .shadow(radius: 2)
                                }
                                .padding(.trailing, 16)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                    
                    Button(action: {
                        placesService.fetchNearbyRestaurants(
                            latitude: region.center.latitude,
                            longitude: region.center.longitude
                        )
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Near Me")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.mud)
                        .foregroundColor(.beige)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Popular Restaurants Section
                            VStack(alignment: .leading) {
                                Text("Popular Halal Restaurants")
                                    .font(.headline)
                                    .padding(.leading)
                                    .foregroundStyle(.darkBrown)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(placesService.popularRestaurants) { restaurant in
                                            RestaurantCard(
                                                name: restaurant.name,
                                                rating: restaurant.rating,
                                                photoReference: restaurant.photoReference
                                            )
                                            .onTapGesture {
                                                navigationState.selectedRestaurant = restaurant
                                                navigationState.showingRestaurantDetail = true
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                            
                            // Recommended Restaurants Section
                            if !placesService.recommendedRestaurants.isEmpty {
                                VStack(alignment: .leading) {
                                    Text("Recommended for You")
                                        .font(.headline)
                                        .padding(.leading)
                                        .foregroundStyle(.darkBrown)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            ForEach(placesService.recommendedRestaurants) { restaurant in
                                                RestaurantCard(
                                                    name: restaurant.name,
                                                    rating: restaurant.rating,
                                                    photoReference: restaurant.photoReference
                                                )
                                                .onTapGesture {
                                                    navigationState.selectedRestaurant = restaurant
                                                    navigationState.showingRestaurantDetail = true
                                                }
                                            }
                                        }
                                        .padding()
                                    }
                                }
                            }
                            
                            /// Recently Verified Section -  hardcoded and subject to change.
                            VStack(alignment: .leading) {
                                Text("Recently Verified Halal Restaurants")
                                    .font(.headline)
                                    .padding(.leading)
                                    .foregroundStyle(.darkBrown)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(placesService.recentlyVerified) { restaurant in
                                            RestaurantCard(
                                                name: restaurant.name,
                                                rating: restaurant.rating,
                                                photoReference: restaurant.photoReference
                                            )
                                            .onTapGesture {
                                                navigationState.selectedRestaurant = restaurant
                                                navigationState.showingRestaurantDetail = true
                                            }
                                        }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showFilter) {
                FilterView()
            }
            .sheet(isPresented: $navigationState.showingRestaurantDetail) {
                if let restaurant = navigationState.selectedRestaurant {
                    RestaurantDetails(
                        restaurant: restaurant,
                        verificationService: placesService.verificationService
                    )
                }
            }
            .onAppear {
                placesService.fetchNearbyRestaurants(
                    latitude: region.center.latitude,
                    longitude: region.center.longitude
                )
                fetchUserData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environmentObject(NavigationStateManager())
    }
}
