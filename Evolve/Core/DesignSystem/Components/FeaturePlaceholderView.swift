import SwiftUI

struct FeaturePlaceholderView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let nextStage: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text(title)
                        .font(AppTypography.screenTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(subtitle)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                }

                FoundationCard {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        Image(systemName: systemImage)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(AppColor.accent)
                            .accessibilityHidden(true)

                        Text("Foundation ready")
                            .font(AppTypography.cardTitle)

                        Text(nextStage)
                            .font(AppTypography.body)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xLarge)
        }
        .background(AppColor.groupedBackground)
        .toolbar(.hidden, for: .navigationBar)
    }
}
