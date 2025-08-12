//
//  PresentationView.swift
//  StageText
//
//  Created by Artur Reshetnikov on 2025-08-12.
//

import SwiftUI

struct PresentationView: View {
    @ObservedObject var model: StageTextModel
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var textWidth: CGFloat = 0
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var showSizeIndicator = false
    @State private var temporaryTextSize: CGFloat = 0
    @State private var autoCalculatedSize: CGFloat = 0
    @State private var screenSize: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if model.timerRemaining > 0 && model.showCountdown {
                    // Timer countdown (only if enabled)
                    VStack {
                        Text("Starting in...")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                            .padding(.bottom, 20)
                        
                        Text("\(model.timerRemaining)")
                            .font(.system(size: 120, weight: .bold))
                            .foregroundColor(themeManager.currentTheme.textColor)
                    }
                } else {
                    // Main text display
                    if model.enableScrolling {
                        // Scrolling text mode - centered horizontally
                        GeometryReader { geo in
                            Text(model.text)
                                .font(.system(size: getCurrentTextSize(), weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .position(x: geo.size.width / 2 + model.scrollOffset, y: geo.size.height / 2)
                                .background(
                                    GeometryReader { textGeometry in
                                        Color.clear
                                            .onAppear {
                                                textWidth = textGeometry.size.width
                                            }
                                    }
                                )
                                .onChange(of: model.scrollOffset) { newOffset in
                                    // Reset scroll when text goes off screen
                                    if newOffset < -geo.size.width - textWidth {
                                        model.resetScroll()
                                    }
                                }
                        }
                        .clipped()
                        .onAppear {
                            // Auto-start scrolling when in scrolling mode
                            model.startScrolling()
                        }
                    } else {
                        // Static text mode - Always centered
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(model.text)
                                .font(.system(size: getCurrentTextSize(), weight: .medium))
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .multilineTextAlignment(.center)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(40)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: geometry.size.height, alignment: .center)
                        }
                    }
                }
                
                // Size indicator (shows when resizing)
                if showSizeIndicator {
                    VStack {
                        Text("\(Int(getCurrentTextSize())) pt")
                            .font(.system(size: 24, weight: .medium))
                            .padding(12)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .padding(.top, 100)
                        Spacer()
                    }
                }
                
                // Close button in top-right corner
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            model.stopPresentation()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.5))
                                .background(Circle().fill(themeManager.currentTheme.backgroundColor.opacity(0.8)))
                        }
                        .padding(20)
                    }
                    Spacer()
                }
            }
            .onAppear {
                screenSize = geometry.size
                
                // Calculate auto-resize if enabled
                if model.autoResizeEnabled && geometry.size.width > 0 && geometry.size.height > 0 {
                    autoCalculatedSize = model.calculateOptimalTextSize(
                        text: model.text,
                        screenSize: geometry.size,
                        isScrollingEnabled: model.enableScrolling
                    )
                    temporaryTextSize = autoCalculatedSize
                    print("PresentationView: Set temporaryTextSize to \(autoCalculatedSize)")
                } else {
                    temporaryTextSize = model.textSize
                    print("PresentationView: Using default textSize \(model.textSize), autoResize: \(model.autoResizeEnabled), geometry: \(geometry.size)")
                }
                
                // Force landscape orientation for presentation
                if #available(iOS 16.0, *) {
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
            }
            .onChange(of: geometry.size) { newSize in
                screenSize = newSize
                
                // Recalculate auto-resize when screen size changes
                if model.autoResizeEnabled && newSize.width > 0 && newSize.height > 0 {
                    autoCalculatedSize = model.calculateOptimalTextSize(
                        text: model.text,
                        screenSize: newSize,
                        isScrollingEnabled: model.enableScrolling
                    )
                    temporaryTextSize = autoCalculatedSize
                    print("PresentationView onChange size: Set temporaryTextSize to \(autoCalculatedSize) for geometry: \(newSize)")
                }
            }
            .onChange(of: model.text) { _ in
            // Recalculate auto-resize when text changes
            if model.autoResizeEnabled {
                autoCalculatedSize = model.calculateOptimalTextSize(
                    text: model.text,
                    screenSize: screenSize,
                    isScrollingEnabled: model.enableScrolling
                )
                temporaryTextSize = autoCalculatedSize
            }
            }
            .onDisappear {
            // Restore normal rotation when exiting
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
            }
            }
            .gesture(
            MagnificationGesture()
                .onChanged { value in
                    // Disable auto-resize when user manually resizes
                    if model.autoResizeEnabled {
                        model.autoResizeEnabled = false
                        model.originalTextSize = temporaryTextSize
                    }
                    
                    let delta = value / lastScaleValue
                    lastScaleValue = value
                    
                    let newSize = getCurrentTextSize() * delta
                    temporaryTextSize = min(max(newSize, 20), 500) // Clamp between 20 and 500
                    showSizeIndicator = true
                }
                .onEnded { _ in
                    lastScaleValue = 1.0
                    model.textSize = temporaryTextSize
                    withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                        showSizeIndicator = false
                    }
                }
            )
            .onTapGesture {
                // Allow tap to dismiss after timer
                if model.timerRemaining == 0 && !model.enableScrolling {
                    model.stopPresentation()
                    dismiss()
                }
            }
        }
    }
    
    // Helper function to get current text size
    private func getCurrentTextSize() -> CGFloat {
        let size: CGFloat
        if model.autoResizeEnabled && autoCalculatedSize > 0 {
            size = autoCalculatedSize
        } else if temporaryTextSize > 0 {
            size = temporaryTextSize
        } else {
            size = model.textSize
        }
        print("getCurrentTextSize: returning \(size) (autoResize: \(model.autoResizeEnabled), autoCalc: \(autoCalculatedSize), temp: \(temporaryTextSize), default: \(model.textSize))")
        return size
    }
}