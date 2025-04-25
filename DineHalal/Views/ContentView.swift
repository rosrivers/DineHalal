
///  ContentView.swift
///  Dine Halal
///  Created by Joanne on 3/5/25.
///  Edited by Chelsea to add signout button on 3/28/25
///  Edited by Iman to add map icon for navigation to map 4/24/2025
///


import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase

struct ContentView: View {
    @State private var navigationPath = NavigationPath() /// Keep track of the navigation path
    
    var body: some View {
        TabView {
            HomeScreen()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            /// Pass navigationPath to UserProfile here
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
            
            HomeScreen() //MapPageView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
        }
    }
}

#Preview {
    ContentView()
}
