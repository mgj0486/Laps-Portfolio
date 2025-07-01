//
//  ContentViewModel.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation
import CoreData
import Combine
import Core

class ContentViewModel: ObservableObject {
    init(context: NSManagedObjectContext? = nil) {
        self.context = context
        
        Publishers.system(
            initial: state,
            reduce: Self.reduce,
            scheduler: RunLoop.main,
            feedbacks: [
                Self.userInput(input: input.eraseToAnyPublisher())
            ]
        )
        .assign(to: \.state, on: self)
        .store(in: &bag)
    }
    
    let context: NSManagedObjectContext?
    
    @Published private(set) var state: State = .idle() {
        didSet {
            print("ContentView", state)
        }
    }
    
    private var bag = Set<AnyCancellable>()
    private let input = PassthroughSubject<Event, Never>()
    
    deinit {
        bag.removeAll()
    }
    
    func send(event: Event) {
        input.send(event)
    }
}

extension ContentViewModel {
    enum State: Equatable {
        case idle(showActivityView: Bool = false, isRunning: Bool = false)
    }
    
    enum Event {
        case toggleActivityView
        case hideActivityView
        case runningStateChanged(Bool)
    }
}

extension ContentViewModel {
    static func reduce(_ state: State, _ event: Event) -> State {
        switch state {
        case .idle(let showActivityView, let isRunning):
            switch event {
            case .toggleActivityView:
                return .idle(showActivityView: !showActivityView, isRunning: isRunning)
            case .hideActivityView:
                return .idle(showActivityView: false, isRunning: isRunning)
            case .runningStateChanged(let running):
                return .idle(showActivityView: showActivityView, isRunning: running)
            }
        }
    }
    
    static func userInput(input: AnyPublisher<Event, Never>) -> Feedback<State, Event> {
        Feedback { _ in input }
    }
}

// Computed properties for easy access
extension ContentViewModel {
    var showActivityView: Bool {
        if case .idle(let show, _) = state {
            return show
        }
        return false
    }
    
    var isRunning: Bool {
        if case .idle(_, let running) = state {
            return running
        }
        return false
    }
}
