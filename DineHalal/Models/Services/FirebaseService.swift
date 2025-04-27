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
    func addReview(restaurantId: String, restaurantName: String, rating: Int, comment: String) {
        guard let user = Auth.auth().currentUser else { return }
        let reviewData: [String: Any] = [
            "id": UUID().uuidString,
            "userId": user.uid,
            "restaurantId": restaurantId,
            "restaurantName": restaurantName, // Added so user reviews show restaurant name
            "rating": rating,
            "comment": comment,
            "date": Timestamp(date: Date())
        ]
        // Save in restaurant -> reviews
        db.collection("restaurants")
            .document(restaurantId)
            .collection("reviews")
            .addDocument(data: reviewData)
        // Save in user -> reviews
        db.collection("users")
            .document(user.uid)
            .collection("reviews")
            .addDocument(data: reviewData)
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
}



