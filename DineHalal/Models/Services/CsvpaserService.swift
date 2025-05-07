
//  CsvpaserService.swift
//  DineHalal
//
//  Created by Joanne on 5/2/25.


import Foundation
import PDFKit

/// Service responsible for handling CSV data for Halal Establishments
class CSVParserService {
    // Static cache to store loaded establishments
    private static var cachedEstablishments: [HalalEstablishment]?
    
    /// Load establishments from CSV, converting from PDF if necessary
    func loadHalalEstablishmentsFromCSV() -> [HalalEstablishment] {
        // First check if we already have cached establishments
        if let cached = CSVParserService.cachedEstablishments {
            return cached
        }
        
        // Try loading from bundled CSV file first
        if let establishments = loadFromLocalCSV() {
            // Cache the loaded data
            CSVParserService.cachedEstablishments = establishments
            return establishments
        }
        
        // If CSV not found, try automatic conversion from PDF
        if let establishments = convertPDFtoCSVAndLoad() {
            // Cache the loaded data
            CSVParserService.cachedEstablishments = establishments
            return establishments
        }
        
        // Cache the empty array to prevent repeated attempts
        CSVParserService.cachedEstablishments = []
        return []
    }
    
    /// Load from local CSV file (check Documents directory too)
    private func loadFromLocalCSV() -> [HalalEstablishment]? {
        // Try loading from app bundle first
        if let path = Bundle.main.path(forResource: "halalestablishmentregistrations", ofType: "csv"),
           let content = try? String(contentsOfFile: path, encoding: .utf8),
           !content.isEmpty {
            return parseCSVContent(content)
        }
        
        // Then try Documents directory
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let csvURL = documentsDirectory.appendingPathComponent("halalestablishmentregistrations.csv")
            
            if FileManager.default.fileExists(atPath: csvURL.path),
               let content = try? String(contentsOf: csvURL, encoding: .utf8),
               !content.isEmpty {
                let establishments = parseCSVContent(content)
                return establishments.isEmpty ? nil : establishments
            }
        }
        
        return nil
    }
    
    /// Automatically convert PDF to CSV and load the data
    private func convertPDFtoCSVAndLoad() -> [HalalEstablishment]? {
        // Try to locate the PDF file
        guard let pdfPath = Bundle.main.path(forResource: "halalestablishmentregistrations", ofType: "pdf"),
              let pdfDocument = PDFDocument(url: URL(fileURLWithPath: pdfPath)) else {
            
            // Try to find PDF in Documents directory
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let pdfURL = documentsDirectory.appendingPathComponent("halalestablishmentregistrations.pdf")
                if FileManager.default.fileExists(atPath: pdfURL.path),
                   let pdfDocument = PDFDocument(url: pdfURL) {
                    return processAndConvertPDF(pdfDocument)
                }
            }
            
            return nil
        }
        
        return processAndConvertPDF(pdfDocument)
    }
    
    /// Process the PDF document and convert to CSV
    private func processAndConvertPDF(_ pdfDocument: PDFDocument) -> [HalalEstablishment]? {
        // Extract text and convert to CSV format
        var csvContent = "name,address,city,state,zip,registration_number\n"
        var allEstablishments: [HalalEstablishment] = []
        
        // Process every single page without limitation
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex),
                  let pageContent = page.string else {
                continue
            }
            
            // Extract establishments using multiple methods
            let mainEstablishments = extractEstablishmentsUsingMainPattern(pageContent)
            let alternativeEstablishments = extractEstablishmentsUsingAlternativePattern(pageContent)
            let extractedEstablishments = mainEstablishments + alternativeEstablishments
            
            // Add to our list
            allEstablishments.append(contentsOf: extractedEstablishments)
            
            // Convert each establishment to CSV line
            for est in extractedEstablishments {
                // Parse address components
                let addressComponents = parseAddress(est.address)
                let street = addressComponents.street
                let city = addressComponents.city
                let state = addressComponents.state
                let zip = addressComponents.zip
                
                // Escape fields properly for CSV
                let csvLine = "\"\(escapeCSVField(est.name))\",\"\(escapeCSVField(street))\",\"\(escapeCSVField(city))\",\"\(escapeCSVField(state))\",\"\(escapeCSVField(zip))\",\"\(escapeCSVField(est.registrationNumber))\"\n"
                csvContent += csvLine
            }
        }
        
        // get more pages from the pdf if needed
        if allEstablishments.count < 100 {
            let desperation = extractAllPossibleEstablishments(pdfDocument)
            if desperation.count > allEstablishments.count {
                allEstablishments = desperation
            }
        }
        
        // Save the CSV file in Documents directory for future use
        do {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let csvURL = documentsDirectory.appendingPathComponent("halalestablishmentregistrations.csv")
                try csvContent.write(to: csvURL, atomically: true, encoding: .utf8)
            }
        } catch {
            // Skip error printing
        }
        
        // Return the extracted establishments
        return allEstablishments.isEmpty ? nil : allEstablishments
    }
    
    /// Extract establishments using the main pattern
    private func extractEstablishmentsUsingMainPattern(_ content: String) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        // Extract name
        if let nameRange = content.range(of: "Name of Establishment:") {
            let afterName = content[nameRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            if let endOfLine = afterName.firstIndex(where: { $0.isNewline }) {
                let name = String(afterName[..<endOfLine]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Extract address (look for various patterns)
                var streetAddress = ""
                var city = ""
                var state = ""
                var zip = ""
                
                if let addressRange = content.range(of: "Street Address of the Establishment:") {
                    let afterAddress = content[addressRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let endOfLine = afterAddress.firstIndex(where: { $0.isNewline }) {
                        streetAddress = String(afterAddress[..<endOfLine]).trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Look for city, state, zip
                        if let cityRange = content.range(of: "City") {
                            let afterCity = content[cityRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                            if let stateIndex = afterCity.range(of: "State") {
                                city = String(afterCity[..<stateIndex.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                let afterState = afterCity[stateIndex.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                                if let zipIndex = afterState.range(of: "Zip") {
                                    state = String(afterState[..<zipIndex.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                                    
                                    let afterZip = afterState[zipIndex.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                                    if let endOfZip = afterZip.firstIndex(where: { $0.isNewline }) {
                                        zip = String(afterZip[..<endOfZip]).trimmingCharacters(in: .whitespacesAndNewlines)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // If we have valid data, create establishment
                if !name.isEmpty && !streetAddress.isEmpty {
                    // Construct full address
                    let fullAddress = "\(streetAddress), \(city), \(state) \(zip)"
                    
                    // Try to extract registration number
                    var regNumber = ""
                    if let regRange = content.range(of: "Registration Number:") {
                        let afterReg = content[regRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                        if let endOfReg = afterReg.firstIndex(where: { $0.isNewline }) {
                            regNumber = String(afterReg[..<endOfReg]).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    
                    // Create establishment
                    let establishment = HalalEstablishment(
                        id: UUID(),
                        name: name,
                        address: fullAddress,
                        certificationType: "Halal Certified",
                        verificationDate: Date(),
                        registrationNumber: regNumber.isEmpty ? "NY-REG-\(UUID().uuidString.prefix(8))" : regNumber
                    )
                    
                    establishments.append(establishment)
                }
            }
        }
        
        return establishments
    }
    
    /// Extract establishments
    private func extractEstablishmentsUsingAlternativePattern(_ content: String) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        // Pattern groups for various PDF formats
        let namePatterns = [
            "Business Name:\\s*([^\\n]+)",
            "Establishment Name:\\s*([^\\n]+)",
            "Restaurant Name:\\s*([^\\n]+)",
            "Name:\\s*([^\\n]+)",
            "Food Establishment:\\s*([^\\n]+)"
        ]
        
        let addressPatterns = [
            "Address:\\s*([^\\n]+)",
            "Business Address:\\s*([^\\n]+)",
            "Location:\\s*([^\\n]+)",
            "Street Address:\\s*([^\\n]+)"
        ]
        
        // Try each name pattern
        for namePattern in namePatterns {
            guard let nameRegex = try? NSRegularExpression(pattern: namePattern, options: [.caseInsensitive]) else { continue }
            
            let nameMatches = nameRegex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count))
            
            for nameMatch in nameMatches {
                guard nameMatch.numberOfRanges > 1,
                      let nameRange = Range(nameMatch.range(at: 1), in: content) else { continue }
                
                let name = String(content[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty names
                if name.isEmpty { continue }
                
                // Try to find a matching address
                var address = ""
                for addressPattern in addressPatterns {
                    guard let addressRegex = try? NSRegularExpression(pattern: addressPattern, options: [.caseInsensitive]) else { continue }
                    
                    if let addressMatch = addressRegex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)),
                       addressMatch.numberOfRanges > 1,
                       let addressRange = Range(addressMatch.range(at: 1), in: content) {
                        
                        address = String(content[addressRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                        break // Use the first address we find
                    }
                }
                
                // If no address found, try another approach - look for text near the name
                if address.isEmpty {
                    // Start looking after the name
                    let nameEndIndex = content.index(nameRange.upperBound, offsetBy: min(100, content.count - nameRange.upperBound.utf16Offset(in: content)))
                    let textAfterName = String(content[nameRange.upperBound..<nameEndIndex])
                    
                    // Look for something that looks like an address
                    if let streetNumberMatch = textAfterName.range(of: #"\b\d+\s+\w+"#, options: .regularExpression) {
                        // Get text from the street number to the next line break or 100 chars
                        let addressStart = streetNumberMatch.lowerBound
                        let potentialAddress = String(textAfterName[addressStart...])
                        
                        if let lineBreak = potentialAddress.firstIndex(where: { $0.isNewline }) {
                            address = String(potentialAddress[..<lineBreak]).trimmingCharacters(in: .whitespacesAndNewlines)
                        } else {
                            address = potentialAddress.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                }
                
                // If we have both name and address, create an establishment
                if !name.isEmpty && !address.isEmpty {
                    let establishment = HalalEstablishment(
                        id: UUID(),
                        name: name,
                        address: address,
                        certificationType: "Halal Certified",
                        verificationDate: Date(),
                        registrationNumber: "NY-REG-\(UUID().uuidString.prefix(8))"
                    )
                    
                    establishments.append(establishment)
                }
            }
        }
        
        return establishments
    }
    
    /// Extract all possible establishments with a different approach
    private func extractAllPossibleEstablishments(_ pdfDocument: PDFDocument) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        // Get text from entire document
        var allText = ""
        for i in 0..<pdfDocument.pageCount {
            if let page = pdfDocument.page(at: i), let text = page.string {
                allText.append(text)
                allText.append("\n--- PAGE BREAK ---\n")
            }
        }
        
        // Look for Registration Forms header followed by establishment info
        let formSections = allText.components(separatedBy: "HALAL FOOD ESTABLISHMENT REGISTRATION")
        
        for (index, section) in formSections.enumerated() {
            // Skip the first split (it's before the first header)
            if index == 0 { continue }
            
            // Each section should be a registration form - try to extract establishment
            var name = ""
            var address = ""
            
            // Extract name with flexible patterns
            let namePatterns = [
                "Name of Establishment:\\s*([^\\n]+)",
                "Business Name:\\s*([^\\n]+)",
                "Establishment Name:\\s*([^\\n]+)",
                "Name:\\s*([^\\n]+)"
            ]
            
            for pattern in namePatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    if let match = regex.firstMatch(in: section, range: NSRange(section.startIndex..., in: section)),
                       match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: section) {
                        name = String(section[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
            
            // Extract address with flexible patterns
            let addressPatterns = [
                "Street Address of the Establishment:\\s*([^\\n]+)",
                "Address:\\s*([^\\n]+)",
                "Location:\\s*([^\\n]+)"
            ]
            
            for pattern in addressPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    if let match = regex.firstMatch(in: section, range: NSRange(section.startIndex..., in: section)),
                       match.numberOfRanges > 1,
                       let range = Range(match.range(at: 1), in: section) {
                        address = String(section[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        break
                    }
                }
            }
            
            // If we still don't have an address, look for any line with a street number
            if address.isEmpty {
                let lines = section.components(separatedBy: .newlines)
                for line in lines {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Look for lines that start with numbers (potential addresses)
                    if trimmed.range(of: "^\\d+\\s+", options: .regularExpression) != nil {
                        address = trimmed
                        break
                    }
                }
            }
            
            // If we successfully extracted both name and address
            if !name.isEmpty && !address.isEmpty {
                let establishment = HalalEstablishment(
                    id: UUID(),
                    name: name,
                    address: address,
                    certificationType: "Halal Certified",
                    verificationDate: Date(),
                    registrationNumber: "NY-REG-\(index)"
                )
                
                establishments.append(establishment)
            }
        }
        
        return establishments
    }
    
    /// Parse CSV content into HalalEstablishment array
    private func parseCSVContent(_ content: String) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        let rows = content.components(separatedBy: .newlines)
        
        // Skip header row if it exists
        let startIndex = rows.first?.lowercased().contains("name") == true ? 1 : 0
        
        for i in startIndex..<rows.count {
            let row = rows[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip empty rows
            if row.isEmpty {
                continue
            }
            
            // Handle CSV escaping (quoted fields that might contain commas)
            let columns = parseCSVRow(row)
            
            // Ensure we have enough columns (name and address at minimum)
            if columns.count >= 2 {
                let name = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Address can be either a single field or separate fields for address, city, state, zip
                var fullAddress: String
                
                if columns.count >= 5 {
                    // We have separate address components
                    let street = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let city = columns[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let state = columns[3].trimmingCharacters(in: .whitespacesAndNewlines)
                    let zip = columns[4].trimmingCharacters(in: .whitespacesAndNewlines)
                    fullAddress = "\(street), \(city), \(state) \(zip)"
                } else {
                    // We have a full address in a single field
                    fullAddress = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                }
                
                // Get registration number if available
                let regNumber = columns.count > 5 ? columns[5] : "NY-REG-\(UUID().uuidString.prefix(8))"
                
                // Create establishment object and add to array
                let establishment = HalalEstablishment(
                    id: UUID(),
                    name: name,
                    address: fullAddress,
                    certificationType: "Halal Certified",
                    verificationDate: Date(),
                    registrationNumber: regNumber
                )
                
                establishments.append(establishment)
            }
        }
        
        return establishments
    }
    
    /// Parse a single CSV row handling quoted values properly
    private func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentColumn = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                columns.append(currentColumn)
                currentColumn = ""
            } else {
                currentColumn.append(char)
            }
        }
        
        // Add the final column
        columns.append(currentColumn)
        
        return columns
    }
    
    /// Parse address into components
    private func parseAddress(_ address: String) -> (street: String, city: String, state: String, zip: String) {
        // Default values
        var street = address
        var city = "New York"
        var state = "NY"
        var zip = ""
        
        // Try to extract ZIP code
        if let zipMatch = try? NSRegularExpression(pattern: "\\b(\\d{5})\\b").firstMatch(in: address, range: NSRange(location: 0, length: address.count)),
           let zipRange = Range(zipMatch.range(at: 1), in: address) {
            zip = String(address[zipRange])
        }
        
        // Try to extract state
        let statePattern = "\\b(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY)\\b"
        if let stateMatch = try? NSRegularExpression(pattern: statePattern).firstMatch(in: address, range: NSRange(location: 0, length: address.count)),
           let stateRange = Range(stateMatch.range, in: address) {
            state = String(address[stateRange])
            
            // Try to extract city (text before state)
            let beforeState = address.prefix(upTo: stateRange.lowerBound)
            if let lastComma = beforeState.lastIndex(of: ",") {
                let cityStart = beforeState.index(after: lastComma)
                city = String(beforeState[cityStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
                street = String(beforeState.prefix(upTo: lastComma)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return (street, city, state, zip)
    }
    
    /// Escape a field for CSV format
    private func escapeCSVField(_ field: String) -> String {
        return field.replacingOccurrences(of: "\"", with: "\"\"")
    }
    
    /// Delete existing CSV file (call this to force regeneration)
    func deleteExistingCSVFile() {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let csvURL = documentsDirectory.appendingPathComponent("halalestablishmentregistrations.csv")
            
            do {
                try FileManager.default.removeItem(at: csvURL)
                
                // Clear the cache
                CSVParserService.cachedEstablishments = nil
            } catch {
                // No need to print error
            }
        }
    }
    
    /// Normalize text for matching comparison
    private func normalizeTextForMatching(_ text: String) -> String {
        var result = text.lowercased()
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "\"", with: "")
        
        // Remove common words that don't help with matching
        let wordsToRemove = [" restaurant", " food", " inc", " corp", " llc", " co", " company", " corporation"]
        for word in wordsToRemove {
            result = result.replacingOccurrences(of: word, with: "")
        }
        
        // Remove all extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
