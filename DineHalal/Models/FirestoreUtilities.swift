
///  FirestoreUtilities.swift
///  DineHalal
///  Created by Joanne on 4/21/25.

import FirebaseFirestore

/// Firestore utility class to handle database updates
class FirestoreUtilities {
    static let shared = FirestoreUtilities()
    private let db = Firestore.firestore()
    
    init() {
        // Configure Firestore for less verbose logging
        let settings = db.settings
        #if !DEBUG
        settings.loggingEnabled = false
        #endif
        db.settings = settings
    }
    
    /// Update Firestore's `isVerified` field for a restaurant
    func updateRestaurantVerification(restaurantID: String, isVerified: Bool, completion: @escaping (Error?) -> Void) {
        let documentRef = db.collection("restaurants").document(restaurantID)
        
        // Check if document exists first
        documentRef.getDocument { (document, error) in
            if let error = error {
                // Only log errors in debug builds
                #if DEBUG
                print("Error checking document: \(error)")
                #endif
                completion(error)
                return
            }
            
            if let document = document, document.exists {
                // Document exists, update it
                documentRef.updateData([
                    "isVerified": isVerified,
                    "lastUpdated": FieldValue.serverTimestamp()
                ]) { error in
                    completion(error)
                }
            } else {
                // Document doesn't exist, create it
                documentRef.setData([
                    "isVerified": isVerified,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastUpdated": FieldValue.serverTimestamp()
                ]) { error in
                    completion(error)
                }
            }
        }
    }
    
    /// Add a method to store restaurant verification votes
    func recordRestaurantVerificationVote(
        restaurantID: String,
        userID: String,
        isUpvote: Bool,
        completion: @escaping (Error?) -> Void
    ) {
        let restaurantRef = db.collection("restaurants").document(restaurantID)
        
        // Use a transaction for data consistency
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            // First check if the restaurant document exists
            let restaurantDoc: DocumentSnapshot
            do {
                restaurantDoc = try transaction.getDocument(restaurantRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            // Create restaurant document if it doesn't exist
            if !restaurantDoc.exists {
                transaction.setData([
                    "isVerified": false,
                    "upvotes": 0,
                    "downvotes": 0,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastUpdated": FieldValue.serverTimestamp()
                ], forDocument: restaurantRef)
            }
            
            // Record the vote
            let voteRef = restaurantRef.collection("votes").document(userID)
            
            transaction.setData([
                "isUpvote": isUpvote,
                "timestamp": FieldValue.serverTimestamp()
            ], forDocument: voteRef)
            
            // Update vote counters
            let field = isUpvote ? "upvotes" : "downvotes"
            transaction.updateData([
                field: FieldValue.increment(Int64(1)),
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: restaurantRef)
            
            return nil
        }) { (_, error) in
            completion(error)
        }
    }
}
