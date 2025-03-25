//
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

struct HomeScreen: View {
    // MARK: - Properties
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var showFilter = false
    
    // Firebase related states
    @State private var userFavorites: [String] = []
    @State private var userReviews: [Review] = []
    @State private var errorMessage: String?
    
    // Date and User states
    @State private var currentDateTime = Date()
    @State private var timer: Timer?
    @State private var userLogin: String = ""
    
    // New York City coordinates
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    
    // MARK: - Helper Methods
    private func formattedDateTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: currentDateTime)
    }
    
    private func fetchUserData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user")
            return
        }
        
        // Get user login
        if let email = Auth.auth().currentUser?.email {
            userLogin = email.components(separatedBy: "@")[0]
        }
        
        // Fetch favorites
        let favoritesRef = Firestore.firestore().collection("users").document(userId).collection("favorites")
        favoritesRef.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting favorites: \(error.localizedDescription)")
                return
            }
            
            self.userFavorites = snapshot?.documents.compactMap { $0.documentID } ?? []
        }
        
        // Fetch reviews
        let reviewsRef = Firestore.firestore().collection("users").document(userId).collection("reviews")
        reviewsRef.addSnapshotListener { (snapshot, error) in
            if let error = error {
                print("Error getting reviews: \(error.localizedDescription)")
                return
            }
            
            self.userReviews = snapshot?.documents.compactMap { document -> Review? in
                try? document.data(as: Review.self)
            } ?? []
        }
    }
    
    func findNearbyRestaurants() {
        let newCenter = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        if abs(region.center.latitude - newCenter.latitude) > 0.000001 ||
           abs(region.center.longitude - newCenter.longitude) > 0.000001 {
            
            region = MKCoordinateRegion(
                center: newCenter,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            
            let sampleLocations = [
                ("Oasis", 40.7128 + 0.01, -74.0060 + 0.01),
                ("Sweet & Savory", 40.7128 - 0.01, -74.0060 - 0.01),
                ("Grill House", 40.7128 + 0.02, -74.0060 - 0.02)
            ]
            
            annotations.removeAll()
            
            for (name, lat, long) in sampleLocations {
                let annotation = MKPointAnnotation()
                annotation.title = name
                annotation.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                annotations.append(annotation)
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Header Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted):")
                            .font(.caption)
                            .foregroundColor(.darkBrown)
                        Text(formattedDateTime())
                            .font(.caption)
                            .foregroundColor(.darkBrown)
                            .bold()
                        
                        Text("Current User's Login:")
                            .font(.caption)
                            .foregroundColor(.darkBrown)
                        Text(userLogin)
                            .font(.caption)
                            .foregroundColor(.darkBrown)
                            .bold()
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Map Section
                    ZStack {
                        GoogleMapView(region: $region, annotations: annotations)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.4)
                            .edgesIgnoringSafeArea(.top)
                            .background(Color(.systemBackground))
                            .onAppear {
                                if annotations.isEmpty {
                                    findNearbyRestaurants()
                                }
                                fetchUserData()
                                
                                // Setup timer for updating date/time
                                timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                    currentDateTime = Date()
                                }
                            }
                            .onDisappear {
                                timer?.invalidate()
                                timer = nil
                            }
                        
                        // Filter Button
                        GeometryReader { geometry in
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
                    }
                    
                    // MARK: - Near Me Button
                    Button(action: {
                        findNearbyRestaurants()
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
                    
                    // MARK: - Recommended Restaurants Section
                    VStack(alignment: .leading) {
                        Text("Recommended Restaurants")
                            .font(.headline)
                            .padding(.leading)
                            .foregroundStyle(.darkBrown)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach([("Oasis", 4), ("Sweet & Savory", 4), ("Grill House", 4)], id: \.0) { name, rating in
                                    RestaurantCard(name: name, rating: rating)
                                        .onTapGesture {
                                            let restaurant = Restaurant(
                                                id: UUID(),
                                                name: name,
                                                address: "123 Sample St, New York, NY",
                                                latitude: 40.7128 + Double.random(in: -0.02...0.02),
                                                longitude: -74.0060 + Double.random(in: -0.02...0.02)
                                            )
                                            navigationState.selectedRestaurant = restaurant
                                            navigationState.showingRestaurantDetail = true
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    // MARK: - Recently Verified Restaurants Section
                    VStack(alignment: .leading) {
                        Text("Recently Verified Halal Restaurants")
                            .font(.headline)
                            .padding(.leading)
                            .foregroundStyle(.darkBrown)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach([("Spice Haven", 5), ("Tandoori Flame", 5), ("Mezze Magic", 5)], id: \.0) { name, rating in
                                    RestaurantCard(name: name, rating: rating)
                                        .onTapGesture {
                                            let restaurant = Restaurant(
                                                id: UUID(),
                                                name: name,
                                                address: "456 Sample St, New York, NY",
                                                latitude: 40.7128 + Double.random(in: -0.02...0.02),
                                                longitude: -74.0060 + Double.random(in: -0.02...0.02)
                                            )
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
            .sheet(isPresented: $showFilter) {
                FilterView()
            }
            .sheet(isPresented: $navigationState.showingRestaurantDetail) {
                if let restaurant = navigationState.selectedRestaurant {
                    RestaurantDetails(restaurant: restaurant)
                }
            }
        }
    }
}

// MARK: - RestaurantCard View
struct RestaurantCard: View {
    let name: String
    let rating: Int
    
    var body: some View {
        VStack {
            Image("food_placeholder")
                .resizable()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
            Text(name)
                .font(.caption)
                .bold()
                .foregroundColor(.mud)
            
            HStack {
                ForEach(0..<5) { index in
                    Image(systemName: index < rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

// MARK: - Preview Provider
struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        HomeScreen()
            .environmentObject(NavigationStateManager())
    }
}
