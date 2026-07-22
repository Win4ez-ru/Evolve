import SwiftUI

struct FoundationCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.xLarge)
            .background(AppColor.surface)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: AppRadius.large,
                    style: .continuous
                )
                .stroke(AppColor.separator.opacity(0.45), lineWidth: 0.5)
            }
            .shadow(
                color: AppElevation.cardColor,
                radius: AppElevation.cardRadius,
                y: AppElevation.cardY
            )
    }
}

#Preview {
    FoundationCard {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Foundation card")
                .font(AppTypography.cardTitle)
            Text("A reusable surface for calm, readable content.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
        }
    }
    .padding()
    .background(AppColor.groupedBackground)
}
