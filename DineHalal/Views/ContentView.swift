
///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.
///  Edited by Chelsea to add signout button on 3/28/25
///

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

struct ContentView: View {
    @State private var navigationPath = NavigationPath() /// Keep track of the navigation path
    @StateObject private var placesService = PlacesService() // Shared PlacesService
    @StateObject private var locationManager = LocationManager() // Use your existing LocationManager
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // New Verified Restaurants tab
            NavigationStack {
                VerifiedRestaurantsView(placesService: placesService)
                    .navigationTitle("Verified Halal")
            }
            .tabItem {
                Image(systemName: "checkmark.seal.fill")
                Text("Verified")
            }
            
            /// Pass navigationPath to UserProfile here
            UserProfile(navigationPath: $navigationPath)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
            
            FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
        }
        .onAppear {
            // Request location permission when the app appears
            locationManager.requestLocationPermission()
            locationManager.getLocation()
            
            // Set up location monitoring
            // Instead of using onChange which requires Equatable
            NotificationCenter.default.addObserver(forName: NSNotification.Name("LocationUpdated"), object: nil, queue: .main) { _ in
                if let location = locationManager.userLocation {
                    placesService.fetchNearbyRestaurants(
                        latitude: location.latitude,
                        longitude: location.longitude
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
