//
//  RunningActivityAttributes.swift
//  Core
//
//  Created by Assistant on 2025/06/22.
//

import Foundation
import ActivityKit

public struct RunningActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public let duration: TimeInterval
        public let distance: Double // in meters
        public let pace: Double // min/km
        
        public init(duration: TimeInterval, distance: Double, pace: Double) {
            self.duration = duration
            self.distance = distance
            self.pace = pace
        }
        
        public var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        public var formattedDistance: String {
            String(format: "%.2f km", distance / 1000)
        }
        
        public var formattedPace: String {
            if pace > 0 {
                return String(format: "%.2f min/km", pace)
            } else {
                return "-- min/km"
            }
        }
    }
    
    public let startDate: Date
    
    public init(startDate: Date) {
        self.startDate = startDate
    }
}