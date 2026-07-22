import SwiftUI

enum AppTypography {
    static let screenTitle = Font.system(
        .largeTitle,
        design: .rounded,
        weight: .semibold
    )

    static let sectionTitle = Font.system(
        .title2,
        design: .rounded,
        weight: .semibold
    )

    static let cardTitle = Font.system(
        .headline,
        design: .rounded,
        weight: .semibold
    )

    static let body = Font.system(.body, design: .default)
    static let supporting = Font.system(.subheadline, design: .default)
    static let caption = Font.system(.caption, design: .rounded, weight: .medium)
    static let action = Font.system(.body, design: .rounded, weight: .semibold)
}
