
///  FirebaseService.swift
///  DineHalal
/// Created by Joanne on 4/1/25.

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
}
