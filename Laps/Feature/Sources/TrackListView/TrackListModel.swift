//
//  TrackListModel.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import Foundation
import CoreLocation

struct TrackListData: Equatable {
    let tracks: [TrackItem]
}

struct TrackItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let createdDate: Date
    let distance: Double
    let centerCoordinate: CLLocationCoordinate2D
    let encodedRoute: String
    
    static func == (lhs: TrackItem, rhs: TrackItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.createdDate == rhs.createdDate &&
        lhs.distance == rhs.distance &&
        lhs.centerCoordinate.latitude == rhs.centerCoordinate.latitude &&
        lhs.centerCoordinate.longitude == rhs.centerCoordinate.longitude &&
        lhs.encodedRoute == rhs.encodedRoute
    }
    
    var formattedDistance: String {
        String(format: "%.2f km", distance / 1000)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: createdDate)
    }
}

enum TrackListError: LocalizedError, Equatable {
    case fetchFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "트랙 목록을 불러올 수 없습니다: \(message)"
        case .deleteFailed(let message):
            return "트랙 삭제 실패: \(message)"
        }
    }
}