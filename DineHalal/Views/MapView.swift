//  MapView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
//  Edited/Modified - Joana + Rosa

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
            print("Tapped restaurant: \(marker.title ?? "")")
            return true
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            // Update region.center when user stops moving the map
            parent.region.center = CLLocationCoordinate2D(
                latitude: position.target.latitude,
                longitude: position.target.longitude
            )
        }
    }

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition(
            latitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: 14
        )
        
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        context.coordinator.mapView = mapView
        
        mapView.isMyLocationEnabled = false
        mapView.settings.myLocationButton = false
        mapView.settings.compassButton = false
        mapView.settings.zoomGestures = true
        mapView.settings.scrollGestures = true
        mapView.settings.rotateGestures = true
        mapView.settings.tiltGestures = false
        
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        print("Updating UIView with", annotations.count, "annotations")
        
        let currentCenter = mapView.camera.target
        let newCenter = CLLocationCoordinate2D(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        if abs(currentCenter.latitude - newCenter.latitude) > 0.000001 ||
            abs(currentCenter.longitude - newCenter.longitude) > 0.000001 {
            let camera = GMSCameraPosition(target: newCenter, zoom: mapView.camera.zoom)
            mapView.animate(to: camera)
        }
        
        updateMarkers(mapView: mapView)
    }

    private func updateMarkers(mapView: GMSMapView) {
        print("Updating markers...")
        mapView.clear()
        
        for annotation in annotations {
            let marker = GMSMarker(position: annotation.coordinate)
            marker.title = annotation.title ?? ""
            marker.snippet = annotation.subtitle ?? ""
            marker.icon = UIImage(named: "halal_pin") ?? GMSMarker.markerImage(with: .brown)
            marker.appearAnimation = .pop
            marker.map = mapView
            print("Added marker:", marker.title ?? "", "at", marker.position)
        }
    }
}
