//
//  SKTextField.swift
//  SuiteKeep
//
//  Premium Text Field Component
//  Noir Luxe 2.0 - Consistent Input Styling
//

import SwiftUI

// MARK: - SKTextField Component
struct SKTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SKSpacing.compact) {
            // Leading icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isFocused ? SKColors.champagne : SKColors.textSecondary)
                    .frame(width: 24)
            }

            // Text input
            if isSecure {
                SecureField(placeholder, text: $text)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textPrimary)
                    .focused($isFocused)
            } else {
                TextField(placeholder, text: $text)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textPrimary)
                    .keyboardType(keyboardType)
                    .focused($isFocused)
            }

            // Clear button
            if !text.isEmpty && isFocused {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SKColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, SKSpacing.standard)
        .padding(.vertical, SKSpacing.compact)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .strokeBorder(
                        isFocused ? SKColors.champagne.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            }
        )
        .animation(SKMotion.stateChange, value: isFocused)
    }
}

// MARK: - SKNumberField Component
struct SKNumberField: View {
    let placeholder: String
    @Binding var value: Double
    var prefix: String? = nil
    var suffix: String? = nil

    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: SKSpacing.tight) {
            // Prefix
            if let prefix = prefix {
                Text(prefix)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textSecondary)
            }

            // Number input
            TextField(placeholder, text: $textValue)
                .font(SKTypography.bodyLarge)
                .foregroundColor(SKColors.textPrimary)
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .multilineTextAlignment(prefix != nil ? .trailing : .leading)
                .onChange(of: textValue) { _, newValue in
                    if let number = Double(newValue.replacingOccurrences(of: ",", with: "")) {
                        value = number
                    }
                }
                .onAppear {
                    textValue = value == 0 ? "" : String(format: "%.0f", value)
                }

            // Suffix
            if let suffix = suffix {
                Text(suffix)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textSecondary)
            }
        }
        .padding(.horizontal, SKSpacing.standard)
        .padding(.vertical, SKSpacing.compact)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .strokeBorder(
                        isFocused ? SKColors.champagne.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            }
        )
        .animation(SKMotion.stateChange, value: isFocused)
    }
}

// MARK: - SKTextEditor Component
struct SKTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 80

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(SKTypography.bodyLarge)
                    .foregroundColor(SKColors.textTertiary)
                    .padding(.horizontal, SKSpacing.micro)
                    .padding(.vertical, SKSpacing.tight)
            }

            // Text editor
            TextEditor(text: $text)
                .font(SKTypography.bodyLarge)
                .foregroundColor(SKColors.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
                .frame(minHeight: minHeight)
        }
        .padding(.horizontal, SKSpacing.compact)
        .padding(.vertical, SKSpacing.tight)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .fill(Color(.secondarySystemBackground))

                RoundedRectangle(cornerRadius: SKSpacing.radiusSmooth)
                    .strokeBorder(
                        isFocused ? SKColors.champagne.opacity(0.6) : Color.clear,
                        lineWidth: 1.5
                    )
            }
        )
        .animation(SKMotion.stateChange, value: isFocused)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        SKTextField(
            placeholder: "Enter name",
            text: .constant(""),
            icon: "person.fill"
        )

        SKTextField(
            placeholder: "Search concerts",
            text: .constant("Taylor Swift"),
            icon: "magnifyingglass"
        )

        SKNumberField(
            placeholder: "0",
            value: .constant(50.0),
            prefix: "$"
        )

        SKTextEditor(
            placeholder: "Add notes...",
            text: .constant("")
        )
    }
    .padding()
    .background(Color.black)
}
