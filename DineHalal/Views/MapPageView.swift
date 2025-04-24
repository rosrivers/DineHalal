//
//  MapPageView.swift
//  DineHalal
//
//  Created by Rosa Rivera on 4/24/25.
//

import SwiftUI
import MapKit
import CoreLocation
import GoogleMaps

// MARK: An interactive full-screen map view with centered "Near Me" button and a side filter control.
struct MapPageView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var filterCriteria = FilterCriteria()                // changed: filter state
    @State private var showFilter = false                               // changed: show filter sheet
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    
    var body: some View {
        ZStack {
            // Full-screen map
            GoogleMapView(region: $region, annotations: annotations)
                .edgesIgnoringSafeArea(.all)

            VStack {
                // Top controls
                HStack(spacing: 12) {
                    Spacer()
                    // Near Me button
                    Button(action: locateUser) {
                        Text("Near Me")
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.mud)
                            .foregroundColor(Color.beige)
                            .clipShape(Capsule())
                    }
                    // Filter button
                    Button(action: { showFilter.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title2)
                            .padding(12)
                            .background(Color.mud)
                            .foregroundColor(Color.beige)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 50)

                Spacer()
            }
        }
        // Initial load
        .onAppear(perform: initialLoad)
        // Update on location change
        .onReceive(locationManager.$userLocation.compactMap { $0 }) { coord in
            region.center = coord
            fetchAndAnnotate(lat: coord.latitude, lon: coord.longitude)
        }
        // Filter sheet
        .sheet(isPresented: $showFilter) {
            FilterView(criteria: $filterCriteria) { criteria in
                applyFilters(criteria)
                showFilter.toggle()
            }
        }
    }
    
    // MARK: - Actions
    
    private func locateUser() {
        locationManager.requestLocationPermission()
        locationManager.getLocation()
    }
    
    private func initialLoad() {
        // Fetch default nearby restaurants
        fetchAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
    }
    
    private func fetchAndAnnotate(lat: Double, lon: Double) {
        placesService.fetchNearbyRestaurants(
            latitude: lat,
            longitude: lon,
            filter: filterCriteria
        )
        // Convert to annotations
        annotations = placesService.allRestaurants.map { r in
            let ann = MKPointAnnotation()
            ann.title = r.name
            ann.coordinate = CLLocationCoordinate2D(latitude: r.latitude, longitude: r.longitude)
            return ann
        }
    }
    
    private func applyFilters(_ criteria: FilterCriteria) {
        // If user requested zip filter, geocode first
        if !criteria.cityZip.isEmpty {
            geocodeZipCode(criteria.cityZip) { coord in
                let latLon = coord ?? region.center
                fetchAndAnnotate(lat: latLon.latitude, lon: latLon.longitude)
            }
        } else if criteria.nearMe, let userLoc = locationManager.userLocation {
            fetchAndAnnotate(lat: userLoc.latitude, lon: userLoc.longitude)
        } else {
            // default region
            fetchAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
        }
    }
    
    // Helper: geocode ZIP
    private func geocodeZipCode(_ zip: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zip) { placemarks, _ in
            completion(placemarks?.first?.location?.coordinate)
        }
    }
}

struct MapPageView_Previews: PreviewProvider {
    static var previews: some View {
        MapPageView()
            .environmentObject(NavigationStateManager())
    }
}
