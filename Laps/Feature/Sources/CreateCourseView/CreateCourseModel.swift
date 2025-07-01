//
//  CreateCourseModel.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import Foundation
import CoreLocation
import Usecase

struct CreateCourseData {
    var name: String = ""
    var description: String = ""
    let workout: WorkoutData
    var detectedPattern: PatternDetector.DetectedPattern?
    var usePatternMode: Bool = false
    
    var isValid: Bool {
        !name.isEmpty
    }
    
    var coordinates: [CLLocationCoordinate2D] {
        workout.route.map { 
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) 
        }
    }
    
    var patternCoordinates: [CLLocationCoordinate2D] {
        if usePatternMode, let pattern = detectedPattern {
            return PatternDetector.simplifyLoop(pattern.loop)
        }
        return coordinates
    }
    
    var centerCoordinate: CLLocationCoordinate2D? {
        let coords = usePatternMode ? patternCoordinates : coordinates
        let latitudes = coords.map { $0.latitude }
        let longitudes = coords.map { $0.longitude }
        
        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else {
            return nil
        }
        
        return CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
    }
    
    mutating func detectPattern() {
        detectedPattern = PatternDetector.detectLoopPattern(from: coordinates)
        if detectedPattern != nil {
            usePatternMode = true
        }
    }
}

enum CreateCourseError: LocalizedError {
    case saveFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "코스 저장 실패: \(message)"
        case .invalidData:
            return "유효하지 않은 데이터입니다"
        }
    }
}