
///  PlacesService+Verification.swift
///  DineHalal
///  Created by Joanne on 4/20/25.
///This extension adds verification capabilities to your existing PlacesService without modifying its core functionality.

import Foundation
import Combine
import SwiftUI
import ObjectiveC
import FirebaseFirestore
import FirebaseAuth

extension PlacesService {

    private static var verificationServiceAssociationKey = 0
    private static var cancellablesAssociationKey = 0
    private static var verificationResultsAssociationKey = 0
    
    var verificationService: VerificationService {
        if let existingService = objc_getAssociatedObject(self, &PlacesService.verificationServiceAssociationKey) as? VerificationService {
            return existingService
        }
        
        let newService = VerificationService()
        objc_setAssociatedObject(self, &PlacesService.verificationServiceAssociationKey, newService, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
 
        newService.objectWillChange.sink { [weak self] _ in
            self?.updateVerificationStatus()
        }
        .store(in: &cancellables)
        
        return newService
    }
    
    private var cancellables: Set<AnyCancellable> {
        get {
            if let existing = objc_getAssociatedObject(self, &PlacesService.cancellablesAssociationKey) as? Set<AnyCancellable> {
                return existing
            }
            let new = Set<AnyCancellable>()
            objc_setAssociatedObject(self, &PlacesService.cancellablesAssociationKey, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
        set {
            objc_setAssociatedObject(self, &PlacesService.cancellablesAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    // Store newly fetched restaurants in Firebase
    func storeRestaurantsInFirebase() {
        let db = Firestore.firestore()
        
        // Store each restaurant in Firebase
        for restaurant in allRestaurants {
            // Get the verification result
            let result = verificationService.verifyRestaurant(restaurant)
            
            // Create complete restaurant data with all fields
            var restaurantData: [String: Any] = [
                "name": restaurant.name,
                "address": restaurant.address,
                "placeId": restaurant.id,
                "latitude": restaurant.latitude,
                "longitude": restaurant.longitude,
                "rating": restaurant.rating,
                "numberOfRatings": restaurant.numberOfRatings,
                "isVerified": result.isVerified,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            // Add verification source if restaurant is verified
            if result.isVerified {
                let sourceString: String
                switch result.source {
                case .officialRegistry:
                    sourceString = "official"
                case .communityVerified:
                    sourceString = "community"
                default:
                    sourceString = "unknown"
                }
                restaurantData["verificationSource"] = sourceString
            }
            
            // Store directly in Firestore
            db.collection("restaurants").document(restaurant.id)
                .setData(restaurantData, merge: true) { error in
                    if let error = error {
                        print("Error storing restaurant in Firebase: \(error.localizedDescription)")
                    }
                }
        }
        
        print("Stored \(allRestaurants.count) restaurants in Firebase")
    }
    
    // Update verification status for all restaurants
    func updateVerificationStatus() {
        // Instead of modifying restaurants directly, store verification results in a dictionary
        var verificationResults: [String: VerificationResult] = [:]
        var verifiedRestaurants: [Restaurant] = [] // Add this line
        
        // Verify all restaurants and store results
        for restaurant in allRestaurants {
            let result = verificationService.verifyRestaurant(restaurant)
            verificationResults[restaurant.id] = result
            
            // Add this block to collect verified restaurants
            if result.isVerified {
                verifiedRestaurants.append(restaurant)
                updateFirebaseVerification(restaurant: restaurant, isVerified: true, source: result.source)
            } else {
                updateFirebaseVerification(restaurant: restaurant, isVerified: false, source: .notVerified)
            }
        }
        
        // Add this line to update the recentlyVerified array
        self.recentlyVerified = verifiedRestaurants
        
        // Force UI refresh to reflect new verification data
        self.objectWillChange.send()
        
        // Store the verification results dictionary
        storeVerificationResults(verificationResults)
    }
    // Helper to update Firebase verification status
    private func updateFirebaseVerification(restaurant: Restaurant, isVerified: Bool, source: VerificationSource) {
        var sourceString = "unknown"
        
        if source == .officialRegistry {
            sourceString = "official"
        } else if source == .communityVerified {
            sourceString = "community"
        } else {
            sourceString = "none" // For unverified restaurants
        }
        
        FirestoreUtilities.shared.updateRestaurantVerification(
            restaurantID: restaurant.id,
            isVerified: isVerified,
            source: sourceString
        ) { error in
            if let error = error {
                print("Error updating verification in Firebase: \(error.localizedDescription)")
            }
        }
    }
    
    // Store verification results using associated objects
    private func storeVerificationResults(_ results: [String: VerificationResult]) {
        objc_setAssociatedObject(self, &PlacesService.verificationResultsAssociationKey, results, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func getVerificationResults() -> [String: VerificationResult] {
        return objc_getAssociatedObject(self, &PlacesService.verificationResultsAssociationKey) as? [String: VerificationResult] ?? [:]
    }
    
    // Add functions to upvote and downvote
    func upvoteRestaurant(_ restaurant: Restaurant) {
        verificationService.upvoteRestaurant(restaurant)
        
        // Update verification results
        var results = getVerificationResults()
        results[restaurant.id] = verificationService.verifyRestaurant(restaurant)
        storeVerificationResults(results)
        
        // Record vote in Firebase - FIXED: Direct Auth access
        if let userID = Auth.auth().currentUser?.uid {
            FirestoreUtilities.shared.recordRestaurantVerificationVote(
                restaurantID: restaurant.id,
                userID: userID,
                isUpvote: true
            ) { error in
                if let error = error {
                    print("Error recording upvote: \(error.localizedDescription)")
                }
            }
        }
        
        self.objectWillChange.send()
    }
    
    func downvoteRestaurant(_ restaurant: Restaurant) {
        verificationService.downvoteRestaurant(restaurant)
        
        // Update verification results
        var results = getVerificationResults()
        results[restaurant.id] = verificationService.verifyRestaurant(restaurant)
        storeVerificationResults(results)
        
        // Record vote in Firebase - FIXED: Direct Auth access
        if let userID = Auth.auth().currentUser?.uid {
            FirestoreUtilities.shared.recordRestaurantVerificationVote(
                restaurantID: restaurant.id,
                userID: userID,
                isUpvote: false
            ) { error in
                if let error = error {
                    print("Error recording downvote: \(error.localizedDescription)")
                }
            }
        }
        
        self.objectWillChange.send()
    }
    
    // Function to find verified restaurants
    func getVerifiedRestaurants() -> [Restaurant] {
        let results = getVerificationResults()
        
        return allRestaurants.filter { restaurant in
            if let result = results[restaurant.id] {
                return result.isVerified
            }
            
            // If we don't have a cached result, verify on demand
            let result = verificationService.verifyRestaurant(restaurant)
            
            // Cache the result
            var updatedResults = getVerificationResults()
            updatedResults[restaurant.id] = result
            storeVerificationResults(updatedResults)
            
            return result.isVerified
        }
    }
    
    // Extension method to get verification result for a restaurant
    func getVerificationResult(for restaurant: Restaurant) -> VerificationResult {
        let results = getVerificationResults()
        
        if let result = results[restaurant.id] {
            return result
        }
        
        // If we don't have a cached result, verify on demand
        let result = verificationService.verifyRestaurant(restaurant)
        
        // Cache the result
        var updatedResults = getVerificationResults()
        updatedResults[restaurant.id] = result
        storeVerificationResults(updatedResults)
        
        return result
    }
    
    // Check if verification is in progress
    var isVerifying: Bool {
        return verificationService.isLoading
    }
}
