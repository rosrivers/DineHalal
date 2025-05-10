//  MapPageView.swift
//  DineHalal
//
//  Created by Rosa Rivera on 4/24/25.
// modified by victoria to make markers pop up


import SwiftUI
import MapKit
import CoreLocation

struct MapPageView: View {
    @EnvironmentObject var locationManager:LocationManager
    @EnvironmentObject var placesService:PlacesService
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var showPopup = false
    @EnvironmentObject var favorites: Favorites
    @StateObject var verificationService = VerificationService()
    @State private var filterCriteria = FilterCriteria()
    @State private var showFilter = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span:MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []

    var body: some View {
            ZStack {
                // map ui
                Map(coordinateRegion: $region, annotationItems: placesService.allRestaurants) { restaurant in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)) {
                        Button(action: {
                            selectedRestaurant = restaurant
                            showPopup = true
                        }) {
                            VStack {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .edgesIgnoringSafeArea(.all)

//                .sheet(isPresented: $showPopup) {
//                    if let selectedRestaurant = selectedRestaurant {
//                        RestaurantDetails(restaurant: selectedRestaurant, verificationService: verificationService)
//                    }
//                }
                // top buttons DO NOT TOUCH VICTORIA
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
            // Popup to restautant details page
            .sheet(item: $selectedRestaurant) { restaurant in
                RestaurantDetails(restaurant: restaurant, verificationService: verificationService)
                    .environmentObject(favorites)
            }

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
            .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                if lastRegionCenter == nil || distanceBetween(region.center, lastRegionCenter!) > 50 {
                    lastRegionCenter = region.center
                    fetchAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
                }
            }
        }

    private func locateUser() {
        locationManager.requestLocationPermission()
        locationManager.getLocation()
    }

    private func initialLoad() {
        fetchAndAnnotate(
            lat: region.center.latitude,
            lon: region.center.longitude
        )
    }

    private func fetchAndAnnotate(lat: Double, lon: Double) {
        placesService.fetchNearbyRestaurants(
            latitude: lat,
            longitude: lon,
            filter: filterCriteria
        ) {
            DispatchQueue.main.async {
                self.annotations = self.placesService.allRestaurants.map {
                    let a = MKPointAnnotation()
                    a.title = $0.name
                    a.coordinate = CLLocationCoordinate2D(
                        latitude:  $0.latitude,
                        longitude: $0.longitude
                    )
                    return a
                }
            }
        }
    }

    private func applyFilters(_ criteria: FilterCriteria) {
        if !criteria.cityZip.isEmpty {
            geocodeZipCode(criteria.cityZip) { coord in
                if let c = coord {
                    region.center = c
                }
                fetchAndAnnotate(
                    lat: region.center.latitude,
                    lon: region.center.longitude
                )
            }
        } else if criteria.nearMe,
                  let loc = locationManager.userLocation {
            region.center = loc
            fetchAndAnnotate(lat: loc.latitude, lon: loc.longitude)
        } else {
            initialLoad()
        }
    }

    private func geocodeZipCode(_ zip: String,
                                completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        CLGeocoder().geocodeAddressString(zip) { marks, _ in
            completion(marks?.first?.location?.coordinate)
        }
    }
}
