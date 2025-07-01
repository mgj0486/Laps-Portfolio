//
//  RunningModel.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import CoreLocation
import Core

struct RunningData: Identifiable, Hashable {
    let id: UUID
    let startDate: Date
    let distance: Double
    let duration: TimeInterval
    let locations: [RunningLocation]
    let trackId: UUID?
    let lapCount: Int
    
    init(id: UUID = UUID(),
         startDate: Date = Date(),
         distance: Double = 0,
         duration: TimeInterval = 0,
         locations: [RunningLocation] = [],
         trackId: UUID? = nil,
         lapCount: Int = 0) {
        self.id = id
        self.startDate = startDate
        self.distance = distance
        self.duration = duration
        self.locations = locations
        self.trackId = trackId
        self.lapCount = lapCount
    }
}

struct RunningLocation: Identifiable, Hashable {
    let id: UUID
    let coordinate: RunningCoordinate
    let timestamp: Date
    
    init(id: UUID = UUID(),
         coordinate: RunningCoordinate,
         timestamp: Date = Date()) {
        self.id = id
        self.coordinate = coordinate
        self.timestamp = timestamp
    }
    
    init(from location: CLLocation) {
        self.id = UUID()
        self.coordinate = RunningCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        self.timestamp = location.timestamp
    }
}

struct RunningCoordinate: Hashable {
    let latitude: Double
    let longitude: Double
}

extension RunningCoordinate: RouteCoordinate {}

enum RunningError: LocalizedError, Equatable, Hashable {
    case locationNotAvailable
    case healthKitNotAvailable
    case authorizationDenied
    case saveFailed(String)
    case insufficientDistance
    case speedViolation
    
    var errorDescription: String? {
        switch self {
        case .locationNotAvailable:
            return "Location services are not available"
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "Permission was denied for location or health data"
        case .saveFailed(let message):
            return "Failed to save workout: \(message)"
        case .insufficientDistance:
            return "Minimum distance not reached"
        case .speedViolation:
            return "비정상적인 속도가 감지되어 러닝이 중단되었습니다"
        }
    }
}