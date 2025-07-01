//
//  ActivityView.swift
//  Feature
//
//  Created by MUNGYU JEONG on 6/18/25.
//  Copyright © 2025 personal. All rights reserved.
//
import SwiftUI
import CoreData
import Core
import UserInterface

struct ActivityView: View {
    init(context: NSManagedObjectContext? = nil) {
        self._viewModel = StateObject(wrappedValue: ActivityViewModel(context: context))
        print("DEBUG: ActivityView init with context: \(String(describing: context))")
    }
    
    @StateObject var viewModel: ActivityViewModel
    //MARK: - Body
    var body: some View {
        content()
        .background(// Background color matching design theme
            Color.adaptiveBackground
            .ignoresSafeArea())
        .onAppear {
            viewModel.send(event: .requestAuthorization)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    ForEach(viewModel.generateMonthOptions(), id: \.self) { date in
                        Button(action: {
                            viewModel.selectedDate = date
                        }) {
                            HStack {
                                Text(monthYearFormatter.string(from: date))
                                if Calendar.current.isDate(date, equalTo: viewModel.selectedDate, toGranularity: .month) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(monthYearFormatter.string(from: viewModel.selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.adaptiveBlueAccent)
                }
            }
        }
        .sheet(item: $viewModel.selectedWorkoutForCourse) { workout in
            if let context = viewModel.context {
                CreateCourseView(
                    workout: workout,
                    context: context,
                    isPresented: Binding(
                        get: { viewModel.selectedWorkoutForCourse != nil },
                        set: { if !$0 { viewModel.clearSelectedWorkoutForCourse() } }
                    )
                )
            } else {
                VStack {
                    Text("Context가 설정되지 않았습니다")
                    Button("닫기") {
                        viewModel.clearSelectedWorkoutForCourse()
                    }
                }
                .padding()
            }
        }
    }
    
    //MARK: -Content
    @ViewBuilder
    func content() -> some View {
        switch viewModel.state {
        case .idle(let data):
            if let data = data {
                activityContent(data)
            } else {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "heart.text.square",
                    description: Text("No activity data available for this month")
                )
            }
        case .authorizationRequested:
            ProgressView("Requesting HealthKit Authorization...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .dataLoading:
            ProgressView("Loading activity data...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let error):
            ContentUnavailableView {
                Label("Error", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                if case .authorizationDenied = error {
                    Button("Request Authorization") {
                        viewModel.send(event: .requestAuthorization)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Retry") {
                        viewModel.send(event: .retry)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    //MARK: - ActivityContent
    @ViewBuilder
    func activityContent(_ data: ActivityData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                monthlySummaryCard(data: data)
                
                if data.workouts.isEmpty {
                    emptyStateView()
                        .padding(.top, 40)
                } else {
                    workoutsList(data: data)
                }
            }
            .padding(.top, 6)
        }
    }
    
    // MARK: - Monthly Summary
    @ViewBuilder
    func monthlySummaryCard(data: ActivityData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.adaptivePrimaryTextAlt)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                StatItemView(
                    icon: "figure.walk",
                    value: "\(data.steps.formatted())",
                    label: "Steps"
                )
                
                StatItemView(
                    icon: "location",
                    value: String(format: "%.1f km", data.walkingDistance / 1000),
                    label: "Distance"
                )
                
                StatItemView(
                    icon: "flame",
                    value: String(format: "%.0f kcal", data.activeEnergy),
                    label: "Active Calories"
                )
                
                StatItemView(
                    icon: "figure.run",
                    value: "\(data.workouts.count)",
                    label: "Workouts"
                )
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Workouts List
    @ViewBuilder
    func workoutsList(data: ActivityData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workouts")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.adaptivePrimaryTextAlt)
                .padding(.horizontal, 20)
            
            let groupedWorkouts = Dictionary(grouping: data.workouts) { workout in
                Calendar.current.startOfDay(for: workout.date)
            }
            
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                if !groupedWorkouts.isEmpty {
                    ForEach(groupedWorkouts.keys.sorted(by: >), id: \.self) { date in
                        Section(header: sectionHeaderView(
                            date: date,
                            workoutCount: groupedWorkouts[date]!.count,
                            isExpanded: viewModel.expandedSections.contains(date)
                        )) {
                            if viewModel.expandedSections.contains(date) {
                                VStack(spacing: 12) {
                                    ForEach(groupedWorkouts[date]!.sorted(by: { $0.date > $1.date })) { workout in
                                        workoutRow(workout)
                                    }
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 8)
                            }
                        }
                        .id(date)  // Add stable ID for each section
                    }
                } else {
                    emptyStateView()
                }
            }
        }
    }
    
    // MARK: - Workout Section
    @ViewBuilder
    func workoutSection(date: Date, workouts: [WorkoutData]) -> some View {
        let isExpanded = viewModel.expandedSections.contains(date)
        
        VStack(spacing: 0) {
            sectionHeader(date: date, workoutCount: workouts.count, isExpanded: isExpanded)
            
            Divider()
                .background(Color.adaptiveDivider)
            
            if isExpanded {
                VStack(spacing: 12) {
                    ForEach(workouts) { workout in
                        workoutRow(workout)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
    }
    
    // MARK: - Section Header
    @ViewBuilder
    func sectionHeader(date: Date, workoutCount: Int, isExpanded: Bool) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.send(event: .toggleSection(date))
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(sectionDateFormatter.string(from: date))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color.adaptivePrimaryTextAlt)
                    
                    HStack(spacing: 8) {
                        Text("\(workoutCount)개의 운동")
                            .font(.system(size: 12))
                            .foregroundColor(Color.adaptiveSecondaryText)
                        
                        if let totalCalories = viewModel.calculateDailyCalories(for: date) {
                            Text("•")
                                .font(.system(size: 12))
                                .foregroundColor(Color.adaptiveSecondaryText)
                            
                            Label(String(format: "%.0f kcal", totalCalories), systemImage: "flame.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color.adaptiveSecondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.adaptiveSecondaryText)
                    .rotationEffect(Angle(degrees: isExpanded ? 180 : 0))
            }
            .padding(.horizontal)
            .frame(height: 65)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Pinned Headers
    @ViewBuilder
    func sectionHeaderView(date: Date, workoutCount: Int, isExpanded: Bool) -> some View {
        VStack(spacing: 0) {
            sectionHeader(date: date, workoutCount: workoutCount, isExpanded: isExpanded)
            Divider()
                .background(Color.adaptiveDivider)
        }
        .background(Color.adaptiveBackground)
    }
    
    // MARK: - Empty State
    @ViewBuilder
    func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 48))
                .foregroundColor(Color.adaptiveSecondaryText.opacity(0.5))
            
            Text("No workouts this month")
                .font(.system(size: 16))
                .foregroundColor(Color.adaptiveSecondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.vertical, 40)
    }
    
    //MARK: - WorkoutRow
    @ViewBuilder
    func workoutRow(_ workout: WorkoutData) -> some View {
        VStack(spacing: 0) {
            // Map on top if route exists
            if workout.route.count > 1 {
                ZStack(alignment: .bottom) {
                    RouteMapView(locations: workout.route)
                        .frame(height: 200)
                    
                    // Gradient overlay for better text readability
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0),
                            Color.mapGradientOverlay
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(alignment: .bottom, spacing: 4) {
                        Text(workout.activityType)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.adaptivePrimaryTextAlt)
                        
                        if (workout.sourceName != "MyLaps") {
                            Text("from \(workout.sourceName)")
                                .font(.system(size: 11))
                                .foregroundColor(Color.adaptiveTertiaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Text(workoutDateFormatter.string(from: workout.date))
                        .font(.system(size: 12))
                        .foregroundColor(Color.adaptiveSecondaryText)
                }
                
                HStack(spacing: 16) {
                    Label(String(format: "%.1f min", workout.duration / 60), systemImage: "timer")
                        .font(.system(size: 13))
                    
                    Label(String(format: "%.2f km", workout.totalDistance / 1000), systemImage: "ruler")
                        .font(.system(size: 13))
                    
                    if workout.pace > 0 {
                        Label(String(format: "%.2f min/km", workout.pace), systemImage: "speedometer")
                            .font(.system(size: 13))
                    }
                    
                    if workout.totalEnergyBurned > 0 {
                        Label(String(format: "%.0f kcal", workout.totalEnergyBurned), systemImage: "flame")
                            .font(.system(size: 13))
                    }
                    
                    Spacer()
                    
                    if !workout.route.isEmpty {
                        // Check if pattern analysis is complete
                        if let hasSimilar = viewModel.similarTrackCache[workout.id] {
                            // Analysis complete
                            if !hasSimilar {
                                Button(action: {
                                    viewModel.selectWorkoutForCourse(workout)
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "map")
                                            .font(.system(size: 12))
                                        Text("코스 생성")
                                            .font(.system(size: 12, weight: .medium))
                                    }
                                    .foregroundColor(Color.adaptiveRedAccent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.adaptiveRedAccent.opacity(0.15))
                                    )
                                }
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                    Text("비슷한 코스 존재")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Color.adaptiveTertiaryText)
                            }
                        } else {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("분석 중")
                                    .font(.system(size: 12))
                            }
                            .foregroundColor(Color.adaptiveTertiaryText)
                            .onAppear {
                                _ = viewModel.hasSimilarTrack(for: workout)
                            }
                        }
                    }
                }
                .foregroundColor(Color.adaptiveSecondaryText)
            }
            .padding()
            .background(Color.adaptiveCardBackground)
        }
        .background(Color.adaptiveCardBackground)
        .cornerRadius(12)
        .shadow(color: Color.cardShadow, radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    
    // MARK: - Date Formatters
    private var sectionDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M월 d일 EEEE"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }
    
    private var monthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 M월"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }
    
    private var workoutDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
}
