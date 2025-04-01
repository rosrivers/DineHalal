
///  UserProfile.swift
///  Dine Halal
///  Created by Iman Ikram on 3/11/25.
/// Edited/ modified - Joana
///Edited by Chelsea to add signout button
///
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct UserProfile: View {
    @Binding var navigationPath: NavigationPath // Pass navigationPath as a binding
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var profileImageURL: URL?
    @State private var userFavorites: [String] = [] // Just store restaurant names for now
    @State private var userReviews: [(restaurantName: String, rating: Int, review: String)] = [] // Simple tuple for reviews
    @State private var isLoading = true
    @State private var isSignedOut = false // Flag to navigate after sign-out
    
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

                                    Button(action: {
                                        print("Edit Avatar")
                                    }) {
                                        Image(systemName: "pencil.circle.fill")
                                            .resizable()
                                            .frame(width: 30, height: 30)
                                            .foregroundColor(.mud)
                                            .background(Circle().fill(Color.white))
                                    }
                                    .offset(x: 35, y: 35)
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

                        // **Favorites Section**
                        VStack(alignment: .leading) {
                            Text("My Favorites")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.darkBrown)
                            
                            if userFavorites.isEmpty {
                                Text("No favorites yet")
                                    .foregroundColor(.mud)
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

                        // **Reviews Section**
                        VStack(alignment: .leading) {
                            Text("My Reviews")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.darkBrown)
                            
                            if userReviews.isEmpty {
                                Text("No reviews yet")
                                    .foregroundColor(.mud)
                            } else {
                                ForEach(userReviews, id: \.restaurantName) { review in
                                    ReviewItem(title: review.restaurantName,
                                             rating: review.rating,
                                             review: review.review)
                                }
                            }
                        }
                        .padding()

                        // **Sign-Out Button** placed at the bottom of the page
                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                                .padding(.top)
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
        .fullScreenCover(isPresented: $isSignedOut) {
            // Navigate back to the Sign-In screen after signing out, passing the navigationPath
            SignInView(path: $navigationPath)
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

    // Load user data from Firebase
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
                
                // Load reviews
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

// **Favorite Item**
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

// **Review Item**
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

// **Preview**
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfile(navigationPath: .constant(NavigationPath()))
    }
}
