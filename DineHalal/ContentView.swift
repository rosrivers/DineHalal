
///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.
///  Edited by Chelsea to add signout button on 3/28/25
///
import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

// New Favorites View
struct FavoritesView: View {
    var body: some View {
        ZStack {
            Color(.accent)
                //.ignoresSafeArea()
            
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
    @State private var navigationPath = NavigationPath() // Keep track of the navigation path
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Pass navigationPath to UserProfile here
            UserProfile(navigationPath: $navigationPath)
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
