//
//  CreateCourseView.swift
//  Feature
//
//  Created by Assistant on 2025/06/21.
//

import SwiftUI
import CoreData
import UserInterface
import Core
import CoreLocation
import MapKit

struct CreateCourseView: View {
    @StateObject private var viewModel: CreateCourseViewModel
    @Binding var isPresented: Bool
    
    init(workout: WorkoutData, context: NSManagedObjectContext, isPresented: Binding<Bool>) {
        self._viewModel = StateObject(wrappedValue: CreateCourseViewModel(workout: workout, context: context))
        self._isPresented = isPresented
        print(workout)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Map Preview
                    if !viewModel.courseData.workout.route.isEmpty {
                        ZStack(alignment: .topTrailing) {
                            PatternRouteMapView(coordinates: viewModel.courseData.workout.route,
                                       highlightedCoordinates: viewModel.courseData.usePatternMode ? viewModel.courseData.patternCoordinates : nil)
                                .frame(height: 200)
                                .cornerRadius(12)
                            
                            // Pattern detection indicator
                            if viewModel.isDetectingPattern {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("패턴 분석 중...")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.toastBackground.opacity(0.875))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .padding(8)
                            } else if let pattern = viewModel.courseData.detectedPattern {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "repeat")
                                            .font(.caption)
                                        Text("\(pattern.repetitions)회 반복 감지")
                                            .font(.caption.bold())
                                    }
                                    Text("신뢰도: \(Int(pattern.confidence * 100))%")
                                        .font(.caption2)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.green.opacity(0.9))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .padding(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Course Info
                    VStack(alignment: .leading, spacing: 16) {
                        // Name Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("코스 이름")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                            
                            TextField("예: 한강공원 5km 코스", text: $viewModel.courseData.name)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Stats
                        HStack(spacing: 20) {
                            StatView(
                                icon: "ruler",
                                value: String(format: "%.2f km", viewModel.courseData.workout.totalDistance / 1000),
                                label: "전체 거리"
                            )
                            
                            StatView(
                                icon: "timer",
                                value: String(format: "%.0f분", viewModel.courseData.workout.duration / 60),
                                label: "소요시간"
                            )
                            
                            if viewModel.courseData.workout.pace > 0 {
                                StatView(
                                    icon: "speedometer",
                                    value: String(format: "%.1f", viewModel.courseData.workout.pace),
                                    label: "페이스(분/km)"
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Pattern Mode Toggle
                        if let pattern = viewModel.courseData.detectedPattern {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.orange)
                                    Text("패턴 모드")
                                        .font(.system(size: 14, weight: .medium))
                                    Spacer()
                                    Toggle("", isOn: $viewModel.courseData.usePatternMode)
                                        .labelsHidden()
                                }
                                
                                if viewModel.courseData.usePatternMode {
                                    VStack(alignment: .leading, spacing: 8) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("• 1회 루프만 저장됩니다")
                                            Text("• 총 \(pattern.repetitions)회 반복 감지됨")
                                            Text("• 단순화된 경로로 저장됩니다")
                                        }
                                        .font(.caption)
                                        .foregroundColor(secondaryTextColor)
                                        
                                        HStack {
                                            Image(systemName: "ruler")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            Text("1바퀴 거리: \(String(format: "%.2f km", viewModel.courseData.workout.totalDistance / Double(pattern.repetitions) / 1000))")
                                                .font(.caption.bold())
                                                .foregroundColor(.orange)
                                        }
                                        .padding(.top, 4)
                                    }
                                    .padding(.leading, 28)
                                }
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        
                        // Description (Optional)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("설명 (선택사항)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(secondaryTextColor)
                            
                            TextEditor(text: $viewModel.courseData.description)
                                .frame(minHeight: 80)
                                .padding(8)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(UIColor.separator), lineWidth: 0.5)
                                )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("새 코스 만들기")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.saveCourse()
                    }
                    .disabled(!viewModel.courseData.isValid)
                }
            }
        }
        .alert(viewModel.state == .saved ? "저장 완료" : "오류", isPresented: $viewModel.showingSaveAlert) {
            Button("확인") {
                if viewModel.state == .saved {
                    isPresented = false
                }
            }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    private var secondaryTextColor: Color {
        Color.adaptiveSecondaryText
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.accentColor)
            
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(UIColor.secondaryLabel))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 72)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
    }
}
