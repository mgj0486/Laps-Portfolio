//
//  StatItemView.swift
//  UserInterface
//
//  Created by Moon kyu Jung on 6/28/25.
//  Copyright © 2025 mooq. All rights reserved.
//

import SwiftUI

public struct StatItemView: View {
    public init(icon: String, value: String, label: String) {
        self.icon = icon
        self.value = value
        self.label = label
    }
    
    let icon: String
    let value: String
    let label: String
    
    public var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color.adaptiveBlueAccent)
                .frame(width: 24)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(Color.adaptiveSecondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.adaptivePrimaryText)
        }
    }
}
