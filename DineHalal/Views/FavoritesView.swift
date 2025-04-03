//
//  FavoritesView.swift
//  DineHalal
///  Created by Joanne on 4/1/25.


import SwiftUI
struct FavoritesView: View {
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
                    
                    Text("Coming Soon!")
                        .foregroundColor(.gray)
                        .padding()
                    
                    Text("Restaurant integration in progress")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
