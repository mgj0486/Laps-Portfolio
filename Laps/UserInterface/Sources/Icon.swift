//
//  Icon.swift
//  UserInterface
//
//  Created by Moon kyu Jung on 6/26/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import SwiftUI

public struct AppIcon: View {
    @Environment(\.colorScheme) var colorScheme
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Background gradient matching theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.black),
                    Color(UIColor.black)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Running track oval
//            RoundedRectangle(cornerRadius: 300)
//                .stroke(
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color.white.opacity(0.4),
//                            Color.white.opacity(0.1)
//                        ]),
//                        startPoint: .top,
//                        endPoint: .bottom
//                    ),
//                    lineWidth: 50
//                )
//                .frame(width: 750, height: 850)
//                .rotationEffect(.degrees(15))
            
            // Motion lines
//            ForEach(0..<3) { index in
//                Capsule()
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [
//                                Color.white.opacity(0.6 - Double(index) * 0.15),
//                                Color.white.opacity(0.2 - Double(index) * 0.05)
//                            ]),
//                            startPoint: .leading,
//                            endPoint: .trailing
//                        )
//                    )
//                    .frame(width: 200 - CGFloat(index * 50), height: 20)
//                    .offset(x: -250 + CGFloat(index * 30), 
//                           y: -100 + CGFloat(index * 40))
//                    .rotationEffect(.degrees(25))
//            }
            
            // Main running figure
            ZStack {
                // Shadow
                Image(systemName: "figure.run")
                    .font(.system(size: 550, weight: .bold))
                    .foregroundColor(.black.opacity(0.3))
                    .offset(x: 15, y: 15)
                    .blur(radius: 25)
                
                // Figure with gradient
                Image(systemName: "figure.run")
                    .font(.system(size: 550, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0)),
                                Color(UIColor(red: 0.3, green: 0.5, blue: 0.7, alpha: 1.0))
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
//            // Lap counter dots
//            HStack(spacing: 30) {
//                ForEach(0..<4) { index in
//                    Circle()
//                        .fill(
//                            index < 2 ?
//                            Color.white.opacity(0.9) :
//                            Color.white.opacity(0.3)
//                        )
//                        .frame(width: 40, height: 40)
//                }
//            }
//            .offset(y: 350)
        }
        .frame(width: 1024, height: 1024)
    }
}

#Preview("App Icon 1024x1024") {
    AppIcon()
        .previewLayout(.fixed(width: 1024, height: 1024))
        .background(Color.gray)
}
