//
//  SKTypography.swift
//  SuiteKeep
//
//  Design System Typography Tokens
//  Noir Luxe 2.0 - Premium Typography Scale
//

import SwiftUI

// MARK: - Typography Tokens
struct SKTypography {

    // MARK: - Display (Hero numbers, splash screens)
    static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)

    // MARK: - Headlines (Screen titles, section headers)
    static let headlineLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headlineMedium = Font.system(size: 24, weight: .semibold, design: .rounded)

    // MARK: - Titles (Card titles, row titles)
    static let titleLarge = Font.system(size: 18, weight: .semibold)
    static let titleMedium = Font.system(size: 16, weight: .semibold)

    // MARK: - Body (Primary and secondary content)
    static let bodyLarge = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 14, weight: .regular)

    // MARK: - Labels (Buttons, tags, badges)
    static let labelLarge = Font.system(size: 14, weight: .semibold)
    static let labelMedium = Font.system(size: 12, weight: .medium)

    // MARK: - Micro (Status text, metadata)
    static let micro = Font.system(size: 10, weight: .semibold)

    // MARK: - Seat Number (Special case for seat visualization)
    static let seatNumber = Font.system(size: 18, weight: .bold, design: .rounded)
    static let seatStatus = Font.system(size: 9, weight: .semibold)

    // MARK: - Metric Numbers (Dashboard metrics with tabular figures)
    static let metricLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let metricMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let metricSmall = Font.system(size: 20, weight: .bold, design: .rounded)
}

// MARK: - View Extension for Typography
extension View {
    func skFont(_ font: Font) -> some View {
        self.font(font)
    }
}

// MARK: - Text Extension for Tracking (Letter Spacing)
extension Text {
    func microStyle() -> Text {
        self
            .font(SKTypography.micro)
            .tracking(1.5)
    }

    func labelStyle() -> Text {
        self
            .font(SKTypography.labelMedium)
            .tracking(0.5)
    }
}
