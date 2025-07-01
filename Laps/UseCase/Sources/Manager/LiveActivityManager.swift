//
//  LiveActivityManager.swift
//  UseCase
//
//  Created by Assistant on 2025/06/22.
//

import Foundation
import ActivityKit
import Core

public class LiveActivityManager {
    public static let shared = LiveActivityManager()
    private var runningActivity: Activity<RunningActivityAttributes>?
    
    private init() {}
    
    public func startRunningActivity(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }
        
        let attributes = RunningActivityAttributes(startDate: startDate)
        let initialState = RunningActivityAttributes.ContentState(
            duration: 0,
            distance: 0,
            pace: 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            self.runningActivity = activity
            print("Started Live Activity: \(activity.id)")
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }
    
    public func updateRunningActivity(duration: TimeInterval, distance: Double) {
        guard let activity = runningActivity else { return }
        
        let pace = distance > 0 ? (duration / 60) / (distance / 1000) : 0
        let updatedState = RunningActivityAttributes.ContentState(
            duration: duration,
            distance: distance,
            pace: pace
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    public func endRunningActivity() {
        guard let activity = runningActivity else { return }
        
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            self.runningActivity = nil
            print("Ended Live Activity")
        }
    }
}