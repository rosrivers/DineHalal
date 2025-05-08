//  UserProfile.swift
//  Dine Halal
//  Created by Iman Ikram on 3/11/25.
//  Edited/ modified - Joana
//  Edited by Chelsea to add signout button
//  Refactored to use Review model, grid layout, and delete support

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct UserProfile: View {
    @Binding var navigationPath: NavigationPath
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var profileImageURL: URL?
    @State private var userFavorites: [String] = [] // Just store restaurant names for now
    @State private var userReviews: [Review] = [] // Using the structured Review model
    @State private var isLoading = true
    @State private var isSignedOut = false
    @State private var reviewToEdit: Review? = nil // For editing reviews
    @EnvironmentObject var favorites: Favorites
    
    var body: some View {
        ZStack {
            // Background Color
            Color(.accent)
            
            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack(alignment: .center) {
                            // Background Image
                            Image("profile_bg")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 340)
                                .scaleEffect(1.1)
                                .clipped()
                                .shadow(radius: 5, x: 0, y: 5)

                            VStack(spacing: 8) {
                                // Profile Picture
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
                                                .foregroundColor(.gray)
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .foregroundColor(.white)
                                        }
                                    } else {
                                        Circle()
                                            .frame(width: 100, height: 100)
                                            .foregroundColor(.gray)
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.white)
                                    }
                                }
                                .offset(y: -18)

                                // User Name
                                Text(userName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(5)
                                    .padding(.horizontal, 10)
                                    .foregroundColor(.darkBrown)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(Color.accent)
                                            .shadow(radius: 5)
                                            .padding(1)
                                    )

                                // User Email
                                Text(userEmail)
                                    .foregroundColor(.darkBrown.opacity(0.8))
                                    .padding(8)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color.accent)
                                            .shadow(radius: 3)
                                            .padding(5)
                                    )
                            }
                            .padding(.top, 100) // Position elements within the background
                        }

                        // **Reviews Section** - Combined from both versions
                        VStack(alignment: .leading) {
                            Text("My Reviews")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.darkBrown)
                            
                            if userReviews.isEmpty {
                                Text("No reviews yet")
                                    .foregroundColor(.mud)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(userReviews.sorted { $0.date > $1.date }) { review in
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(review.restaurantName)
                                                .font(.headline)
                                                .lineLimit(1)

                                            HStack(spacing: 2) {
                                                ForEach(1...5, id: \.self) { index in
                                                    Image(systemName: index <= review.rating ? "star.fill" : "star")
                                                        .foregroundColor(.yellow)
                                                        .font(.system(size: 10))
                                                }
                                            }

                                            Text(review.comment)
                                                .font(.caption)
                                                .lineLimit(2)

                                            HStack {
                                                Button(role: .destructive) {
                                                    deleteReview(review)
                                                } label: {
                                                    Image(systemName: "trash")
                                                        .foregroundColor(.red)
                                                }

                                                Button {
                                                    reviewToEdit = review
                                                } label: {
                                                    Image(systemName: "pencil")
                                                        .foregroundColor(.blue)
                                                }
                                            }
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()

                        Spacer()
                        // **Sign-Out Button** placed at the bottom of the page
                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.mud)
                                .cornerRadius(10)
                                .padding(.top)

                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            loadUserData()
        }
        .fullScreenCover(isPresented: $isSignedOut) {
            // Navigate back to the Sign-In screen after signing out, passing the navigationPath
            SignInView(path: $navigationPath)
        }
        .sheet(item: $reviewToEdit) { review in
            EditReviewView(restaurantId: review.restaurantId, review: review) {
                loadUserData()
            }
        }
    }

    // Sign-Out Function
    private func signOut() {
        do {
            try Auth.auth().signOut()
            print("User signed out successfully.")
            isSignedOut = true  // Trigger navigation to Sign-In view
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // Load user data from Firebase - Combined approach
    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }
        
        userName = user.displayName ?? "User"
        userEmail = user.email ?? ""
        profileImageURL = user.photoURL
        
        let db = Firestore.firestore()
        
        // Load favorites
        db.collection("users").document(user.uid).collection("favorites")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting favorites: \(error)")
                } else {
                    userFavorites = snapshot?.documents.compactMap { doc in
                        doc.data()["name"] as? String
                    } ?? []
                }
            }
        
        // Load reviews using FirebaseService (from main-backup)
        FirebaseService.shared.fetchUserReviews { reviews, error in
            if let reviews = reviews {
                self.userReviews = reviews
            }
            isLoading = false
        }
    }
    
    // Delete review function from main-backup
    private func deleteReview(_ review: Review) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        FirebaseService.shared.deleteReview(restaurantId: review.restaurantId, reviewId: review.id, userId: userId)
        userReviews.removeAll { $0.id == review.id }
    }
}

// **Preview**
//struct UserProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserProfile(navigationPath: .constant(NavigationPath()))
//    }
//}
