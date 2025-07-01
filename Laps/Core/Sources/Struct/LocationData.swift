//
//  LocationData.swift
//  Core
//
//  Created by Assistant on 2025/06/22.
//

import Foundation
import CoreLocation

public struct LocationData: Identifiable, Hashable {
    public let id: UUID
    public let latitude: Double
    public let longitude: Double
    public let timestamp: Date
    
    public init(id: UUID = UUID(), latitude: Double, longitude: Double, timestamp: Date = Date()) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
    }
    
    public init(from location: CLLocation) {
        self.id = UUID()
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = location.timestamp
    }
}

extension LocationData: RouteCoordinate {}