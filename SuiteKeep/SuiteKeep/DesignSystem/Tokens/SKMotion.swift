//
//  SKMotion.swift
//  SuiteKeep
//
//  Design System Animation & Motion Tokens
//  Noir Luxe 2.0 - Premium Interaction Feel
//

import SwiftUI

// MARK: - Motion Tokens
struct SKMotion {

    // MARK: - Animation Presets

    /// Quick tap response - buttons, toggles
    static let tap = Animation.spring(response: 0.2, dampingFraction: 0.7)

    /// Press and hold states
    static let press = Animation.spring(response: 0.15, dampingFraction: 0.8)

    /// State changes - status updates, toggles
    static let stateChange = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Expand/collapse - sheets, cards
    static let expand = Animation.spring(response: 0.4, dampingFraction: 0.72)

    /// Ambient animations - glows, pulses
    static let ambient = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)

    /// Quick ease for subtle movements
    static let quickEase = Animation.easeInOut(duration: 0.15)

    /// Standard ease for general transitions
    static let standardEase = Animation.easeInOut(duration: 0.3)

    // MARK: - Scale Values

    /// Button tap scale
    static let tapScale: CGFloat = 0.97

    /// Card press scale
    static let cardPressScale: CGFloat = 0.98

    /// Seat tap scale
    static let seatTapScale: CGFloat = 0.92

    // MARK: - Shadow Animation Values

    /// Shadow radius when pressed
    static let shadowPressedRadius: CGFloat = 4

    /// Shadow radius when normal
    static let shadowNormalRadius: CGFloat = 12

    // MARK: - Duration Constants
    struct Duration {
        static let instant: Double = 0.1
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let ambient: Double = 2.5
    }
}

// MARK: - View Extension for Animations
extension View {
    /// Apply tap animation with scale effect
    func skTapAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? SKMotion.tapScale : 1.0)
            .animation(SKMotion.tap, value: isPressed)
    }

    /// Apply card press animation
    func skCardPressAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? SKMotion.cardPressScale : 1.0)
            .animation(SKMotion.press, value: isPressed)
    }

    /// Apply seat tap animation
    func skSeatTapAnimation(isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? SKMotion.seatTapScale : 1.0)
            .animation(SKMotion.tap, value: isPressed)
    }

    /// Apply ambient pulse animation
    func skAmbientPulse(_ binding: Binding<Bool>) -> some View {
        self
            .onAppear { binding.wrappedValue = true }
            .animation(SKMotion.ambient, value: binding.wrappedValue)
    }
}

// MARK: - Animation Extension for Legacy Compatibility
extension Animation {
    static var skQuickSpring: Animation { SKMotion.tap }
    static var skStandardSpring: Animation { SKMotion.stateChange }
    static var skGentleSpring: Animation { SKMotion.expand }
}
