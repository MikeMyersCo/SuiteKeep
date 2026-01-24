//
//  SKColors.swift
//  SuiteKeep
//
//  Design System Color Tokens
//  Noir Luxe 2.0 - Unified Color Semantics
//

import SwiftUI

// MARK: - SK Color Namespace
struct SKColors {

    // MARK: - Primary Brand: Champagne Gold
    static let champagne = Color(red: 0.87, green: 0.75, blue: 0.52)          // #DEC084
    static let champagneLight = Color(red: 0.95, green: 0.88, blue: 0.72)     // #F2E0B8
    static let champagneMuted = Color(red: 0.66, green: 0.56, blue: 0.38)     // #A89060

    // MARK: - Noir Surfaces (Elevation Hierarchy)
    static let surfaceBase = Color(red: 0.04, green: 0.035, blue: 0.06)       // #0A0910 - Deepest
    static let surfaceCard = Color(red: 0.08, green: 0.07, blue: 0.10)        // #14121A - Cards
    static let surfaceElevated = Color(red: 0.12, green: 0.11, blue: 0.14)    // #1E1B24 - Modals
    static let surfaceInteractive = Color(red: 0.16, green: 0.14, blue: 0.18) // #28242E - Hover

    // MARK: - Seat Status Colors (Unified across all views)
    static let statusAvailable = Color(red: 0.36, green: 0.75, blue: 0.54)    // #5DBF8A - Soft emerald
    static let statusReserved = Color(red: 0.87, green: 0.75, blue: 0.52)     // Champagne (brand alignment)
    static let statusSold = Color(red: 0.48, green: 0.58, blue: 0.75)         // #7B93BF - Slate blue

    // MARK: - Feedback Colors
    static let success = Color(red: 0.36, green: 0.75, blue: 0.54)            // #5DBF8A
    static let warning = Color(red: 0.90, green: 0.65, blue: 0.30)            // #E6A64D
    static let error = Color(red: 0.85, green: 0.42, blue: 0.45)              // #D96B73

    // MARK: - Text Colors
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let textOnAccent = Color.white

    // MARK: - Glass Effect Colors
    static let glassWhite = Color.white.opacity(0.08)
    static let glassBorder = champagne.opacity(0.15)
    static let glassHighlight = champagne.opacity(0.25)
    static let glassShimmer = champagne.opacity(0.4)

    // MARK: - Accent Colors (Secondary palette)
    static let accentBlue = Color(red: 0.45, green: 0.60, blue: 0.80)
    static let accentPurple = Color(red: 0.55, green: 0.45, blue: 0.70)
    static let accentTeal = Color(red: 0.40, green: 0.65, blue: 0.65)

    // MARK: - Gradients

    /// Hero section gradient with champagne accent
    static let heroGradient = LinearGradient(
        colors: [
            champagne.opacity(0.15),
            champagne.opacity(0.05),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Ambient glow gradient for firepit replacement
    static let ambientGlow = RadialGradient(
        colors: [
            champagne.opacity(0.6),
            champagne.opacity(0.3),
            champagne.opacity(0.1),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 60
    )

    /// Card background gradient
    static func cardGradient(accent: Color = champagne) -> LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.08),
                accent.opacity(0.02),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Seat glow gradient based on status
    static func seatGlow(for status: SeatStatus) -> RadialGradient {
        let color = statusColor(for: status)
        return RadialGradient(
            colors: [
                color.opacity(0.6),
                color.opacity(0.3),
                color.opacity(0.1)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 30
        )
    }

    /// Dynamic background gradient
    static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    surfaceBase,
                    Color(red: 0.06, green: 0.05, blue: 0.08),
                    surfaceBase
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.94),
                    Color(red: 0.99, green: 0.98, blue: 0.96),
                    Color(red: 0.97, green: 0.96, blue: 0.93)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Helper Functions

    /// Get status color for seat status
    static func statusColor(for status: SeatStatus) -> Color {
        switch status {
        case .available: return statusAvailable
        case .reserved: return statusReserved
        case .sold: return statusSold
        }
    }

    /// Get contrasting text color for status
    static func statusTextColor(for status: SeatStatus) -> Color {
        return .white
    }
}

// MARK: - Color Extension for Compatibility
extension Color {
    // Convenience accessors for common colors
    static var skChampagne: Color { SKColors.champagne }
    static var skChampagneLight: Color { SKColors.champagneLight }
    static var skSurfaceCard: Color { SKColors.surfaceCard }
    static var skStatusAvailable: Color { SKColors.statusAvailable }
    static var skStatusReserved: Color { SKColors.statusReserved }
    static var skStatusSold: Color { SKColors.statusSold }
}
