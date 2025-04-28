//
//  MapPageView.swift
//  DineHalal
//
//  Created by Rosa Rivera on 4/24/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapPageView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var navigationState: NavigationStateManager
    
    @State private var filterCriteria = FilterCriteria()
    @State private var showFilter = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    
    var body: some View {
        ZStack {
            GoogleMapView(region: $region, annotations: annotations)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                HStack(spacing: 12) {
                    Spacer()
                    
                    Button(action: locateUser) {
                        Text("Near Me")
                            .fontWeight(.medium)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.mud)
                            .foregroundColor(Color.beige)
                            .clipShape(Capsule())
                    }
                    
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
        .onAppear(perform: initialLoad)
        .onReceive(locationManager.$userLocation.compactMap { $0 }) { coord in
            region.center = coord
            fetchAndAnnotate(lat: coord.latitude, lon: coord.longitude)
        }
        .sheet(isPresented: $showFilter) {
            FilterView(criteria: $filterCriteria) { criteria in
                applyFilters(criteria)
                showFilter.toggle()
            }
        }
    }
    
    private func locateUser() {
        locationManager.requestLocationPermission()
        locationManager.getLocation()
    }
    
    private func initialLoad() {
        fetchAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
    }
    
    private func fetchAndAnnotate(lat: Double, lon: Double) {
        placesService.fetchNearbyRestaurants(latitude: lat, longitude: lon, filter: filterCriteria) {
            DispatchQueue.main.async {
                self.annotations = self.placesService.allRestaurants.map { restaurant in
                    let annotation = MKPointAnnotation()
                    annotation.title = restaurant.name
                    annotation.coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
                    return annotation
                }
                print("Fetched annotations count:", self.annotations.count)
            }
        }
    }

    
    private func applyFilters(_ criteria: FilterCriteria) {
        if !criteria.cityZip.isEmpty {
            geocodeZipCode(criteria.cityZip) { coord in
                fetchAndAnnotate(lat: coord?.latitude ?? region.center.latitude,
                                 lon: coord?.longitude ?? region.center.longitude)
            }
        } else if criteria.nearMe, let userLoc = locationManager.userLocation {
            fetchAndAnnotate(lat: userLoc.latitude, lon: userLoc.longitude)
        } else {
            fetchAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
        }
    }
    
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
