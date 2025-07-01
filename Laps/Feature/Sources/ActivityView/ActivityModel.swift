//
//  ActivityModel.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation
import Core

struct ActivityData: Identifiable, Hashable {
    let id: UUID
    let date: Date
    let steps: Int
    let walkingDistance: Double
    let activeEnergy: Double
    let latestHeartRate: Double
    let workouts: [WorkoutData]
    let dailyCalories: [Date: Double]
    
    init(id: UUID = UUID(), 
         date: Date = Date(),
         steps: Int = 0,
         walkingDistance: Double = 0,
         activeEnergy: Double = 0,
         latestHeartRate: Double = 0,
         workouts: [WorkoutData] = [],
         dailyCalories: [Date: Double] = [:]) {
        self.id = id
        self.date = date
        self.steps = steps
        self.walkingDistance = walkingDistance
        self.activeEnergy = activeEnergy
        self.latestHeartRate = latestHeartRate
        self.workouts = workouts
        self.dailyCalories = dailyCalories
    }
}

struct WorkoutData: Identifiable, Hashable {
    let id: UUID
    let healthKitId: UUID?
    let date: Date
    let activityType: String
    let duration: Double
    let totalEnergyBurned: Double
    let totalDistance: Double
    let pace: Double
    let sourceName: String
    let route: [LocationData]
    
    init(id: UUID = UUID(),
         healthKitId: UUID? = nil,
         date: Date = Date(),
         activityType: String,
         duration: Double,
         totalEnergyBurned: Double,
         totalDistance: Double,
         pace: Double,
         sourceName: String = "Unknown",
         route: [LocationData] = []) {
        self.id = id
        self.healthKitId = healthKitId
        self.date = date
        self.activityType = activityType
        self.duration = duration
        self.totalEnergyBurned = totalEnergyBurned
        self.totalDistance = totalDistance
        self.pace = pace
        self.sourceName = sourceName
        self.route = route
    }
    
    init(from workout: HKWorkout, route: [LocationData] = []) {
        self.id = UUID()
        self.healthKitId = workout.uuid
        self.date = workout.startDate
        self.activityType = workout.workoutActivityType.name
        self.duration = workout.duration
        self.totalEnergyBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        self.totalDistance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
        
        let km = workout.totalDistance?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
        self.pace = km > 0 ? (workout.duration/60)/km : 0
        
        self.sourceName = workout.sourceRevision.source.name ?? "Unknown"
        self.route = route
    }
}


enum ActivityError: LocalizedError, Equatable {
    case healthKitNotAvailable
    case authorizationDenied
    case dataFetchFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .healthKitNotAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .dataFetchFailed(let message):
            return "Failed to fetch data: \(message)"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running: return "Running"
        case .walking: return "Walking"
        case .cycling: return "Cycling"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Strength Training"
        case .swimming: return "Swimming"
        case .functionalStrengthTraining: return "Functional Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        default: return "Other"
        }
    }
}