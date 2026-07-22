import SwiftUI

struct LearningCardShell: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: LearningSessionItem
    let position: Int
    let total: Int
    let isCompleted: Bool
    let actionTitle: String
    let onAction: () -> Void

    var body: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                header

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text(item.title)
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(item.summary)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                Label {
                    Text("A focused card in a finite \(total)-card session")
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                } icon: {
                    Image(systemName: "rectangle.stack.fill")
                        .foregroundStyle(AppColor.accent)
                }
                .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: AppSpacing.large)

                Button(actionTitle, action: onAction)
                    .buttonStyle(.primaryAction)
                    .accessibilityHint(
                        position == total
                            ? "Completes this learning session"
                            : "Moves to the next card"
                    )
            }
            .frame(maxWidth: .infinity, minHeight: 430, alignment: .topLeading)
        }
        .overlay(alignment: .topTrailing) {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(AppColor.success)
                    .padding(AppSpacing.xLarge)
                    .accessibilityLabel("Completed")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Card \(position) of \(total): \(item.title)")
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    categoryLabel
                    durationLabel
                }
            } else {
                HStack(alignment: .center, spacing: AppSpacing.small) {
                    categoryLabel

                    Spacer(minLength: AppSpacing.small)

                    durationLabel
                }
            }
        }
    }

    private var categoryLabel: some View {
        Text(item.categoryName)
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.accent)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.medium)
            .padding(.vertical, AppSpacing.small)
            .background(AppColor.accent.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }

    private var durationLabel: some View {
        Label("\(item.estimatedMinutes) min", systemImage: "clock")
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .monospacedDigit()
    }
}

#Preview {
    LearningCardShell(
        item: LearningSessionItem(
            id: UUID(),
            title: "The boundary of control",
            summary: "A reflection on directing effort toward choices rather than outcomes.",
            categoryName: "Philosophy",
            kindName: "Principle",
            estimatedMinutes: 4
        ),
        position: 1,
        total: 3,
        isCompleted: false,
        actionTitle: "Next card"
    ) {}
    .padding()
    .background(AppColor.groupedBackground)
}
