//
//  UIComponents.swift
//  StageText
//
//  Created by Artur Reshetnikov on 2025-08-12.
//

import SwiftUI

// MARK: - Card Component
struct Card<Content: View>: View {
    let content: Content
    @ObservedObject var themeManager: ThemeManager
    var padding: CGFloat = 16
    
    init(themeManager: ThemeManager, padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.themeManager = themeManager
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.currentTheme.cardBackgroundColor)
                    .shadow(
                        color: themeManager.currentTheme.shadowColor,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.borderColor, lineWidth: 0.5)
            )
    }
}

// MARK: - Custom Toggle
struct CustomToggle: View {
    @Binding var isOn: Bool
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(isOn ? themeManager.currentTheme.accentColor : themeManager.currentTheme.inactiveToggleColor)
                .frame(width: 51, height: 31)
            
            Circle()
                .fill(Color.white)
                .frame(width: 27, height: 27)
                .offset(x: isOn ? 10 : -10)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
        }
        .onTapGesture {
            withAnimation {
                isOn.toggle()
            }
        }
    }
}

// MARK: - Settings Row
struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    @ObservedObject var themeManager: ThemeManager
    
    init(icon: String, title: String, themeManager: ThemeManager, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.themeManager = themeManager
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Label {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(themeManager.currentTheme.accentColor)
                    .frame(width: 24)
            }
            
            Spacer()
            
            content
        }
    }
}

// MARK: - Custom Segmented Control
struct CustomSegmentedControl<SelectionValue: Hashable>: View {
    let options: [(String, SelectionValue)]
    @Binding var selection: SelectionValue
    @ObservedObject var themeManager: ThemeManager
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.1) { option in
                Text(option.0)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(selection == option.1 ? 
                        themeManager.currentTheme.backgroundColor : 
                        themeManager.currentTheme.textColor.opacity(0.7))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        ZStack {
                            if selection == option.1 {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(themeManager.currentTheme.accentColor)
                                    .matchedGeometryEffect(id: "selection", in: animation)
                            }
                        }
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selection = option.1
                        }
                    }
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(themeManager.currentTheme.segmentedControlBackground)
        )
    }
}

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    @ObservedObject var themeManager: ThemeManager
    @State private var isPressed = false
    
    init(title: String, icon: String? = nil, themeManager: ThemeManager, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.themeManager = themeManager
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [
                        themeManager.currentTheme.accentColor,
                        themeManager.currentTheme.accentColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: themeManager.currentTheme.accentColor.opacity(0.3),
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 1 : 3
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            },
            perform: {})
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(themeManager.currentTheme.secondaryColor)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    @ObservedObject var themeManager: ThemeManager
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .font(.system(size: 16))
            .foregroundColor(themeManager.currentTheme.textColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(themeManager.currentTheme.inputBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 0.5)
                    )
            )
    }
}