//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
/// Edited/Modified - Joana
/// Edited by Chelsea 4/5/25

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
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var showFilter = false

    @State private var userFavorites: [String] = []
    @State private var userReviews: [Review] = []
    @State private var errorMessage: String?

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    @State private var filterCriteria = FilterCriteria()

    private func geocodeZipCode(_ zip: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zip) { placemarks, error in
            if let error = error {
                print("Geocoding error: \(error.localizedDescription)")
                completion(nil)
            } else if let location = placemarks?.first?.location {
                completion(location.coordinate)
            } else {
                completion(nil)
            }
        }
    }

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

    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        GoogleMapView(region: $region, annotations: annotations)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.45)
                            .edgesIgnoringSafeArea(.top)
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                    }

                    // NEW: Buttons side by side
                    HStack(spacing: 20) {
                        Button(action: {
                            if !filterCriteria.cityZip.isEmpty {
                                geocodeZipCode(filterCriteria.cityZip) { coordinate in
                                    if let coordinate = coordinate {
                                        placesService.fetchNearbyRestaurants(
                                            latitude: coordinate.latitude,
                                            longitude: coordinate.longitude,
                                            filter: filterCriteria
                                        )
                                    } else {
                                        placesService.fetchNearbyRestaurants(
                                            latitude: region.center.latitude,
                                            longitude: region.center.longitude,
                                            filter: filterCriteria
                                        )
                                    }
                                }
                            } else {
                                placesService.fetchNearbyRestaurants(
                                    latitude: region.center.latitude,
                                    longitude: region.center.longitude,
                                    filter: filterCriteria
                                )
                            }
                        }) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Near Me")
                            }
                            .padding(.horizontal, 70) // Reduce horizontal padding for shorter width
                            .padding(.vertical, 14)
                            .background(.mud)
                            .foregroundColor(.beige)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                        }

                        Button(action: {
                            showFilter.toggle()
                        }) {
                            HStack {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 36, height: 36)
                                    .padding(4)
                                    .background(Color.mud)
                                    .foregroundColor(Color.beige)
                                    .cornerRadius(30)
                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    .offset(y: -12)

                    // Restaurant Sections
                    ScrollView {
                        VStack(spacing: 20) {
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
                FilterView(criteria: $filterCriteria) { criteria in
                    if !criteria.cityZip.isEmpty {
                        geocodeZipCode(criteria.cityZip) { coordinate in
                            if let coordinate = coordinate {
                                placesService.fetchNearbyRestaurants(
                                    latitude: coordinate.latitude,
                                    longitude: coordinate.longitude,
                                    filter: criteria
                                )
                            } else {
                                placesService.fetchNearbyRestaurants(
                                    latitude: region.center.latitude,
                                    longitude: region.center.longitude,
                                    filter: criteria
                                )
                            }
                        }
                    } else {
                        placesService.fetchNearbyRestaurants(
                            latitude: region.center.latitude,
                            longitude: region.center.longitude,
                            filter: criteria
                        )
                    }
                }
            }
            .sheet(isPresented: $navigationState.showingRestaurantDetail) {
                if let restaurant = navigationState.selectedRestaurant {
                    RestaurantDetails(restaurant: restaurant)
                }
            }
            .onAppear {
                if !filterCriteria.cityZip.isEmpty {
                    geocodeZipCode(filterCriteria.cityZip) { coordinate in
                        if let coordinate = coordinate {
                            placesService.fetchNearbyRestaurants(
                                latitude: coordinate.latitude,
                                longitude: coordinate.longitude,
                                filter: filterCriteria
                            )
                        } else {
                            placesService.fetchNearbyRestaurants(
                                latitude: region.center.latitude,
                                longitude: region.center.longitude,
                                filter: filterCriteria
                            )
                        }
                    }
                } else {
                    placesService.fetchNearbyRestaurants(
                        latitude: region.center.latitude,
                        longitude: region.center.longitude,
                        filter: filterCriteria
                    )
                }
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
