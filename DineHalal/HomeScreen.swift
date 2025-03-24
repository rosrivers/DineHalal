//
//  HomeScreen.swift
//  Dine Halal
//
//  Created by Iman Ikram on 3/10/25.
//

import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(region, animated: true)
        uiView.removeAnnotations(uiView.annotations)
        uiView.addAnnotations(annotations)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
    }
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
                        Toggle("Certified by Authority", isOn: $halalCertified)
                        Toggle("User Verified", isOn: $userVerified)
                        Toggle("Third-Party Verified", isOn: $thirdPartyVerified)
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
        
        
        struct HomeView_Previews: PreviewProvider {
            static var previews: some View {
                HomeScreen()
            }
        }
    
    func findNearbyRestaurants() {
        // Request user's location
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        if let userLocation = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            
            // Fetch nearby restaurants (this is a placeholder, replace with actual data fetching logic)
            let nearbyRestaurants = [
                ("Restaurant A", userLocation.latitude + 0.01, userLocation.longitude + 0.01),
                ("Restaurant B", userLocation.latitude - 0.01, userLocation.longitude - 0.01)
            ]
            
            annotations = nearbyRestaurants.map { restaurant in
                let annotation = MKPointAnnotation()
                annotation.title = restaurant.0
                annotation.coordinate = CLLocationCoordinate2D(latitude: restaurant.1, longitude: restaurant.2)
                return annotation
            }
        }
    }
        
    }


// Permission to access Location

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            // Handle case where user denied location access
            break
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
}



