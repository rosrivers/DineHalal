
///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.
///  Edited by Chelsea to add signout button on 3/28/25
///
import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

struct FavoritesView: View {
    var body: some View {
        ZStack {
            Color(.accent)
            VStack(spacing: 20) {
                Text("My Favorite Restaurants")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.mud)
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
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // New Restaurants tab for testing
            RestaurantsListView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Restaurants")
                }
            
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
        }
    }
}

#Preview {
    ContentView()
}
