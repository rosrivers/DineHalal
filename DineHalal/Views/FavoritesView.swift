//
//  FavoritesView.swift
//  DineHalal
///  Created by Joanne on 4/1/25.
///  Modified by Victoria


import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favorites: Favorites
    
    var body: some View {
        NavigationView {
            ScrollView {
                ZStack {
                    Color("AccentColor")
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Text("My Favorite Restaurants")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        if favorites.favorites.isEmpty {
                            FavoritesEmptyState()
                        } else {
                            FavoritesList()
                        }
                    }
                }
                .navigationTitle("Favorites")
                .padding(.bottom, 40)
            }
            .background(Color("AccentColor").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct FavoritesEmptyState: View {
    var body: some View {
        VStack {
            Text("No favorite restaurants yet.")
                .foregroundColor(.black)
            Text("Tap the heart icon on a restaurant to add it!")
                .font(.caption)
                .foregroundColor(.black)
        }
        .padding()
    }
}

struct FavoritesList: View {
    @EnvironmentObject var favorites: Favorites

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(favorites.favorites) { restaurant in
                NavigationLink(destination: RestaurantDetails(restaurant: restaurant).environmentObject(favorites)) {
                    FavoriteTile(restaurant: restaurant)
                    // RestaurantCard(restaurant: restaurant) <- alternate to come back to
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal)
    }
}

struct FavoriteTile: View {
    let restaurant: Restaurant
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let ref = restaurant.photoReference,
               let url = GoogleMapConfig.getPhotoURL(photoReference: ref) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 150)
                            .clipped()
                            .cornerRadius(10)
                    default:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 150)
                            .cornerRadius(10)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(restaurant.vicinity)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

