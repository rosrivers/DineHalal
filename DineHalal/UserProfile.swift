//  UserProfile.swift
//  Dine Halal
//  Created by Iman Ikram on 3/11/25.
//  Edited by Joana & Chelsea on 4/27/25
//  Refactored on 5/4/25 to use Review model, grid layout, and delete support

import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct UserProfile: View {
    @Binding var navigationPath: NavigationPath
    @State private var userName: String = ""
    @State private var userEmail: String = ""
    @State private var profileImageURL: URL?
    @State private var userReviews: [Review] = []
    @State private var isLoading = true
    @State private var isSignedOut = false
    @State private var reviewToEdit: Review? = nil
    @EnvironmentObject var favorites: Favorites

    var body: some View {
        ZStack {
            Color(.accent)

            if isLoading {
                ProgressView()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack(alignment: .center) {
                            Image("profile_bg")
                                .resizable()
                                .scaledToFill()
                                .frame(height: 340)
                                .scaleEffect(1.1)
                                .clipped()
                                .shadow(radius: 5, x: 0, y: 5)

                            VStack(spacing: 8) {
                                ZStack {
                                    if let imageURL = profileImageURL {
                                        AsyncImage(url: imageURL) { image in
                                            image.resizable().scaledToFill()
                                        } placeholder: {
                                            Circle().foregroundColor(.gray)
                                            Image(systemName: "person.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 60, height: 60)
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    } else {
                                        Circle().frame(width: 100, height: 100).foregroundColor(.gray)
                                        Image(systemName: "person.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 60)
                                            .foregroundColor(.white)
                                    }

//                                    Button(action: {
//                                        print("Edit Avatar")
//                                    }) {
//                                        Image(systemName: "pencil.circle.fill")
//                                            .resizable()
//                                            .frame(width: 30, height: 30)
//                                            .foregroundColor(.mud)
//                                            .background(Circle().fill(Color.white))
//                                    }
//                                    .offset(x: 35, y: 35)
                                }
                                .offset(y: -18)

                                Text(userName)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .padding(5)
                                    .padding(.horizontal, 10)
                                    .foregroundColor(.darkBrown)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.accent).shadow(radius: 5))

                                Text(userEmail)
                                    .foregroundColor(.darkBrown.opacity(0.8))
                                    .padding(8)
                                    .padding(.horizontal, 10)
                                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.accent).shadow(radius: 3))
                            }
                            .padding(.top, 100)
                        }
                        // **Favorites Section**
                                                // NO MORE FAVORITES
                        //                        VStack(alignment: .leading, spacing: 10) {
                        //                            Text("My Favorites")
                        //                                .font(.title2)
                        //                                .fontWeight(.bold)
                        //                                .foregroundColor(.darkBrown)
                        //
                        //                            if favorites.favorites.isEmpty {
                        //                                Text("No favorites yet")
                        //                                    .foregroundColor(.mud)
                        //                            } else {
                        //                                ScrollView(.horizontal, showsIndicators: false) {
                        //                                    HStack(spacing: 15) {
                        //                                        ForEach(favorites.favorites) { restaurant in
                        //                                            NavigationLink {
                        //                                                RestaurantDetails(restaurant: restaurant)
                        //                                                    .environmentObject(favorites)
                        //                                            } label: {
                        //                                                VStack(spacing: 8) {
                        //                                                    // Thumbnail
                        //                                                    if let photoReference = restaurant.photoReference,
                        //                                                       let url = GoogleMapConfig.getPhotoURL(photoReference: photoReference) {
                        //                                                        AsyncImage(url: url) { phase in
                        //                                                            switch phase {
                        //                                                            case .empty:
                        //                                                                ProgressView()
                        //                                                                    .frame(width: 100, height: 100)
                        //                                                            case .success(let image):
                        //                                                                image
                        //                                                                    .resizable()
                        //                                                                    .scaledToFill()
                        //                                                                    .frame(width: 100, height: 100)
                        //                                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                        //                                                            case .failure:
                        //                                                                Image(systemName: "photo")
                        //                                                                    .resizable()
                        //                                                                    .frame(width: 100, height: 100)
                        //                                                                    .foregroundColor(.gray)
                        //                                                            @unknown default:
                        //                                                                EmptyView()
                        //                                                            }
                        //                                                        }
                        //                                                    } else {
                        //                                                        Image(systemName: "photo")
                        //                                                            .resizable()
                        //                                                            .frame(width: 100, height: 100)
                        //                                                            .foregroundColor(.gray)
                        //                                                    }
                        //
                        //                                                    // Name
                        //                                                    Text(restaurant.name)
                        //                                                        .font(.caption)
                        //                                                        .multilineTextAlignment(.center)
                        //                                                        .frame(width: 100)
                        //                                                        .foregroundColor(.primary)
                        //                                                }
                        //                                                .frame(width: 100)
                        //                                            }
                        //                                            .buttonStyle(PlainButtonStyle())
                        //                                        }
                        //                                    }
                        //                                    .padding(.horizontal)
                        //                                }
                        //                            }
                        //                        }
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
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                        .padding()

                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear(perform: loadUserData)
        .fullScreenCover(isPresented: $isSignedOut) {
            SignInView(path: $navigationPath)
        }
        .sheet(item: $reviewToEdit) { review in
            EditReviewView(restaurantId: review.restaurantId, review: review) {
                loadUserData()
            }
        }
    }

    private func signOut() {
        do {
            try Auth.auth().signOut()
            isSignedOut = true
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    private func loadUserData() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            return
        }

        userName = user.displayName ?? "User"
        userEmail = user.email ?? ""
        profileImageURL = user.photoURL

        FirebaseService.shared.fetchUserReviews { reviews, error in
            if let reviews = reviews {
                self.userReviews = reviews
            }
            isLoading = false
        }
    }

    private func deleteReview(_ review: Review) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        FirebaseService.shared.deleteReview(restaurantId: review.restaurantId, reviewId: review.id, userId: userId)
        userReviews.removeAll { $0.id == review.id }
    }
}
