//
//  SKSpacing.swift
//  SuiteKeep
//
//  Design System Spacing & Corner Radius Tokens
//  Noir Luxe 2.0 - Consistent Spatial System
//

import SwiftUI

// MARK: - Spacing Tokens
struct SKSpacing {

    // MARK: - Spacing Scale
    static let micro: CGFloat = 4        // Icon gaps, tight inline spacing
    static let tight: CGFloat = 8        // Within components
    static let compact: CGFloat = 12     // Related elements
    static let standard: CGFloat = 16    // Default spacing
    static let comfortable: CGFloat = 20 // Card padding
    static let relaxed: CGFloat = 24     // Section gaps
    static let spacious: CGFloat = 32    // Major divisions
    static let luxurious: CGFloat = 48   // Hero sections

    // MARK: - Corner Radius Scale
    static let radiusSubtle: CGFloat = 8      // Small buttons, chips
    static let radiusSmooth: CGFloat = 12     // Standard elements
    static let radiusRounded: CGFloat = 16    // Cards
    static let radiusSoft: CGFloat = 20       // Feature cards
    static let radiusGenerous: CGFloat = 24   // Panels
    static let radiusDramatic: CGFloat = 32   // Modals

    // MARK: - Component-Specific Spacing
    struct Card {
        static let padding: CGFloat = comfortable
        static let cornerRadius: CGFloat = radiusRounded
        static let contentSpacing: CGFloat = compact
    }

    struct Button {
        static let horizontalPadding: CGFloat = standard
        static let verticalPadding: CGFloat = compact
        static let cornerRadius: CGFloat = radiusSmooth
        static let iconGap: CGFloat = tight
    }

    struct Seat {
        static let size: CGFloat = 48
        static let cornerRadius: CGFloat = radiusSmooth
        static let spacing: CGFloat = -2  // Negative for tighter vertical grouping
        static let borderWidth: CGFloat = 1.5
        static let glowRadius: CGFloat = 12
    }

    struct Layout {
        static let screenPadding: CGFloat = standard
        static let sectionGap: CGFloat = relaxed
        static let cardGap: CGFloat = standard
    }
}

// MARK: - View Extension for Padding
extension View {
    /// Apply standard card padding
    func skCardPadding() -> some View {
        self.padding(SKSpacing.Card.padding)
    }

    /// Apply standard screen padding
    func skScreenPadding() -> some View {
        self.padding(.horizontal, SKSpacing.Layout.screenPadding)
    }

    /// Apply section spacing
    func skSectionSpacing() -> some View {
        self.padding(.vertical, SKSpacing.Layout.sectionGap)
    }
}

// MARK: - CGFloat Extension for Legacy Compatibility
extension CGFloat {
    // Map legacy constants to new tokens
    static let skRadiusSmall: CGFloat = SKSpacing.radiusSmooth
    static let skRadiusMedium: CGFloat = SKSpacing.radiusRounded
    static let skRadiusLarge: CGFloat = SKSpacing.radiusGenerous
}
