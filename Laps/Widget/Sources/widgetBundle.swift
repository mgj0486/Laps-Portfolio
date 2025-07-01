//
//  testBundle.swift
//  test
//
//  Created by Moon kyu Jung on 3/8/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import WidgetKit
import SwiftUI

@main
struct widgetBundle: WidgetBundle {
    var body: some Widget {
        RunningWidget()
        RunningActivityWidget()
    }
}

//@main
//struct RunningActivityWidgetBundle: WidgetBundle {
//    var body: some Widget {
//            }
//}
