//
//  RunningView.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/18/25.
//  Copyright © 2025 personal. All rights reserved.
//
import SwiftUI
import CoreData
import MapKit
import Core
import UserInterface
import CoreLocation

struct RunningView: View {
    init(context: NSManagedObjectContext? = nil, onStateChanged: ((RunningViewModel.State) -> Void)? = nil) {
        self._viewModel = StateObject(wrappedValue: RunningViewModel(context: context))
        self.onStateChanged = onStateChanged
    }
    
    @StateObject var viewModel: RunningViewModel
    private let onStateChanged: ((RunningViewModel.State) -> Void)?
    @State private var showActivityView = false
    @State private var showTrackListView = false
    @State private var isLongPressing = false
    @State private var longPressProgress: CGFloat = 0
    @State private var showStartAlert = false
    @State private var showTrackStartAlert = false
    @State private var longPressTimer: Timer?
    @State private var showToast = false
    @State private var showSiriStartAlert = false
    @State private var showMinimumDistanceAlert = false
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
        latitudinalMeters: 500,
        longitudinalMeters: 500
    )
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                // Background - similar to design sample
                Color.adaptiveBackground
                .ignoresSafeArea()
                
                // Main content
                content()
                
                // FABs
                VStack {
                    Spacer()
                    HStack(alignment: .bottom, spacing: 16) {
                        Spacer()
                        // TrackListView FAB
                        if let context = viewModel.context {
                            NavigationLink(destination: TrackListView(context: context)
                                .navigationTitle("내 코스")
                                .navigationBarTitleDisplayMode(.automatic)
                            ) {
                                Image(systemName: "map.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.adaptiveRedAccentAlt)
                                    .clipShape(Circle())
                                    .shadow(color: Color.fabShadow, radius: 4, x: 0, y: 2)
                            }
                            .disabled(isRunning)
                            .opacity(isRunning ? 0.5 : 1.0)
                        }
                        
                        // ActivityView FAB
                        NavigationLink(destination: ActivityView(context: viewModel.context)
                            .navigationTitle("활동 기록")
                            .navigationBarTitleDisplayMode(.automatic)
                        ) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.adaptiveBlueAccent)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .disabled(isRunning)
                        .opacity(isRunning ? 0.5 : 1.0)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.send(event: .requestPermissions)
                setupSiriNotifications()
            }
            .onChange(of: viewModel.state) { newState in
                onStateChanged?(newState)
                
                // Check for minimum distance error
                if case .error(let error) = newState,
                   case .insufficientDistance = error {
                    showMinimumDistanceAlert = true
                }
            }
            .onChange(of: scenePhase) { newPhase in
                if case .running = viewModel.state {
                    if newPhase == .active {
                        // App came to foreground, update duration
                        viewModel.send(event: .updateDuration)
                    }
                }
            }
            .onChange(of: viewModel.nearbyTrackForStart) { nearbyTrack in
                if nearbyTrack != nil && !isRunning {
                    showTrackStartAlert = true
                }
            }
            .overlay(
                // Toast overlay
                VStack {
                    if showToast {
                        Text("2초간 길게 눌러 종료")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.toastBackground)
                            .cornerRadius(20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.3), value: showToast)
                    }
                    Spacer()
                }
                .padding(.top, 50)
            )
        }
    }
    
    @ViewBuilder
    func content() -> some View {
        Group {
            switch viewModel.state {
            case .idle:
                idleView()
            case .permissionsRequested:
                ProgressView("권한 요청 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .running(let data):
                runningView(data)
            case .saving:
                ProgressView("운동 저장 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let error):
                if case .insufficientDistance = error {
                    idleView()
                } else {
                    errorView(error)
                }
            }
        }
    }
    
    @ViewBuilder
    func idleView() -> some View {
        ZStack {
            // Map background with vignette effect
            RunningMapView(
                currentLocation: viewModel.currentLocation,
                heading: viewModel.currentHeading,
                runningPath: [],
                nearbyTracks: viewModel.allTracks,
                region: $mapRegion
            )
            .ignoresSafeArea()
            .opacity(0.4)
            .overlay(
                VignetteOverlay(
                    isDarkMode: colorScheme == .dark,
                    intensity: 0.9
                )
            )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                Text("러닝")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color.adaptivePrimaryTextAlt)
            
            // Stats display
            VStack(spacing: 24) {
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("00:00")
                            .font(.system(size: 42, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.adaptivePrimaryText)
                        Text("시간")
                            .font(.system(size: 14))
                            .foregroundColor(Color.adaptiveSecondaryText)
                    }
                    
                    VStack(spacing: 8) {
                        Text("0.00")
                            .font(.system(size: 42, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.adaptivePrimaryText)
                        Text("거리 (km)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.adaptiveSecondaryText)
                    }
                }
            }
            .padding(.vertical, 40)
            
            Spacer()
            
            // Large play button
            Button(action: {
                showStartAlert = true
            }) {
                ZStack {
                    Circle()
                        .fill(Color.adaptiveGreenAccent)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .offset(x: 4) // Slight offset to center the play icon visually
                }
            }
            .shadow(color: Color.buttonShadow, radius: 8, x: 0, y: 4)
            .alert("기록 시작", isPresented: $showStartAlert) {
                Button("취소", role: .cancel) { }
                Button("시작", role: .none) {
                    viewModel.send(event: .startRun)
                }
            } message: {
                Text("러닝 기록을 시작하시겠습니까?")
            }
            .alert("코스 시작점 근처", isPresented: $showTrackStartAlert) {
                Button("취소", role: .cancel) {
                    // Mark this track as declined so we don't ask again
                    if let track = viewModel.nearbyTrackForStart {
                        viewModel.declineTrackStart(trackId: track.id)
                    }
                }
                Button("시작", role: .none) {
                    if let track = viewModel.nearbyTrackForStart {
                        viewModel.send(event: .startButtonTapped(track: track))
                    } else {
                        viewModel.send(event: .startRun)
                    }
                }
            } message: {
                if let track = viewModel.nearbyTrackForStart {
                    Text("'\(track.name)' 코스의 시작점 근처에 있습니다. 러닝을 시작하시겠습니까?")
                }
            }
            .alert("기록 시작", isPresented: $showSiriStartAlert) {
                Button("취소", role: .cancel) { }
                Button("시작", role: .none) {
                    viewModel.send(event: .startRun)
                }
            } message: {
                Text("러닝 기록을 시작하시겠습니까?")
            }
            .alert("거리 부족", isPresented: $showMinimumDistanceAlert) {
                Button("확인", role: .cancel) {
                    viewModel.send(event: .retry)
                }
            } message: {
                Text("최소 100m 이상 달려야 기록을 저장할 수 있습니다.")
            }
            
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    func runningView(_ data: RunningData) -> some View {
        ZStack {
            // Map background showing running path
            RunningMapView(
                currentLocation: viewModel.currentLocation,
                heading: viewModel.currentHeading,
                runningPath: data.locations.map { CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) },
                nearbyTracks: viewModel.allTracks,
                region: $mapRegion
            )
            .ignoresSafeArea()
            .opacity(0.6)
            
            // Dark overlay for better readability
            Color.mapOverlay
                .ignoresSafeArea()
            
            // Vignette effect
            VignetteOverlay(
                isDarkMode: colorScheme == .dark,
                intensity: 0.7
            )
            
            VStack(spacing: 40) {
                Spacer()
                
                // Title
                Text(data.trackId != nil && data.lapCount > 0 ? "러닝 중 (\(data.lapCount) laps)" : "러닝 중")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(Color.adaptivePrimaryTextAlt)
            
            // Stats display
            VStack(spacing: 24) {
                HStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text(formatTime(data.duration))
                            .font(.system(size: 42, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.adaptivePrimaryText)
                        Text("시간")
                            .font(.system(size: 14))
                            .foregroundColor(Color.adaptiveSecondaryText)
                    }
                    
                    VStack(spacing: 8) {
                        Text(String(format: "%.2f", data.distance / 1000))
                            .font(.system(size: 42, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.adaptivePrimaryText)
                        Text("거리 (km)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.adaptiveSecondaryText)
                    }
                }
            }
            .padding(.vertical, 40)
            
            Spacer()
            
            // Large stop button with long press
            VStack(spacing: 16) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.adaptiveRedAccent)
                        .frame(width: 120, height: 120)
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: longPressProgress)
                        .stroke(
                            Color.progressCircleStroke,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 108, height: 108)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 0.05), value: longPressProgress)
                    
                    Image(systemName: "stop.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .scaleEffect(isLongPressing ? 0.9 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isLongPressing)
                }
                .shadow(color: Color.buttonShadow, radius: 8, x: 0, y: 4)
                .onLongPressGesture(minimumDuration: 2.0, maximumDistance: .infinity) {
                    // Action when long press completes
                    viewModel.send(event: .stopRun)
                } onPressingChanged: { pressing in
                    isLongPressing = pressing
                    if pressing {
                        // Start timer for progress
                        longPressProgress = 0
                        longPressTimer?.invalidate()
                        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                            if longPressProgress < 1.0 {
                                longPressProgress += 0.05 / 2.0 // 2 seconds
                            } else {
                                longPressTimer?.invalidate()
                            }
                        }
                    } else {
                        // Reset progress and show toast if released early
                        longPressTimer?.invalidate()
                        if longPressProgress < 1.0 && longPressProgress > 0 {
                            showToast = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                showToast = false
                            }
                        }
                        withAnimation(.easeOut(duration: 0.2)) {
                            longPressProgress = 0
                        }
                    }
                }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
    
    @ViewBuilder
    func errorView(_ error: RunningError) -> some View {
        ContentUnavailableView {
            Label("오류", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            if case .authorizationDenied = error {
                Button("권한 요청") {
                    viewModel.send(event: .requestPermissions)
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("다시 시도") {
                    viewModel.send(event: .retry)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // Helper function to format time
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let seconds = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var isRunning: Bool {
        if case .running = viewModel.state {
            return true
        }
        return false
    }
    
    private func setupSiriNotifications() {
        NotificationCenter.default.addObserver(
            forName: .startRunningFromSiri,
            object: nil,
            queue: .main
        ) { _ in
            if case .idle = viewModel.state {
                showSiriStartAlert = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .stopRunningFromSiri,
            object: nil,
            queue: .main
        ) { _ in
            if case .running = viewModel.state {
                viewModel.send(event: .stopRun)
            }
        }
    }
}

extension Notification.Name {
    static let startRunningFromSiri = Notification.Name("startRunningFromSiri")
    static let stopRunningFromSiri = Notification.Name("stopRunningFromSiri")
}
