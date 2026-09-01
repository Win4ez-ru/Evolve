import SwiftUI

struct ContentMetadataView: View {
    let item: LearningSessionItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.small) {
                Label(item.difficulty.displayName, systemImage: "gauge.with.dots.needle.33percent")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Text("·")
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityHidden(true)

                Text(item.kindName)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(item.difficulty.displayName) difficulty, \(item.kindName)")

            HStack(alignment: .top, spacing: AppSpacing.medium) {
                Image(systemName: "book.closed")
                    .foregroundStyle(AppColor.accent)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    if let url = item.source.url {
                        Link(destination: url) {
                            Text(item.source.title)
                                .font(AppTypography.supporting)
                                .foregroundStyle(AppColor.accent)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .accessibilityHint("Opens the original source")
                    } else {
                        Text(item.source.title)
                            .font(AppTypography.supporting)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Text(item.source.creator)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(sourceAccessibilityLabel)
        }
    }

    private var sourceAccessibilityLabel: String {
        var components = [
            "Source \(item.source.title)",
            "by \(item.source.creator)"
        ]
        if let license = item.source.license {
            components.append("License \(license)")
        }
        return components.joined(separator: ". ")
    }
}

private extension ContentDifficulty {
    var displayName: String {
        switch self {
        case .introductory:
            "Introductory"
        case .foundational:
            "Foundational"
        case .intermediate:
            "Intermediate"
        case .advanced:
            "Advanced"
        case .expert:
            "Expert"
        }
    }
}
