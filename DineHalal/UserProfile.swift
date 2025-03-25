
///  UserProfile.swift
///  Dine Halal
///  Created by Iman Ikram on 3/11/25.
/// Edited/ modified - Joana

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct UserProfile: View {
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var profileImageURL: URL?
    @State private var userFavorites: [String] = [] /// Just store restaurant names for now
    @State private var userReviews: [(restaurantName: String, rating: Int, review: String)] = [] /// Simple tuple for reviews
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            // Background Color
            Color(.accent)
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Picture with Edit Button
                        ZStack {
                            if let imageURL = profileImageURL {
                                AsyncImage(url: imageURL) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.or)
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 60, height: 60)
                                        .foregroundColor(.white)
                                }
                            } else {
                                Circle()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.or)
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white)
                            }

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

                        /// User Name
                        VStack {
                            Text(userName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.mud)
                            Text(userEmail)
                                .foregroundColor(.or)
                        }

                        /// Favorites Section
                        VStack(alignment: .leading) {
                            Text("My Favorites")
                                .font(.headline)
                            
                            if userFavorites.isEmpty {
                                Text("No favorites yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 15) {
                                        ForEach(userFavorites, id: \.self) { restaurantName in
                                            FavoriteItem(title: restaurantName)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding()

                        /// Reviews Section
                        VStack(alignment: .leading) {
                            Text("My Reviews")
                                .font(.headline)
                            
                            if userReviews.isEmpty {
                                Text("No reviews yet")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(userReviews, id: \.restaurantName) { review in
                                    ReviewItem(title: review.restaurantName,
                                             rating: review.rating,
                                             review: review.review)
                                }
                            }
                        }
                        .padding()

                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    /// Updated function to load user data from Firebase
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        userName = user.displayName ?? "User"
        userEmail = user.email ?? ""
        if let photoURL = user.photoURL {
            profileImageURL = photoURL
        }
        
        let db = Firestore.firestore()
        
        /// Load favorites (simple string array for now since restaurant fetching data is not available yet)
        db.collection("users").document(user.uid).collection("favorites")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting favorites: \(error)")
                } else {
                    userFavorites = snapshot?.documents.compactMap { doc in
                        doc.data()["name"] as? String
                    } ?? []
                }
                
                /// Load reviews
                db.collection("users").document(user.uid).collection("reviews")
                    .getDocuments { snapshot, error in
                        if let error = error {
                            print("Error getting reviews: \(error)")
                        } else {
                            userReviews = snapshot?.documents.compactMap { doc -> (String, Int, String)? in
                                let data = doc.data()
                                guard let restaurantName = data["restaurantName"] as? String,
                                      let rating = data["rating"] as? Int,
                                      let review = data["reviewText"] as? String else {
                                    return nil
                                }
                                return (restaurantName, rating, review)
                            } ?? []
                        }
                        
                        isLoading = false
                    }
            }
    }
}


struct FavoriteItem: View {
    var title: String

    var body: some View {
        Text(title)
            .frame(width: 120)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(12)
    }
}

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
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfile()
    }
}
