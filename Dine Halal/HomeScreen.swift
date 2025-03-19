//
//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
//

import SwiftUI

struct HomeScreen: View {
    @State private var searchText = ""
    @State private var showFilter = false  // Controls filter popup
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor") // Background color
                    .ignoresSafeArea() // Extends to edges
                VStack {
                    /// Map and App Title (to be done by Joana, actually tried map integration broke my code lol)
                    ZStack(alignment: .topTrailing) {
                        //Image("map_background") // Replace with actual MapKit
                        //.resizable()
                        // .scaledToFit()
                        
                        
                        Text("DineHalal")
                            .font(.largeTitle)
                            .bold()
                        //.padding()
                            .foregroundColor(.darkBrown)
                    }
                    
                    .frame(height: 180)
                    
                    // Search and Filter Section
                    HStack {
                        TextField("Search for halal restaurants...", text: $searchText)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        
                        Button(action: {
                            showFilter.toggle() // Show filter sheet
                        }) {
                            Label("Filter", systemImage: "slider.horizontal.3")
                                .padding()
                                .background(.mud)
                                .foregroundColor(.beige)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // "Near Me" Button
                    Button(action: {
                        // Implement location search functionality
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Near Me")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.mud)
                        .foregroundColor(.beige)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    // Recommended Restaurants
                    VStack(alignment: .leading) {
                        Text("Recommended Restaurants")
                            .font(.headline)
                            .padding(.leading)
                            .foregroundStyle(.darkBrown)
                        
                        ScrollView(.horizontal, showsIndicators: false) {  // Hardcoded for now
                            HStack {
                                RestaurantCard(name: "Oasis", rating: 4)
                                RestaurantCard(name: "Sweet & Savory", rating: 3)
                                RestaurantCard(name: "Grill House", rating: 4)
                            }
                            .padding()
                        }
                    }
                    
                    // Recently Verified Restaurants
                    VStack(alignment: .leading) {
                        Text("Recently Verified Halal Restaurants")
                            .font(.headline)
                            .padding(.leading)
                            .foregroundStyle(.darkBrown)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                RestaurantCard(name: "Spice Haven", rating: 5)
                                RestaurantCard(name: "Tandoori Flame", rating: 4)
                                RestaurantCard(name: "Mezze Magic", rating: 5)
                            }
                            .padding()
                        }
                    }
                    
                    Spacer()
                    
                    
                    
                    // Bottom Navigation Bar
                    HStack {
                        NavigationButton(icon: "house.fill", title: "Home", destination: HomeScreen())
                        NavigationButton(icon: "heart.fill", title: "Favorites", destination: UserProfile())
                        NavigationButton(icon: "plus.circle.fill", title: "Add Review", destination: Review())
                    }
                    .frame(maxWidth: .infinity) // Ensures it stretches across the screen
                    .padding(.bottom)
                    .background(.mud)
                    .foregroundColor(.beige)
                }
            }
            
            .sheet(isPresented: $showFilter) {  // Filter Sheet
                FilterView()
            }
        }
    }
    
    
    //
    
    // Filter View (Popup)
    struct FilterView: View {
        @Environment(\.presentationMode) var presentationMode // To close the sheet
        
        @State private var halalCertified = false
        @State private var userVerified = false
        @State private var thirdPartyVerified = false
        @State private var nearMe = false
        @State private var cityZip = ""
        @State private var middleEastern = false
        @State private var mediterranean = false
        @State private var southAsian = false
        @State private var american = false
        @State private var rating: Double = 3
        @State private var priceBudget = false
        @State private var priceModerate = false
        @State private var priceExpensive = false
        
        var body: some View {
            VStack {
                Text("Filter Restaurants")
                    .font(.title2)
                    .bold()
                    .padding()
                
                Form {
                    Section(header: Text("Halal Certification")) {
                        Toggle("Certified by Authority", isOn: $halalCertified) // NYC Agriculture Website
                        Toggle("User Verified", isOn: $userVerified) // Maybe?
                        Toggle("Third-Party Verified", isOn: $thirdPartyVerified) // Yelp
                    }
                    
                    Section(header: Text("Location")) {
                        Toggle("Near Me", isOn: $nearMe)
                        TextField("Enter City/Zipcode", text: $cityZip)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Section(header: Text("Cuisine")) {
                        Toggle("Middle Eastern", isOn: $middleEastern)
                        Toggle("Mediterranean", isOn: $mediterranean)
                        Toggle("South Asian", isOn: $southAsian)
                        Toggle("American", isOn: $american)
                    }
                    
                    Section(header: Text("Rating")) {
                        Slider(value: $rating, in: 1...5, step: 1)
                        Text("Min Rating: \(Int(rating)) stars")
                    }
                    
                    Section(header: Text("Price Range")) {
                        Toggle("$ (Budget)", isOn: $priceBudget)
                        Toggle("$$ (Moderate)", isOn: $priceModerate)
                        Toggle("$$$ (Expensive)", isOn: $priceExpensive)
                    }
                }
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss() // Close the filter popup
                }) {
                    Text("Apply Filters")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.mud)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
    
    
    //
    struct RestaurantCard: View {
        let name: String
        let rating: Int
        
        var body: some View {
            VStack {
                Image("food_placeholder") // Replace with actual images from Yelp
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                
                Text(name)
                    .font(.caption)
                    .bold()
                
                HStack {
                    ForEach(0..<5) { index in
                        Image(systemName: index < rating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
    
    struct NavigationButton<Destination: View>: View {
        let icon: String
        let title: String
        let destination: Destination
        
        var body: some View {
            NavigationLink(destination: destination) {
                VStack {
                    Image(systemName: icon)
                    Text(title)
                        .font(.footnote)
                }
                .padding()
            }
        }
    }
    
        struct HomeScreen_Previews: PreviewProvider {
            static var previews: some View {
                HomeScreen()
            }
        }
    
}
