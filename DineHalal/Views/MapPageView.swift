//
//  MapPageView.swift
//  DineHalal
//
//  Created by Rosa Rivera on 4/24/25.
//  modified by victoria to make markers pop up

import SwiftUI
import MapKit
import CoreLocation

struct MapPageView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var placesService = PlacesService()
    @EnvironmentObject var navigationState: NavigationStateManager
    @State private var selectedRestaurant: Restaurant? = nil
    @State private var showPopup = false
    @EnvironmentObject var favorites: Favorites
    @StateObject private var verificationService = VerificationService()
    @State private var filterCriteria = FilterCriteria()
    @State private var showFilter = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var annotations: [MKPointAnnotation] = []
    @State private var lastRegionCenter: CLLocationCoordinate2D? = nil
    @State private var debounceWorkItem: DispatchWorkItem?
    @State private var isFetching = false

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
                                .foregroundColor(.brown)
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.all)

            // top buttons DO NOT TOUCH VICTORIA
            VStack {
                HStack(spacing: 12) {
                    Spacer()

                    //  Near Me Button with sheet dismissal + delay
                    Button(action: {
                        Task {
                            selectedRestaurant = nil // close the sheet
                            try? await Task.sleep(nanoseconds: 300_000_000) // wait 0.3s
                            locateUser()
                        }
                    }) {
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

        // Restaurant detail sheet
        .sheet(item: $selectedRestaurant) { restaurant in
            RestaurantDetails(restaurant: restaurant, verificationService: verificationService)
                .environmentObject(favorites)
        }

        .onAppear {
            Task { await initialLoad() }
        }

        // Location changes trigger fetch
        .onReceive(locationManager.$userLocation.compactMap { $0 }) { coord in
            region.center = coord
            Task {
                await fetchNearbyAndAnnotate(lat: coord.latitude, lon: coord.longitude)
            }
        }

        .sheet(isPresented: $showFilter) {
            FilterView(criteria: $filterCriteria) { criteria in
                applyFilters(criteria)
                showFilter.toggle()
            }
        }

        // Debounced map movement fetch
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            if isFetching { return }

            debounceWorkItem?.cancel()
            let workItem = DispatchWorkItem {
                if lastRegionCenter == nil || distanceBetween(region.center, lastRegionCenter!) > 50 {
                    lastRegionCenter = region.center
                    Task {
                        await fetchNearbyAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
                    }
                }
            }
            debounceWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }

    private func locateUser() {
        locationManager.requestLocationPermission()
        locationManager.getLocation()
    }

    private func applyFilters(_ criteria: FilterCriteria) {
        if !criteria.cityZip.isEmpty {
            geocodeZipCode(criteria.cityZip) { coord in
                if let coord = coord {
                    region.center = coord
                } else {
                    Task {
                        await fetchNearbyAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
                    }
                }
            }
        } else if let userLoc = locationManager.userLocation {
            region.center = userLoc
        } else {
            Task {
                await fetchNearbyAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
            }
        }
    }

    private func geocodeZipCode(_ zip: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(zip) { placemarks, _ in
            completion(placemarks?.first?.location?.coordinate)
        }
    }

    private func distanceBetween(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let loc2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return loc1.distance(from: loc2)
    }

    private func initialLoad() async {
        await fetchNearbyAndAnnotate(lat: region.center.latitude, lon: region.center.longitude)
    }

    @MainActor
    private func fetchNearbyAndAnnotate(lat: Double, lon: Double) async {
        if isFetching { return }
        isFetching = true

        await withCheckedContinuation { continuation in
            placesService.fetchNearbyRestaurants(latitude: lat, longitude: lon, filter: filterCriteria) {
                let newAnnotations = self.placesService.allRestaurants.map { restaurant in
                    let annotation = MKPointAnnotation()
                    annotation.title = restaurant.name
                    annotation.coordinate = CLLocationCoordinate2D(latitude: restaurant.latitude, longitude: restaurant.longitude)
                    return annotation
                }

                self.annotations = newAnnotations
                self.isFetching = false
                continuation.resume()
            }
        }
    }
}
