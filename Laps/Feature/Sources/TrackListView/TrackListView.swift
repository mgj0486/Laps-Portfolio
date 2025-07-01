//
//  TrackListView.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import SwiftUI
import CoreData
import UserInterface
import Core
import MapKit

struct TrackListView: View {
    @StateObject private var viewModel: TrackListViewModel
    @State private var trackToDelete: TrackItem?
    @State private var showingDeleteAlert = false
    
    init(context: NSManagedObjectContext) {
        self._viewModel = StateObject(wrappedValue: TrackListViewModel(context: context))
    }
    
    var body: some View {
        
        content()
            .onAppear {
                viewModel.send(event: .loadTracks)
            }
            .alert("코스 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    if let track = trackToDelete {
                        viewModel.send(event: .deleteTrack(track))
                    }
                }
            } message: {
                Text("\"\(trackToDelete?.name ?? "")\" 코스를 삭제하시겠습니까?")
            }
    }
    
    @ViewBuilder
    func content() -> some View {
        switch viewModel.state {
        case .idle:
            Color.clear
                .onAppear {
                    viewModel.send(event: .loadTracks)
                }
            
        case .loading:
            ProgressView("코스 목록을 불러오는 중...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
        case .loaded(let data):
            if data.tracks.isEmpty {
                emptyStateView()
            } else {
                trackListView(data.tracks)
            }
            
        case .error(let error):
            ContentUnavailableView {
                Label("오류", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("다시 시도") {
                    viewModel.send(event: .retry)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    @ViewBuilder
    func trackListView(_ tracks: [TrackItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(tracks) { track in
                    trackRow(track)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color.adaptiveBackground)
    }
    
    @ViewBuilder
    func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "map.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("저장된 코스가 없습니다")
                .font(.title3)
                .foregroundColor(.primary)
            
            Text("운동 기록에서 코스를 생성해보세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.adaptiveBackground)
    }
    
    // MARK: - Track Row (Similar to WorkoutRow)
    @ViewBuilder
    func trackRow(_ track: TrackItem) -> some View {
        VStack(spacing: 0) {
            // Map on top if route exists
            if let decodedRoute = track.encodedRoute.decodePolyline(),
               !decodedRoute.isEmpty {
                ZStack(alignment: .bottom) {
                    RouteMapView(coordinates: decodedRoute)
                        .frame(height: 200)
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.black.opacity(0.2)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
            }
            
            // Track info integrated with the card
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(track.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(primaryTextColor)
                    
                    Spacer()
                    
                    Text(track.formattedDate)
                        .font(.system(size: 12))
                        .foregroundColor(secondaryTextColor)
                }
                
                HStack(spacing: 16) {
                    Label(track.formattedDistance, systemImage: "ruler")
                        .font(.system(size: 13))
                        .foregroundColor(secondaryTextColor)
                    
                    Spacer()
                    
                    // Delete button
                    Menu {
                        Button(role: .destructive) {
                            self.trackToDelete = track
                            self.showingDeleteAlert = true
                        } label: {
                            Label("삭제", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundColor(secondaryTextColor)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding()
        }
        .background(cardBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(cardBorderColor, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
    
    // MARK: - Color Properties
    private var cardBackgroundColor: Color {
        Color.adaptiveCardBackground
    }
    
    private var cardBorderColor: Color {
        Color.adaptiveCardBorder
    }
    
    private var primaryTextColor: Color {
        Color.adaptivePrimaryTextAlt
    }
    
    private var secondaryTextColor: Color {
        Color.adaptiveSecondaryText
    }
}

