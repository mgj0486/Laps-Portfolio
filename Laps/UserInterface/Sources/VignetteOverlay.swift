//
//  VignetteOverlay.swift
//  UserInterface
//
//  Created by Assistant on 2025/06/22.
//

import SwiftUI

public struct VignetteOverlay: View {
    let isDarkMode: Bool
    let intensity: Double // 0.0 to 1.0
    
    public init(isDarkMode: Bool, intensity: Double) {
        self.isDarkMode = isDarkMode
        self.intensity = intensity
    }
    
    public var body: some View {
        ZStack {
            // Multiple gradient layers for stronger effect
            
            // Layer 1: Main radial gradient
            RadialGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.clear, location: 0.0),
                    .init(color: Color.clear, location: 0.2),
                    .init(color: backgroundColor.opacity(0.5 * intensity), location: 0.35),
                    .init(color: backgroundColor.opacity(0.8 * intensity), location: 0.5),
                    .init(color: backgroundColor.opacity(0.95 * intensity), location: 0.7),
                    .init(color: backgroundColor.opacity(1.0 * intensity), location: 1.0)
                ]),
                center: .center,
                startRadius: 80,
                endRadius: 350
            )
            
            // Layer 2: Edge darkening
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor.opacity(0.8 * intensity),
                            Color.clear,
                            Color.clear,
                            backgroundColor.opacity(0.8 * intensity)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .clear, location: 0.15),
                            .init(color: .clear, location: 0.85),
                            .init(color: .black, location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            // Layer 3: Top and bottom fade
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            backgroundColor.opacity(0.7 * intensity),
                            Color.clear,
                            Color.clear,
                            backgroundColor.opacity(0.7 * intensity)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .black, location: 0.0),
                            .init(color: .clear, location: 0.2),
                            .init(color: .clear, location: 0.8),
                            .init(color: .black, location: 1.0)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    
    private var backgroundColor: Color {
        Color(UIColor { traitCollection in
            if isDarkMode {
                return UIColor(red: 0.15, green: 0.17, blue: 0.20, alpha: 1.0)
            } else {
                return UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1.0)
            }
        })
    }
}