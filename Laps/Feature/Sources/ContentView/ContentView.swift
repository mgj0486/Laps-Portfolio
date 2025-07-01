//
//  ContentView.swift
//  Feature
//
//  Created by Moon kyu Jung on 3/8/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import SwiftUI
import CoreData
import Core

public struct ContentView: View {
    public init(context: NSManagedObjectContext?) {
        self.viewModel = ContentViewModel(context: context)
    }
    
    @ObservedObject private var viewModel: ContentViewModel
    @State private var refreshID = UUID()
    
    public var body: some View {
        RunningView(context: viewModel.context) { state in
            switch state {
            case .running:
                viewModel.send(event: .runningStateChanged(true))
            default:
                viewModel.send(event: .runningStateChanged(false))
            }
        }
        .id(refreshID)
    }
}

#Preview {
    ContentView(context: nil)
}
