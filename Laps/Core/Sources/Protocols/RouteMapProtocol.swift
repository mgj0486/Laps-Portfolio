//
//  RouteMapProtocol.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import SwiftUI

public protocol RouteCoordinate {
    var latitude: Double { get }
    var longitude: Double { get }
}

public protocol RouteMapViewProtocol: View {
    init(coordinates: [RouteCoordinate])
}
