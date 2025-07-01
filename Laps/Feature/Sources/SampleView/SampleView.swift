//
//  SampleView.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/20/25.
//  Copyright © 2025 personal. All rights reserved.
//

import SwiftUI
import UserInterface

struct SampleView: View {
    @ObservedObject var store: SampleStore
    
    init(store: SampleStore) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("Sample")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { store.send(.loadData) }) {
                            Image(systemName: "arrow.clockwise")
                        }
                        .disabled(store.state.isLoading)
                    }
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch (store.state.isLoading, store.state.error) {
        case (true, _):
            loadingView
        case (false, .some(let error)):
            errorView(error)
        case (false, .none):
            itemsListView
        }
    }
    
    private var loadingView: some View {
        ProgressView("Loading...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: SampleError) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                store.send(.retry)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var itemsListView: some View {
        Group {
            if store.state.items.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(store.state.items) { item in
                        itemRow(item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            store.send(.deleteItem(store.state.items[index]))
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Items",
            systemImage: "tray",
            description: Text("Your list is empty")
        )
    }
    
    private func itemRow(_ item: SampleItem) -> some View {
        HStack {
            Button(action: {
                store.send(.toggleItem(item))
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .gray)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                
                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
struct SampleView_Previews: PreviewProvider {
    static var previews: some View {
        SampleFeature.createPreview()
    }
}