
///  Restaurant+Verification.swift
///  DineHalal
///  Created by Joanne on 4/20/25.


import Foundation
import ObjectiveC

/// Extension to add verification support to the Restaurant model
extension Restaurant {
    /// Property to store verification result
    private struct AssociatedKeys {
        static var verificationResultKey = "verificationResult"
    }
    
    var verificationResult: VerificationResult? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.verificationResultKey) as? VerificationResult
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.verificationResultKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
