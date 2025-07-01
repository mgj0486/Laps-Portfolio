//
//  ContentModel.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import Foundation

enum ContentError: LocalizedError, Equatable {
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .unknown:
            return "An unknown error occurred"
        }
    }
}