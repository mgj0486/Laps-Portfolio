//
//  SampleEnvironment.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import CoreData
import Combine

// MARK: - Environment
struct SampleEnvironment {
    let sampleService: SampleServiceProtocol
    let mainQueue: AnySchedulerOf<DispatchQueue>
    
    init(
        sampleService: SampleServiceProtocol,
        mainQueue: AnySchedulerOf<DispatchQueue> = .main
    ) {
        self.sampleService = sampleService
        self.mainQueue = mainQueue
    }
}

// MARK: - Service Protocol
protocol SampleServiceProtocol {
    func fetchItems() -> AnyPublisher<[SampleItem], SampleError>
    func saveItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError>
    func deleteItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError>
}

// MARK: - Service Implementation
final class SampleService: SampleServiceProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetchItems() -> AnyPublisher<[SampleItem], SampleError> {
        Future<[SampleItem], SampleError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.dataNotFound))
                return
            }
            
            // Simulate async data loading
            // In a real app, this would fetch from CoreData
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                // Mock data - replace with actual CoreData fetch
                let mockItems = [
                    SampleItem(title: "First Item"),
                    SampleItem(title: "Second Item"),
                    SampleItem(title: "Third Item"),
                    SampleItem(title: "Fourth Item"),
                    SampleItem(title: "Fifth Item")
                ]
                promise(.success(mockItems))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func saveItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError> {
        Future<Void, SampleError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.dataNotFound))
                return
            }
            
            // TODO: Implement CoreData save logic
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
    
    func deleteItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError> {
        Future<Void, SampleError> { [weak self] promise in
            guard let self = self else {
                promise(.failure(.dataNotFound))
                return
            }
            
            // TODO: Implement CoreData delete logic
            promise(.success(()))
        }
        .eraseToAnyPublisher()
    }
}

// MARK: - Mock Service for Testing
final class MockSampleService: SampleServiceProtocol {
    var fetchItemsResult: Result<[SampleItem], SampleError> = .success([])
    var saveItemResult: Result<Void, SampleError> = .success(())
    var deleteItemResult: Result<Void, SampleError> = .success(())
    
    func fetchItems() -> AnyPublisher<[SampleItem], SampleError> {
        fetchItemsResult.publisher.eraseToAnyPublisher()
    }
    
    func saveItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError> {
        saveItemResult.publisher.eraseToAnyPublisher()
    }
    
    func deleteItem(_ item: SampleItem) -> AnyPublisher<Void, SampleError> {
        deleteItemResult.publisher.eraseToAnyPublisher()
    }
}

// MARK: - Environment Extensions
extension SampleEnvironment {
    static func live(context: NSManagedObjectContext) -> SampleEnvironment {
        SampleEnvironment(
            sampleService: SampleService(context: context),
            mainQueue: .main
        )
    }
    
    static var mock: SampleEnvironment {
        SampleEnvironment(
            sampleService: MockSampleService(),
            mainQueue: .main
        )
    }
}

// MARK: - Scheduler Type (for TCA compatibility)
struct AnySchedulerOf<Scheduler: Combine.Scheduler> {
    private let _now: () -> Scheduler.SchedulerTimeType
    private let _minimumTolerance: () -> Scheduler.SchedulerTimeType.Stride
    private let _schedule: (Scheduler.SchedulerOptions?, @escaping () -> Void) -> Void
    
    static var main: AnySchedulerOf<DispatchQueue> {
        AnySchedulerOf<DispatchQueue>(
            DispatchQueue.main
        )
    }
    
    init(_ scheduler: Scheduler) {
        self._now = { scheduler.now }
        self._minimumTolerance = { scheduler.minimumTolerance }
        self._schedule = scheduler.schedule
    }
}