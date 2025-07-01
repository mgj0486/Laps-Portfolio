//
//  ColorExtensions.swift
//  Entities
//
//  Created by dev team on 1/8/24.
//  Copyright © 2024 perspective. All rights reserved.
//

import SwiftUI

public extension Color {
    // MARK: - Existing Accent Colors
    static let accentColor_light = Color(#colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1))
    static let accentColor_dark = Color(#colorLiteral(red: 0.8078431487, green: 0.02745098062, blue: 0.3333333433, alpha: 1))
    
    // MARK: - Background Colors
    static let backgroundDark = Color(#colorLiteral(red: 0.15, green: 0.17, blue: 0.20, alpha: 1))
    static let backgroundLight = Color(#colorLiteral(red: 0.94, green: 0.95, blue: 0.96, alpha: 1))
    
    // MARK: - Card Background Colors
    static let cardBackgroundDark = Color(#colorLiteral(red: 0.2, green: 0.22, blue: 0.25, alpha: 1))
    static let cardBackgroundLight = Color(#colorLiteral(red: 0.98, green: 0.98, blue: 0.99, alpha: 1))
    
    // MARK: - Text Colors
    static let primaryTextDark = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
    static let primaryTextLight = Color(#colorLiteral(red: 0.1, green: 0.1, blue: 0.1, alpha: 1))
    static let primaryTextLightAlt = Color(#colorLiteral(red: 0.15, green: 0.15, blue: 0.15, alpha: 1))
    static let secondaryTextDark = Color(#colorLiteral(red: 0.7, green: 0.7, blue: 0.7, alpha: 1))
    static let secondaryTextLight = Color(#colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1))
    static let tertiaryTextDark = Color(#colorLiteral(red: 0.6, green: 0.6, blue: 0.6, alpha: 1))
    static let tertiaryTextLight = Color(#colorLiteral(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
    
    // MARK: - Blue Accent Colors
    static let blueAccentDark = Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0.7, alpha: 1))
    static let blueAccentLight = Color(#colorLiteral(red: 0.2, green: 0.4, blue: 0.6, alpha: 1))
    
    // MARK: - Red Accent Colors
    static let redAccentDark = Color(#colorLiteral(red: 0.9, green: 0.3, blue: 0.3, alpha: 1))
    static let redAccentLight = Color(#colorLiteral(red: 0.8, green: 0.2, blue: 0.2, alpha: 1))
    static let redAccentDarkAlt = Color(#colorLiteral(red: 0.8, green: 0.3, blue: 0.3, alpha: 1))
    static let redAccentLightAlt = Color(#colorLiteral(red: 0.7, green: 0.2, blue: 0.2, alpha: 1))
    
    // MARK: - Green Accent Colors (Play Button)
    static let greenAccentDark = Color(#colorLiteral(red: 0.2, green: 0.7, blue: 0.5, alpha: 1))
    static let greenAccentLight = Color(#colorLiteral(red: 0.1, green: 0.6, blue: 0.4, alpha: 1))
    
    // MARK: - Border and Divider Colors
    static let cardBorderDark = Color(#colorLiteral(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.3))
    static let cardBorderLight = Color(#colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
    static let dividerDark = Color(#colorLiteral(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))
    static let dividerLight = Color(#colorLiteral(red: 0.9, green: 0.9, blue: 0.9, alpha: 1))
    
    // MARK: - Widget Colors
    static let widgetGradientStart = Color(#colorLiteral(red: 0.2, green: 0.4, blue: 0.6, alpha: 1))
    static let widgetGradientEnd = Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0.7, alpha: 1))
    
    // MARK: - Overlay Colors
    static let mapOverlay = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.3))
    static let mapGradientOverlay = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2))
    static let progressCircleStroke = Color(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.4))
    
    // MARK: - Shadow Colors
    static let buttonShadow = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.15))
    static let fabShadow = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2))
    static let cardShadow = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.08))
    static let lightCardShadow = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.05))
    
    // MARK: - Toast Background
    static let toastBackground = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.8))
    
    // MARK: - Icon Colors
    static let iconBackground = Color(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1))
    static let iconRunningFigure = Color(#colorLiteral(red: 0.3, green: 0.5, blue: 0.7, alpha: 1))
    
    // MARK: - Adaptive Colors
    static var adaptiveBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.backgroundDark) :
                UIColor(Color.backgroundLight)
        })
    }
    
    static var adaptiveCardBackground: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.cardBackgroundDark) :
                UIColor(Color.cardBackgroundLight)
        })
    }
    
    static var adaptivePrimaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.primaryTextDark) :
                UIColor(Color.primaryTextLight)
        })
    }
    
    static var adaptivePrimaryTextAlt: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.primaryTextDark) :
                UIColor(Color.primaryTextLightAlt)
        })
    }
    
    static var adaptiveSecondaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.secondaryTextDark) :
                UIColor(Color.secondaryTextLight)
        })
    }
    
    static var adaptiveTertiaryText: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.tertiaryTextDark) :
                UIColor(Color.tertiaryTextLight)
        })
    }
    
    static var adaptiveBlueAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.blueAccentDark) :
                UIColor(Color.blueAccentLight)
        })
    }
    
    static var adaptiveRedAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.redAccentDark) :
                UIColor(Color.redAccentLight)
        })
    }
    
    static var adaptiveRedAccentAlt: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.redAccentDarkAlt) :
                UIColor(Color.redAccentLightAlt)
        })
    }
    
    static var adaptiveGreenAccent: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.greenAccentDark) :
                UIColor(Color.greenAccentLight)
        })
    }
    
    static var adaptiveCardBorder: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.cardBorderDark) :
                UIColor(Color.cardBorderLight)
        })
    }
    
    static var adaptiveDivider: Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color.dividerDark) :
                UIColor(Color.dividerLight)
        })
    }
}
