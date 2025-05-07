///  VerificationService.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.
///References: Core Data https://developer.apple.com/documentation/foundation/userdefaults

import Foundation
import Combine
import FirebaseFirestore
import Firebase

/// Service responsible for verifying if a restaurant is halal certified
class VerificationService: ObservableObject {
    @Published private(set) var halalData: [HalalEstablishment] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    /// Community verification data
    @Published private(set) var restaurantVotes: [String: VoteData] = [:]
    
    /// Track if data is loaded and processing state
    private var isPDFLoaded = false
    private var isPDFLoading = false
    
    /// CSV Parser Service
    private let csvParserService = CSVParserService()
    
    //MARK: Firestore reference - backend on console
    private lazy var db: Firestore = {
        return Firestore.firestore()
    }()
    
    /// Initialize the service and load halal data from CSV
    init() {
        loadSavedVotes()
        // Start loading CSV data -
        Task {
           await loadHalalDataAsync()
        }
    }
    
    /// Regular non-blocking function to start CSV loading
    func loadHalalData() {
        Task {
            await loadHalalDataAsync()
        }
    }
    
    // Async function loads and waits for CSV data
    @MainActor
    func loadHalalDataAsync() async {
        // Prevent concurrent loading attempts
        if isLoading || isPDFLoaded { return }
        
        isLoading = true
        isPDFLoading = true
        
        // Load from CSV - PDF converted to Csv file
        let data = csvParserService.loadHalalEstablishmentsFromCSV()
        
        if !data.isEmpty {
            self.halalData = data
            self.isPDFLoaded = true
        } else {
            // If CSV fails, fall back to sample data -  not used might delete
            //self.halalData = csvParserService.loadSampleData()
            self.isPDFLoaded = !self.halalData.isEmpty
        }
        
        isPDFLoading = false
        isLoading = false
    }
    
    /// Wait for data to be available - with timeout
    @MainActor
    func ensurePDFDataLoaded() async -> Bool {
        if isPDFLoaded && !halalData.isEmpty {
            return true
        }
        
        if !isPDFLoading {
            await loadHalalDataAsync()
        } else {
            // Wait a reasonable time for the data to load
            let maxWaitTimeSeconds = 10.0
            let startTime = Date()
            
            while isPDFLoading && Date().timeIntervalSince(startTime) < maxWaitTimeSeconds {
                try? await Task.sleep(nanoseconds: 500_000_000) // Wait 0.5 seconds
            }
        }
        
        // Return true if we have data, false otherwise
        return isPDFLoaded && !halalData.isEmpty
    }
    
    /// Update verification status in Firestore
    private func updateFirestoreVerification(restaurantID: String, isVerified: Bool, source: VerificationSource) {
        var data: [String: Any] = ["isVerified": isVerified]
        
        /// Add source information
        if source == .officialRegistry {
            data["verificationSource"] = "official"
        } else if source == .communityVerified {
            data["verificationSource"] = "community"
        } else {
            // For unverified restaurants
            data["verificationSource"] = FieldValue.delete()
        }
        
        // Add timestamp - not entirely important. meh
        data["lastUpdated"] = FieldValue.serverTimestamp()
        
        // Get document reference
        let documentRef = db.collection("restaurants").document(restaurantID)
        
        // Use setData with merge instead of updateData
        documentRef.setData(data, merge: true) { [weak self] error in
            if error == nil {
                // Only try to delete the confidence field if we're setting to unverified
                if source == .notVerified {
                    documentRef.updateData(["verificationConfidence": FieldValue.delete()]) { error in
                        
                    }
                }
            }
        }
    }
    
    /// Function to verify if a restaurant is halal certified
    func verifyRestaurant(_ restaurant: Restaurant) -> VerificationResult {
        // If data is not yet loaded, load
        if !isPDFLoaded {
            Task {
                let dataLoaded = await ensurePDFDataLoaded()
                if dataLoaded {
                    // This will update the Firebase status when data loads, but we can't
                    // immediately update the UI since we've already returned - get back to this later.
                    _ = findExactMatch(for: restaurant)
                }
            }
            
            // Return community verification if available, otherwise not verified
            if let voteData = restaurantVotes[restaurant.id], voteData.isConsideredVerified() {
                return VerificationResult(
                    isVerified: true,
                    establishment: nil,
                    source: .communityVerified,
                    voteData: voteData
                )
            }
            
            return VerificationResult(
                isVerified: false,
                establishment: nil,
                source: .notVerified,
                voteData: restaurantVotes[restaurant.id]
            )
        }
        
        // If data is loaded, check for official match
        if let match = findExactMatch(for: restaurant) {
            // Update Firestore when direct match is found
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .officialRegistry)
            
            return VerificationResult(
                isVerified: true,
                establishment: match,
                source: .officialRegistry
            )
        }
        
        // Check community verification
        if let voteData = restaurantVotes[restaurant.id], voteData.isConsideredVerified() {
            // Update Firestore when community verification threshold is met
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .communityVerified)
            
            return VerificationResult(
                isVerified: true,
                establishment: nil,
                source: .communityVerified,
                voteData: voteData
            )
        }
        
        return VerificationResult(
            isVerified: false,
            establishment: nil,
            source: .notVerified,
            voteData: restaurantVotes[restaurant.id]
        )
    }
    
    /// Find exact match according to both strict nameing and address creteria
    func findExactMatch(for restaurant: Restaurant) -> HalalEstablishment? {
        // IMPORTANT: Early return if data is empty to prevent the infinite loop
        if halalData.isEmpty {
            return nil
        }
        
        // Get restaurant details
        let restaurantName = restaurant.name
        let restaurantAddress = restaurant.address.isEmpty ? restaurant.vicinity : restaurant.address
        
        // 1: check strict name and address matching
        for establishment in halalData {
            // Check name match
            if areNamesEqual(restaurantName, establishment.name) {
                // Check address match
                if areAddressesRelated(restaurantAddress, establishment.address) {
                    return establishment
                }
            }
        }
        
        //similar name match with strong address matching
        for establishment in halalData {
            if areNamesSimilar(restaurantName, establishment.name) {
                if areAddressesStreetMatch(restaurantAddress, establishment.address) {
                    return establishment
                }
            }
        }
        
        // name/adress/zip code match
        for establishment in halalData {
            // Check if names share significant keywords
            if shareSignificantKeywords(restaurantName, establishment.name) {
                // With keyword matching, require zip code match for safety
                if haveMatchingZipCodes(restaurantAddress, establishment.address) {
                    return establishment
                }
            }
        }
        
        return nil
    }
    
    
    // MARK: - Verify Places API Results Directly
    
    /// Verify an array of restaurants from Places API directly
    func verifyPlacesAPIRestaurants(_ restaurants: [Restaurant]) -> [String: VerificationResult] {
        var results: [String: VerificationResult] = [:]
        
        // Make sure data is loaded first
        if !isPDFLoaded {
            Task {
                let _ = await ensurePDFDataLoaded()
                // Update the results when data becomes available
                let updatedResults = self.verifyPlacesAPIRestaurants(restaurants)
                // Post a notification that results are ready - not needed might delete
                NotificationCenter.default.post(name: Notification.Name("HalalVerificationResultsUpdated"),
                                              object: nil,
                                              userInfo: ["results": updatedResults])
            }
            
            // Return empty results for now
            return results
        }
        
        // Data is loaded, check each restaurant
        for restaurant in restaurants {
            // Check for official match
            if let match = findExactMatch(for: restaurant) {
                results[restaurant.id] = VerificationResult(
                    isVerified: true,
                    establishment: match,
                    source: .officialRegistry
                )
                
                // Also update Firestore
                updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .officialRegistry)
            }
            // Check for community verification
            else if let voteData = restaurantVotes[restaurant.id], voteData.isConsideredVerified() {
                results[restaurant.id] = VerificationResult(
                    isVerified: true,
                    establishment: nil,
                    source: .communityVerified,
                    voteData: voteData
                )
            }
            // Not verified
            else {
                results[restaurant.id] = VerificationResult(
                    isVerified: false,
                    establishment: nil,
                    source: .notVerified,
                    voteData: restaurantVotes[restaurant.id]
                )
            }
        }
        
        return results
    }
    
    // MARK
    
    /// Check if two names are effectively equal
    private func areNamesEqual(_ name1: String, _ name2: String) -> Bool {
        let n1 = normalizeText(name1)
        let n2 = normalizeText(name2)
        
        return n1 == n2 || n1.contains(n2) || n2.contains(n1)
    }
    
    /// Check if two names are similar
    private func areNamesSimilar(_ name1: String, _ name2: String) -> Bool {
        let n1 = normalizeText(name1)
        let n2 = normalizeText(name2)
        
        // Direct match
        if n1 == n2 || n1.contains(n2) || n2.contains(n1) {
            return true
        }
        
        // Remove "The" prefix and check again
        let n1NoThe = n1.hasPrefix("the ") ? String(n1.dropFirst(4)) : n1
        let n2NoThe = n2.hasPrefix("the ") ? String(n2.dropFirst(4)) : n2
        
        if n1NoThe == n2NoThe {
            return true
        }
        
        // Check if one name is the beginning of the other
        if n1.count > 5 && n2.count > 5 {
            if n1.hasPrefix(String(n2.prefix(5))) || n2.hasPrefix(String(n1.prefix(5))) {
                return true
            }
        }
        
        return false
    }
    
    /// Check if two names share significant keywords
    private func shareSignificantKeywords(_ name1: String, _ name2: String) -> Bool {
        let n1 = normalizeText(name1)
        let n2 = normalizeText(name2)
        
        let words1 = n1.split(separator: " ")
        let words2 = n2.split(separator: " ")
        
        // Ignore common words
        let commonWords = ["the", "and", "of", "in", "halal", "food", "restaurant"]
        
        // Look for significant keywords (longer than 3 letters and not in common words)
        let keywords1 = words1.filter { $0.count > 3 && !commonWords.contains(String($0)) }
        let keywords2 = words2.filter { $0.count > 3 && !commonWords.contains(String($0)) }
        
        // Check if they share any significant keywords
        for word1 in keywords1 {
            for word2 in keywords2 {
                if word1 == word2 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if addresses are related (more flexible)
    private func areAddressesRelated(_ addr1: String, _ addr2: String) -> Bool {
        // Try different matching strategies
        
        // 1. Standard address comparison
        if normalizeAddress(addr1).contains(normalizeAddress(addr2)) ||
           normalizeAddress(addr2).contains(normalizeAddress(addr1)) {
            return true
        }
        
        let components1 = extractAddressComponents(from: addr1)
        let components2 = extractAddressComponents(from: addr2)
        
        // ZIP code matching
        if let zip1 = components1.zip, let zip2 = components2.zip, zip1 == zip2 {
            return true
        }
        
        // Street number + street name matching
        if let num1 = components1.number, let num2 = components2.number,
           let street1 = components1.street, let street2 = components2.street,
           num1 == num2 && (street1.contains(street2) || street2.contains(street1)) {
            return true
        }
        
        return false
    }
    
    /// Check if addresses share the same street (number + name)
    private func areAddressesStreetMatch(_ addr1: String, _ addr2: String) -> Bool {
        let components1 = extractAddressComponents(from: addr1)
        let components2 = extractAddressComponents(from: addr2)
        
        if let num1 = components1.number, let num2 = components2.number, num1 == num2 {
            // Street number match is a strong indicator - to be officially verified.
            return true
        }
        
        return false
    }
    
    /// Check if addresses have matching ZIP codes
    private func haveMatchingZipCodes(_ addr1: String, _ addr2: String) -> Bool {
        let components1 = extractAddressComponents(from: addr1)
        let components2 = extractAddressComponents(from: addr2)
        
        if let zip1 = components1.zip, let zip2 = components2.zip, zip1 == zip2 {
            return true
        }
        
        return false
    }
    
    /// Normalize text by removing extra spaces and standardizing capitalization
    private func normalizeText(_ text: String) -> String {
        let normalized = text.lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
        
        // Remove common company suffixes
        let suffixes = [" inc", " corp", " llc", " co", " company", " corporation"]
        var result = normalized
        for suffix in suffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }
        
        // Remove extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Normalize address specifically
    private func normalizeAddress(_ address: String) -> String {
        var result = address.lowercased()
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: "")
        
        // Standardize street types
        let streetTypes: [(full: String, abbr: String)] = [
            ("street", "st"),
            ("avenue", "ave"),
            ("boulevard", "blvd"),
            ("road", "rd"),
            ("place", "pl"),
            ("drive", "dr"),
            ("lane", "ln"),
            ("court", "ct")
        ]
        
        for (full, abbr) in streetTypes {
            result = result.replacingOccurrences(of: " \(full)", with: " \(abbr)")
        }
        
        // Standardize directions
        let directions: [(full: String, abbr: String)] = [
            ("north", "n"),
            ("south", "s"),
            ("east", "e"),
            ("west", "w"),
            ("northeast", "ne"),
            ("northwest", "nw"),
            ("southeast", "se"),
            ("southwest", "sw")
        ]
        
        for (full, abbr) in directions {
            result = result.replacingOccurrences(of: " \(full) ", with: " \(abbr) ")
            result = result.replacingOccurrences(of: "\(full) ", with: "\(abbr) ")
        }
        
        // Handle New York variations
        result = result.replacingOccurrences(of: " ny ", with: " new york ")
        result = result.replacingOccurrences(of: " nyc", with: " new york")
        if result.hasSuffix(" ny") {
            result = result.replacingOccurrences(of: " ny", with: " new york")
        }
        
        // Remove extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract address components for structured comparison
    private func extractAddressComponents(from address: String) -> (number: String?, street: String?, zip: String?) {
        // Extract street number
        let streetNumber = extractStreetNumber(from: address)
        
        // Extract street name
        let streetName = extractStreetName(from: address)
        
        // Extract ZIP code
        let zipCode = extractZipCode(from: address)
        
        return (streetNumber, streetName, zipCode)
    }
    
    /// Compare address components with more flexibility
    private func doAddressComponentsMatch(_ components1: (number: String?, street: String?, zip: String?),
                                         _ components2: (number: String?, street: String?, zip: String?)) -> Bool {
        // If both have ZIP codes and they match, consider it a match
        if let zip1 = components1.zip, let zip2 = components2.zip, zip1 == zip2 {
            return true
        }
        
        // If both have street numbers and they match, it's a strong indicator
        let hasStreetNumberMatch = components1.number != nil && components2.number != nil && components1.number == components2.number
        
        // If both have street names, check if they match or if one contains the other
        var hasStreetMatch = false
        if let street1 = components1.street, let street2 = components2.street {
            hasStreetMatch = street1 == street2 || street1.contains(street2) || street2.contains(street1)
        }
        
        // For a match, require street number match or street name match
        return hasStreetNumberMatch || hasStreetMatch
    }
    
    /// Extract street number
    private func extractStreetNumber(from address: String) -> String? {
        let pattern = "^\\d+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: address.count)
            if let match = regex.firstMatch(in: address, range: range),
               let range = Range(match.range, in: address) {
                return String(address[range])
            }
        }
        return nil
    }
    
    /// Extract street name
    private func extractStreetName(from address: String) -> String? {
        if let regex = try? NSRegularExpression(pattern: "^\\d+\\s+(.+?)(?:,|$)") {
            let range = NSRange(location: 0, length: address.count)
            if let match = regex.firstMatch(in: address, range: range),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: address) {
                return String(address[range])
            }
        }
        return nil
    }
    
    /// Extract ZIP code
    private func extractZipCode(from address: String) -> String? {
        let pattern = "\\b\\d{5}(?:-\\d{4})?\\b" // US ZIP code pattern
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: address, options: [], range: NSRange(location: 0, length: address.count)),
           let range = Range(match.range, in: address) {
            return String(address[range])
        }
        return nil
    }
    
    
    
    // MARK: - Community Verification Methods
    
    /// Add an upvote for a restaurant
    func upvoteRestaurant(_ restaurant: Restaurant) {
        var currentVotes = restaurantVotes[restaurant.id] ?? VoteData()
        currentVotes.upvotes += 1
        restaurantVotes[restaurant.id] = currentVotes
        saveVotes()
        
        // Check if the restaurant now meets verification threshold
        if currentVotes.isConsideredVerified() {
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .communityVerified)
        }
    }
    
    /// Add a downvote for a restaurant
    func downvoteRestaurant(_ restaurant: Restaurant) {
        var currentVotes = restaurantVotes[restaurant.id] ?? VoteData()
        currentVotes.downvotes += 1
        restaurantVotes[restaurant.id] = currentVotes
        saveVotes()
        
        // Check if verification status needs to be revised
        if let oldVotes = restaurantVotes[restaurant.id],
           oldVotes.isConsideredVerified() && !currentVotes.isConsideredVerified() {
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: false, source: .notVerified)
        }
    }
    
    /// Save votes to UserDefaults
    private func saveVotes() {
        let encodedData = try? JSONEncoder().encode(restaurantVotes)
        UserDefaults.standard.set(encodedData, forKey: "restaurantHalalVotes")
    }
    
    /// Load saved votes from UserDefaults
    private func loadSavedVotes() {
        guard let savedData = UserDefaults.standard.data(forKey: "restaurantHalalVotes"),
              let decodedVotes = try? JSONDecoder().decode([String: VoteData].self, from: savedData) else {
            return
        }
        restaurantVotes = decodedVotes
    }
}


/// Data structure for storing votes
struct VoteData: Codable {
    var upvotes: Int = 0
    var downvotes: Int = 0
    
    func isConsideredVerified() -> Bool {
        /// Stricter verification: Require at least 5 votes total and 75% upvotes
        let totalVotes = upvotes + downvotes
        return totalVotes >= 5 && Double(upvotes) / Double(totalVotes) >= 0.75
    }
}

/// Result of the verification process
struct VerificationResult {
    let isVerified: Bool
    let establishment: HalalEstablishment?
    let source: VerificationSource
    let voteData: VoteData?
    
    init(isVerified: Bool, establishment: HalalEstablishment?, source: VerificationSource, voteData: VoteData? = nil) {
        self.isVerified = isVerified
        self.establishment = establishment
        self.source = source
        self.voteData = voteData
    }
}

/// Source of verification
enum VerificationSource {
    case officialRegistry   /// Verified from the official registry
    case communityVerified  /// Verified through user votes
    case notVerified        /// Not verified
}
