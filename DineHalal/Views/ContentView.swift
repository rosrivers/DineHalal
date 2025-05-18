///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.
///  Edited by Chelsea to add signout button on 3/28/25
///  Edited by Iman to add map icon for navigation to map 4/24/2025
///

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

struct ContentView: View {
    @State private var navigationPath = NavigationPath()
    @EnvironmentObject var navigationState:NavigationStateManager
    @EnvironmentObject var favorites:Favorites
    @EnvironmentObject var verificationService:VerificationService
    @EnvironmentObject var placesService:PlacesService
    @EnvironmentObject var locationManager:LocationManager

    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }

            // New Verified Restaurants tab
            NavigationStack(path: $navigationPath) {
                VerifiedRestaurantsView()
                    
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

            MapPageView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
        }
        .onAppear {
            // Request permission and then fetch location
            locationManager.requestLocationPermission()
            locationManager.getLocation()

            // Listen for updates and reload restaurants
            NotificationCenter.default.addObserver(
                forName: .init("LocationUpdated"),
                object: nil,
                queue: .main
            ) { _ in
                if let loc = locationManager.userLocation {
                    placesService.fetchNearbyRestaurants(
                        latitude: loc.latitude,
                        longitude: loc.longitude,
                        filter: FilterCriteria()
                    )
                }
            }
        }
    }
}
