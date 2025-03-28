//
//  NavBar.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/23/25.
//
import SwiftUI

// BottomNavBar Component (bottom navigation bar with Home, Favorites, Profile)
struct BottomNavBar: View {
    @Binding var navigationPath: NavigationPath // Pass navigationPath as a binding

    var body: some View {
        HStack {
            NavigationButton(icon: "house.fill", title: "Home", destination: HomeScreen())
            // Pass the navigationPath to UserProfile
            NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile(navigationPath: $navigationPath))
            // Pass the navigationPath to UserProfile
            NavigationButton(icon: "person.fill", title: "Profile", destination: UserProfile(navigationPath: $navigationPath))
        }
        .frame(maxWidth: 300, minHeight: 50, maxHeight: 55)
        .padding(.horizontal, 10)
        .background(Color(.mud))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .foregroundColor(.beige)
        .padding(.bottom, 30)
    }
}

// HomeBar Component (top navigation bar with Home, Favorites, Profile)
struct HomeBar: View {
    @Binding var navigationPath: NavigationPath // Pass navigationPath as a binding

    var body: some View {
        HStack {
            Button(action: {}) {
                VStack {
                    Image(systemName: "house.fill")
                    Text("Home")
                        .font(.footnote)
                }
                .padding()
            }
            .foregroundColor(.beige)

            // Navigation Buttons for other pages
            // Pass the navigationPath to UserProfile
            NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile(navigationPath: $navigationPath))
            // Pass the navigationPath to UserProfile
            NavigationButton(icon: "person.fill", title: "Profile", destination: UserProfile(navigationPath: $navigationPath))
        }
        .frame(maxWidth: 300, minHeight: 50, maxHeight: 55)
        .padding(.horizontal, 10)
        .background(Color(.mud))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .foregroundColor(.beige)
        .padding(.bottom, 30)
    }
}

// Main NavBar View that includes both the HomeBar and BottomNavBar
struct NavBar: View {
    @Binding var navigationPath: NavigationPath // Pass navigationPath as a binding
    
    var body: some View {
        VStack {
            HomeBar(navigationPath: $navigationPath) // Pass navigationPath to HomeBar
            Spacer() // You can use a Spacer to adjust positioning or add some space if needed
            BottomNavBar(navigationPath: $navigationPath) // Pass navigationPath to BottomNavBar
        }
    }
}
