//
//  MapPolylineView.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import SwiftUI
import MapKit

struct MapPolylineView: UIViewRepresentable {
    let polyline: MKPolyline
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // Disable all user interactions
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        mapView.isUserInteractionEnabled = false
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30), animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                // Theme-matching colors
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    renderer.strokeColor = UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) // Soft blue for dark mode
                } else {
                    renderer.strokeColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0) // Darker blue for light mode
                }
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
