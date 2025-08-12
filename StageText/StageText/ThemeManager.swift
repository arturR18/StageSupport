//
//  ThemeManager.swift
//  StageText
//
//  Created by Artur Reshetnikov on 2025-08-12.
//

import SwiftUI

enum ColorTheme: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case sunny = "Sunny"
    
    var backgroundColor: Color {
        switch self {
        case .light:
            return Color(red: 0.98, green: 0.98, blue: 0.98)
        case .dark:
            return Color(red: 0.05, green: 0.05, blue: 0.05)
        case .sunny:
            return Color(red: 1.0, green: 0.98, blue: 0.85) // Light yellow
        }
    }
    
    var textColor: Color {
        switch self {
        case .light:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .dark:
            return Color(red: 0.95, green: 0.95, blue: 0.95)
        case .sunny:
            return Color(red: 0.0, green: 0.2, blue: 0.4) // Dark blue
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .light:
            return Color(red: 0.5, green: 0.5, blue: 0.5)
        case .dark:
            return Color(red: 0.6, green: 0.6, blue: 0.6)
        case .sunny:
            return Color(red: 0.4, green: 0.5, blue: 0.6)
        }
    }
    
    var controlBackgroundColor: Color {
        switch self {
        case .light:
            return Color(UIColor.systemGray6)
        case .dark:
            return Color(UIColor.systemGray5)
        case .sunny:
            return Color(red: 1.0, green: 0.95, blue: 0.8).opacity(0.5)
        }
    }
    
    // New colors for modern UI
    var cardBackgroundColor: Color {
        switch self {
        case .light:
            return Color.white
        case .dark:
            return Color(red: 0.12, green: 0.12, blue: 0.12)
        case .sunny:
            return Color(red: 1.0, green: 0.98, blue: 0.92)
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.08)
        case .dark:
            return Color.black.opacity(0.3)
        case .sunny:
            return Color(red: 0.8, green: 0.7, blue: 0.5).opacity(0.15)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .light:
            return Color.black.opacity(0.06)
        case .dark:
            return Color.white.opacity(0.08)
        case .sunny:
            return Color(red: 0.9, green: 0.85, blue: 0.7).opacity(0.3)
        }
    }
    
    var accentColor: Color {
        switch self {
        case .light:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // Blue
        case .dark:
            return Color(red: 0.1, green: 0.58, blue: 1.0) // Lighter blue
        case .sunny:
            return Color(red: 1.0, green: 0.6, blue: 0.0) // Orange
        }
    }
    
    var inactiveToggleColor: Color {
        switch self {
        case .light:
            return Color(red: 0.78, green: 0.78, blue: 0.8)
        case .dark:
            return Color(red: 0.25, green: 0.25, blue: 0.25)
        case .sunny:
            return Color(red: 0.9, green: 0.85, blue: 0.7)
        }
    }
    
    var segmentedControlBackground: Color {
        switch self {
        case .light:
            return Color(red: 0.94, green: 0.94, blue: 0.95)
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.15)
        case .sunny:
            return Color(red: 1.0, green: 0.95, blue: 0.85).opacity(0.5)
        }
    }
    
    var inputBackgroundColor: Color {
        switch self {
        case .light:
            return Color(red: 0.97, green: 0.97, blue: 0.97)
        case .dark:
            return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .sunny:
            return Color.white.opacity(0.7)
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var currentTheme: ColorTheme = .light
    
    func setTheme(_ theme: ColorTheme) {
        currentTheme = theme
    }
}