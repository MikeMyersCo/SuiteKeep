//
//  SKToggle.swift
//  SuiteKeep
//
//  Premium Toggle Component
//  Noir Luxe 2.0 - Champagne Accent Toggle
//

import SwiftUI

// MARK: - SKToggle Component
struct SKToggle: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: SKSpacing.compact) {
                // Icon
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isOn ? SKColors.champagne : SKColors.textSecondary)
                        .frame(width: 28)
                }

                // Labels
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(SKTypography.bodyLarge)
                        .foregroundColor(SKColors.textPrimary)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(SKTypography.bodyMedium)
                            .foregroundColor(SKColors.textSecondary)
                    }
                }
            }
        }
        .tint(SKColors.champagne)
        .onChange(of: isOn) { _, _ in
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - SKToggleRow Component (for settings lists)
struct SKToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: SKSpacing.standard) {
            // Icon with background
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: SKSpacing.radiusSubtle)
                        .fill(isOn ? SKColors.champagne.opacity(0.2) : Color(.tertiarySystemBackground))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isOn ? SKColors.champagne : SKColors.textSecondary)
                }
            }

            // Labels
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(SKTypography.bodyMedium)
                        .foregroundColor(SKColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Toggle
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(SKColors.champagne)
        }
        .padding(.vertical, SKSpacing.tight)
        .onChange(of: isOn) { _, _ in
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SKToggle(
            title: "Enable Notifications",
            isOn: .constant(true),
            subtitle: "Receive alerts for ticket sales",
            icon: "bell.fill"
        )

        SKToggle(
            title: "Dark Mode",
            isOn: .constant(false),
            icon: "moon.fill"
        )

        Divider()

        SKToggleRow(
            title: "CloudSync",
            isOn: .constant(true),
            subtitle: "Sync data across all your devices",
            icon: "icloud.fill"
        )

        SKToggleRow(
            title: "Analytics",
            isOn: .constant(false),
            subtitle: "Track concert performance",
            icon: "chart.bar.fill"
        )
    }
    .padding()
    .background(Color.black)
}
