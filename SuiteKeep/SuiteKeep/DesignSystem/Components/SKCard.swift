//
//  SKCard.swift
//  SuiteKeep
//
//  Unified Card Component
//  Noir Luxe 2.0 - Configurable Glass Morphism Cards
//

import SwiftUI

// MARK: - Card Variants
enum SKCardVariant {
    case standard      // Default card with subtle glass effect
    case metric        // Dashboard metric cards with accent glow
    case glass         // Heavy glass morphism for overlays
    case settings      // Clean settings-style cards
    case interactive   // Cards with press states
}

// MARK: - Card Sizes
enum SKCardSize {
    case compact       // Tight padding
    case standard      // Default padding
    case spacious      // Generous padding

    var padding: CGFloat {
        switch self {
        case .compact: return SKSpacing.compact
        case .standard: return SKSpacing.comfortable
        case .spacious: return SKSpacing.relaxed
        }
    }
}

// MARK: - SKCard Component
struct SKCard<Content: View>: View {
    let variant: SKCardVariant
    let size: SKCardSize
    let accent: Color
    let content: Content

    @State private var isPressed = false

    init(
        variant: SKCardVariant = .standard,
        size: SKCardSize = .standard,
        accent: Color = SKColors.champagne,
        @ViewBuilder content: () -> Content
    ) {
        self.variant = variant
        self.size = size
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        content
            .padding(size.padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(cardBorder)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
            .scaleEffect(variant == .interactive && isPressed ? SKMotion.cardPressScale : 1.0)
            .animation(SKMotion.press, value: isPressed)
            .if(variant == .interactive) { view in
                view.onTapGesture {}
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isPressed = true }
                            .onEnded { _ in isPressed = false }
                    )
            }
    }

    // MARK: - Computed Properties

    private var cornerRadius: CGFloat {
        switch variant {
        case .metric: return SKSpacing.radiusSoft
        case .settings: return SKSpacing.radiusSmooth
        default: return SKSpacing.radiusRounded
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        switch variant {
        case .standard:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.tertiarySystemBackground))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SKColors.cardGradient(accent: accent))
            }

        case .metric:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SKColors.cardGradient(accent: accent))
                // Mesh gradient for premium feel
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                accent.opacity(0.15),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
            }

        case .glass:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SKColors.glassWhite)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.clear,
                                Color.black.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

        case .settings:
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.secondarySystemBackground))

        case .interactive:
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(.tertiarySystemBackground))
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(SKColors.cardGradient(accent: accent))
            }
        }
    }

    @ViewBuilder
    private var cardBorder: some View {
        switch variant {
        case .metric, .glass:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            accent.opacity(0.4),
                            SKColors.glassHighlight,
                            accent.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        case .standard, .interactive:
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(accent.opacity(0.15), lineWidth: 1)
        case .settings:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .metric: return accent.opacity(0.15)
        case .glass: return Color.black.opacity(0.1)
        case .interactive: return isPressed ? accent.opacity(0.1) : accent.opacity(0.15)
        default: return Color.black.opacity(0.08)
        }
    }

    private var shadowRadius: CGFloat {
        switch variant {
        case .metric: return 15
        case .glass: return 20
        case .interactive: return isPressed ? 8 : 15
        default: return 10
        }
    }

    private var shadowY: CGFloat {
        switch variant {
        case .metric: return 8
        case .glass: return 10
        case .interactive: return isPressed ? 4 : 8
        default: return 5
        }
    }
}

// MARK: - View Extension Helper
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Convenience Initializers
extension SKCard where Content == EmptyView {
    init(variant: SKCardVariant = .standard) {
        self.init(variant: variant) { EmptyView() }
    }
}

// MARK: - SKMetricCard (Specialized for Dashboard)
struct SKMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color

    @State private var animatedValue: Double = 0
    private let targetValue: Double

    init(title: String, value: Int, icon: String, accent: Color = SKColors.champagne) {
        self.title = title
        self.value = "\(value)"
        self.icon = icon
        self.accent = accent
        self.targetValue = Double(value)
    }

    init(title: String, value: String, icon: String, accent: Color = SKColors.champagne) {
        self.title = title
        self.value = value
        self.icon = icon
        self.accent = accent
        // Try to extract number for animation
        if let number = Double(value.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
            self.targetValue = number
        } else {
            self.targetValue = 0
        }
    }

    var body: some View {
        SKCard(variant: .metric, accent: accent) {
            VStack(alignment: .leading, spacing: SKSpacing.tight) {
                // Icon with glow
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accent)
                }

                Spacer()

                // Value with animation
                Text(value)
                    .font(SKTypography.metricMedium)
                    .foregroundColor(SKColors.textPrimary)
                    .contentTransition(.numericText())

                // Title
                Text(title)
                    .font(SKTypography.labelMedium)
                    .foregroundColor(SKColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            SKCard(variant: .standard) {
                Text("Standard Card")
                    .font(SKTypography.titleMedium)
            }

            SKCard(variant: .metric, accent: SKColors.statusAvailable) {
                Text("Metric Card")
                    .font(SKTypography.titleMedium)
            }

            SKCard(variant: .glass) {
                Text("Glass Card")
                    .font(SKTypography.titleMedium)
            }

            SKCard(variant: .settings) {
                Text("Settings Card")
                    .font(SKTypography.titleMedium)
            }

            SKMetricCard(
                title: "Tickets Sold",
                value: 24,
                icon: "ticket.fill",
                accent: SKColors.statusSold
            )
            .frame(width: 150, height: 120)
        }
        .padding()
    }
    .background(Color.black)
}
