import SwiftUI

struct SessionStopStateView: View {
    let phase: LearningSessionPhase
    let position: Int
    let total: Int
    let completedCount: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.xLarge) {
            Spacer(minLength: AppSpacing.section)

            Image(systemName: iconName)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.medium) {
                Text(title)
                    .font(AppTypography.screenTitle)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FoundationCard {
                HStack(spacing: AppSpacing.large) {
                    metric(value: "\(completedCount)", label: "Completed")
                    Divider()
                    metric(value: "\(total)", label: "Session size")
                    Divider()
                    metric(value: "\(position)", label: "Last card")
                }
                .frame(maxWidth: .infinity)
            }

            Spacer(minLength: AppSpacing.xLarge)

            Button("Back to Today", action: onDismiss)
                .buttonStyle(.primaryAction)
        }
        .padding(AppSpacing.xLarge)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.groupedBackground)
        .accessibilityElement(children: .contain)
    }

    private var title: String {
        phase == .completed ? "Session complete" : "Session stopped"
    }

    private var message: String {
        if phase == .completed {
            return "You reached the clear end of this finite session. No extra cards were added."
        }

        return "You stopped at card \(position) of \(total). You can return when you choose—there is no endless feed waiting."
    }

    private var iconName: String {
        phase == .completed ? "checkmark.circle.fill" : "pause.circle.fill"
    }

    private var iconColor: Color {
        phase == .completed ? AppColor.success : AppColor.accent
    }

    private func metric(value: String, label: String) -> some View {
        VStack(spacing: AppSpacing.xSmall) {
            Text(value)
                .font(AppTypography.sectionTitle)
                .monospacedDigit()

            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("Completed") {
    SessionStopStateView(
        phase: .completed,
        position: 3,
        total: 3,
        completedCount: 3
    ) {}
}

#Preview("Stopped") {
    SessionStopStateView(
        phase: .stopped,
        position: 2,
        total: 3,
        completedCount: 1
    ) {}
}
