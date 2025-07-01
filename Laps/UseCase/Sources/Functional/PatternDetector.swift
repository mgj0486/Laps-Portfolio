//
//  PatternDetector.swift
//  Usecase
//
//  Created by Assistant on 2025/06/22.
//

import Foundation
import CoreLocation

public struct PatternDetector {
    
    public struct DetectedPattern {
        public let loop: [CLLocationCoordinate2D]
        public let repetitions: Int
        public let confidence: Double
        public let startIndex: Int
        public let endIndex: Int
        
        public init(loop: [CLLocationCoordinate2D], repetitions: Int, confidence: Double, startIndex: Int, endIndex: Int) {
            self.loop = loop
            self.repetitions = repetitions
            self.confidence = confidence
            self.startIndex = startIndex
            self.endIndex = endIndex
        }
    }
    
    public static func detectLoopPattern(
        from coordinates: [CLLocationCoordinate2D],
        minLoopSize: Int = 20,
        maxLoopSize: Int = 500,
        distanceThreshold: Double = 10.0
    ) -> DetectedPattern? {
        guard coordinates.count > minLoopSize * 2 else { return nil }
        
        var bestPattern: DetectedPattern?
        var highestScore: Double = 0
        
        // Try different loop sizes
        for loopSize in minLoopSize...min(maxLoopSize, coordinates.count / 2) {
            // Try different starting points
            for startIdx in 0..<min(coordinates.count - loopSize * 2, loopSize) {
                if let pattern = detectPatternAtPosition(
                    coordinates: coordinates,
                    startIndex: startIdx,
                    loopSize: loopSize,
                    distanceThreshold: distanceThreshold
                ) {
                    let score = Double(pattern.repetitions) * pattern.confidence
                    if score > highestScore {
                        highestScore = score
                        bestPattern = pattern
                    }
                }
            }
        }
        
        return bestPattern
    }
    
    private static func detectPatternAtPosition(
        coordinates: [CLLocationCoordinate2D],
        startIndex: Int,
        loopSize: Int,
        distanceThreshold: Double
    ) -> DetectedPattern? {
        guard startIndex + loopSize <= coordinates.count else { return nil }
        
        let candidateLoop = Array(coordinates[startIndex..<startIndex + loopSize])
        var repetitions = 1
        var totalDistance: Double = 0
        var matchCount = 0
        
        // Check how many times this pattern repeats
        var currentIndex = startIndex + loopSize
        
        while currentIndex + loopSize <= coordinates.count {
            let nextSegment = Array(coordinates[currentIndex..<currentIndex + loopSize])
            let (isMatch, avgDistance) = compareLoops(
                candidateLoop,
                nextSegment,
                threshold: distanceThreshold
            )
            
            if isMatch {
                repetitions += 1
                totalDistance += avgDistance
                matchCount += 1
                currentIndex += loopSize
            } else {
                break
            }
        }
        
        // Need at least 2 repetitions to be considered a pattern
        guard repetitions >= 2 else { return nil }
        
        // Calculate confidence based on how well the patterns match
        let avgMatchDistance = matchCount > 0 ? totalDistance / Double(matchCount) : 0
        let confidence = 1.0 - min(avgMatchDistance / distanceThreshold, 1.0)
        
        // Verify the loop closes properly
        let loopStartLocation = CLLocation(
            latitude: candidateLoop.first!.latitude,
            longitude: candidateLoop.first!.longitude
        )
        let loopEndLocation = CLLocation(
            latitude: candidateLoop.last!.latitude,
            longitude: candidateLoop.last!.longitude
        )
        let loopClosureDistance = loopStartLocation.distance(from: loopEndLocation)
        
        // If the loop doesn't close well, reduce confidence
        let closureConfidence = loopClosureDistance < distanceThreshold * 2 ? 1.0 : 0.5
        
        return DetectedPattern(
            loop: candidateLoop,
            repetitions: repetitions,
            confidence: confidence * closureConfidence,
            startIndex: startIndex,
            endIndex: startIndex + (loopSize * repetitions)
        )
    }
    
    private static func compareLoops(
        _ loop1: [CLLocationCoordinate2D],
        _ loop2: [CLLocationCoordinate2D],
        threshold: Double
    ) -> (matches: Bool, avgDistance: Double) {
        guard loop1.count == loop2.count else { return (false, Double.infinity) }
        
        var totalDistance: Double = 0
        var maxDistance: Double = 0
        
        // Find the best alignment by trying different starting points
        var bestAlignment = 0
        var bestAvgDistance = Double.infinity
        
        for offset in 0..<min(loop1.count, 10) {
            var offsetDistance: Double = 0
            
            for i in 0..<loop1.count {
                let idx1 = i
                let idx2 = (i + offset) % loop2.count
                
                let loc1 = CLLocation(
                    latitude: loop1[idx1].latitude,
                    longitude: loop1[idx1].longitude
                )
                let loc2 = CLLocation(
                    latitude: loop2[idx2].latitude,
                    longitude: loop2[idx2].longitude
                )
                
                offsetDistance += loc1.distance(from: loc2)
            }
            
            let avgDist = offsetDistance / Double(loop1.count)
            if avgDist < bestAvgDistance {
                bestAvgDistance = avgDist
                bestAlignment = offset
            }
        }
        
        // Calculate final comparison with best alignment
        for i in 0..<loop1.count {
            let idx1 = i
            let idx2 = (i + bestAlignment) % loop2.count
            
            let loc1 = CLLocation(
                latitude: loop1[idx1].latitude,
                longitude: loop1[idx1].longitude
            )
            let loc2 = CLLocation(
                latitude: loop2[idx2].latitude,
                longitude: loop2[idx2].longitude
            )
            
            let distance = loc1.distance(from: loc2)
            totalDistance += distance
            maxDistance = max(maxDistance, distance)
        }
        
        let avgDistance = totalDistance / Double(loop1.count)
        let matches = avgDistance < threshold && maxDistance < threshold * 3
        
        return (matches, avgDistance)
    }
    
    // Simplify the detected loop by removing redundant points
    public static func simplifyLoop(
        _ coordinates: [CLLocationCoordinate2D],
        tolerance: Double = 5.0
    ) -> [CLLocationCoordinate2D] {
        guard coordinates.count > 3 else { return coordinates }
        
        // Douglas-Peucker algorithm for line simplification
        return douglasPeucker(coordinates, tolerance: tolerance)
    }
    
    private static func douglasPeucker(
        _ points: [CLLocationCoordinate2D],
        tolerance: Double
    ) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }
        
        // Find the point with maximum distance from line between first and last
        var maxDistance: Double = 0
        var maxIndex = 0
        
        let firstLocation = CLLocation(
            latitude: points.first!.latitude,
            longitude: points.first!.longitude
        )
        let lastLocation = CLLocation(
            latitude: points.last!.latitude,
            longitude: points.last!.longitude
        )
        
        for i in 1..<points.count - 1 {
            let pointLocation = CLLocation(
                latitude: points[i].latitude,
                longitude: points[i].longitude
            )
            let distance = perpendicularDistance(
                point: pointLocation,
                lineStart: firstLocation,
                lineEnd: lastLocation
            )
            
            if distance > maxDistance {
                maxDistance = distance
                maxIndex = i
            }
        }
        
        // If max distance is greater than tolerance, recursively simplify
        if maxDistance > tolerance {
            let firstPart = douglasPeucker(
                Array(points[0...maxIndex]),
                tolerance: tolerance
            )
            let secondPart = douglasPeucker(
                Array(points[maxIndex..<points.count]),
                tolerance: tolerance
            )
            
            return firstPart.dropLast() + secondPart
        } else {
            return [points.first!, points.last!]
        }
    }
    
    private static func perpendicularDistance(
        point: CLLocation,
        lineStart: CLLocation,
        lineEnd: CLLocation
    ) -> Double {
        let A = point.distance(from: lineStart)
        let B = point.distance(from: lineEnd)
        let C = lineStart.distance(from: lineEnd)
        
        if C == 0 { return A }
        
        // Using Heron's formula to find the area of the triangle
        let s = (A + B + C) / 2
        let area = sqrt(max(0, s * (s - A) * (s - B) * (s - C)))
        
        // Height = 2 * Area / Base
        return 2 * area / C
    }
}