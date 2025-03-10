//
//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
//

import SwiftUI

struct HomeScreen: View {
    @State private var searchText = ""
    
    var body: some View {
        ZStack {
            Color("AccentColor") // Background color
                .ignoresSafeArea() // Extends to edges
            VStack {
                // Map and App Title
                ZStack(alignment: .topTrailing) {
                    //Image("map_background") // Replace with actual map image or MapKit
                        //.resizable()
                       // .scaledToFit()
                        
                    
                    Text("DineHalal")
                        .font(.largeTitle)
                        .bold()
                        //.padding()
                        .foregroundColor(.darkBrown)
                }
                
                .frame(height: 180)
                
                // Search and Filter Section
                HStack {
                    TextField("Search for halal restaurants...", text: $searchText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    
                    Button(action: {
                        // Implement filter action
                    }) {
                        Label("Filter", systemImage: "slider.horizontal.3")
                            .padding()
                            .background(.mud)
                            .foregroundColor(.beige)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // "Near Me" Button
                Button(action: {
                    // Implement location search functionality
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
                // Recommended Restaurants
                VStack(alignment: .leading) {
                    Text("Recommended Restaurants")
                        .font(.headline)
                        .padding(.leading)
                        .foregroundStyle(.darkBrown)
                    
                    ScrollView(.horizontal, showsIndicators: false) {  // Hardcoded for now
                        HStack {
                            RestaurantCard(name: "Oasis", rating: 4)
                            RestaurantCard(name: "Sweet & Savory", rating: 3)
                            RestaurantCard(name: "Grill House", rating: 4)
                        }
                        .padding()
                    }
                }
                
                // Recently Verified Restaurants
                VStack(alignment: .leading) {
                    Text("Recently Verified Halal Restaurants")
                        .font(.headline)
                        .padding(.leading)
                        .foregroundStyle(.darkBrown)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            RestaurantCard(name: "Spice Haven", rating: 5)
                            RestaurantCard(name: "Tandoori Flame", rating: 4)
                            RestaurantCard(name: "Mezze Magic", rating: 5)
                        }
                        .padding()
                    }
                }
                
                Spacer()
                
                // Bottom Navigation Bar
                HStack {
                    NavigationButton(icon: "house.fill", title: "Home")
                    NavigationButton(icon: "heart.fill", title: "Favorites")
                    NavigationButton(icon: "plus.circle.fill", title: "Add Review")
                }
                .frame(maxWidth: .infinity) // Ensures it stretches across the screen
                .padding(.bottom)
                .background(.mud)
                .foregroundColor(.beige)
            }
        }
    }
    
    struct RestaurantCard: View {
        let name: String
        let rating: Int
        
        var body: some View {
            VStack {
                Image("food_placeholder") // Replace with actual images from Yelp
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                
                Text(name)
                    .font(.caption)
                    .bold()
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    struct NavigationButton: View {
        let icon: String
        let title: String
        
        var body: some View {
            VStack {
                Image(systemName: icon)
                Text(title)
                    .font(.footnote)
            }
            .padding()
        }
    }
    
    struct HomeView_Previews: PreviewProvider {
        static var previews: some View {
            HomeScreen()
        }
    }
    
}
