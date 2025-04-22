
///  PDFParserService.swift
///  Dine Halal
///  Created by Joanne on 3/19/25.
///

import Foundation
import PDFKit

/// Service responsible for downloading and parsing the Halal Establishment PDF
class PDFParserService {
    
    /// Function to download and parse the PDF, returning an array of HalalEstablishment objects
    func downloadAndParsePDF() async throws -> [HalalEstablishment] {
        let pdfData = try await downloadPDF()
        return extractEstablishmentData(from: pdfData)
    }
    
    /// Function to download the PDF from the provided URL
    func downloadPDF() async throws -> Data {
        /// Try to load from local file first
        if let localPath = Bundle.main.path(forResource: "halalestablishmentregistrations", ofType: "pdf"),
           let localData = try? Data(contentsOf: URL(fileURLWithPath: localPath)) {
            print("Using local PDF file")
            return localData
        }
        
        /// Fall back to remote URL if local file not found
        guard let url = URL(string: "https://agriculture.ny.gov/system/files/documents/2025/03/halalestablishmentregistrations.pdf") else {
            throw URLError(.badURL)
        }
        
        print("Downloading PDF from URL")
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    func extractEstablishmentData(from pdfData: Data) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        guard let pdfDocument = PDFDocument(data: pdfData) else {
            print("Failed to create PDF document")
            return establishments
        }
        
        print("Processing PDF with \(pdfDocument.pageCount) pages")
        
        // Process each page in the PDF
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            guard let pageContent = page.string else { continue }
            
            // Look for form headers to identify establishment records
            if pageContent.contains("HALAL REGISTRATION FORM") ||
               pageContent.contains("Name of Establishment:") {
                
                // Extract establishments from this page
                let pageEstablishments = extractEstablishmentsFromFormPage(pageContent)
                establishments.append(contentsOf: pageEstablishments)
                
                if !pageEstablishments.isEmpty {
                    print("Found \(pageEstablishments.count) establishment(s) on page \(pageIndex + 1)")
                }
            }
        }
        
        print("Extracted \(establishments.count) establishments from PDF")
        return establishments
    }
    
    /// Try to extract establishments from a page containing registration forms
    private func extractEstablishmentsFromFormPage(_ pageContent: String) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        // First try the exact form format extraction (based on the screenshot)
        if let establishment = extractFormStructuredEstablishment(pageContent) {
            establishments.append(establishment)
            return establishments
        }
        
        // Fallback to alternative extraction methods
        if let establishment = extractEstablishmentFromPage(pageContent) {
            establishments.append(establishment)
        }
        
        if establishments.isEmpty {
            if let establishment = extractEstablishmentWithRegex(pageContent) {
                establishments.append(establishment)
            }
        }
        
        return establishments
    }
    
    /// Extract establishment data from the exact form format shown in the screenshot
    private func extractFormStructuredEstablishment(_ pageContent: String) -> HalalEstablishment? {
        // Pattern to match the exact form structure from screenshot
        let namePattern = "Name of Establishment:\\s*([^\\n]+)"
        let addressPattern = "Street Address of the Establishment:\\s*([^\\n]+)"
        let cityStatePattern = "City\\s+([^\\s]+)\\s+State\\s+([^\\s]+)\\s+Zip\\s+([^\\s]+)"
        let phonePattern = "Phone Number of Establishment(?:[^:]*):(?:\\s*\\(Optional\\))?\\s*([^\\n]+)"
        
        // Extract name
        var name: String? = nil
        if let regex = try? NSRegularExpression(pattern: namePattern),
           let match = regex.firstMatch(in: pageContent, range: NSRange(pageContent.startIndex..., in: pageContent)),
           match.numberOfRanges > 1,
           let nameRange = Range(match.range(at: 1), in: pageContent) {
            name = String(pageContent[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract address
        var streetAddress: String? = nil
        if let regex = try? NSRegularExpression(pattern: addressPattern),
           let match = regex.firstMatch(in: pageContent, range: NSRange(pageContent.startIndex..., in: pageContent)),
           match.numberOfRanges > 1,
           let addressRange = Range(match.range(at: 1), in: pageContent) {
            streetAddress = String(pageContent[addressRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Extract city, state, zip
        var city: String? = nil
        var state: String? = nil
        var zip: String? = nil
        
        if let regex = try? NSRegularExpression(pattern: cityStatePattern),
           let match = regex.firstMatch(in: pageContent, range: NSRange(pageContent.startIndex..., in: pageContent)),
           match.numberOfRanges > 3 {
            if let cityRange = Range(match.range(at: 1), in: pageContent) {
                city = String(pageContent[cityRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let stateRange = Range(match.range(at: 2), in: pageContent) {
                state = String(pageContent[stateRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            if let zipRange = Range(match.range(at: 3), in: pageContent) {
                zip = String(pageContent[zipRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Extract phone number
        var phone: String? = nil
        if let regex = try? NSRegularExpression(pattern: phonePattern),
           let match = regex.firstMatch(in: pageContent, range: NSRange(pageContent.startIndex..., in: pageContent)),
           match.numberOfRanges > 1,
           let phoneRange = Range(match.range(at: 1), in: pageContent) {
            phone = String(pageContent[phoneRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // If we found a name, construct the establishment
        guard let name = name, !name.isEmpty else {
            return nil
        }
        
        // Construct full address
        var fullAddress = streetAddress ?? ""
        
        if let city = city {
            if !fullAddress.isEmpty { fullAddress += ", " }
            fullAddress += city
        }
        
        if let state = state {
            if !fullAddress.isEmpty { fullAddress += ", " }
            fullAddress += state
        }
        
        if let zip = zip {
            if !fullAddress.isEmpty { fullAddress += " " }
            fullAddress += zip
        }
        
        // If address is empty, try to extract from the text
        if fullAddress.isEmpty {
            fullAddress = extractAddressFromText(pageContent) ?? "New York"
        }
        
        let regNumber = "NY-\(UUID().uuidString.prefix(8))"
        
        return HalalEstablishment(
            id: UUID(),
            name: name,
            address: fullAddress,
            certificationType: "Halal Certified",
            verificationDate: Date(),
            registrationNumber: regNumber
        )
    }
    
    /// IMPROVED: More flexible extraction using multiple patterns
    private func extractEstablishmentFromPage(_ pageContent: String) -> HalalEstablishment? {
        let lines = pageContent.components(separatedBy: .newlines)
        
        // Variables to store extracted information
        var name: String?
        var streetAddress: String?
        var city: String?
        var state: String?
        var zip: String?
        var regNumber: String?
        
        // First look for a name field
        for (index, line) in lines.enumerated() {
            // Try different name patterns
            let namePatterns = [
                "Name of Establishment:",
                "Establishment Name:",
                "Establishment:",
                "Business Name:"
            ]
            
            for pattern in namePatterns {
                if line.contains(pattern) {
                    name = extractValue(from: line, after: pattern)
                    
                    // If name is empty, try the next line (in case it's on a separate line)
                    if name?.isEmpty ?? true, index + 1 < lines.count {
                        name = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    if !(name?.isEmpty ?? true) {
                        break
                    }
                }
            }
            
            if !(name?.isEmpty ?? true) {
                break
            }
        }
        
        // Now look for an address field
        for (index, line) in lines.enumerated() {
            let addressPatterns = [
                "Street Address of the Establishment:",
                "Street Address:",
                "Address:",
                "Business Address:"
            ]
            
            for pattern in addressPatterns {
                if line.contains(pattern) {
                    streetAddress = extractValue(from: line, after: pattern)
                    
                    // If address is empty, try the next line
                    if streetAddress?.isEmpty ?? true, index + 1 < lines.count {
                        streetAddress = lines[index + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    if !(streetAddress?.isEmpty ?? true) {
                        break
                    }
                }
            }
            
            if !(streetAddress?.isEmpty ?? true) {
                break
            }
        }
        
        // Try to find city, state, zip
        for line in lines {
            // City, State, Zip
            if line.contains("City") && line.contains("State") && line.contains("Zip") {
                // Extract city
                if let cityRange = line.range(of: "City") {
                    let afterCity = String(line[cityRange.upperBound...])
                    if let stateRange = afterCity.range(of: "State") {
                        city = String(afterCity[..<stateRange.lowerBound])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                // Extract state
                if let stateRange = line.range(of: "State") {
                    let afterState = String(line[stateRange.upperBound...])
                    if let zipRange = afterState.range(of: "Zip") {
                        state = String(afterState[..<zipRange.lowerBound])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }
                
                // Extract zip
                if let zipRange = line.range(of: "Zip") {
                    zip = String(line[zipRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Look for registration number
        for line in lines {
            if line.contains("Registration") && line.contains("Number") {
                if let regRange = line.range(of: "Number") {
                    regNumber = String(line[regRange.upperBound...])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // If essential information is missing, return nil
        guard let name = name, !name.isEmpty else {
            return nil
        }
        
        // For address, even if parts are missing, try to construct what we can
        var fullAddress = streetAddress ?? ""
        if let city = city, !city.isEmpty {
            if !fullAddress.isEmpty {
                fullAddress += ", "
            }
            fullAddress += city
        }
        if let state = state, !state.isEmpty {
            if !fullAddress.isEmpty && !fullAddress.hasSuffix(",") {
                fullAddress += ", "
            }
            fullAddress += state
        }
        if let zip = zip, !zip.isEmpty {
            if !fullAddress.isEmpty {
                fullAddress += " "
            }
            fullAddress += zip
        }
        
        // If we couldn't extract an address at all, check if the full text contains
        // any address-like patterns and use that
        if fullAddress.isEmpty {
            fullAddress = extractAddressFromText(pageContent) ?? "New York"
        }
        
        // Create and return the establishment
        return HalalEstablishment(
            id: UUID(),
            name: name,
            address: fullAddress,
            certificationType: "Halal Certified",
            verificationDate: Date(),
            registrationNumber: regNumber ?? "NY-REG"
        )
    }
    
    /// Extract address using regex pattern matching
    private func extractAddressFromText(_ text: String) -> String? {
        // Look for patterns like street numbers followed by street names
        let patterns = [
            "\\d+\\s+[A-Za-z\\s]+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Place|Pl|Lane|Ln|Drive|Dr)",
            "\\d+-\\d+\\s+[A-Za-z\\s]+(Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Place|Pl|Lane|Ln|Drive|Dr)",
            "\\d+\\s+[A-Za-z\\s]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Place|Pl|Lane|Ln|Drive|Dr)[,\\s]+(?:[A-Za-z\\s]+)[,\\s]+(?:NY|New York)[\\s]+(?:\\d{5})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
               let range = Range(match.range, in: text) {
                
                // Try to extract more complete address
                let addressStart = text[range.lowerBound...]
                let endIndex = addressStart.index(addressStart.startIndex, offsetBy: min(100, addressStart.count))
                let addressSection = String(addressStart[..<endIndex])
                
                // Try to find the end of the address (usually ends with ZIP code)
                if let zipMatch = try? NSRegularExpression(pattern: "\\b\\d{5}\\b").firstMatch(in: addressSection, options: [], range: NSRange(location: 0, length: addressSection.count)),
                   let zipRange = Range(zipMatch.range, in: addressSection) {
                    
                    let endOffset = zipRange.upperBound.utf16Offset(in: addressSection)
                    let extractedText = String(addressSection.prefix(endOffset))
                    return extractedText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // If no ZIP code found, just return the matched street
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
    
    /// Alternative extraction method using regular expressions
    private func extractEstablishmentWithRegex(_ pageContent: String) -> HalalEstablishment? {
        // Try to find name pattern
        var name: String?
        var address: String?
        
        // Try to extract name with more flexible patterns
        let namePatterns = [
            "Name[\\s:]*([^\n]+)",
            "Establishment[\\s:]*([^\n]+)",
            "Business Name[\\s:]*([^\n]+)",
            "HALAL REGISTRATION FORM[\\s\\S]*?Name[^:]*:[\\s]*([^\n]+)",
            "([^\\s]+(?:\\s+[^\\s]+){1,5})\\s*(?:LLC|INC|CORP|RESTAURANT)"
        ]
        
        for pattern in namePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: pageContent, options: [], range: NSRange(location: 0, length: pageContent.count)),
               match.numberOfRanges > 1,
               let range = Range(match.range(at: 1), in: pageContent) {
                
                name = String(pageContent[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Extract address with flexible patterns
        let addressPatterns = [
            "Address[\\s:]*([^\n]+)",
            "Street Address[\\s:]*([^\n]+)",
            "\\b(\\d+[\\w\\s-]+(?:Street|St|Avenue|Ave|Road|Rd|Boulevard|Blvd|Place|Pl|Lane|Ln|Drive|Dr)[,\\s]+(?:[A-Za-z\\s]+)[,\\s]+(?:[A-Z]{2})[\\s]+(?:\\d{5}))",
        ]
        
        for pattern in addressPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: pageContent, options: [], range: NSRange(location: 0, length: pageContent.count)),
               let matchRange = Range(match.range(at: match.numberOfRanges > 1 ? 1 : 0), in: pageContent) {
                
                address = String(pageContent[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        
        // Default to NY if we can't extract a proper address
        if address == nil {
            address = extractAddressFromText(pageContent) ?? "New York"
        }
        
        /// If we found a name, create an establishment
        if let name = name, !name.isEmpty {
            return HalalEstablishment(
                id: UUID(),
                name: name,
                address: address ?? "New York",
                certificationType: "Halal Certified",
                verificationDate: Date(),
                registrationNumber: "NY-REG-AUTO"
            )
        }
        
        return nil
    }
    
    private func extractValue(from line: String, after label: String) -> String? {
        guard let range = line.range(of: label) else { return nil }
        return String(line[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // Helper function to find ZIP codes in text
    private func findZipCodeInText(_ text: String) -> String? {
        let pattern = "\\b\\d{5}(?:-\\d{4})?\\b" // US ZIP code pattern
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(location: 0, length: text.count)),
           let range = Range(match.range, in: text) {
            return String(text[range])
        }
        return nil
    }
}
