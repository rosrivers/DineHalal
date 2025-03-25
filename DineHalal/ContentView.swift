
///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

// New Favorites View
struct FavoritesView: View {
    var body: some View {
        ZStack {
            Color(.accent)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("My Favorite Restaurants")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mud)
                
                // Placeholder message
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

struct ContentView: View {
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            UserProfile()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
            FavoritesView()  // Changed from UserProfile() to FavoritesView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Favorites")
                }
        }
    }
}

#Preview {
    ContentView()
}
