//
//  MapView.swift
//  DineHalal
//
//  Created by Iman Ikram on 3/24/25.
//

import SwiftUI
import MapKit
import CoreLocation
import GoogleMaps


struct GoogleMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var annotations: [MKPointAnnotation]

    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(
            withLatitude: region.center.latitude,
            longitude: region.center.longitude,
            zoom: 10.0
        )
        let mapView = GMSMapView(frame: .zero)
        mapView.camera = camera
        return mapView
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        for annotation in annotations {
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2D(
                latitude: annotation.coordinate.latitude,
                longitude: annotation.coordinate.longitude
            )
            marker.title = annotation.title
            marker.map = mapView
        }
    }
}
