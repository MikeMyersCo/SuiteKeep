//
//  DesignSystem.swift
//  SuiteKeep
//
//  Noir Luxe 2.0 Design System
//  A premium, systematic approach to the champagne-on-noir aesthetic
//

import SwiftUI

// MARK: - Design System Overview
/*
 The SuiteKeep Design System provides a unified set of:

 TOKENS (in Tokens/):
 - SKTypography: Font scale from micro to display
 - SKColors: Champagne/noir palette with semantic status colors
 - SKSpacing: Consistent spacing and corner radius scale
 - SKMotion: Animation presets for premium interactions

 COMPONENTS (in Components/):
 - SKCard: Unified card with variants (standard, metric, glass, settings, interactive)
 - SKButton: Unified button with variants (primary, secondary, ghost, destructive)
 - SKSeatView: Premium seat visualization with glass morphism
 - SKAmbientCenter: Refined champagne glow (replaces fire theme)
 - SKStatusLegend: Horizontal pill badges for seat status
 - SKTextField: Consistent text input styling
 - SKToggle: Premium toggle with champagne accent

 USAGE:
 ```swift
 // Typography
 Text("Title").font(SKTypography.headlineLarge)

 // Colors
 .foregroundColor(SKColors.champagne)
 .background(SKColors.surfaceCard)

 // Spacing
 .padding(SKSpacing.comfortable)
 .cornerRadius(SKSpacing.radiusRounded)

 // Components
 SKCard(variant: .metric, accent: SKColors.statusSold) {
     // content
 }

 SKButton("Save", icon: "checkmark", variant: .primary) {
     // action
 }
 ```
 */

// MARK: - Design System Constants
struct SK {
    // Quick access to common design values
    static let accentColor = SKColors.champagne
    static let backgroundColor = SKColors.surfaceBase
    static let cardBackground = SKColors.surfaceCard

    // Status colors
    static let available = SKColors.statusAvailable
    static let reserved = SKColors.statusReserved
    static let sold = SKColors.statusSold

    // Common animations
    static let tapAnimation = SKMotion.tap
    static let stateAnimation = SKMotion.stateChange
}

// MARK: - View Modifier for Design System Background
struct SKBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(SKColors.backgroundGradient(for: colorScheme))
    }
}

extension View {
    func skBackground() -> some View {
        modifier(SKBackgroundModifier())
    }
}

// MARK: - Section Header Component
struct SKSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(SKTypography.titleMedium)
                .foregroundColor(SKColors.textPrimary)

            Spacer()

            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(SKTypography.labelMedium)
                        .foregroundColor(SKColors.champagne)
                }
            }
        }
        .padding(.horizontal, SKSpacing.standard)
    }
}

// MARK: - Divider with Accent
struct SKDivider: View {
    var accent: Bool = false

    var body: some View {
        Rectangle()
            .fill(accent ? SKColors.champagne.opacity(0.3) : Color(.separator))
            .frame(height: 1)
    }
}

// MARK: - Badge Component
struct SKBadge: View {
    let text: String
    var color: Color = SKColors.champagne

    var body: some View {
        Text(text)
            .font(SKTypography.micro)
            .foregroundColor(color)
            .padding(.horizontal, SKSpacing.tight)
            .padding(.vertical, SKSpacing.micro)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
            )
            .overlay(
                Capsule()
                    .strokeBorder(color.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Empty State Component
struct SKEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        VStack(spacing: SKSpacing.standard) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(SKColors.champagne.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(SKColors.champagne.opacity(0.6))
            }

            // Text
            VStack(spacing: SKSpacing.tight) {
                Text(title)
                    .font(SKTypography.titleLarge)
                    .foregroundColor(SKColors.textPrimary)

                Text(message)
                    .font(SKTypography.bodyMedium)
                    .foregroundColor(SKColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Optional action
            if let action = action, let label = actionLabel {
                SKButton(label, variant: .secondary, action: action)
                    .padding(.top, SKSpacing.tight)
            }
        }
        .padding(SKSpacing.spacious)
    }
}

// MARK: - Preview
#Preview("Design System Overview") {
    ScrollView {
        VStack(spacing: 30) {
            // Header
            Text("Noir Luxe 2.0")
                .font(SKTypography.displayMedium)
                .foregroundColor(SKColors.champagne)

            Text("SuiteKeep Design System")
                .font(SKTypography.titleMedium)
                .foregroundColor(SKColors.textSecondary)

            Divider()

            // Colors
            VStack(alignment: .leading, spacing: 12) {
                Text("Status Colors")
                    .font(SKTypography.titleMedium)

                HStack(spacing: 16) {
                    VStack {
                        Circle().fill(SKColors.statusAvailable).frame(width: 40, height: 40)
                        Text("Available").font(SKTypography.micro)
                    }
                    VStack {
                        Circle().fill(SKColors.statusReserved).frame(width: 40, height: 40)
                        Text("Reserved").font(SKTypography.micro)
                    }
                    VStack {
                        Circle().fill(SKColors.statusSold).frame(width: 40, height: 40)
                        Text("Sold").font(SKTypography.micro)
                    }
                }
            }
            .foregroundColor(.white)

            // Badges
            HStack {
                SKBadge(text: "NEW", color: SKColors.statusAvailable)
                SKBadge(text: "SOLD", color: SKColors.statusSold)
                SKBadge(text: "VIP", color: SKColors.champagne)
            }

            // Empty state
            SKEmptyState(
                icon: "ticket",
                title: "No Concerts",
                message: "Add your first concert to get started",
                action: {},
                actionLabel: "Add Concert"
            )
        }
        .padding()
    }
    .background(Color.black)
}
