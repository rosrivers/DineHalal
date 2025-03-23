
///  RestaurantDetails.swift
///  Dine Halal
///  Created by Iman Ikram and Joana on 3/11/25.
///


import SwiftUI

/// View displaying the details of a restaurant, including halal certification status
struct RestaurantDetails: View {
    var restaurant: Restaurant
    @State private var verificationResult: VerificationResult?
    /// @State private var yelpData: YelpData? /// Temporarily commented out Yelp data uncomment when integrated.
    
    var body: some View {
        VStack {
            /// Display basic restaurant information
            Text(restaurant.name)
                .font(.largeTitle)
            Text(restaurant.address)
                .font(.subheadline)
            
            /// Display halal verification status
            if let verificationResult = verificationResult {
                Text(verificationResult.isVerified ? "Verified Halal" : "Not Verified")
                    .font(.headline)
                    .foregroundColor(verificationResult.isVerified ? .green : .red)
            }
            
            // Display Yelp data (to be implemented by teammate)
            // Temporarily commented out to prevent loading issues
            /*
            if let yelpData = yelpData {
                // Example: Display Yelp rating
                Text("Yelp Rating: \(yelpData.rating)/5")
                    .font(.headline)
                
                // Example: Display Yelp reviews
                ForEach(yelpData.reviews, id: \.id) { review in
                    Text(review.text)
                        .font(.subheadline)
                }
            }
            */
        }
        .onAppear {
            Task {
                await verifyRestaurant() /// Verify the restaurant when the view appears
                /// await fetchYelpData()    // Temporarily commented out Yelp data fetching
            }
        }
    }
    
    /// Function to verify the restaurant using the VerificationService
    func verifyRestaurant() async {
        let verificationService = VerificationService()
        verificationResult = await verificationService.verifyRestaurant(name: restaurant.name, address: restaurant.address)
    }
    
    /// Function to fetch Yelp data (to be implemented by teammate)
    /*
    func fetchYelpData() async {
        // Placeholder for fetching Yelp data
        // Teammate should implement API call to Yelp Fusion API and update yelpData state
        // Example:
        // let yelpService = YelpService()
        // yelpData = try await yelpService.fetchRestaurantData(name: restaurant.name, address: restaurant.address)
    }
    */
}


/// Preview for the RestaurantDetails view
struct RestaurantDetails_Previews: PreviewProvider {
    static var previews: some View {
        let sampleRestaurant = Restaurant(id: UUID(), name: "Sample Restaurant", address: "123 Sample Street")
        RestaurantDetails(restaurant: sampleRestaurant)
    }
}
