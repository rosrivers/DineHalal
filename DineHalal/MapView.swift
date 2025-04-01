//
//  MapView.swift
//  DineHalal
//
///  Created by Iman Ikram on 3/24/25.
///  Edited/Modified - Joana

import SwiftUI
import GoogleMaps
import MapKit
import CoreLocation

struct GoogleMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MKPointAnnotation]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        var mapView: GMSMapView?
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
            super.init()
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            print("Tapped marker: \(marker.title ?? "")")
            return true
        }
    }

    func makeUIView(context: Context) -> GMSMapView {
        // Create camera position with initial location
        let camera = GMSCameraPosition(
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: 15
        )
        
        // Create map view with camera
        let mapView = GMSMapView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height * 0.4), camera: camera)
        
        // Configure map settings
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = false
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false
        
        // Set delegate
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        // Only update if there's a significant change
        let currentPosition = mapView.camera.target
        let newPosition = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        if abs(currentPosition.latitude - newPosition.latitude) > 0.000001 ||
           abs(currentPosition.longitude - newPosition.longitude) > 0.000001 {
            let camera = GMSCameraPosition(
                target: newPosition,
                zoom: mapView.camera.zoom
            )
            mapView.animate(to: camera)
        }
        
        // Update markers only if they've changed
        updateMarkers(mapView: mapView)
    }
    
    private func updateMarkers(mapView: GMSMapView) {
        // Remove existing markers
        mapView.clear()
        
        // Add new markers
        for annotation in annotations {
            let marker = GMSMarker(position: annotation.coordinate)
            marker.title = annotation.title ?? ""
            marker.snippet = annotation.subtitle ?? ""
            marker.icon = GMSMarker.markerImage(with: .systemRed)
            marker.map = mapView
        }
    }
}
