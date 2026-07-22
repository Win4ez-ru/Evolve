import SwiftUI

struct SessionProgressHeader: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let position: Int
    let total: Int
    let progress: Double
    let onStop: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.medium) {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityHeader
            } else {
                standardHeader
            }

            SwiftUI.ProgressView(value: progress)
                .tint(AppColor.accent)
                .accessibilityLabel("Session progress")
                .accessibilityValue("Card \(position) of \(total)")
        }
        .padding(.horizontal, AppSpacing.xLarge)
        .padding(.top, AppSpacing.small)
        .padding(.bottom, AppSpacing.medium)
        .background(AppColor.groupedBackground)
    }

    private var standardHeader: some View {
        HStack(spacing: AppSpacing.medium) {
            stopButton

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Learning session")
                    .font(AppTypography.cardTitle)

                Text("Card \(position) of \(total)")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer(minLength: AppSpacing.small)

            positionLabel
        }
    }

    private var accessibilityHeader: some View {
        HStack(spacing: AppSpacing.medium) {
            stopButton

            Text("Session")
                .font(AppTypography.cardTitle)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.small)

            positionLabel
        }
        .accessibilityElement(children: .contain)
    }

    private var stopButton: some View {
        Button(action: onStop) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(AppColor.surface)
                .clipShape(Circle())
        }
        .foregroundStyle(AppColor.textPrimary)
        .accessibilityLabel("Stop session")
        .accessibilityHint("Shows a confirmation before ending the session")
    }

    private var positionLabel: some View {
        Text("\(position)/\(total)")
            .font(AppTypography.caption)
            .foregroundStyle(AppColor.textSecondary)
            .monospacedDigit()
            .accessibilityLabel("Card \(position) of \(total)")
    }
}

#Preview {
    SessionProgressHeader(position: 1, total: 3, progress: 1.0 / 3.0) {}
        .background(AppColor.groupedBackground)
}
