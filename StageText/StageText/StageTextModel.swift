//
//  StageTextModel.swift
//  StageText
//
//  Created by Artur Reshetnikov on 2025-08-12.
//

import SwiftUI
import Combine

enum ScrollSpacing: String, CaseIterable {
    case tight = "Tight"
    case wide = "Wide"
    
    func spacing(for textSize: CGFloat) -> CGFloat {
        switch self {
        case .tight:
            return textSize * 1.0 // Minimal gap proportional to text size
        case .wide:
            return textSize * 8.0 // Large gap proportional to text size
        }
    }
}

class StageTextModel: ObservableObject {
    @Published var text: String = ""
    @Published var textSize: CGFloat = 50.0
    @Published var timerDuration: Int = 5 // seconds
    @Published var isPresenting: Bool = false
    @Published var timerRemaining: Int = 0
    @Published var textAlignment: TextAlignment = .center
    @Published var verticalAlignment: VerticalAlignment = .center
    @Published var showCountdown: Bool = true // Make countdown optional
    
    // Auto-resize properties
    @Published var autoResizeEnabled: Bool = true
    @Published var originalTextSize: CGFloat = 50.0 // Preserve user's manual size preference
    
    // Scrolling text properties
    @Published var isScrolling: Bool = false
    @Published var scrollSpeed: Double = 1.0 // 0.5 = slow, 1.0 = normal, 2.0 = fast
    @Published var scrollOffset: CGFloat = 0
    @Published var enableScrolling: Bool = false
    @Published var scrollSpacing: ScrollSpacing = .wide // Spacing between text copies
    
    private var timerCancellable: AnyCancellable?
    private var scrollTimer: Timer?
    private var textWidth: CGFloat = 0
    private var screenWidth: CGFloat = 0
    
    /// Calculates the optimal text size using binary search algorithm
    /// - Parameters:
    ///   - text: The text string to measure
    ///   - screenSize: The screen dimensions (width, height)
    ///   - isScrollingEnabled: Whether scrolling is enabled
    /// - Returns: The optimal font size that fits within the constraints
    func calculateOptimalTextSize(text: String, screenSize: CGSize, isScrollingEnabled: Bool) -> CGFloat {
        // Handle empty text gracefully
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return 50.0 // Default fallback size
        }
        
        print("Calculating optimal size for text: '\(text)' with screen size: \(screenSize)")
        
        // Constants
        let minSize: CGFloat = 20.0
        let maxSize: CGFloat = 500.0
        let padding: CGFloat = 40.0
        let tolerance: CGFloat = 1.0
        
        // Available space after padding
        let availableWidth = screenSize.width - (padding * 2)
        let availableHeight = screenSize.height - (padding * 2)
        
        // Binary search for optimal size
        var low = minSize
        var high = maxSize
        var optimalSize = minSize
        
        while high - low > tolerance {
            let mid = (low + high) / 2
            let font = UIFont.systemFont(ofSize: mid, weight: .medium)
            
            var fits = false
            
            if isScrollingEnabled {
                // For scrolling text: only consider height (single line)
                let textAttributes = [NSAttributedString.Key.font: font]
                let textBoundingRect = text.boundingRect(
                    with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: textAttributes,
                    context: nil
                )
                let textHeight = ceil(textBoundingRect.height)
                fits = textHeight <= availableHeight
            } else {
                // For static text: allow multi-line wrapping
                let textAttributes = [NSAttributedString.Key.font: font]
                
                // First check if it fits on a single line
                let singleLineRect = text.boundingRect(
                    with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: textAttributes,
                    context: nil
                )
                
                if singleLineRect.width <= availableWidth && singleLineRect.height <= availableHeight {
                    // Fits on single line
                    fits = true
                } else {
                    // Check multi-line with word wrapping
                    let multiLineRect = text.boundingRect(
                        with: CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading, .usesDeviceMetrics],
                        attributes: textAttributes,
                        context: nil
                    )
                    let textHeight = ceil(multiLineRect.height)
                    fits = textHeight <= availableHeight
                }
            }
            
            if fits {
                optimalSize = mid
                low = mid
            } else {
                high = mid
            }
        }
        
        print("Calculated optimal size: \(optimalSize) for text: '\(text)'")
        return optimalSize
    }
    
    func startPresentation() {
        isPresenting = true
        timerRemaining = timerDuration
        
        if timerDuration > 0 {
            timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    if self.timerRemaining > 0 {
                        self.timerRemaining -= 1
                    } else {
                        self.timerCancellable?.cancel()
                    }
                }
        }
    }
    
    func stopPresentation() {
        isPresenting = false
        timerCancellable?.cancel()
        timerRemaining = 0
        stopScrolling()
    }
    
    func startScrolling() {
        isScrolling = true
        scrollOffset = UIScreen.main.bounds.width / 2
        
        // Create a timer for smooth scrolling
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            withAnimation(.linear(duration: 0.016)) {
                self.scrollOffset -= CGFloat(self.scrollSpeed * 2)
            }
        }
    }
    
    func startScrollingSeamless(screenWidth: CGFloat) {
        isScrolling = true
        self.screenWidth = screenWidth
        
        // Calculate text width (approximate based on character count and font size)
        let approximateCharWidth = textSize * 0.6
        textWidth = CGFloat(text.count) * approximateCharWidth + scrollSpacing.spacing(for: textSize) // Use proportional spacing
        
        // Start text from right edge of screen
        scrollOffset = 0
        
        // Create a timer for smooth scrolling (60 FPS)
        scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            // No animation wrapper for smoother continuous movement
            self.scrollOffset -= CGFloat(self.scrollSpeed * 2)
            
            // When first text copy has scrolled its full width, reset position
            // This creates a seamless loop
            if self.scrollOffset <= -self.textWidth {
                self.scrollOffset += self.textWidth
            }
        }
    }
    
    func updateTextWidth() {
        // Recalculate text width when size changes
        let approximateCharWidth = textSize * 0.6
        textWidth = CGFloat(text.count) * approximateCharWidth + scrollSpacing.spacing(for: textSize)
    }
    
    func stopScrolling() {
        isScrolling = false
        scrollTimer?.invalidate()
        scrollTimer = nil
        scrollOffset = 0
    }
    
    func resetScroll() {
        scrollOffset = screenWidth > 0 ? screenWidth : UIScreen.main.bounds.width / 2
    }
    
    deinit {
        timerCancellable?.cancel()
        scrollTimer?.invalidate()
    }
}