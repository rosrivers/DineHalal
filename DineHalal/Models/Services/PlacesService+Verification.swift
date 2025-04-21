
///  PlacesService+Verification.swift
///  DineHalal
///  Created by Joanne on 4/20/25.
///This extension adds verification capabilities to your existing PlacesService without modifying its core functionality.

import Foundation
import Combine
import SwiftUI
import ObjectiveC

// Extension to add verification support to PlacesService
extension PlacesService {
    // Add the verification service
    static var verificationServiceKey = "verificationService"
    
    var verificationService: VerificationService {
        if let existingService = objc_getAssociatedObject(self, &PlacesService.verificationServiceKey) as? VerificationService {
            return existingService
        }
        
        let newService = VerificationService()
        objc_setAssociatedObject(self, &PlacesService.verificationServiceKey, newService, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        // Subscribe to changes in verification data
        newService.objectWillChange.sink { [weak self] _ in
            self?.updateVerificationStatus()
        }
        .store(in: &cancellables)
        
        return newService
    }
    
    // Add storage for cancellables
    private static var cancellablesKey = "cancellables"
    
    private var cancellables: Set<AnyCancellable> {
        get {
            if let existing = objc_getAssociatedObject(self, &PlacesService.cancellablesKey) as? Set<AnyCancellable> {
                return existing
            }
            let new = Set<AnyCancellable>()
            objc_setAssociatedObject(self, &PlacesService.cancellablesKey, new, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return new
        }
        set {
            objc_setAssociatedObject(self, &PlacesService.cancellablesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // Update verification status for all restaurants
    func updateVerificationStatus() {
        // Instead of modifying restaurants directly, store verification results in a dictionary
        var verificationResults: [String: VerificationResult] = [:]
        
        // Verify all restaurants and store results
        for restaurant in allRestaurants {
            let result = verificationService.verifyRestaurant(restaurant)
            verificationResults[restaurant.id] = result
        }
        
        // Force UI refresh to reflect new verification data
        self.objectWillChange.send()
        
        // Store the verification results dictionary
        storeVerificationResults(verificationResults)
    }
    
    // Store verification results using associated objects
    private static var verificationResultsKey = "verificationResults"
    
    private func storeVerificationResults(_ results: [String: VerificationResult]) {
        objc_setAssociatedObject(self, &PlacesService.verificationResultsKey, results, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func getVerificationResults() -> [String: VerificationResult] {
        return objc_getAssociatedObject(self, &PlacesService.verificationResultsKey) as? [String: VerificationResult] ?? [:]
    }
    
    // Add functions to upvote and downvote
    func upvoteRestaurant(_ restaurant: Restaurant) {
        verificationService.upvoteRestaurant(restaurant)
        
        // Update verification results
        var results = getVerificationResults()
        results[restaurant.id] = verificationService.verifyRestaurant(restaurant)
        storeVerificationResults(results)
        
        self.objectWillChange.send()
    }
    
    func downvoteRestaurant(_ restaurant: Restaurant) {
        verificationService.downvoteRestaurant(restaurant)
        
        // Update verification results
        var results = getVerificationResults()
        results[restaurant.id] = verificationService.verifyRestaurant(restaurant)
        storeVerificationResults(results)
        
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
}
