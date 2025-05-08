///  VerifiedRestaurantView.swift
///  DineHalal
///  Created by Joanne on 4/20/25.

import SwiftUI

struct VerifiedRestaurantsView: View {
    @EnvironmentObject var placesService:PlacesService
    @EnvironmentObject var locationManager:LocationManager
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading) {
                        Text("Verified Halal Restaurants")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.darkBrown)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        if locationManager.errorMessage != nil {
                            LocationErrorView(retryAction: {
                                locationManager.getLocation()
                            })
                        } else if locationManager.userLocation == nil {
                            RequestLocationView(requestAction: {
                                locationManager.requestLocationPermission()
                                locationManager.getLocation()
                            })
                        } else if placesService.isLoading {
                            VStack {
                                ProgressView("Finding verified restaurants...")
                                    .foregroundColor(.darkBrown)
                                    .padding()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 50)
                        } else {
                            let verifiedRestaurants = placesService.recentlyVerified
                            
                            if verifiedRestaurants.isEmpty {
                                NoVerifiedRestaurantsView()
                            } else {
                                /// Show verified restaurants with consistent spacing
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                    ForEach(verifiedRestaurants) { restaurant in
                                        NavigationLink(destination: RestaurantDetails(
                                            restaurant: restaurant,
                                            verificationService: placesService.verificationService
                                        )) {
                                            RestaurantCardWithVerification(
                                                restaurant: restaurant,
                                                verificationResult: placesService.getVerificationResult(for: restaurant)
                                            )
                                            .padding(2) // Add small padding around each card
                                            .contentShape(Rectangle()) // Ensure consistent tap area
                                        }
                                    }
                                }
                                .padding(10) // Consistent padding around the entire grid
                            }
                        }
                    }
                }
            }
            .onAppear {
                if let location = locationManager.userLocation {
                    placesService.fetchNearbyRestaurants(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        filter: FilterCriteria()
                    )
                } else {
                    locationManager.getLocation()
                }
            }
        }
    }
}


/// Helper Views for various states with updated colors

struct LocationErrorView: View {
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.slash.fill")
                .font(.largeTitle)
                .foregroundColor(.mud)
            
            Text("Unable to access your location")
                .font(.headline)
                .foregroundColor(.darkBrown)
            
            Text("We need your location to find verified halal restaurants near you.")
                .multilineTextAlignment(.center)
                .foregroundColor(.darkBrown.opacity(0.7))
            
            Button(action: retryAction) {
                Text("Try Again")
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.mud)
                    .foregroundColor(.beige)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct RequestLocationView: View {
    let requestAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.fill")
                .font(.largeTitle)
                .foregroundColor(.mud)
            
            Text("Location Access Required")
                .font(.headline)
                .foregroundColor(.darkBrown)
            
            Text("To find verified halal restaurants near you, we need your location.")
                .multilineTextAlignment(.center)
                .foregroundColor(.darkBrown.opacity(0.7))
            
            Button(action: requestAction) {
                Text("Share Location")
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.mud)
                    .foregroundColor(.beige)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct NoVerifiedRestaurantsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.mud)
            
            Text("No Verified Restaurants Found")
                .font(.headline)
                .foregroundColor(.darkBrown)
            
            Text("We couldn't find any halal-verified restaurants in your current area. Try exploring a different location or check back later.")
                .multilineTextAlignment(.center)
                .foregroundColor(.darkBrown.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}
