//
//  NavBar.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/23/25.
//

import SwiftUI

struct BottomNavBar: View {
    var body: some View {
        HStack {
            NavigationButton(icon: "house.fill", title: "Home", destination: HomeScreen())
            NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile())
            NavigationButton(icon: "person.fill", title: "Profile", destination: UserProfile())
        }
        .frame(maxWidth: 300, minHeight: 50, maxHeight: 55)
                .padding(.horizontal, 10)
                .background(Color(.mud))
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .foregroundColor(.beige)
                .padding(.bottom, 30) 
            
    }
}


struct HomeBar: View {
    var body: some View {
        HStack {
            // Home Button (does nothing when clicked)
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
            NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile())
            NavigationButton(icon: "person.fill", title: "Profile", destination: UserProfile())
        }
        .frame(maxWidth: 300, minHeight: 50, maxHeight: 55)
                .padding(.horizontal, 10)
                .background(Color(.mud))
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .foregroundColor(.beige)
                .padding(.bottom, 30)
            
    }
}
