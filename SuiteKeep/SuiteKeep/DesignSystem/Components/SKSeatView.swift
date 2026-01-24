//
//  SKSeatView.swift
//  SuiteKeep
//
//  Premium Seat Visualization Component
//  Noir Luxe 2.0 - Glass Morphism Seats with Status Glow
//

import SwiftUI

// MARK: - SKSeatView Component
struct SKSeatView: View {
    let seatNumber: Int
    let seat: Seat
    let isSelected: Bool
    let isBatchMode: Bool
    let isBuyerView: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    @State private var isPressed = false
    @State private var shakeOffset: CGFloat = 0

    // MARK: - Computed Properties

    private var seatColor: Color {
        if isBuyerView {
            // Buyer view: green for available, slate blue for unavailable
            switch seat.status {
            case .available: return SKColors.statusAvailable
            case .reserved, .sold: return SKColors.statusSold
            }
        } else if isBatchMode && isSelected {
            return SKColors.accentBlue
        } else {
            return SKColors.statusColor(for: seat.status)
        }
    }

    private var statusText: String {
        if isBuyerView {
            switch seat.status {
            case .available: return "OPEN"
            case .reserved, .sold: return "SOLD"
            }
        }

        // Management view: detailed status
        if seat.status == .sold {
            if seat.source == .donation {
                return "DONATION"
            }
            if seat.source == .family, let note = seat.note, !note.isEmpty {
                return String(note.prefix(4)).uppercased()
            } else if let price = seat.price {
                return "$\(Int(price))"
            }
            return "SOLD"
        }

        if seat.status == .reserved {
            if let note = seat.note, !note.isEmpty {
                return String(note.prefix(7)).uppercased()
            }
            return "RESV"
        }

        return ""
    }

    var body: some View {
        VStack(spacing: SKSpacing.Seat.spacing) {
            // Seat button with glass morphism
            ZStack {
                // Outer glow effect
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                seatColor.opacity(0.4),
                                seatColor.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: SKSpacing.Seat.size + 16, height: SKSpacing.Seat.size + 16)
                    .blur(radius: 8)
                    .opacity(isPressed ? 0.6 : 1.0)

                // Glass background
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .frame(width: SKSpacing.Seat.size, height: SKSpacing.Seat.size)

                // Colored gradient overlay
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                seatColor.opacity(0.5),
                                seatColor.opacity(0.3)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: SKSpacing.Seat.size / 2
                        )
                    )
                    .frame(width: SKSpacing.Seat.size, height: SKSpacing.Seat.size)

                // Glowing border stroke
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                seatColor.opacity(0.8),
                                seatColor.opacity(0.4),
                                seatColor.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: SKSpacing.Seat.borderWidth
                    )
                    .frame(width: SKSpacing.Seat.size, height: SKSpacing.Seat.size)

                // Content: checkmark or seat number
                if isBatchMode && isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                } else {
                    Text("\(seatNumber)")
                        .font(SKTypography.seatNumber)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }
            .scaleEffect(isPressed ? SKMotion.seatTapScale : 1.0)
            .shadow(
                color: seatColor.opacity(0.4),
                radius: isPressed ? SKMotion.shadowPressedRadius : SKSpacing.Seat.glowRadius,
                x: 0,
                y: isPressed ? 2 : 4
            )

            // Status text with fixed height for alignment
            Text(statusText.isEmpty ? " " : statusText)
                .font(SKTypography.seatStatus)
                .foregroundColor(SKColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(height: 24)
                .opacity(statusText.isEmpty ? 0 : 1)
        }
        .offset(x: shakeOffset)
        .onTapGesture {
            guard !isBuyerView else { return }

            withAnimation(SKMotion.tap) {
                isPressed = true
            }
            HapticManager.shared.impact(style: .medium)
            onTap()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(SKMotion.tap) {
                    isPressed = false
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0.6) {
            guard !isBuyerView else { return }

            // Shake animation for batch mode entry
            withAnimation(.interpolatingSpring(stiffness: 900, damping: 8).repeatCount(3, autoreverses: true)) {
                shakeOffset = 5
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                shakeOffset = 0
            }

            HapticManager.shared.impact(style: .heavy)
            onLongPress()
        }
    }
}

// MARK: - Shareable Seat View (Static, for screenshots)
struct SKShareableSeatView: View {
    let seatNumber: Int
    let seat: Seat

    private var seatColor: Color {
        switch seat.status {
        case .available: return SKColors.statusAvailable
        case .reserved, .sold: return SKColors.statusSold
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Glass background
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)

                // Colored overlay
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .fill(seatColor.opacity(0.5))
                    .frame(width: 44, height: 44)

                // Border
                RoundedRectangle(cornerRadius: SKSpacing.Seat.cornerRadius)
                    .strokeBorder(seatColor.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 44, height: 44)

                Text("\(seatNumber)")
                    .font(SKTypography.seatNumber)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 2)
            }
            .shadow(color: seatColor.opacity(0.4), radius: 8, x: 0, y: 4)

            // Status indicator
            Text(seat.status == .available ? "OPEN" : "SOLD")
                .font(SKTypography.micro)
                .foregroundColor(seatColor)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 40) {
            // Available seat
            SKSeatView(
                seatNumber: 1,
                seat: Seat(status: .available),
                isSelected: false,
                isBatchMode: false,
                isBuyerView: false,
                onTap: {},
                onLongPress: {}
            )

            // Reserved seat
            SKSeatView(
                seatNumber: 2,
                seat: Seat(status: .reserved, note: "John"),
                isSelected: false,
                isBatchMode: false,
                isBuyerView: false,
                onTap: {},
                onLongPress: {}
            )

            // Sold seat
            SKSeatView(
                seatNumber: 3,
                seat: Seat(status: .sold, price: 50),
                isSelected: false,
                isBatchMode: false,
                isBuyerView: false,
                onTap: {},
                onLongPress: {}
            )

            // Selected in batch mode
            SKSeatView(
                seatNumber: 4,
                seat: Seat(status: .available),
                isSelected: true,
                isBatchMode: true,
                isBuyerView: false,
                onTap: {},
                onLongPress: {}
            )
        }
    }
}
