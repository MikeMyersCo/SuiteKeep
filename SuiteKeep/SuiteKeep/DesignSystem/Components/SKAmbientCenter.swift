//
//  SKAmbientCenter.swift
//  SuiteKeep
//
//  Premium Ambient Center Component
//  Noir Luxe 2.0 - Refined Champagne Glow (replaces fire theme)
//

import SwiftUI

// MARK: - SKAmbientCenter Component
struct SKAmbientCenter: View {
    let isPulsing: Bool
    @State private var pulsePhase: Bool = false

    var body: some View {
        ZStack {
            // Outer ambient glow
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    RadialGradient(
                        colors: [
                            SKColors.champagne.opacity(0.25),
                            SKColors.champagne.opacity(0.12),
                            SKColors.champagne.opacity(0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 130, height: 80)
                .blur(radius: 12)
                .scaleEffect(pulsePhase ? 1.08 : 1.0)

            // Secondary glow layer
            RoundedRectangle(cornerRadius: 10)
                .fill(
                    RadialGradient(
                        colors: [
                            SKColors.champagne.opacity(0.35),
                            SKColors.champagne.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 50
                    )
                )
                .frame(width: 110, height: 60)
                .blur(radius: 6)
                .scaleEffect(pulsePhase ? 1.05 : 0.98)

            // Main ambient panel with glass morphism
            ZStack {
                // Glass base
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .frame(width: 100, height: 50)

                // Champagne gradient fill
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [
                                SKColors.champagne.opacity(0.4),
                                SKColors.champagneMuted.opacity(0.3),
                                SKColors.champagne.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 50)

                // Inner highlight
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                SKColors.champagneLight.opacity(0.5),
                                SKColors.champagne.opacity(0.3),
                                SKColors.champagneMuted.opacity(0.2)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 88, height: 40)
                    .blur(radius: 2)

                // Subtle shimmer overlay
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.clear,
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 40)

                // Minimalist warmth icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                SKColors.champagneLight,
                                SKColors.champagne
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: SKColors.champagne.opacity(0.6), radius: 4)

                // Border with gradient
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                SKColors.champagne.opacity(0.5),
                                SKColors.champagneMuted.opacity(0.3),
                                SKColors.champagne.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 100, height: 50)
            }
            .shadow(color: SKColors.champagne.opacity(0.4), radius: 12)
            .shadow(color: SKColors.champagneMuted.opacity(0.2), radius: 6)
        }
        .onAppear {
            if isPulsing {
                pulsePhase = true
            }
        }
        .animation(SKMotion.ambient, value: pulsePhase)
    }
}

// MARK: - Compact Ambient Center (for smaller layouts)
struct SKAmbientCenterCompact: View {
    let isPulsing: Bool
    @State private var pulsePhase: Bool = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            SKColors.champagne.opacity(0.3),
                            SKColors.champagne.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 40
                    )
                )
                .frame(width: 70, height: 70)
                .blur(radius: 8)
                .scaleEffect(pulsePhase ? 1.1 : 1.0)

            // Main circle
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 50, height: 50)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                SKColors.champagneLight.opacity(0.4),
                                SKColors.champagne.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 25
                        )
                    )
                    .frame(width: 50, height: 50)

                Circle()
                    .strokeBorder(SKColors.champagne.opacity(0.5), lineWidth: 1)
                    .frame(width: 50, height: 50)

                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(SKColors.champagne)
            }
            .shadow(color: SKColors.champagne.opacity(0.4), radius: 8)
        }
        .onAppear {
            if isPulsing {
                pulsePhase = true
            }
        }
        .animation(SKMotion.ambient, value: pulsePhase)
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 60) {
            Text("Ambient Center")
                .font(SKTypography.headlineMedium)
                .foregroundColor(SKColors.champagne)

            SKAmbientCenter(isPulsing: true)

            Text("Compact Version")
                .font(SKTypography.titleMedium)
                .foregroundColor(SKColors.textSecondary)

            SKAmbientCenterCompact(isPulsing: true)
        }
    }
}
