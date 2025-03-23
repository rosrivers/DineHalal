//
//  UserProfile.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/11/25.
//

import SwiftUI

struct UserProfile: View {
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture with Edit Button
            ZStack {
                Circle()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray.opacity(0.3))

                Image(systemName: "person.fill") // Placeholder Avatar
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.white)

                Button(action: {
                    print("Edit Avatar")
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.brown)
                        .background(Circle().fill(Color.white))
                }
                .offset(x: 35, y: 35)
            }

            // User Name
            VStack {
                Text("Layla Ali")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("@laylaali")
                    .foregroundColor(.gray)
            }

            // Favorites Section
            VStack(alignment: .leading) {
                Text("My Favorites")
                    .font(.headline)
                
                HStack {
                    FavoriteItem(title: "Sweet & Savory")
                    FavoriteItem(title: "Tandoori")
                }
            }
            .padding()

            // Reviews Section
            VStack(alignment: .leading) {
                Text("My Reviews")
                    .font(.headline)
                
                ReviewItem(title: "Grill House", rating: 4, review: "The lamb kebabs were juicy and full of flavor!")
            }
            .padding()

            Spacer()
            
            BottomNavBar()
        }
        
    }
}

// Favorite Item View
struct FavoriteItem: View {
    var title: String

    var body: some View {
        Text(title)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
    }
}

// Review Item View
struct ReviewItem: View {
    var title: String
    var rating: Int
    var review: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .fontWeight(.bold)
            HStack {
                ForEach(0..<5) { index in
                    Image(systemName: index < rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
            }
            Text(review)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

// Preview
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfile()
    }
}
