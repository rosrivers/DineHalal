
///  FirestoreUtilities.swift
///  DineHalal
///  Created by Joanne on 4/21/25.

import FirebaseFirestore

/// Firestore utility class to handle database updates - on firebase console
class FirestoreUtilities {
    static let shared = FirestoreUtilities()
    private let db = Firestore.firestore()
    
    /// Update Firestore's `isVerified` field for a restaurant - on console 
    func updateRestaurantVerification(restaurantID: String, isVerified: Bool, completion: @escaping (Error?) -> Void) {
        db.collection("restaurants").document(restaurantID).updateData([
            "isVerified": isVerified
        ]) { error in
            if let error = error {
                print("Error updating Firestore verification status: \(error)")
                completion(error)
            } else {
                print("Successfully updated verification status for \(restaurantID) to \(isVerified)")
                completion(nil)
            }
        }
    }
}

