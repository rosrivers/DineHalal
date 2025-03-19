
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
        let pdfData = try await downloadPDF() /// Download the PDF data
        return extractEstablishmentData(from: pdfData) /// Extract establishment data from the PDF
    }
    
    /// Function to download the PDF from the provided URL
    func downloadPDF() async throws -> Data {
        guard let url = URL(string: "https://agriculture.ny.gov/system/files/documents/2025/03/halalestablishmentregistrations.pdf") else {
            throw URLError(.badURL) /// Throw an error if the URL is invalid
        }
        let (data, _) = try await URLSession.shared.data(from: url) /// Download the PDF data
        return data
    }
    
    /// Function to extract establishment data from the PDF
    func extractEstablishmentData(from pdfData: Data) -> [HalalEstablishment] {
        var establishments: [HalalEstablishment] = []
        
        guard let pdfDocument = PDFDocument(data: pdfData) else { return establishments } /// Create a PDF document from the data
        
        /// Iterate through each page in the PDF
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            guard let pageContent = page.string else { continue }
            
            /// Process the page content to extract establishment data
            let lines = pageContent.components(separatedBy: "\n")
            for line in lines {
                /// Parse each line to create a HalalEstablishment object
                let components = line.components(separatedBy: ",")
                if components.count >= 5 {
                    let establishment = HalalEstablishment(
                        id: UUID(),
                        name: components[0].trimmingCharacters(in: .whitespaces),
                        address: components[1].trimmingCharacters(in: .whitespaces),
                        certificationType: components[2].trimmingCharacters(in: .whitespaces),
                        verificationDate: Date(), /// Parse the actual date from the components as needed
                        registrationNumber: components[4].trimmingCharacters(in: .whitespaces)
                    )
                    establishments.append(establishment)
                }
            }
        }
        
        return establishments
    }
}
