//
//  SearchView.swift
//  DineHalal
//  Created by Joanne on 4/1/25.


import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @ObservedObject var placesService: PlacesService
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search restaurants...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                if placesService.isLoading {
                    ProgressView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 15) {
                            ForEach(placesService.recommendedRestaurants) { restaurant in
                                SearchResultRow(restaurant: restaurant)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Search")
        }
    }
}

struct SearchResultRow: View {
    let restaurant: Restaurant
    
    var body: some View {
        HStack {
            // Placeholder for restaurant image
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(restaurant.name)
                    .font(.headline)
                
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", restaurant.rating))
                    Text("(\(restaurant.numberOfRatings))")
                        .foregroundColor(.gray)
                }
                .font(.caption)
                
                Text(restaurant.vicinity)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
