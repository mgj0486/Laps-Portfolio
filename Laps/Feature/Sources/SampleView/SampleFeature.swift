//
//  SampleFeature.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import SwiftUI
import CoreData

// MARK: - Feature
struct SampleFeature {
    let store: SampleStore
    let view: SampleView
    
    init(context: NSManagedObjectContext) {
        let environment = SampleEnvironment.live(context: context)
        self.store = SampleStore(environment: environment)
        self.view = SampleView(store: store)
    }
}

// MARK: - Feature Factory
extension SampleFeature {
    static func create(
        context: NSManagedObjectContext? = nil,
        environment: SampleEnvironment? = nil
    ) -> SampleView {
        let env = environment ?? {
            if let context = context {
                return SampleEnvironment(
                    sampleService: SampleService(context: context)
                )
            } else {
                fatalError("Context is required for live environment")
            }
        }()
        
        let store = SampleStore(environment: env)
        return SampleView(store: store)
    }
    
    static func createPreview() -> SampleView {
        let mockService = MockSampleService()
        mockService.fetchItemsResult = .success([
            SampleItem(title: "Preview Item 1", isCompleted: true),
            SampleItem(title: "Preview Item 2"),
            SampleItem(title: "Preview Item 3")
        ])
        
        let environment = SampleEnvironment(
            sampleService: mockService
        )
        
        let store = SampleStore(environment: environment)
        return SampleView(store: store)
    }
}

// MARK: - SwiftUI Environment Key
private struct SampleStoreKey: EnvironmentKey {
    static let defaultValue: SampleStore? = nil
}

extension EnvironmentValues {
    var sampleStore: SampleStore? {
        get { self[SampleStoreKey.self] }
        set { self[SampleStoreKey.self] = newValue }
    }
}