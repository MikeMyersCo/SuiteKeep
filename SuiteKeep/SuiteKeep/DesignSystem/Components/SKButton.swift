//
//  SKButton.swift
//  SuiteKeep
//
//  Unified Button Component
//  Noir Luxe 2.0 - Premium Interactive Buttons
//

import SwiftUI

// MARK: - Button Variants
enum SKButtonVariant {
    case primary       // Filled champagne accent
    case secondary     // Outlined with accent
    case ghost         // Text only, subtle hover
    case destructive   // Red/error actions
}

// MARK: - Button Sizes
enum SKButtonSize {
    case small
    case medium
    case large

    var horizontalPadding: CGFloat {
        switch self {
        case .small: return SKSpacing.compact
        case .medium: return SKSpacing.standard
        case .large: return SKSpacing.comfortable
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: return SKSpacing.tight
        case .medium: return SKSpacing.compact
        case .large: return SKSpacing.standard
        }
    }

    var font: Font {
        switch self {
        case .small: return SKTypography.labelMedium
        case .medium: return SKTypography.labelLarge
        case .large: return SKTypography.titleMedium
        }
    }

    var iconSize: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: return SKSpacing.radiusSubtle
        case .medium: return SKSpacing.radiusSmooth
        case .large: return SKSpacing.radiusRounded
        }
    }
}

// MARK: - SKButton Component
struct SKButton: View {
    let title: String
    let icon: String?
    let variant: SKButtonVariant
    let size: SKButtonSize
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(
        _ title: String,
        icon: String? = nil,
        variant: SKButtonVariant = .primary,
        size: SKButtonSize = .medium,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.variant = variant
        self.size = size
        self.isLoading = isLoading
        self.action = action
    }

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            HapticManager.shared.impact(style: .light)
            action()
        }) {
            HStack(spacing: SKSpacing.tight) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size.iconSize, weight: .semibold))
                }

                Text(title)
                    .font(size.font)
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(minWidth: minWidth)
            .foregroundColor(textColor)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
            .overlay(buttonBorder)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(isPressed ? SKMotion.tapScale : 1.0)
            .animation(SKMotion.tap, value: isPressed)
            .opacity(isLoading ? 0.8 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .disabled(isLoading)
    }

    // MARK: - Computed Properties

    private var minWidth: CGFloat {
        switch size {
        case .small: return 60
        case .medium: return 80
        case .large: return 100
        }
    }

    private var accentColor: Color {
        switch variant {
        case .primary, .secondary, .ghost: return SKColors.champagne
        case .destructive: return SKColors.error
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary: return SKColors.surfaceBase
        case .secondary, .ghost: return accentColor
        case .destructive: return variant == .primary ? .white : SKColors.error
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch variant {
        case .primary:
            ZStack {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor,
                                accentColor.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                // Highlight overlay
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }

        case .secondary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .fill(.ultraThinMaterial)

        case .ghost:
            Color.clear

        case .destructive:
            ZStack {
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                SKColors.error,
                                SKColors.error.opacity(0.85)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch variant {
        case .primary, .destructive:
            EmptyView()
        case .secondary:
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
        case .ghost:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: return accentColor.opacity(isPressed ? 0.2 : 0.3)
        case .secondary: return accentColor.opacity(isPressed ? 0.1 : 0.15)
        case .ghost: return Color.clear
        case .destructive: return SKColors.error.opacity(isPressed ? 0.2 : 0.3)
        }
    }

    private var shadowRadius: CGFloat {
        isPressed ? 5 : 10
    }

    private var shadowY: CGFloat {
        isPressed ? 2 : 5
    }
}

// MARK: - Icon-Only Button Variant
struct SKIconButton: View {
    let icon: String
    let variant: SKButtonVariant
    let size: SKButtonSize
    let action: () -> Void

    @State private var isPressed = false

    init(
        icon: String,
        variant: SKButtonVariant = .secondary,
        size: SKButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.variant = variant
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.impact(style: .light)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize + 2, weight: .semibold))
                .frame(width: buttonSize, height: buttonSize)
                .foregroundColor(textColor)
                .background(buttonBackground)
                .clipShape(Circle())
                .overlay(buttonBorder)
                .shadow(color: shadowColor, radius: isPressed ? 4 : 8, x: 0, y: isPressed ? 2 : 4)
                .scaleEffect(isPressed ? SKMotion.tapScale : 1.0)
                .animation(SKMotion.tap, value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var buttonSize: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }

    private var accentColor: Color {
        switch variant {
        case .primary, .secondary, .ghost: return SKColors.champagne
        case .destructive: return SKColors.error
        }
    }

    private var textColor: Color {
        switch variant {
        case .primary: return SKColors.surfaceBase
        case .secondary, .ghost: return accentColor
        case .destructive: return .white
        }
    }

    @ViewBuilder
    private var buttonBackground: some View {
        switch variant {
        case .primary:
            Circle().fill(accentColor)
        case .secondary:
            Circle().fill(.ultraThinMaterial)
        case .ghost:
            Color.clear
        case .destructive:
            Circle().fill(SKColors.error)
        }
    }

    @ViewBuilder
    private var buttonBorder: some View {
        switch variant {
        case .secondary:
            Circle().strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
        default:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .primary: return accentColor.opacity(0.3)
        case .ghost: return Color.clear
        default: return Color.black.opacity(0.1)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Primary buttons
        HStack(spacing: 12) {
            SKButton("Small", size: .small) {}
            SKButton("Medium") {}
            SKButton("Large", size: .large) {}
        }

        // With icons
        HStack(spacing: 12) {
            SKButton("Add", icon: "plus") {}
            SKButton("Save", icon: "checkmark") {}
        }

        // Secondary
        HStack(spacing: 12) {
            SKButton("Cancel", variant: .secondary) {}
            SKButton("Edit", icon: "pencil", variant: .secondary) {}
        }

        // Ghost
        HStack(spacing: 12) {
            SKButton("Learn More", variant: .ghost) {}
        }

        // Destructive
        HStack(spacing: 12) {
            SKButton("Delete", icon: "trash", variant: .destructive) {}
        }

        // Icon buttons
        HStack(spacing: 12) {
            SKIconButton(icon: "plus", variant: .primary) {}
            SKIconButton(icon: "gear") {}
            SKIconButton(icon: "trash", variant: .destructive) {}
        }

        // Loading state
        SKButton("Loading...", isLoading: true) {}
    }
    .padding()
    .background(Color.black)
}
