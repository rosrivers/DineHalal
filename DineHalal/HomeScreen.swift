//
//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct Restaurantt: Identifiable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
}

struct HomeScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var showFilter = false  // Controls filter popup
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060), // Default to New York City
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        @State private var annotations: [MKPointAnnotation] = []
  
    var body: some View {
        NavigationStack {
            ZStack {
                Color("AccentColor") // Background color
                    .ignoresSafeArea() // Extends to edges
                VStack {
                    // Map and App Title
                    ZStack(alignment: .topTrailing) {
                        MapView(region: $region, annotations: annotations)
                            .frame(height: UIScreen.main.bounds.height / 3)
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
                        findNearbyRestaurants()
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
                    .sheet(isPresented: $showFilter) {  // Filter Sheet
                                    FilterView()
                                }
                }
            }
        }
    }
    
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

    
    func findNearbyRestaurants() {
        guard let userLocation = locationManager.manager.location?.coordinate
        else {
            print("Failed to get user location")
            return
        }
        
        let apiKey = "GOOGE MAPS API KEY"
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(userLocation.latitude),\(userLocation.longitude)&radius=1500&type=restaurant&key=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            print("Failed to create URL")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]] {
                    let nearbyRestaurants = results.compactMap { result -> Restaurantt? in
                        guard let name = result["name"] as? String,
                              let geometry = result["geometry"] as? [String: Any],
                              let location = geometry["location"] as? [String: Any],
                              let latitude = location["lat"] as? Double,
                              let longitude = location["lng"] as? Double else { return nil }
                        return Restaurantt(name: name, latitude: latitude, longitude: longitude)
                    }
                    
                    DispatchQueue.main.async {
                        self.annotations = nearbyRestaurants.map { restaurant in
                            let annotation = MKPointAnnotation()
                            annotation.title = restaurant.name
                            annotation.coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
                            return annotation
                        }
                    }
                }
            } catch {
                print("Failed to parse JSON: \(error)")
            }
        }.resume()
    }
}


