//
//  NotificationExtensions.swift
//  Core
//
//  Created by Moon kyu Jung on 6/26/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import Foundation

public extension Notification.Name {
    static let newCourseCreated = Notification.Name("newCourseCreated")
    static let startRunningFromSiri = Notification.Name("startRunningFromSiri")
    static let stopRunningFromSiri = Notification.Name("stopRunningFromSiri")
}
