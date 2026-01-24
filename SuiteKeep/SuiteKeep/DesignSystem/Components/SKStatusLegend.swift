//
//  SKStatusLegend.swift
//  SuiteKeep
//
//  Premium Status Legend Component
//  Noir Luxe 2.0 - Horizontal Pill Badges
//

import SwiftUI

// MARK: - SKStatusLegend Component
struct SKStatusLegend: View {
    let isBuyerView: Bool

    var body: some View {
        HStack(spacing: SKSpacing.comfortable) {
            // Available
            StatusPill(
                label: isBuyerView ? "Open" : "Available",
                color: SKColors.statusAvailable
            )

            // Reserved (only show in management view)
            if !isBuyerView {
                StatusPill(
                    label: "Reserved",
                    color: SKColors.statusReserved
                )
            }

            // Sold
            StatusPill(
                label: "Sold",
                color: SKColors.statusSold
            )
        }
        .padding(.horizontal, SKSpacing.comfortable)
        .padding(.vertical, SKSpacing.compact)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .strokeBorder(SKColors.glassBorder, lineWidth: 1)
            }
        )
    }
}

// MARK: - Status Pill Component
struct StatusPill: View {
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: SKSpacing.tight) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 14, height: 14)
                .shadow(color: color.opacity(0.5), radius: 4)

            // Label
            Text(label)
                .font(SKTypography.labelMedium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Expanded Status Legend (with counts)
struct SKStatusLegendExpanded: View {
    let available: Int
    let reserved: Int
    let sold: Int
    let isBuyerView: Bool

    var body: some View {
        HStack(spacing: SKSpacing.relaxed) {
            StatusPillWithCount(
                label: isBuyerView ? "Open" : "Available",
                count: available,
                color: SKColors.statusAvailable
            )

            if !isBuyerView {
                StatusPillWithCount(
                    label: "Reserved",
                    count: reserved,
                    color: SKColors.statusReserved
                )
            }

            StatusPillWithCount(
                label: "Sold",
                count: sold,
                color: SKColors.statusSold
            )
        }
        .padding(.horizontal, SKSpacing.comfortable)
        .padding(.vertical, SKSpacing.compact)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .strokeBorder(SKColors.glassBorder, lineWidth: 1)
            }
        )
    }
}

// MARK: - Status Pill with Count
struct StatusPillWithCount: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(SKTypography.titleMedium)
                .foregroundColor(color)

            Text(label)
                .font(SKTypography.micro)
                .foregroundColor(color.opacity(0.8))
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Status Legends")
                .font(SKTypography.headlineMedium)
                .foregroundColor(SKColors.champagne)

            SKStatusLegend(isBuyerView: false)

            SKStatusLegend(isBuyerView: true)

            SKStatusLegendExpanded(
                available: 3,
                reserved: 2,
                sold: 3,
                isBuyerView: false
            )
        }
    }
}
