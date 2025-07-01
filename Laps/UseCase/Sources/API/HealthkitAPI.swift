//
//  HealthkitAPI.swift
//  Usecase
//
//  Created by Moon kyu Jung on 6/21/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import Foundation
import HealthKit
import Combine
import CoreLocation

public final class HealthKitAPI {
    private let healthStore = HKHealthStore()
    
    public init() {}
    
    // MARK: - Authorization
    
    public func requestReadAuthorization() -> AnyPublisher<Bool, Error> {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        return Future<Bool, Error> { promise in
            self.healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func requestWriteAuthorization() -> AnyPublisher<Bool, Error> {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute()
        ]
        
        return Future<Bool, Error> { promise in
            self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Read Operations
    
    public func fetchMonthlyCumulative(id: HKQuantityTypeIdentifier, unit: HKUnit, date: Date) -> AnyPublisher<[HKStatisticsCollection.DayData], Error> {
        let quantityType = HKQuantityType.quantityType(forIdentifier: id)!
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)!.start
        let endOfMonth = calendar.dateInterval(of: .month, for: date)!.end
        let dailyInterval = DateComponents(day: 1)
        let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: endOfMonth, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startOfMonth,
            intervalComponents: dailyInterval
        )
        
        return Future<[HKStatisticsCollection.DayData], Error> { promise in
            query.initialResultsHandler = { _, result, error in
                if let error = error {
                    promise(.failure(error))
                } else if let result = result {
                    let dayData = result.toDayData(unit: unit)
                    promise(.success(dayData))
                } else {
                    promise(.success([]))
                }
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
    
    public func fetchLatestHeartRate() -> AnyPublisher<Double?, Error> {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return Future<Double?, Error> { promise in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    promise(.failure(error))
                } else if let sample = samples?.first as? HKQuantitySample {
                    let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    promise(.success(heartRate))
                } else {
                    promise(.success(nil))
                }
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
    
    public func fetchMonthlyWorkouts(for date: Date) -> AnyPublisher<[Workout], Error> {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)!.start
        let endOfMonth = calendar.dateInterval(of: .month, for: date)!.end
        let predicate = HKQuery.predicateForSamples(withStart: startOfMonth, end: endOfMonth, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return Future<[Workout], Error> { promise in
            let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
                if let error = error {
                    promise(.failure(error))
                } else if let workouts = samples as? [HKWorkout] {
                    let publishers = workouts.map { workout in
                        self.fetchRoute(for: workout)
                            .map { route in
                                Workout(
                                    id: workout.uuid,
                                    date: workout.startDate,
                                    duration: workout.duration,
                                    distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                                    totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                                    avgHeartRate: nil,
                                    avgPace: nil,
                                    activityType: workout.workoutActivityType,
                                    sourceName: workout.sourceRevision.source.name ?? "Unknown",
                                    route: route
                                )
                            }
                            .replaceError(with: Workout(
                                id: workout.uuid,
                                date: workout.startDate,
                                duration: workout.duration,
                                distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                                totalEnergyBurned: workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0,
                                avgHeartRate: nil,
                                avgPace: nil,
                                activityType: workout.workoutActivityType,
                                sourceName: workout.sourceRevision.source.name ?? "Unknown",
                                route: []
                            ))
                    }
                    
                    Publishers.MergeMany(publishers)
                        .collect()
                        .sink(
                            receiveCompletion: { _ in },
                            receiveValue: { workouts in
                                promise(.success(workouts))
                            }
                        )
                        .store(in: &self.cancellables)
                } else {
                    promise(.success([]))
                }
            }
            self.healthStore.execute(query)
        }
        .eraseToAnyPublisher()
    }
    
    public func fetchRoute(for workout: HKWorkout) -> AnyPublisher<[CLLocation], Error> {
        let routePredicate = HKQuery.predicateForObjects(from: workout)
        
        return Future<[CLLocation], Error> { promise in
            let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: routePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    promise(.failure(error))
                } else if let routeSamples = samples as? [HKWorkoutRoute], let routeSample = routeSamples.first {
                    var locations: [CLLocation] = []
                    let routeLocationQuery = HKWorkoutRouteQuery(route: routeSample) { _, returnedLocations, done, error in
                        if let error = error {
                            promise(.failure(error))
                        } else if let returnedLocations = returnedLocations {
                            locations.append(contentsOf: returnedLocations)
                            if done {
                                promise(.success(locations))
                            }
                        }
                    }
                    self.healthStore.execute(routeLocationQuery)
                } else {
                    promise(.success([]))
                }
            }
            self.healthStore.execute(routeQuery)
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Write Operations
    
    public func saveWorkout(duration: TimeInterval, distance: Double, workoutType: HKWorkoutActivityType = .running) -> AnyPublisher<HKWorkout, Error> {
        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance)
        let workout = HKWorkout(
            activityType: workoutType,
            start: Date().addingTimeInterval(-duration),
            end: Date(),
            duration: duration,
            totalEnergyBurned: nil,
            totalDistance: distanceQuantity,
            metadata: nil
        )
        
        return Future<HKWorkout, Error> { promise in
            self.healthStore.save(workout) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else if success {
                    promise(.success(workout))
                } else {
                    promise(.failure(NSError(domain: "HealthKitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to save workout"])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func saveRoute(workout: HKWorkout, locations: [CLLocation]) -> AnyPublisher<Bool, Error> {
        let routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        
        return Future<Bool, Error> { promise in
            routeBuilder.insertRouteData(locations) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else if success {
                    routeBuilder.finishRoute(with: workout, metadata: nil) { route, error in
                        if let error = error {
                            promise(.failure(error))
                        } else if route != nil {
                            promise(.success(true))
                        } else {
                            promise(.failure(NSError(domain: "HealthKitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to finish route"])))
                        }
                    }
                } else {
                    promise(.failure(NSError(domain: "HealthKitAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert route data"])))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - Combined Operations
    
    public func fetchActivityData(date: Date) -> AnyPublisher<ActivityData, Error> {
        Publishers.CombineLatest4(
            fetchMonthlyCumulative(id: .stepCount, unit: .count(), date: date),
            fetchMonthlyCumulative(id: .distanceWalkingRunning, unit: .meter(), date: date),
            fetchMonthlyCumulative(id: .activeEnergyBurned, unit: .kilocalorie(), date: date),
            fetchLatestHeartRate()
        )
        .combineLatest(fetchMonthlyWorkouts(for: date))
        .map { (cumulativeData, workouts) in
            let (steps, distance, calories, heartRate) = cumulativeData
            return ActivityData(
                date: date,
                steps: steps,
                distance: distance,
                calories: calories,
                heartRate: heartRate,
                workouts: workouts
            )
        }
        .eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
}

// MARK: - Supporting Types

public struct ActivityData {
    public let date: Date
    public let steps: [HKStatisticsCollection.DayData]
    public let distance: [HKStatisticsCollection.DayData]
    public let calories: [HKStatisticsCollection.DayData]
    public let heartRate: Double?
    public let workouts: [Workout]
}

public struct Workout {
    public let id: UUID
    public let date: Date
    public let duration: TimeInterval
    public let distance: Double
    public let totalEnergyBurned: Double
    public let avgHeartRate: Double?
    public let avgPace: Double?
    public let activityType: HKWorkoutActivityType
    public let sourceName: String
    public let route: [CLLocation]
}

// MARK: - Extensions

extension HKStatisticsCollection {
    public struct DayData {
        public let date: Date
        public let value: Double
    }
    
    func toDayData(unit: HKUnit) -> [DayData] {
        var dayData: [DayData] = []
        
        self.enumerateStatistics(from: self.statistics().first?.startDate ?? Date(), to: Date()) { (statistics: HKStatistics, stop: UnsafeMutablePointer<ObjCBool>) in
            if let sum = statistics.sumQuantity() {
                let value = sum.doubleValue(for: unit)
                dayData.append(DayData(date: statistics.startDate, value: value))
            }
        }
        
        return dayData
    }
}
