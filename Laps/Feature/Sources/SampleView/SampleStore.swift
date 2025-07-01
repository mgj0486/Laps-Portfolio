//
//  SampleStore.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import Combine
import Core

// MARK: - Store Protocol
protocol SampleStoreProtocol: ObservableObject {
    var state: SampleState { get }
    func send(_ action: SampleAction)
}

// MARK: - Store Implementation
final class SampleStore: SampleStoreProtocol {
    // MARK: - Properties
    @Published private(set) var state: SampleState
    
    private let environment: SampleEnvironment
    private var cancellables = Set<AnyCancellable>()
    private let input = PassthroughSubject<SampleAction, Never>()
    
    // MARK: - Initialization
    init(
        initialState: SampleState = SampleState(),
        environment: SampleEnvironment
    ) {
        self.state = initialState
        self.environment = environment
        
        setupBindings()
        
        // Auto-load data on initialization
        send(.loadData)
    }
    
    // MARK: - Setup
    private func setupBindings() {
        Publishers.system(
            initial: state,
            reduce: Self.reducer,
            scheduler: DispatchQueue.main,
            feedbacks: [
                Self.whenLoading(environment: environment),
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func send(_ action: SampleAction) {
        input.send(action)
    }
}

// MARK: - Reducer
extension SampleStore {
    static func reducer(_ state: SampleState, _ action: SampleAction) -> SampleState {
        var newState = state
        
        switch action {
        case .loadData:
            newState.isLoading = true
            newState.error = nil
            
        case .dataLoaded(let items):
            newState.items = items
            newState.isLoading = false
            newState.error = nil
            
        case .loadDataFailed(let error):
            newState.error = error
            newState.isLoading = false
            
        case .retry:
            newState.isLoading = true
            newState.error = nil
            
        case .toggleItem(let item):
            if let index = newState.items.firstIndex(where: { $0.id == item.id }) {
                newState.items[index] = item.toggleCompletion()
            }
            
        case .deleteItem(let item):
            newState.items.removeAll { $0.id == item.id }
        }
        
        return newState
    }
}

// MARK: - Feedbacks
extension SampleStore {
    static func userInput(input: AnyPublisher<SampleAction, Never>) -> Feedback<SampleState, SampleAction> {
        Feedback { _ in input }
    }
    
    static func whenLoading(environment: SampleEnvironment) -> Feedback<SampleState, SampleAction> {
        Feedback { (state: SampleState) -> AnyPublisher<SampleAction, Never> in
            guard state.isLoading else {
                return Empty().eraseToAnyPublisher()
            }
            
            return environment.sampleService.fetchItems()
                .map(SampleAction.dataLoaded)
                .catch { error in
                    Just(SampleAction.loadDataFailed(error))
                }
                .eraseToAnyPublisher()
        }
    }
}