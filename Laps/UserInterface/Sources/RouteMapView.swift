//
//  RouteMapView.swift
//  UserInterface
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import SwiftUI
import MapKit
import CoreLocation
import Core

public struct RouteMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    
    // Init with CLLocationCoordinate2D array
    public init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
    }
    
    // Init with LocationData array
    public init(locations: [LocationData]) {
        self.coordinates = locations.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
    }
    
    // Init with generic RouteCoordinate array (for backward compatibility)
    public init<T: RouteCoordinate>(coordinates: [T]) {
        self.coordinates = coordinates.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
    }
    
    public var body: some View {
        Map {
            MapPolyline(coordinates: coordinates)
                .stroke(Color(UIColor { traitCollection in
                    traitCollection.userInterfaceStyle == .dark ?
                        UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0) :
                        UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0)
                }), lineWidth: 3)
        }
        .mapStyle(.standard(elevation: .flat))
        .mapControlVisibility(.hidden)
        .disabled(true)
    }
}
