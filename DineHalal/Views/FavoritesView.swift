//
//  FavoritesView.swift
//  DineHalal
///  Created by Joanne on 4/1/25.
///  Modified by Victoria


import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favorites: Favorites
    @EnvironmentObject var verificationService: VerificationService
    
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
    @EnvironmentObject var verificationService: VerificationService

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 16)], spacing: 16) {
            ForEach(favorites.favorites) { restaurant in
                NavigationLink(destination: RestaurantDetails(restaurant: restaurant, verificationService: verificationService).environmentObject(favorites)) {
                    FavoriteCard(restaurant: restaurant)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
    }
}

struct FavoriteCard: View {
    let restaurant: Restaurant

    var body: some View {
        VStack {
            if let ref = restaurant.photoReference,
               let url = GoogleMapConfig.getPhotoURL(photoReference: ref) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image("food_placeholder")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 160, height: 160)
                .clipped()
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < Int(restaurant.rating) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                }
            }
            .frame(width: 160, alignment: .leading)
            .padding(.vertical, 6)
        }
        .frame(width: 170, height: 230)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
}

