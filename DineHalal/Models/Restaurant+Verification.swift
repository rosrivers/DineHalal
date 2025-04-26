
///  Restaurant+Verification.swift
///  DineHalal
///  Created by Joanne on 4/20/25.


import Foundation

// Apply the same pattern for Restaurant extensions
extension Restaurant {
    // Create a private storage for associated values
    private static var verificationResultsMap = [String: VerificationResult]()
    private static let lock = NSLock()
    
    var verificationResult: VerificationResult? {
        get {
            Restaurant.lock.lock()
            defer { Restaurant.lock.unlock() }
            return Restaurant.verificationResultsMap[self.id]
        }
        set {
            Restaurant.lock.lock()
            if let newValue = newValue {
                Restaurant.verificationResultsMap[self.id] = newValue
            } else {
                Restaurant.verificationResultsMap.removeValue(forKey: self.id)
            }
            Restaurant.lock.unlock()
        }
    }
    
    // Clean up when no longer needed - optional - still
    func clearVerificationResult() {
        Restaurant.lock.lock()
        Restaurant.verificationResultsMap.removeValue(forKey: self.id)
        Restaurant.lock.unlock()
    }
}
