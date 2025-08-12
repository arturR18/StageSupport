//
//  ContentView.swift
//  StageText
//
//  Created by Artur Reshetnikov on 2025-08-12.
//

import SwiftUI
import Combine

// Device orientation detector
struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct ContentView: View {
    @StateObject private var model = StageTextModel()
    @StateObject private var themeManager = ThemeManager()
    @State private var customTimerValue = "5" // Custom timer input
    @FocusState private var isTextFieldFocused: Bool
    @State private var orientation = UIDeviceOrientation.portrait
    @State private var isLandscape = false
    @State private var temporaryTextSize: CGFloat = 0
    @State private var lastScaleValue: CGFloat = 1.0
    @State private var showSizeIndicator = false
    @State private var enableTimer = false
    @State private var autoCalculatedSize: CGFloat = 0
    @State private var textPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2) // For landscape text position
    @State private var initialTextPosition = CGPoint.zero
    @State private var isDragging = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                themeManager.currentTheme.backgroundColor
                    .ignoresSafeArea()
                
                if isLandscape {
                    // Landscape Mode - Full screen text presentation only
                    landscapeView(geometry: geometry)
                } else {
                    // Portrait Mode - Editing interface
                    portraitView(geometry: geometry)
                }
            }
            .onAppear {
                temporaryTextSize = model.textSize
                updateOrientation(UIDevice.current.orientation)
            }
            .onRotate { newOrientation in
                updateOrientation(newOrientation)
            }
            .fullScreenCover(isPresented: $model.isPresenting) {
                PresentationView(model: model, themeManager: themeManager)
            }
        }
    }
    
    // Portrait mode view - optimized for text editing
    @ViewBuilder
    private func portraitView(geometry: GeometryProxy) -> some View {
        ZStack {
            themeManager.currentTheme.backgroundColor
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping on background
                    isTextFieldFocused = false
                }
            
            VStack(spacing: 0) {
                // Header with modern styling
                VStack(spacing: 4) {
                    Text("StageText")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(themeManager.currentTheme.textColor)
                    
                    Text("Your personal teleprompter")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                }
                .padding(.top, 50)
                .padding(.bottom, 20)
                .onTapGesture {
                    // Dismiss keyboard when tapping on header
                    isTextFieldFocused = false
                }
                
                // Main text editor area with card styling
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Text")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(themeManager.currentTheme.secondaryColor)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.horizontal, 20)
                    
                    Card(themeManager: themeManager, padding: 12) {
                        ZStack(alignment: .topLeading) {
                            // Placeholder text
                            if model.text.isEmpty && !isTextFieldFocused {
                                Text("Start typing your script here...")
                                    .font(.system(size: 16))
                                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.3))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 8)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $model.text)
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.currentTheme.textColor)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .focused($isTextFieldFocused)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: geometry.size.height * 0.35)
                }
                .padding(.bottom, 16)
                
                // Settings section with modern cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Scrolling Text Card
                        Card(themeManager: themeManager) {
                            VStack(spacing: 16) {
                                SettingsRow(icon: "text.alignleft", title: "Scrolling Text", themeManager: themeManager) {
                                    CustomToggle(isOn: $model.enableScrolling, themeManager: themeManager)
                                }
                                
                                if model.enableScrolling {
                                    VStack(spacing: 12) {
                                        // Speed Control
                                        VStack(alignment: .leading, spacing: 8) {
                                            SectionHeader(title: "Speed", themeManager: themeManager)
                                            CustomSegmentedControl(
                                                options: [("Slow", 0.5), ("Normal", 1.0), ("Fast", 2.0)],
                                                selection: $model.scrollSpeed,
                                                themeManager: themeManager
                                            )
                                        }
                                        
                                        // Spacing Control
                                        VStack(alignment: .leading, spacing: 8) {
                                            SectionHeader(title: "Spacing", themeManager: themeManager)
                                            CustomSegmentedControl(
                                                options: ScrollSpacing.allCases.map { ($0.rawValue, $0) },
                                                selection: $model.scrollSpacing,
                                                themeManager: themeManager
                                            )
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Countdown Card
                        Card(themeManager: themeManager) {
                            VStack(spacing: 16) {
                                SettingsRow(icon: "timer", title: "Countdown", themeManager: themeManager) {
                                    CustomToggle(isOn: $enableTimer, themeManager: themeManager)
                                        .onChange(of: enableTimer) { newValue in
                                            if !newValue {
                                                model.timerDuration = 0
                                                model.timerRemaining = 0
                                            } else {
                                                if let seconds = Int(customTimerValue), seconds > 0 {
                                                    model.timerDuration = seconds
                                                } else {
                                                    model.timerDuration = 5
                                                }
                                            }
                                        }
                                }
                                
                                if enableTimer {
                                    VStack(alignment: .leading, spacing: 8) {
                                        SectionHeader(title: "Delay (seconds)", themeManager: themeManager)
                                        CustomTextField(
                                            placeholder: "5",
                                            text: $customTimerValue,
                                            themeManager: themeManager,
                                            keyboardType: .numberPad
                                        )
                                        .onChange(of: customTimerValue) { newValue in
                                            if let seconds = Int(newValue), seconds > 0 {
                                                model.timerDuration = seconds
                                            }
                                        }
                                    }
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                    .onAppear {
                                        model.showCountdown = true
                                        if let seconds = Int(customTimerValue), seconds > 0 {
                                            model.timerDuration = seconds
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Theme Card
                        Card(themeManager: themeManager) {
                            SettingsRow(icon: "paintbrush", title: "Theme", themeManager: themeManager) {
                                Menu {
                                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                                        Button(action: { 
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                themeManager.currentTheme = theme 
                                            }
                                        }) {
                                            HStack {
                                                Text(theme.rawValue)
                                                if theme == themeManager.currentTheme {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Text(themeManager.currentTheme.rawValue)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(themeManager.currentTheme.accentColor)
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(themeManager.currentTheme.accentColor)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(themeManager.currentTheme.accentColor.opacity(0.1))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Auto-Resize Card
                        Card(themeManager: themeManager) {
                            VStack(spacing: 8) {
                                SettingsRow(icon: "textformat.size", title: "Auto-Resize in Full Screen", themeManager: themeManager) {
                                    CustomToggle(isOn: $model.autoResizeEnabled, themeManager: themeManager)
                                }
                                
                                Text("Automatically sizes text to fit screen")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(themeManager.currentTheme.secondaryColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 8)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // Full Screen Button
                        PrimaryButton(
                            title: "Full Screen",
                            icon: "arrow.up.left.and.arrow.down.right",
                            themeManager: themeManager
                        ) {
                            if #available(iOS 16.0, *) {
                                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                            }
                            model.isPresenting = true
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 16)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
    }
    
    // Landscape mode view - full screen text presentation
    @ViewBuilder
    private func landscapeView(geometry: GeometryProxy) -> some View {
        ZStack {
            if model.timerRemaining > 0 && model.showCountdown {
                // Timer countdown
                VStack {
                    Text("Starting in...")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(themeManager.currentTheme.textColor.opacity(0.7))
                        .padding(.bottom, 20)
                    
                    Text("\(model.timerRemaining)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(themeManager.currentTheme.textColor)
                }
            } else if model.enableScrolling {
                // Scrolling text mode with seamless looping
                GeometryReader { geo in
                    let currentTextSize = getCurrentTextSize()
                    let textWidth = CGFloat(model.text.count) * currentTextSize * 0.6 + model.scrollSpacing.spacing(for: currentTextSize)
                    ZStack {
                        // First copy of text
                        Text(model.text.isEmpty ? "Type Here" : model.text)
                            .font(.system(size: currentTextSize, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .position(x: geo.size.width / 2 + model.scrollOffset, y: geo.size.height / 2)
                            .animation(nil, value: model.scrollOffset) // Disable animation for smooth scrolling
                        
                        // Second copy of text for seamless loop
                        Text(model.text.isEmpty ? "Type Here" : model.text)
                            .font(.system(size: currentTextSize, weight: .medium))
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .position(x: geo.size.width / 2 + model.scrollOffset + textWidth, y: geo.size.height / 2)
                            .animation(nil, value: model.scrollOffset) // Disable animation for smooth scrolling
                    }
                }
                .clipped()
                .onAppear {
                    // Always center text vertically when entering landscape
                    textPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Calculate auto-resize if enabled
                    if model.autoResizeEnabled && geometry.size.width > 0 && geometry.size.height > 0 {
                        autoCalculatedSize = model.calculateOptimalTextSize(
                            text: model.text,
                            screenSize: geometry.size,
                            isScrollingEnabled: model.enableScrolling
                        )
                        temporaryTextSize = autoCalculatedSize
                    } else {
                        temporaryTextSize = model.textSize
                    }
                    
                    if !model.isScrolling {
                        model.startScrollingSeamless(screenWidth: geometry.size.width)
                    }
                }
                .onChange(of: model.scrollSpacing) { _ in
                    // Restart scrolling with new spacing when changed
                    if model.isScrolling {
                        model.stopScrolling()
                        model.startScrollingSeamless(screenWidth: geometry.size.width)
                    }
                }
            } else {
                // Static text mode with draggable position
                Text(model.text.isEmpty ? "Type Here" : model.text)
                    .font(.system(size: getCurrentTextSize(), weight: .medium))
                    .foregroundColor(themeManager.currentTheme.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .position(textPosition)
                    .onAppear {
                        // Always center text when entering landscape
                        textPosition = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        
                        // Calculate auto-resize if enabled
                        if model.autoResizeEnabled && geometry.size.width > 0 && geometry.size.height > 0 {
                            autoCalculatedSize = model.calculateOptimalTextSize(
                                text: model.text,
                                screenSize: geometry.size,
                                isScrollingEnabled: model.enableScrolling
                            )
                            temporaryTextSize = autoCalculatedSize
                        } else {
                            temporaryTextSize = model.textSize
                        }
                    }
            }
            
            // Size indicator when resizing
            if showSizeIndicator {
                VStack {
                    Text("\(Int(getCurrentTextSize())) pt")
                        .font(.system(size: 24, weight: .medium))
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.top, 50)
                    Spacer()
                }
            }
        }
        .onChange(of: geometry.size) { newSize in
            // Recalculate auto-resize when screen size changes
            if model.autoResizeEnabled && newSize.width > 0 && newSize.height > 0 {
                autoCalculatedSize = model.calculateOptimalTextSize(
                    text: model.text,
                    screenSize: newSize,
                    isScrollingEnabled: model.enableScrolling
                )
                temporaryTextSize = autoCalculatedSize
            }
        }
        .onChange(of: model.text) { _ in
            // Recalculate auto-resize when text changes
            if model.autoResizeEnabled && geometry.size.width > 0 && geometry.size.height > 0 {
                autoCalculatedSize = model.calculateOptimalTextSize(
                    text: model.text,
                    screenSize: geometry.size,
                    isScrollingEnabled: model.enableScrolling
                )
                temporaryTextSize = autoCalculatedSize
            }
        }
        .gesture(
            // Combined pinch and drag gesture
            MagnificationGesture()
                .simultaneously(with: DragGesture(minimumDistance: 0))
                .onChanged { value in
                    // Handle pinch to resize
                    if let magnification = value.first {
                        // Disable auto-resize when user manually resizes
                        if model.autoResizeEnabled {
                            model.autoResizeEnabled = false
                            model.originalTextSize = temporaryTextSize > 0 ? temporaryTextSize : model.textSize
                        }
                        
                        let delta = magnification / lastScaleValue
                        lastScaleValue = magnification
                        
                        let newSize = (temporaryTextSize > 0 ? temporaryTextSize : model.textSize) * delta
                        temporaryTextSize = min(max(newSize, 20), 300)
                        showSizeIndicator = true
                    }
                    
                    // Handle drag to move (while pinching)
                    if let drag = value.second {
                        if !isDragging {
                            isDragging = true
                            initialTextPosition = textPosition
                        }
                        // Update position based on the center point between fingers
                        let translation = drag.translation
                        textPosition = CGPoint(
                            x: initialTextPosition.x + translation.width,
                            y: initialTextPosition.y + translation.height
                        )
                    }
                }
                .onEnded { _ in
                    lastScaleValue = 1.0
                    isDragging = false
                    model.textSize = temporaryTextSize
                    // Update text width when size changes for scrolling mode
                    if model.enableScrolling && model.isScrolling {
                        model.updateTextWidth()
                    }
                    withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                        showSizeIndicator = false
                    }
                }
        )
    }
    
    // Update orientation state
    private func updateOrientation(_ orientation: UIDeviceOrientation) {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch orientation {
            case .landscapeLeft, .landscapeRight:
                isLandscape = true
                hideKeyboard()
                // Reset text position to center when entering landscape
                textPosition = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
                // Only start timer if explicitly enabled
                if enableTimer && model.timerDuration > 0 {
                    model.timerRemaining = model.timerDuration
                    startLandscapeTimer()
                } else if model.enableScrolling && !model.isScrolling {
                    // Start scrolling immediately if no timer
                    model.startScrollingSeamless(screenWidth: UIScreen.main.bounds.width)
                }
            case .portrait, .portraitUpsideDown:
                isLandscape = false
                // Stop scrolling when returning to portrait
                if model.isScrolling {
                    model.stopScrolling()
                }
                // Reset timer
                model.timerRemaining = 0
            default:
                break
            }
            self.orientation = orientation
        }
    }
    
    // Helper function to get current text size for landscape view
    private func getCurrentTextSize() -> CGFloat {
        if model.autoResizeEnabled && autoCalculatedSize > 0 {
            return autoCalculatedSize
        } else if temporaryTextSize > 0 {
            return temporaryTextSize
        } else {
            return model.textSize
        }
    }
    
    // Timer for landscape mode
    private func startLandscapeTimer() {
        if model.timerDuration > 0 {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if model.timerRemaining > 0 {
                    model.timerRemaining -= 1
                } else {
                    timer.invalidate()
                    if model.enableScrolling && !model.isScrolling {
                        model.startScrolling()
                    }
                }
            }
        }
    }
}

// Helper function to hide keyboard
func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// Extension to handle scroll events for desktop
extension View {
    func onScroll(perform action: @escaping (ScrollPhase, CGSize) -> Void) -> some View {
        self.background(ScrollDetector(action: action))
    }
}

enum ScrollPhase {
    case began
    case changed(CGSize, CGSize)
    case ended
}

struct ScrollDetector: UIViewRepresentable {
    let action: (ScrollPhase, CGSize) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.allowedScrollTypesMask = [.continuous]
        view.addGestureRecognizer(pan)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }
    
    class Coordinator: NSObject {
        let action: (ScrollPhase, CGSize) -> Void
        private var lastTranslation: CGSize = .zero
        
        init(action: @escaping (ScrollPhase, CGSize) -> Void) {
            self.action = action
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            let cgSize = CGSize(width: translation.x, height: translation.y)
            
            switch gesture.state {
            case .began:
                action(.began, cgSize)
                lastTranslation = cgSize
            case .changed:
                let delta = CGSize(
                    width: cgSize.width - lastTranslation.width,
                    height: cgSize.height - lastTranslation.height
                )
                action(.changed(cgSize, delta), cgSize)
                lastTranslation = cgSize
            case .ended, .cancelled:
                action(.ended, cgSize)
                lastTranslation = .zero
            default:
                break
            }
        }
    }
}