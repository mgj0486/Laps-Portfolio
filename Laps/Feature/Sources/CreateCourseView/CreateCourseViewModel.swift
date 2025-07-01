//
//  CreateCourseViewModel.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import SwiftUI
import Combine
import CoreData
import Core
import CoreLocation

class CreateCourseViewModel: ObservableObject {
    @Published var courseData: CreateCourseData
    @Published var state: State = .idle
    @Published var showingSaveAlert = false
    @Published var isDetectingPattern = false
    
    private let context: NSManagedObjectContext
    private var bag = Set<AnyCancellable>()
    
    init(workout: WorkoutData, context: NSManagedObjectContext) {
        self.courseData = CreateCourseData(workout: workout)
        self.context = context
        detectPatternIfNeeded()
    }
    
    enum State: Equatable {
        case idle
        case saving
        case saved
        case error(String)
    }
    
    func saveCourse() {
        guard courseData.isValid else {
            state = .error("코스 이름을 입력해주세요")
            showingSaveAlert = true
            return
        }
        
        state = .saving
        
        CoreDataSaveModelPublisher(
            action: { [weak self] in
                guard let self = self else { return }
                
                let track = Track(context: self.context)
                track.id = UUID()
                track.createdate = Date()
                track.name = self.courseData.name
                
                // If pattern mode is enabled, save distance for one lap
                if self.courseData.usePatternMode, let pattern = self.courseData.detectedPattern {
                    track.distance = self.courseData.workout.totalDistance / Double(pattern.repetitions)
                } else {
                    track.distance = self.courseData.workout.totalDistance
                }
                
                // Set center coordinate
                if let center = self.courseData.centerCoordinate {
                    track.centerLatitude = center.latitude
                    track.centerLongitude = center.longitude
                }
                
                // Encode route using polyline encoding
                track.route = self.courseData.patternCoordinates.encodePolyline()
                
                // Store pattern info if detected
                if self.courseData.usePatternMode, let pattern = self.courseData.detectedPattern {
                    track.setValue(Int32(pattern.repetitions), forKey: "repetitions")
                } else {
                    track.setValue(Int32(1), forKey: "repetitions")
                }
            },
            context: context
        )
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .error(error.localizedDescription)
                    self?.showingSaveAlert = true
                }
            },
            receiveValue: { [weak self] success in
                if success {
                    self?.state = .saved
                    self?.showingSaveAlert = true
                    // Notify that a new course has been created
                    NotificationCenter.default.post(name: .newCourseCreated, object: nil)
                } else {
                    self?.state = .error("알 수 없는 오류가 발생했습니다")
                    self?.showingSaveAlert = true
                }
            }
        )
        .store(in: &bag)
    }
    
    var alertMessage: String {
        switch state {
        case .saved:
            return "코스가 성공적으로 저장되었습니다."
        case .error(let message):
            return message
        default:
            return ""
        }
    }
    
    func detectPatternIfNeeded() {
        guard courseData.coordinates.count > 100 else { return }
        
        isDetectingPattern = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.courseData.detectPattern()
            
            DispatchQueue.main.async {
                self?.isDetectingPattern = false
                self?.objectWillChange.send()
            }
        }
    }
    
    func togglePatternMode() {
        courseData.usePatternMode.toggle()
    }
}
