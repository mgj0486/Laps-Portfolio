//
//  RouteSimilarityChecker.swift
//  Usecase
//
//  Created by Assistant on 2025/06/22.
//

import Foundation
import CoreLocation

public struct RouteSimilarityChecker {
    
    public struct SimilarityResult {
        public let isSimilar: Bool
        public let confidence: Double
        public let reason: String
        
        public init(isSimilar: Bool, confidence: Double, reason: String) {
            self.isSimilar = isSimilar
            self.confidence = confidence
            self.reason = reason
        }
    }
    
    /// Check if two routes are similar, including pattern detection
    public static func checkSimilarity(
        route1: [CLLocationCoordinate2D],
        route2: [CLLocationCoordinate2D],
        distanceThreshold: Double = 50.0,
        coverageThreshold: Double = 0.7
    ) -> SimilarityResult {
        
        // Quick checks
        if route1.isEmpty || route2.isEmpty {
            return SimilarityResult(isSimilar: false, confidence: 0, reason: "Empty route")
        }
        
        // Check if one route is a pattern of the other
        if let patternResult = checkPatternSimilarity(route1: route1, route2: route2, distanceThreshold: distanceThreshold) {
            return patternResult
        }
        
        // Check direct similarity
        return checkDirectSimilarity(route1: route1, route2: route2, distanceThreshold: distanceThreshold, coverageThreshold: coverageThreshold)
    }
    
    /// Check if one route is a repeated pattern of the other
    private static func checkPatternSimilarity(
        route1: [CLLocationCoordinate2D],
        route2: [CLLocationCoordinate2D],
        distanceThreshold: Double
    ) -> SimilarityResult? {
        
        // Check if route1 is a pattern repeated in route2
        if let pattern1 = PatternDetector.detectLoopPattern(from: route1) {
            if areRoutesEquivalent(pattern1.loop, route2, threshold: distanceThreshold) {
                return SimilarityResult(
                    isSimilar: true,
                    confidence: pattern1.confidence,
                    reason: "Route matches detected pattern (\(pattern1.repetitions) loops)"
                )
            }
        }
        
        // Check if route2 is a pattern repeated in route1
        if let pattern2 = PatternDetector.detectLoopPattern(from: route2) {
            if areRoutesEquivalent(route1, pattern2.loop, threshold: distanceThreshold) {
                return SimilarityResult(
                    isSimilar: true,
                    confidence: pattern2.confidence,
                    reason: "Route matches existing pattern (\(pattern2.repetitions) loops)"
                )
            }
        }
        
        // Check if both have patterns and the patterns match
        if let pattern1 = PatternDetector.detectLoopPattern(from: route1),
           let pattern2 = PatternDetector.detectLoopPattern(from: route2) {
            if areRoutesEquivalent(pattern1.loop, pattern2.loop, threshold: distanceThreshold) {
                return SimilarityResult(
                    isSimilar: true,
                    confidence: (pattern1.confidence + pattern2.confidence) / 2,
                    reason: "Both routes have matching patterns"
                )
            }
        }
        
        return nil
    }
    
    /// Check direct route similarity using coverage-based algorithm
    private static func checkDirectSimilarity(
        route1: [CLLocationCoordinate2D],
        route2: [CLLocationCoordinate2D],
        distanceThreshold: Double,
        coverageThreshold: Double
    ) -> SimilarityResult {
        
        // Calculate how much of route1 is covered by route2
        let coverage1 = calculateRouteCoverage(
            route: route1,
            referenceRoute: route2,
            threshold: distanceThreshold
        )
        
        // Calculate how much of route2 is covered by route1
        let coverage2 = calculateRouteCoverage(
            route: route2,
            referenceRoute: route1,
            threshold: distanceThreshold
        )
        
        // Both routes should have high coverage of each other
        let avgCoverage = (coverage1 + coverage2) / 2
        let isSimilar = coverage1 >= coverageThreshold && coverage2 >= coverageThreshold
        
        return SimilarityResult(
            isSimilar: isSimilar,
            confidence: avgCoverage,
            reason: isSimilar ? "Routes match (coverage: \(Int(avgCoverage * 100))%)" : "Routes differ significantly"
        )
    }
    
    /// Calculate what percentage of a route is covered by another route
    private static func calculateRouteCoverage(
        route: [CLLocationCoordinate2D],
        referenceRoute: [CLLocationCoordinate2D],
        threshold: Double
    ) -> Double {
        guard !route.isEmpty && !referenceRoute.isEmpty else { return 0 }
        
        var coveredPoints = 0
        
        for point in route {
            let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude)
            
            // Find minimum distance to any point in reference route
            var minDistance = Double.infinity
            for refPoint in referenceRoute {
                let refLocation = CLLocation(latitude: refPoint.latitude, longitude: refPoint.longitude)
                let distance = pointLocation.distance(from: refLocation)
                minDistance = min(minDistance, distance)
                
                // Early exit if we found a close point
                if minDistance < threshold {
                    break
                }
            }
            
            if minDistance < threshold {
                coveredPoints += 1
            }
        }
        
        return Double(coveredPoints) / Double(route.count)
    }
    
    /// Check if two routes are equivalent within a threshold
    private static func areRoutesEquivalent(
        _ route1: [CLLocationCoordinate2D],
        _ route2: [CLLocationCoordinate2D],
        threshold: Double
    ) -> Bool {
        // Routes should have similar lengths
        let lengthRatio = Double(min(route1.count, route2.count)) / Double(max(route1.count, route2.count))
        if lengthRatio < 0.8 {
            return false
        }
        
        // Check coverage in both directions
        let coverage1 = calculateRouteCoverage(route: route1, referenceRoute: route2, threshold: threshold)
        let coverage2 = calculateRouteCoverage(route: route2, referenceRoute: route1, threshold: threshold)
        
        // Both should have high coverage
        return coverage1 > 0.8 && coverage2 > 0.8
    }
    
    /// Calculate total distance of a route
    public static func calculateRouteDistance(_ route: [CLLocationCoordinate2D]) -> Double {
        guard route.count > 1 else { return 0 }
        
        var totalDistance: Double = 0
        for i in 1..<route.count {
            let loc1 = CLLocation(latitude: route[i-1].latitude, longitude: route[i-1].longitude)
            let loc2 = CLLocation(latitude: route[i].latitude, longitude: route[i].longitude)
            totalDistance += loc1.distance(from: loc2)
        }
        
        return totalDistance
    }
}