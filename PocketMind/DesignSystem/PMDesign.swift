import SwiftUI

enum PMDesign {

    // MARK: - Semantic Colors (auto dark mode)

    static let background = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let tertiaryBackground = Color(.tertiarySystemBackground)
    static let groupedBackground = Color(.systemGroupedBackground)

    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)

    // MARK: - Brand

    static let accent = Color.indigo
    static let accentSecondary = Color.cyan
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    // MARK: - Gradients

    static let brandGradient = LinearGradient(
        colors: [Color.indigo, Color.cyan.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let subtleGradient = LinearGradient(
        colors: [Color.indigo.opacity(0.15), Color.cyan.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Corner Radii

    static let cornerSmall: CGFloat = 12
    static let cornerMedium: CGFloat = 16
    static let cornerLarge: CGFloat = 24

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 16
    static let spacingL: CGFloat = 24
    static let spacingXL: CGFloat = 32
}
