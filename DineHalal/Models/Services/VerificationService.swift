
///  VerificationService.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.
///References: Core Data - https://developer.apple.com/documentation/foundation/userdefaults
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
    
    /// Debugging properties - just for dubugging
    private var matchAttemptCount = 0
    private var successfulMatchCount = 0
    private var lastFailedMatches: [(name: String, address: String)] = []
    
    //MARK: Firestore reference - backend on console
    private lazy var db: Firestore = { ///Let Firestore be created only when it is first accessed, and not when VerificationService initializes it
        return Firestore.firestore()
    }()
    
    /// Initialize the service and load halal data from the PDF
    init() {
        loadHalalData()
        loadSavedVotes()
    }
    
    func loadHalalData() {
        isLoading = true
        
        Task {
            do {
                let pdfParserService = PDFParserService()
                let data = try await pdfParserService.downloadAndParsePDF()
                
                await MainActor.run {
                    self.halalData = data
                    self.isLoading = false
                    print("Loaded \(data.count) halal establishments from registry")
                    
                    /// Print sample data for debugging
                    self.printSampleEstablishmentData()
                    
                    // Add test establishments for testing matching
                    self.addTestEstablishments()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                    print("Error loading halal data: \(error)")
                }
            }
        }
    }
    
    /// Print sample establishment data for debugging
    private func printSampleEstablishmentData() {
        guard !halalData.isEmpty else { return }
        
        print("===== SAMPLE HALAL ESTABLISHMENTS FROM REGISTRY =====")
        for i in 0..<min(5, halalData.count) {
            let establishment = halalData[i]
            print("- Name: \"\(establishment.name)\"")
            print("  Address: \"\(establishment.address)\"")
            print("  RegNum: \(establishment.registrationNumber)")
            print("---")
        }
    }
    
    /// Print matching statistics for debugging
    func printMatchingStats() {
        print("===== HALAL VERIFICATION MATCHING STATS =====")
        print("Total restaurants checked: \(matchAttemptCount)")
        print("Successfully matched: \(successfulMatchCount) (\(successfulMatchCount > 0 ? Double(successfulMatchCount) / Double(matchAttemptCount) * 100 : 0)%)")
        
        if successfulMatchCount == 0 && !lastFailedMatches.isEmpty {
            print("=== Sample of unmatched restaurants ===")
            for restaurant in lastFailedMatches {
                print("- \"\(restaurant.name)\" at \"\(restaurant.address)\"")
            }
            
            // Print sample of establishments
            if !halalData.isEmpty {
                print("=== Sample of registry establishments ===")
                for i in 0..<min(3, halalData.count) {
                    let establishment = halalData[i]
                    print("- \"\(establishment.name)\" at \"\(establishment.address)\"")
                }
            }
        }
    }
    
    
    /// Simple direct match check
    private func directTestMatch(restaurant: Restaurant) -> HalalEstablishment? {
        // Try direct name match first
        return halalData.first(where: {
            $0.name.lowercased() == restaurant.name.lowercased() ||
            ($0.name.contains(restaurant.name) || restaurant.name.contains($0.name))
        })
    }
    
    /// MARK: Enhanced function to update verification status in Firestore
    private func updateFirestoreVerification(restaurantID: String, isVerified: Bool, source: VerificationSource, confidence: MatchConfidence? = nil) {
        var data: [String: Any] = ["isVerified": isVerified]
        
        /// Add source information - proof
        data["verificationSource"] = source == .officialRegistry ? "official" : "community"
        
        // Add confidence level if available (for official verifications)
        if let confidence = confidence {
            var confidenceString = "low"
            switch confidence {
                case .high: confidenceString = "high"
                case .medium: confidenceString = "medium"
                case .low: confidenceString = "low"
            }
            data["verificationConfidence"] = confidenceString
        }
        
        db.collection("restaurants").document(restaurantID).updateData(data) { error in
            if let error = error {
                print("Error updating Firestore verification: \(error)")
            } else {
                var confidenceString = "N/A"
                if let confidence = confidence {
                    switch confidence {
                        case .high: confidenceString = "high"
                        case .medium: confidenceString = "medium"
                        case .low: confidenceString = "low"
                    }
                }
                print("Successfully updated verification status for \(restaurantID) to \(isVerified), source: \(source), confidence: \(confidenceString)")
            }
        }
    }
    
    /// Function to verify if a restaurant is halal certified
    func verifyRestaurant(_ restaurant: Restaurant) -> VerificationResult {
        matchAttemptCount += 1
        
        /// First try direct match for test establishments
        if let directMatch = directTestMatch(restaurant: restaurant) {
            successfulMatchCount += 1
            print("DIRECT MATCH FOUND: \(restaurant.name) matches \(directMatch.name)")
            
            //MARK: Update Firestore when direct match is found
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .officialRegistry, confidence: .high)
            
            return VerificationResult(
                isVerified: true,
                establishment: directMatch,
                source: .officialRegistry,
                matchConfidence: .high
            )
        }
        
        // Find best match using new algorithm - confidence algo 2x
        let (bestMatch, confidence, reason) = findBestMatch(for: restaurant)
        
        // If we have a match
        if let establishment = bestMatch, confidence >= 0.15 { // We detect matches at 0.15, but don't necessarily verify them
            // Determine the confidence level
            let matchConfidence: MatchConfidence
            if confidence >= 0.5 {
                matchConfidence = .high
            } else if confidence >= 0.3 {
                matchConfidence = .medium
            } else {
                matchConfidence = .low
            }
            
            // IMPORTANT CHANGE: Only consider medium and high confidence as officially verified
            if confidence >= 0.3 { // Only medium or high confidence counts as verified
                successfulMatchCount += 1
                
                print("MATCH FOUND: \(restaurant.name) matches \(establishment.name) with \(Int(confidence * 100))% confidence")
                print("Reason: \(reason)")
                
                //MARK: Update Firestore when a good match is found
                updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .officialRegistry, confidence: matchConfidence)
                
                return VerificationResult(
                    isVerified: true,
                    establishment: establishment,
                    source: .officialRegistry,
                    matchConfidence: matchConfidence
                )
            } else {
                // Low confidence matches are NOT considered verified
                print("LOW CONFIDENCE MATCH: \(restaurant.name) has a weak match with \(establishment.name) (\(Int(confidence * 100))%). Leaving to community verification.")
                
                // Store as a failed match for debugging
                if lastFailedMatches.count < 5 {
                    lastFailedMatches.append((name: restaurant.name, address: restaurant.vicinity))
                }
            }
        } else {
            // No match found at all
            // Store failed match info for debugging
            if lastFailedMatches.count < 5 {
                lastFailedMatches.append((name: restaurant.name, address: restaurant.vicinity))
            }
        }
        
        // Check community verification
        if let voteData = restaurantVotes[restaurant.id], voteData.isConsideredVerified() {
            //MARK: Update Firestore when community verification threshold is met
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: true, source: .communityVerified)
            
            return VerificationResult(
                isVerified: true,
                establishment: nil,
                source: .communityVerified,
                voteData: voteData
            )
        }
        
        // Print debug info after checking a batch of restaurants
        if matchAttemptCount % 10 == 0 {
            printMatchingStats()
        }
        
        return VerificationResult(
            isVerified: false,
            establishment: nil,
            source: .notVerified,
            voteData: restaurantVotes[restaurant.id]
        )
    }
    
    /// Function to match a restaurant with the halal data (exact match)
    private func matchEstablishment(name: String, address: String) -> HalalEstablishment? {
        return halalData.first { establishment in
            isSimilarName(establishment.name, name) &&
            isSimilarAddress(establishment.address, address)
        }
    }
    
    /// Function to match just by name with fuzzy matching
    private func fuzzyMatchByName(name: String) -> HalalEstablishment? {
        return halalData.first { establishment in
            isSimilarName(establishment.name, name, threshold: 0.15) // SUPER OPTIMIZED: Consistent threshold
        }
    }
    
    /// Enhanced name similarity check - make thresholds strict to make sure name matches exactly??? maybe just maybe
    private func isSimilarName(_ name1: String, _ name2: String, threshold: Double = 0.15) -> Bool { // SUPER OPTIMIZED: Consistent threshold
        // Clean and normalize names
        let cleanName1 = normalizeEstablishmentName(name1)
        let cleanName2 = normalizeEstablishmentName(name2)
        
        // Exact match check
        if cleanName1 == cleanName2 {
            return true
        }
        
        // Contains check - more relaxed
        if cleanName1.contains(cleanName2) || cleanName2.contains(cleanName1) {
            return true
        }
        
        /// SUPER OPTIMIZED: Special case for borough matches
        let boroughs = ["brooklyn", "queens", "bronx", "manhattan", "staten island",]
        for borough in boroughs {
            if cleanName1.contains(borough) && cleanName2.contains(borough) {
                if (cleanName1.contains(cleanName2.replacingOccurrences(of: borough, with: "").trimmingCharacters(in: .whitespacesAndNewlines)) ||
                    cleanName2.contains(cleanName1.replacingOccurrences(of: borough, with: "").trimmingCharacters(in: .whitespacesAndNewlines))) {
                    return true
                }
            }
        }
        
        /// Word overlap check - this handles things like word order differences
        let words1 = Set(cleanName1.components(separatedBy: " "))
        let words2 = Set(cleanName2.components(separatedBy: " "))
        
        /// SUPER OPTIMIZED: First-word matching for halal restaurants if not common term
        let commonTerms = ["halal", "restaurant", "food", "kitchen", "grill", "cafe", "deli", "the", "and", "of", "inc", "corp", "llc"]
        
        if let firstWord1 = words1.first?.lowercased(),
           let firstWord2 = words2.first?.lowercased(),
           !commonTerms.contains(firstWord1) &&
           !commonTerms.contains(firstWord2) &&
           firstWord1 == firstWord2 {
            return true
        }
        
        /// OPTIMIZED: Special case for single-word restaurant names
        if (words1.count == 1 || words2.count == 1) &&
           calculateSimilarity(cleanName1, cleanName2) > 0.5 {
            return true
        }
        
        // Word overlap check
        let commonWords = words1.intersection(words2)
        
        // Filter out common words like "halal", "restaurant", etc.
        let significantCommonWords = commonWords.filter { !commonTerms.contains($0.lowercased()) }
        
        if significantCommonWords.count >= 1 {
            return true
        }
        
        // Levenshtein similarity as last resort
        let similarity = calculateSimilarity(cleanName1, cleanName2)
        return similarity >= threshold
    }
    
    /// Enhanced address similarity check
    private func isSimilarAddress(_ address1: String, _ address2: String) -> Bool {
        let cleanAddress1 = normalizeAddress(address1)
        let cleanAddress2 = normalizeAddress(address2)
        
        // Exact match
        if cleanAddress1 == cleanAddress2 {
            return true
        }
        
        // Extract street numbers and names
        if let street1 = extractStreetInfo(from: cleanAddress1),
           let street2 = extractStreetInfo(from: cleanAddress2) {
            if street1 == street2 {
                return true
            }
        }
        
        // Check for street number match (most reliable part of address)
        let number1 = extractStreetNumber(from: cleanAddress1)
        let number2 = extractStreetNumber(from: cleanAddress2)
        
        if let num1 = number1, let num2 = number2, num1 == num2 {
            // Same building number, now check if street names have overlap
            let streetName1 = extractStreetName(from: cleanAddress1)
            let streetName2 = extractStreetName(from: cleanAddress2)
            
            if let street1 = streetName1, let street2 = streetName2 {
                // Check if one street name contains the other
                if street1.contains(street2) || street2.contains(street1) {
                    return true
                }
                
                // Check if they share significant words
                let words1 = Set(street1.components(separatedBy: " "))
                let words2 = Set(street2.components(separatedBy: " "))
                let commonWords = words1.intersection(words2)
                
                // If there's at least one significant matching word (not "st", "ave", etc.)
                let insignificantWords = ["st", "street", "ave", "avenue", "rd", "road", "blvd", "boulevard"]
                let significantCommonWords = commonWords.filter { !insignificantWords.contains($0) }
                
                if significantCommonWords.count > 0 {
                    return true
                }
            }
        }
        
        // OPTIMIZED: Check for ZIP code match as a strong signal on its own
        let zip1 = extractZipCode(from: cleanAddress1)
        let zip2 = extractZipCode(from: cleanAddress2)
        if let z1 = zip1, let z2 = zip2, z1 == z2 {
            return true
        }
        
        // SUPER OPTIMIZED: Check for borough match
        let boroughs = ["brooklyn", "queens", "bronx", "manhattan", "staten island"]
        for borough in boroughs {
            if cleanAddress1.contains(borough) && cleanAddress2.contains(borough) {
                // If same borough and addresses have some similarity
                if calculateSimilarity(cleanAddress1, cleanAddress2) > 0.3 {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Normalize establishment name
    private func normalizeEstablishmentName(_ name: String) -> String {
        var result = name.lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // SUPER OPTIMIZED: Remove location indicators that might differ
        result = result
            .replacingOccurrences(of: " ny", with: "")
            .replacingOccurrences(of: " nyc", with: "")
            .replacingOccurrences(of: " new york", with: "")
            
        // Remove common company suffixes
        let suffixes = [" inc", " corp", " llc", " co", " company", " corporation", " restaurant", " kitchen", " halal", " food"]
        for suffix in suffixes {
            if result.hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }
        
        // Remove common words that don't help with matching
        let commonWords = [" the ", " and ", " of ", " a ", " an "]
        for word in commonWords {
            result = result.replacingOccurrences(of: word, with: " ")
        }
        
        // Clean up extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Normalize address
    private func normalizeAddress(_ address: String) -> String {
        var result = address.lowercased()
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
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
            
            // Also handle cases like "W.125th" or "W 125th"
            if result.contains("\(full) ") {
                result = result.replacingOccurrences(of: "\(full) ", with: "\(abbr) ")
            }
        }
        
        // Clean up extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract just the street number
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
    
    /// Extract just the street name without the number
    private func extractStreetName(from address: String) -> String? {
        // Skip the number at the beginning
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
    
    /// Helper function to extract street information from an address
    private func extractStreetInfo(from address: String) -> String? {
        // Match pattern like "123 Main St" - get the whole thing
        let pattern = "\\d+\\s+[\\w\\s]+(st|ave|rd|dr|ln|blvd|pl|ct)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
           let match = regex.firstMatch(in: address, options: [], range: NSRange(location: 0, length: address.count)),
           let range = Range(match.range, in: address) {
            return String(address[range])
        }
        return nil
    }
    
    /// Calculate simple string similarity (Levenshtein distance based)
    private func calculateSimilarity(_ s1: String, _ s2: String) -> Double {
        let empty = [Int](repeating: 0, count: s2.count + 1)
        var last = [Int](0...s2.count)
        
        for (i, c1) in s1.enumerated() {
            var current = [i + 1] + empty
            for (j, c2) in s2.enumerated() {
                current[j + 1] = c1 == c2 ? last[j] : min(last[j], last[j + 1], current[j]) + 1
            }
            last = current
        }
        
        let maxLength = max(s1.count, s2.count)
        guard maxLength > 0 else { return 1.0 }
        
        let distance = Double(last[s2.count])
        return 1.0 - (distance / Double(maxLength))
    }
    
    /// Extract ZIP code from address
    private func extractZipCode(from address: String) -> String? {
        // Pattern for US ZIP codes (5 digits, optionally followed by hyphen and 4 digits)
        let pattern = "\\b\\d{5}(?:-\\d{4})?\\b"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: address, range: NSRange(address.startIndex..., in: address)),
           let range = Range(match.range, in: address) {
            return String(address[range])
        }
        return nil
    }
    
    /// Address-specific similarity calculation
    private func calculateAddressSimilarity(_ address1: String, _ address2: String) -> Double {
        // Handle nil or empty addresses
        guard !address1.isEmpty && !address2.isEmpty else {
            return 0.0
        }
        
        // Extract street numbers
        let number1 = extractStreetNumber(from: address1)
        let number2 = extractStreetNumber(from: address2)
        
        // Extract street names
        let street1 = extractStreetName(from: address1)?.lowercased()
        let street2 = extractStreetName(from: address2)?.lowercased()
        
        // Extract zip codes
        let zip1 = extractZipCode(from: address1)
        let zip2 = extractZipCode(from: address2)
        
        var score = 0.0
        
        // Street number match is a strong signal
        if let num1 = number1, let num2 = number2, num1 == num2 {
            score += 0.6
        }
        
        // Street name match
        if let s1 = street1, let s2 = street2 {
            if s1 == s2 {
                score += 0.3
            } else if s1.contains(s2) || s2.contains(s1) {
                score += 0.2
            } else {
                // Check word overlap
                let words1 = Set(s1.split(separator: " ").map { String($0) })
                let words2 = Set(s2.split(separator: " ").map { String($0) })
                let commonWords = words1.intersection(words2)
                
                if !commonWords.isEmpty {
                    score += 0.1 * Double(commonWords.count)
                }
            }
        }
        
        // Zip code match
        if let z1 = zip1, let z2 = zip2, z1 == z2 {
            score += 0.3 // SUPER OPTIMIZED: Increased weight for ZIP match
        }
        
        // SUPER OPTIMIZED: Check for same borough
        let boroughs = ["brooklyn", "queens", "bronx", "manhattan", "staten island"]
        for borough in boroughs {
            if address1.contains(borough) && address2.contains(borough) {
                score += 0.1
                break
            }
        }
        
        return min(1.0, score)
    }
    
    /// Extract keywords from a name (removing common words)
    private func extractKeywords(from text: String) -> Set<String> {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let commonWords = ["the", "and", "of", "a", "an", "in", "on", "at", "&", "inc", "llc", "corp"]
        
        return Set(words.filter { word in
            !commonWords.contains(word) && word.count > 2
        })
    }
    
    
    /// Enhanced matching with better thresholds for both name and address - Subject to change for testing.
    func findBestMatch(for restaurant: Restaurant) -> (HalalEstablishment?, Double, String) {
        let restaurantName = normalizeEstablishmentName(restaurant.name)
        let restaurantAddr = normalizeAddress(restaurant.vicinity)
        
        print("Looking for match: \"\(restaurantName)\" at \"\(restaurantAddr)\"")
        
        var bestMatch: HalalEstablishment? = nil
        var bestScore = 0.0
        var matchReason = ""
        
        for establishment in halalData {
            let establishmentName = normalizeEstablishmentName(establishment.name)
            let establishmentAddr = normalizeAddress(establishment.address)
            
            // Calculate name similarity
            let nameSimilarity = calculateSimilarity(restaurantName, establishmentName)
            
            // Calculate address similarity
            let addressSimilarity = calculateAddressSimilarity(restaurantAddr, establishmentAddr)
            
            // Require BOTH name and address to meet minimum thresholds
            if nameSimilarity < 0.3 || addressSimilarity < 0.2 {
                continue // Skip this match if either falls below minimum
            }
          
            
            // SUPER OPTIMIZED: More weight on name matching (85/20)-make address similarity more strictier
            let score = (nameSimilarity * 0.85) + (addressSimilarity * 0.2)
            
            // If this is our best match so far
            if score > bestScore && score > 0.15 { // SUPER OPTIMIZED: Consistent threshold
                bestScore = score
                bestMatch = establishment
                
                let namePercent = Int(nameSimilarity * 100)
                let addrPercent = Int(addressSimilarity * 100)
                matchReason = "Name match: \(namePercent)%, Address match: \(addrPercent)%"
                
                // Debug high-scoring matches
                if score > 0.5 { // SUPER OPTIMIZED: Lowered from 0.6
                    print("Potential match:")
                    print("  Registry: \"\(establishment.name)\" at \"\(establishment.address)\"")
                    print("  Google: \"\(restaurant.name)\" at \"\(restaurant.vicinity)\"")
                    print("  Score: \(Int(score * 100))%, Reason: \(matchReason)")
                }
            }
        }
        
        return (bestMatch, bestScore, matchReason)
    }
    
    /// Add test establishments for debugging
    func addTestEstablishments() {
        let testEstablishments = [
            HalalEstablishment(
                id: UUID(),
                name: "Halal Eats",
                address: "89-25 Queens Blvd, Queens",  // Exact format as from Google
                certificationType: "Halal Certified",
                verificationDate: Date(),
                registrationNumber: "NY-TEST-1"
            ),
            HalalEstablishment(
                id: UUID(),
                name: "Sharif's Famous",  // Exact name as returned by Google
                address: "W 31st St &, Broadway, New York",  // Exact format with comma placement
                certificationType: "Halal Certified",
                verificationDate: Date(),
                registrationNumber: "NY-TEST-2"
            ),
            HalalEstablishment(
                id: UUID(),
                name: "ZAMZAM HALAL - زمزم حلال",  // Exact with Arabic characters
                address: "102 Saratoga Ave, Brooklyn",
                certificationType: "Halal Certified",
                verificationDate: Date(),
                registrationNumber: "NY-TEST-3"
            ),
            HalalEstablishment(
                id: UUID(),
                name: "Halal Bros Grill Queens Village",
                address: "218-74 Hempstead Ave, Queens Village",
                certificationType: "Halal Certified",
                verificationDate: Date(),
                registrationNumber: "NY-TEST-4"
            )
        ]
        
        // Add to existing data
        halalData.append(contentsOf: testEstablishments)
        
        print("Added \(testEstablishments.count) exact-match test establishments")
    }
    
    // MARK: - Community Verification Methods
    
    /// Add an upvote for a restaurant
    func upvoteRestaurant(_ restaurant: Restaurant) {
        var currentVotes = restaurantVotes[restaurant.id] ?? VoteData()
        currentVotes.upvotes += 1
        restaurantVotes[restaurant.id] = currentVotes
        saveVotes()
        
        // ADDED: Check if the restaurant now meets verification threshold
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
        
        // ADDED: Check if verification status needs to be revised
        if let oldVotes = restaurantVotes[restaurant.id],
           oldVotes.isConsideredVerified() && !currentVotes.isConsideredVerified() {
            updateFirestoreVerification(restaurantID: restaurant.id, isVerified: false, source: .communityVerified)
        }
    }
    
    /// Save votes to UserDefaults - Userdefaults: a class that allows you to store small amounts of data persistently across app launches. eg: user preferences.
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
    let matchConfidence: MatchConfidence
    let voteData: VoteData?
    
    init(isVerified: Bool, establishment: HalalEstablishment?, source: VerificationSource, matchConfidence: MatchConfidence = .high, voteData: VoteData? = nil) {
        self.isVerified = isVerified
        self.establishment = establishment
        self.source = source
        self.matchConfidence = matchConfidence
        self.voteData = voteData
    }
}

/// Source of verification
enum VerificationSource {
    case officialRegistry   /// Verified from the PDF
    case communityVerified  /// Verified through user votes
    case notVerified        /// Not verified
}

/// Confidence level of the match
enum MatchConfidence {
    case high    /// Direct match for pdf
    case medium  /// Name match but address differences
    case low     /// Partial match - needed tweeking
}
