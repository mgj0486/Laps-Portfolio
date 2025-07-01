//
//  RunningViewModel.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/18/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import HealthKit
import CoreLocation
import CoreData
import Combine
import Core
import Usecase
import UserInterface
import ActivityKit

class RunningViewModel: NSObject, ObservableObject {
    init(context: NSManagedObjectContext? = nil) {
        self.context = context
        self.healthKitAPI = HealthKitAPI()
        self.locationManager = CLLocationManager()
        super.init()
        
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.headingFilter = 5.0 // Update heading when change is > 5 degrees
        
        // Load all tracks on init
        if let context = context {
            DispatchQueue.global(qos: .utility).async { [weak self] in
                let tracks = RunningMapView.fetchAllTracks(context: context)
                print("Initial load: Found \(tracks.count) total tracks")
                DispatchQueue.main.async {
                    self?.allTracks = tracks
                }
            }
        }
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.locationTracking(locationManager: locationManager),
                Self.processing(healthKitAPI: healthKitAPI, locationManager: locationManager),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }
    
    let context: NSManagedObjectContext?
    private let healthKitAPI: HealthKitAPI
    private let locationManager: CLLocationManager

    
    @Published private(set) var state: State = .idle() {
        didSet {
            print("RunningView", state)
        }
    }
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: CLHeading?
    @Published var allTracks: [RunningMapView.TrackMapItem] = []
    @Published var nearbyTrackForStart: RunningMapView.TrackMapItem?
    
    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()
    private var timer: Timer?
    private let minimumDistanceThreshold: Double = 100.0
    private let trackProximityThreshold: Double = 10.0 // 10 meters from track start
    private let lapProximityThreshold: Double = 20.0 // 20 meters from start point for lap detection
    private let maximumRunningSpeed: Double = 30.0 // 30 km/h (약 8.33 m/s) - 엘리트 러너도 이 속도를 지속하기 어려움
    private var hasCheckedNearbyTrack = false
    private var declinedTrackIds: Set<UUID> = []
    private var speedViolationCount = 0
    private var hasPassedStartPoint = false // To track if runner has left start point
    private var lastLapTime: Date?
    
    deinit {
        bag.removeAll()
        timer?.invalidate()
    }
    
    func send(event: Event) {
        print("RunningViewModel received event: \(event)")
        
        // Reset speed violation count and lap tracking when starting a new run
        if case .startRun = event {
            speedViolationCount = 0
            hasPassedStartPoint = false
            lastLapTime = nil
        }
        if case .startButtonTapped = event {
            speedViolationCount = 0
            hasPassedStartPoint = false
            lastLapTime = nil
        }
        
        input.send(event)
    }

}

extension RunningViewModel {
    enum State: Equatable, Hashable {
        case idle(data: RunningData? = nil)
        case permissionsRequested
        case running(data: RunningData)
        case saving(data: RunningData)
        case error(RunningError)
    }
    
    enum Event {
        case requestPermissions
        case permissionsGranted
        case permissionsDenied
        case startRun
        case startButtonTapped(track: RunningMapView.TrackMapItem?)
        case runStarted(Date)
        case stopRun
        case updateLocation([CLLocation])
        case updateDuration
        case savingWorkout
        case workoutSaved
        case saveFailed(RunningError)
        case retry
        case speedViolationDetected
        case lapCompleted
    }
}

extension RunningViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle:
            switch event {
            case .requestPermissions:
                return .permissionsRequested
            case .startRun:
                let startDate = Date()
                // Start Live Activity
                LiveActivityManager.shared.startRunningActivity(startDate: startDate)
                return .running(data: RunningData(startDate: startDate))
            case .startButtonTapped(let track):
                let startDate = Date()
                // Start Live Activity
                LiveActivityManager.shared.startRunningActivity(startDate: startDate)
                return .running(data: RunningData(startDate: startDate, trackId: track?.id))
            default:
                return state
            }
        case .permissionsRequested:
            switch event {
            case .permissionsGranted:
                return .idle()
            case .permissionsDenied:
                return .error(.authorizationDenied)
            default:
                return state
            }
        case .running(let data):
            switch event {
            case .updateLocation(let locations):
                var newData = data
                var distance = data.distance
                var runningLocations = data.locations
                
                for location in locations {
                    if let lastLocation = runningLocations.last {
                        let lastCLLocation = CLLocation(
                            latitude: lastLocation.coordinate.latitude,
                            longitude: lastLocation.coordinate.longitude
                        )
                        distance += location.distance(from: lastCLLocation)
                    }
                    runningLocations.append(RunningLocation(from: location))
                }
                
                // Update Live Activity with new distance
                LiveActivityManager.shared.updateRunningActivity(
                    duration: data.duration,
                    distance: distance
                )
                return .running(data: RunningData(
                    id: data.id,
                    startDate: data.startDate,
                    distance: distance,
                    duration: data.duration,
                    locations: runningLocations,
                    trackId: data.trackId,
                    lapCount: data.lapCount
                ))
            case .updateDuration:
                let currentDuration = Date().timeIntervalSince(data.startDate)
                // Update Live Activity
                LiveActivityManager.shared.updateRunningActivity(
                    duration: currentDuration,
                    distance: data.distance
                )
                return .running(data: RunningData(
                    id: data.id,
                    startDate: data.startDate,
                    distance: data.distance,
                    duration: currentDuration,
                    locations: data.locations,
                    trackId: data.trackId,
                    lapCount: data.lapCount
                ))
            case .lapCompleted:
                return .running(data: RunningData(
                    id: data.id,
                    startDate: data.startDate,
                    distance: data.distance,
                    duration: data.duration,
                    locations: data.locations,
                    trackId: data.trackId,
                    lapCount: data.lapCount + 1
                ))
            case .stopRun:
                return .saving(data: data)
            case .speedViolationDetected:
                // 속도 위반 시 에러 상태로 전환 (저장하지 않음)
                LiveActivityManager.shared.endRunningActivity()
                return .error(.speedViolation)
            default:
                return state
            }
        case .saving:
            switch event {
            case .workoutSaved:
                return .idle()
            case .saveFailed(let error):
                return .error(error)
            default:
                return state
            }
        case .error:
            switch event {
            case .retry:
                return .idle()
            case .requestPermissions:
                return .permissionsRequested
            default:
                return state
            }
        }
    }

    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }

    static func locationTracking(locationManager: CLLocationManager) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            switch state {
            case .running:
                return Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .map { _ in Event.updateDuration }
                    .eraseToAnyPublisher()
            default:
                return Empty().eraseToAnyPublisher()
            }
        }
    }

    static func processing(healthKitAPI: HealthKitAPI, locationManager: CLLocationManager) -> Feedback<State, Event> {
        Feedback { (state: State) -> AnyPublisher<Event, Never> in
            switch state {
            case .permissionsRequested:
                return requestPermissions(healthKitAPI: healthKitAPI, locationManager: locationManager)
            case .idle:
                // Always use high accuracy
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.distanceFilter = kCLDistanceFilterNone
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
                return Empty().eraseToAnyPublisher()
            case .running:
                // Use high accuracy when running
                locationManager.desiredAccuracy = kCLLocationAccuracyBest
                locationManager.distanceFilter = kCLDistanceFilterNone // Update for every movement
                locationManager.startUpdatingLocation()
                locationManager.startUpdatingHeading()
                return Empty().eraseToAnyPublisher()
            case .saving(let data):
                locationManager.stopUpdatingLocation()
                locationManager.stopUpdatingHeading()
                // End Live Activity
                LiveActivityManager.shared.endRunningActivity()
                if data.distance < 100.0 {
                    return Just(Event.saveFailed(.insufficientDistance))
                        .eraseToAnyPublisher()
                }
                return saveWorkout(healthKitAPI: healthKitAPI, data: data)
            default:
                return Empty().eraseToAnyPublisher()
            }
        }
    }

    private static func requestPermissions(healthKitAPI: HealthKitAPI, locationManager: CLLocationManager) -> AnyPublisher<Event, Never> {
        return healthKitAPI.requestWriteAuthorization()
            .map { success in
                locationManager.requestWhenInUseAuthorization()
                return success ? Event.permissionsGranted : Event.permissionsDenied
            }
            .catch { _ in
                Just(Event.permissionsDenied)
            }
            .eraseToAnyPublisher()
    }
    
    private static func saveWorkout(healthKitAPI: HealthKitAPI, data: RunningData) -> AnyPublisher<Event, Never> {
        let clLocations = data.locations.map { location in
            CLLocation(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        }
        
        return healthKitAPI.saveWorkout(duration: data.duration, distance: data.distance)
            .flatMap { workout in
                if !clLocations.isEmpty {
                    return healthKitAPI.saveRoute(workout: workout, locations: clLocations)
                        .map { _ in Event.workoutSaved }
                        .catch { _ in
                            Just(Event.saveFailed(.saveFailed("Failed to save route")))
                        }
                        .eraseToAnyPublisher()
                } else {
                    return Just(Event.workoutSaved)
                        .eraseToAnyPublisher()
                }
            }
            .catch { error in
                Just(Event.saveFailed(.saveFailed(error.localizedDescription)))
            }
            .eraseToAnyPublisher()
    }
}

extension RunningViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations newLocations: [CLLocation]) {
        // Update current location for map with filtering
        if let location = newLocations.last,
           location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 {
            // Only update if location is accurate enough
            currentLocation = location
            
            // Fetch all tracks if not already loaded
            if allTracks.isEmpty, let context = context {
                DispatchQueue.global(qos: .utility).async { [weak self] in
                    let tracks = RunningMapView.fetchAllTracks(context: context)
                    print("Found \(tracks.count) total tracks")
                    for track in tracks {
                        print("Track: \(track.name), route points: \(track.route.count)")
                    }
                    DispatchQueue.main.async {
                        self?.allTracks = tracks
                    }
                }
            }
            
            // Check proximity to track starts when idle
            if case .idle = state, !hasCheckedNearbyTrack {
                checkNearbyTrackStart(location: location)
            }
        }
        
        if case .running = state {
            // Check speed before updating location
            if let location = newLocations.last,
               location.speed > 0 { // speed is in m/s
                let speedKmh = location.speed * 3.6 // Convert to km/h
                
                if speedKmh > maximumRunningSpeed {
                    speedViolationCount += 1
                    print("Speed violation detected: \(speedKmh) km/h (count: \(speedViolationCount))")
                    
                    // 3번 연속 속도 위반 시 러닝 중단
                    if speedViolationCount >= 3 {
                        send(event: .speedViolationDetected)
                        return
                    }
                } else {
                    // Reset violation count if speed is normal
                    speedViolationCount = 0
                }
            }
            
            send(event: .updateLocation(newLocations))
            
            // Check for lap completion if running on a track
            if case .running(let data) = state,
               let trackId = data.trackId,
               let track = allTracks.first(where: { $0.id == trackId }),
               let location = newLocations.last,
               location.horizontalAccuracy > 0 && location.horizontalAccuracy < 50 {
                
                checkLapCompletion(currentLocation: location, track: track)
            }
        }
    }
    
    private func checkLapCompletion(currentLocation: CLLocation, track: RunningMapView.TrackMapItem) {
        guard let firstPoint = track.route.first else { return }
        
        let startLocation = CLLocation(
            latitude: firstPoint.latitude,
            longitude: firstPoint.longitude
        )
        
        let distanceFromStart = currentLocation.distance(from: startLocation)
        
        // Check if runner is at start point
        if distanceFromStart <= lapProximityThreshold {
            // If runner has left start point and comes back, it's a lap
            if hasPassedStartPoint {
                // Avoid counting multiple laps too quickly (minimum 30 seconds between laps)
                if let lastLapTime = lastLapTime,
                   Date().timeIntervalSince(lastLapTime) < 30 {
                    return
                }
                
                print("Lap completed! Distance from start: \(distanceFromStart)m")
                send(event: .lapCompleted)
                lastLapTime = Date()
                hasPassedStartPoint = false
            }
        } else if distanceFromStart > lapProximityThreshold * 2 {
            // Runner has left the start point area
            hasPassedStartPoint = true
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if case .permissionsRequested = state {
                send(event: .permissionsGranted)
            }
        case .denied, .restricted:
            if case .permissionsRequested = state {
                send(event: .permissionsDenied)
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Update heading if it's valid
        if newHeading.headingAccuracy >= 0 {
            currentHeading = newHeading
            print("Heading updated: \(newHeading.trueHeading) degrees")
        }
    }
    
    private func checkNearbyTrackStart(location: CLLocation) {
        // Check all tracks for proximity to their start points
        for track in allTracks {
            // Skip declined tracks
            if declinedTrackIds.contains(track.id) {
                continue
            }
            
            guard let firstPoint = track.route.first else { continue }
            
            let trackStartLocation = CLLocation(
                latitude: firstPoint.latitude,
                longitude: firstPoint.longitude
            )
            
            let distance = location.distance(from: trackStartLocation)
            
            if distance <= trackProximityThreshold {
                nearbyTrackForStart = track
                hasCheckedNearbyTrack = true
                print("Near track start: \(track.name) at \(distance)m")
                return
            }
        }
        
        // Reset if moved away from any track
        if nearbyTrackForStart != nil {
            nearbyTrackForStart = nil
            hasCheckedNearbyTrack = false
        }
    }
    
    func resetTrackProximityCheck() {
        hasCheckedNearbyTrack = false
        nearbyTrackForStart = nil
    }
    
    func declineTrackStart(trackId: UUID) {
        declinedTrackIds.insert(trackId)
        resetTrackProximityCheck()
    }
}

// Helper to fetch all tracks
extension RunningMapView {
    public static func fetchAllTracks(
        context: NSManagedObjectContext
    ) -> [TrackMapItem] {
        var results: [TrackMapItem] = []
        
        context.performAndWait {
            let fetchRequest: NSFetchRequest<Track> = Track.fetchRequest()
            // Fetch all tracks without distance filtering
            
            print("Fetching all tracks from database")
        
            do {
                let tracks = try context.fetch(fetchRequest)
                print("Found \(tracks.count) tracks in database")
                
                results = tracks.compactMap { track in
                    guard let id = track.id,
                          let name = track.name,
                          let encodedRoute = track.route else {
                        print("Track missing required fields")
                        return nil
                    }
                    
                    guard let decodedRoute = encodedRoute.decodePolyline() else {
                        print("Failed to decode route for track: \(name)")
                        return nil
                    }
                    
                    print("Track \(name): \(decodedRoute.count) points")
                    
                    // Calculate distance from route
                    let distance = track.distance // Use stored distance
                    
                    // Include all tracks
                    return TrackMapItem(
                        id: id,
                        name: name,
                        route: decodedRoute,
                        distance: distance
                    )
                }
            } catch {
                print("Error fetching nearby tracks: \(error)")
            }
        }
        
        return results
    }
}

