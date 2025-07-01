//
//  SampleStoreTests.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import XCTest
import Combine
@testable import Feature

final class SampleStoreTests: XCTestCase {
    var store: SampleStore!
    var mockService: MockSampleService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockSampleService()
        let environment = SampleEnvironment(sampleService: mockService)
        store = SampleStore(environment: environment)
        cancellables = []
    }
    
    override func tearDown() {
        store = nil
        mockService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(store.state.items, [])
        XCTAssertFalse(store.state.isLoading)
        XCTAssertNil(store.state.error)
    }
    
    func testLoadDataSuccess() {
        // Given
        let expectedItems = [
            SampleItem(title: "Test 1"),
            SampleItem(title: "Test 2")
        ]
        mockService.fetchItemsResult = .success(expectedItems)
        
        // When
        store.send(.loadData)
        
        // Then
        let expectation = XCTestExpectation(description: "State updated")
        
        store.$state
            .dropFirst()
            .sink { state in
                if !state.isLoading && state.items == expectedItems {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(store.state.items, expectedItems)
        XCTAssertFalse(store.state.isLoading)
        XCTAssertNil(store.state.error)
    }
    
    func testLoadDataFailure() {
        // Given
        let expectedError = SampleError.networkError("Test error")
        mockService.fetchItemsResult = .failure(expectedError)
        
        // When
        store.send(.loadData)
        
        // Then
        let expectation = XCTestExpectation(description: "State updated")
        
        store.$state
            .dropFirst()
            .sink { state in
                if !state.isLoading && state.error == expectedError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(store.state.error, expectedError)
        XCTAssertFalse(store.state.isLoading)
    }
    
    func testToggleItem() {
        // Given
        let item = SampleItem(title: "Test", isCompleted: false)
        store = SampleStore(
            initialState: SampleState(items: [item]),
            environment: SampleEnvironment(sampleService: mockService)
        )
        
        // When
        store.send(.toggleItem(item))
        
        // Then
        XCTAssertTrue(store.state.items.first?.isCompleted ?? false)
    }
    
    func testDeleteItem() {
        // Given
        let item1 = SampleItem(title: "Test 1")
        let item2 = SampleItem(title: "Test 2")
        store = SampleStore(
            initialState: SampleState(items: [item1, item2]),
            environment: SampleEnvironment(sampleService: mockService)
        )
        
        // When
        store.send(.deleteItem(item1))
        
        // Then
        XCTAssertEqual(store.state.items.count, 1)
        XCTAssertEqual(store.state.items.first?.title, "Test 2")
    }
    
    func testRetry() {
        // Given
        let expectedItems = [SampleItem(title: "Test")]
        mockService.fetchItemsResult = .success(expectedItems)
        store = SampleStore(
            initialState: SampleState(error: SampleError.unknown),
            environment: SampleEnvironment(sampleService: mockService)
        )
        
        // When
        store.send(.retry)
        
        // Then
        let expectation = XCTestExpectation(description: "State updated")
        
        store.$state
            .dropFirst()
            .sink { state in
                if !state.isLoading && state.items == expectedItems {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        wait(for: [expectation], timeout: 2.0)
        
        XCTAssertEqual(store.state.items, expectedItems)
        XCTAssertNil(store.state.error)
    }
}