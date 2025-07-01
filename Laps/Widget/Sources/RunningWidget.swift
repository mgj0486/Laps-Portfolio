//
//  test.swift
//  test
//
//  Created by Moon kyu Jung on 3/8/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import WidgetKit
import SwiftUI
import Feature
import Usecase
import Core
import Charts
import AppIntents

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [WidgetEntry] = []
        let entry = WidgetEntry(date: Date())
        entries = [entry]
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
}


struct RunningEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.6),
                    Color(red: 0.3, green: 0.5, blue: 0.7)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                Image(systemName: "figure.run")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Start Running")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .widgetURL(URL(string: "mylaps://start-running"))
    }
}

struct RunningWidget: Widget {
    let kind: String = "Running"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                RunningEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                RunningEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("MyLaps 러닝")
        .description("탭하여 러닝을 바로 시작합니다.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
//        .widgetAccentable(false)
    }
}

#Preview(as: .systemSmall) {
    RunningWidget()
} timeline: {
    WidgetEntry(date: Date())
}
