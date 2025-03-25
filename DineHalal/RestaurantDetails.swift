
///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.
///
import SwiftUI


/// View displaying the details of a restaurant, including halal certification status
struct RestaurantDetails: View {
    var restaurant: Restaurant
    @State private var verificationResult: VerificationResult?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            /// Display basic restaurant information
            Text(restaurant.name)
                .font(.largeTitle)
            Text(restaurant.address)
                .font(.subheadline)
            
            /// Display coordinates
            Text("Location: \(String(format: "%.4f", restaurant.latitude)), \(String(format: "%.4f", restaurant.longitude))")
                .font(.caption)
                .foregroundColor(.gray)
            
            /// Display halal verification status
            if let verificationResult = verificationResult {
                Text(verificationResult.isVerified ? "Verified Halal" : "Not Verified")
                    .font(.headline)
                    .foregroundColor(verificationResult.isVerified ? .green : .red)
            }
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            Task {
                await verifyRestaurant()
            }
        }
    }
    
    /// Function to verify the restaurant using the VerificationService
    func verifyRestaurant() async {
        let verificationService = VerificationService()
        // Pass all required parameters from the restaurant model
        verificationResult = await verificationService.verifyRestaurant(
            //id: restaurant.id,
            name: restaurant.name,
            address: restaurant.address
        )
    }
}

/// Preview for the RestaurantDetails view
struct RestaurantDetails_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRestaurant = Restaurant(
            id: UUID(),
            name: "Sample Restaurant",
            address: "123 Sample Street",
            latitude: 37.7749,
            longitude: -122.4194
        )
        RestaurantDetails(restaurant: sampleRestaurant)
    }
}
