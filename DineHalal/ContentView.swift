//
//  ContentView.swift
//  Dine Halal
//  Created by Joanne on 3/5/25.

import SwiftUI
import GoogleSignIn
import FirebaseAuth
import Firebase
import SwiftUI



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
            UserProfile()
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
