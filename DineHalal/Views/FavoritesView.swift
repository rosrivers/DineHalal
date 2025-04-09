//
//  FavoritesView.swift
//  DineHalal
///  Created by Joanne on 4/1/25.


import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var favorites: Favorites

    var body: some View {
        NavigationView {
            ZStack {
                Color("AccentColor")
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("My Favorite Restaurants")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    if favorites.favorites.isEmpty {
                        VStack {
                            Text("No favorite restaurants yet.")
                                .foregroundColor(.gray)
                            Text("Tap the heart icon on a restaurant to add it!")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                    } else {
                        // subject to change: adjust the view so its more visually appealing
                        List(favorites.favorites) { restaurant in
                            HStack {
                                Text(restaurant.name)
                                Spacer()
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Favorites")
        }
    }
}
