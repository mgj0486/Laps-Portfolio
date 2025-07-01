//
//  SampleState.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation

// MARK: - State
struct SampleState: Equatable {
    var items: [SampleItem]
    var isLoading: Bool
    var error: SampleError?
    
    init(
        items: [SampleItem] = [],
        isLoading: Bool = false,
        error: SampleError? = nil
    ) {
        self.items = items
        self.isLoading = isLoading
        self.error = error
    }
}

// MARK: - Action
enum SampleAction: Equatable {
    case loadData
    case dataLoaded([SampleItem])
    case loadDataFailed(SampleError)
    case retry
    case toggleItem(SampleItem)
    case deleteItem(SampleItem)
}

// MARK: - Models
struct SampleItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let isCompleted: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isCompleted = isCompleted
    }
}

// MARK: - Extensions
extension SampleItem {
    func toggleCompletion() -> SampleItem {
        SampleItem(
            id: id,
            title: title,
            createdAt: createdAt,
            updatedAt: Date(),
            isCompleted: !isCompleted
        )
    }
    
    func updateTitle(_ newTitle: String) -> SampleItem {
        SampleItem(
            id: id,
            title: newTitle,
            createdAt: createdAt,
            updatedAt: Date(),
            isCompleted: isCompleted
        )
    }
}

// MARK: - Errors
enum SampleError: LocalizedError, Equatable {
    case dataNotFound
    case invalidData
    case networkError(String)
    case persistenceError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "No data found"
        case .invalidData:
            return "Invalid data format"
        case .networkError(let message):
            return "Network error: \(message)"
        case .persistenceError(let message):
            return "Storage error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataNotFound:
            return "Try refreshing the data"
        case .invalidData:
            return "Please contact support if this persists"
        case .networkError:
            return "Check your internet connection and try again"
        case .persistenceError:
            return "Try restarting the app"
        case .unknown:
            return "Please try again later"
        }
    }
}