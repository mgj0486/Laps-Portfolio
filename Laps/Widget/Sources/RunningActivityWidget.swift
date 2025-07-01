//
//  RunningActivityWidget.swift
//  Widget
//
//  Created by Assistant on 2025/06/22.
//

import WidgetKit
import SwiftUI
import ActivityKit
import Core

struct RunningActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RunningActivityAttributes.self) { context in
            // Lock Screen/Banner UI (appears on the lock screen and as a banner on the home screen)
            RunningLockScreenView(context: context)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI (when Dynamic Island is expanded)
                DynamicIslandExpandedRegion(.leading) {
                    Label("러닝", systemImage: "figure.run")
                        .font(.caption)
                        .foregroundColor(Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)))
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.formattedDuration)
                        .font(.system(size: 24, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                DynamicIslandExpandedRegion(.center) {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("거리")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(context.state.formattedDistance)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("페이스")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(context.state.formattedPace)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Empty
                }
            } compactLeading: {
                // Compact leading content (small Dynamic Island)
                Image(systemName: "figure.run")
                    .font(.caption)
                    .foregroundColor(Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)))
            } compactTrailing: {
                // Compact trailing content (small Dynamic Island)
                Text(context.state.formattedDuration)
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(.white)
            } minimal: {
                // Minimal view (appears in the Dynamic Island when there are multiple activities)
                Image(systemName: "figure.run")
                    .font(.caption2)
                    .foregroundColor(Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)))
            }
            .widgetURL(URL(string: "laps://running"))
            .keylineTint(Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)))
        }
    }
}

// Lock Screen View
struct RunningLockScreenView: View {
    let context: ActivityViewContext<RunningActivityAttributes>
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "figure.run")
                        .foregroundColor(Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)))
                    Text("러닝 중")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("시간")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(context.state.formattedDuration)
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("거리")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(context.state.formattedDistance)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("페이스")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(context.state.formattedPace)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
    }
}
