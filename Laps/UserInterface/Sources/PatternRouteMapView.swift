//
//  PatternRouteMapView.swift
//  UserInterface
//
//  Created by Assistant on 2025/06/22.
//

import SwiftUI
import MapKit
import Core

public struct PatternRouteMapView: UIViewRepresentable {
    let coordinates: [LocationData]
    let highlightedCoordinates: [CLLocationCoordinate2D]?
    
    public init(coordinates: [LocationData], highlightedCoordinates: [CLLocationCoordinate2D]?) {
        self.coordinates = coordinates
        self.highlightedCoordinates = highlightedCoordinates
    }
    
    public func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        return mapView
    }
    
    public func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        let coords = coordinates.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
        
        guard coords.count > 1 else { return }
        
        // Add full route as background
        let fullPolyline = MKPolyline(coordinates: coords, count: coords.count)
        fullPolyline.title = "full"
        mapView.addOverlay(fullPolyline)
        
        // Add highlighted pattern if available
        if let highlighted = highlightedCoordinates, highlighted.count > 1 {
            let patternPolyline = MKPolyline(coordinates: highlighted, count: highlighted.count)
            patternPolyline.title = "pattern"
            mapView.addOverlay(patternPolyline, level: .aboveRoads)
        }
        
        // Add start/end markers
        let displayCoords = highlightedCoordinates ?? coords
        if let start = displayCoords.first, let end = displayCoords.last {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = start
            startAnnotation.title = "시작"
            mapView.addAnnotation(startAnnotation)
            
            let endAnnotation = MKPointAnnotation()
            endAnnotation.coordinate = end
            endAnnotation.title = "종료"
            mapView.addAnnotation(endAnnotation)
        }
        
        let padding = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mapView.setVisibleMapRect(fullPolyline.boundingMapRect, edgePadding: padding, animated: false)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    public class Coordinator: NSObject, MKMapViewDelegate {
        public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                
                if polyline.title == "pattern" {
                    renderer.strokeColor = .systemGreen
                    renderer.lineWidth = 4
                } else {
                    renderer.strokeColor = .systemBlue.withAlphaComponent(0.3)
                    renderer.lineWidth = 3
                }
                
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let identifier = "Marker"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
            } else {
                view?.annotation = annotation
            }
            
            if let markerView = view as? MKMarkerAnnotationView {
                markerView.markerTintColor = annotation.title == "시작" ? .systemGreen : .systemRed
                markerView.glyphImage = UIImage(systemName: annotation.title == "시작" ? "flag" : "flag.checkered")
            }
            
            return view
        }
    }
}
