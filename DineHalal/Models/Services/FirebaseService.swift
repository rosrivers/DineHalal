//  FirebaseService.swift
//  DineHalal
// Created by Joanne on 4/1/25.
//Edited by Chelsea on 4/27/25

import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()

    // Fetch all restaurants
    func fetchAllRestaurants(completion: @escaping ([Restaurant]?, Error?) -> Void) {
        db.collection("restaurants").getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let documents = snapshot?.documents else {
                completion(nil, nil)
                return
            }
            let restaurants = documents.compactMap { doc -> Restaurant? in
                try? doc.data(as: Restaurant.self)
            }
            completion(restaurants, nil)
        }
    }

    // Fetch user favorites
    func fetchUserFavorites(completion: @escaping ([Restaurant]?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        db.collection("users").document(userId).collection("favorites").getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let documents = snapshot?.documents else {
                completion(nil, nil)
                return
            }
            let favorites = documents.compactMap { doc -> Restaurant? in
                try? doc.data(as: Restaurant.self)
            }
            completion(favorites, nil)
        }
    }

    // Fetch user reviews
    func fetchUserReviews(completion: @escaping ([Review]?, Error?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil, NSError(domain: "FirebaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
            return
        }
        db.collection("users").document(userId).collection("reviews").getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let documents = snapshot?.documents else {
                completion(nil, nil)
                return
            }
            let reviews = documents.compactMap { doc -> Review? in
                try? doc.data(as: Review.self)
            }
            completion(reviews, nil)
        }
    }

    // Fetch reviews for a restaurant
    func fetchRestaurantReviews(restaurantId: String, completion: @escaping ([Review]?, Error?) -> Void) {
        db.collection("restaurants").document(restaurantId).collection("reviews").getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let documents = snapshot?.documents else {
                completion(nil, nil)
                return
            }
            let reviews = documents.compactMap { doc -> Review? in
                try? doc.data(as: Review.self)
            }
            completion(reviews, nil)
        }
    }

    // Add review for a restaurant
    func addReview(restaurantId: String, restaurantName: String, rating: Int, comment: String, username: String) {
        guard let user = Auth.auth().currentUser else { return }

        let reviewId = UUID().uuidString
        let reviewData: [String: Any] = [
            "id": reviewId,
            "userId": user.uid,
            "restaurantId": restaurantId,
            "restaurantName": restaurantName,
            "rating": rating,
            "comment": comment,
            "date": Timestamp(date: Date()),
            "username": username
        ]

        // Save in restaurant -> reviews
        db.collection("restaurants")
            .document(restaurantId)
            .collection("reviews")
            .document(reviewId)
            .setData(reviewData)

        // Save in user -> reviews
        db.collection("users")
            .document(user.uid)
            .collection("reviews")
            .document(reviewId)
            .setData(reviewData)

        // Increment restaurant review count
        db.collection("restaurants")
            .document(restaurantId)
            .updateData([
                "reviewCount": FieldValue.increment(Int64(1))
            ])

        // Recalculate and update average rating
        let reviewsRef = db.collection("restaurants")
            .document(restaurantId)
            .collection("reviews")

        reviewsRef.getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else { return }

            let ratings = documents.compactMap { $0["rating"] as? Int }
            let average = Double(ratings.reduce(0, +)) / Double(max(ratings.count, 1))

            self.db.collection("restaurants")
                .document(restaurantId)
                .updateData([
                    "rating": average
                ])
        }
    }

    func deleteReview(restaurantId: String, reviewId: String, userId: String) {
        db.collection("restaurants")
            .document(restaurantId)
            .collection("reviews")
            .whereField("id", isEqualTo: reviewId)
            .getDocuments { (snapshot, error) in
                if let docs = snapshot?.documents {
                    for doc in docs {
                        doc.reference.delete()
                    }
                }
            }

        db.collection("users")
            .document(userId)
            .collection("reviews")
            .whereField("id", isEqualTo: reviewId)
            .getDocuments { (snapshot, error) in
                if let docs = snapshot?.documents {
                    for doc in docs {
                        doc.reference.delete()
                    }
                }
            }
    }

    func updateReview(restaurantId: String, review: Review) {
        let db = Firestore.firestore()
        guard let userId = Auth.auth().currentUser?.uid else { return }

        // Update restaurant review
        let restaurantReviewRef = db.collection("restaurants").document(restaurantId)
            .collection("reviews").document(review.id)

        restaurantReviewRef.setData([
            "rating": review.rating,
            "comment": review.comment,
            "date": Timestamp(date: Date()),
            "username": review.username ?? "Anonymous",
            "userId": userId
        ], merge: true)

        // Update user review
        let userReviewRef = db.collection("users").document(userId)
            .collection("reviews").document(review.id)

        userReviewRef.setData([
            "rating": review.rating,
            "comment": review.comment,
            "date": Timestamp(date: Date()),
            "username": review.username ?? "Anonymous",
            "restaurantId": restaurantId
        ], merge: true)
    }
}
