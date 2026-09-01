import SwiftUI

struct SessionStopStateView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let phase: LearningSessionPhase
    let position: Int
    let total: Int
    let completedCount: Int
    let sessionItems: [LearningSessionItem]
    let onSaveAction: ((UUID, String) -> Bool)?
    let onDismiss: () -> Void

    @State private var selectedContentUnitID: UUID?
    @State private var actionText = ""
    @State private var didSaveAction = false

    init(
        phase: LearningSessionPhase,
        position: Int,
        total: Int,
        completedCount: Int,
        sessionItems: [LearningSessionItem] = [],
        onSaveAction: ((UUID, String) -> Bool)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.phase = phase
        self.position = position
        self.total = total
        self.completedCount = completedCount
        self.sessionItems = sessionItems
        self.onSaveAction = onSaveAction
        self.onDismiss = onDismiss
        _selectedContentUnitID = State(initialValue: sessionItems.last?.id)
    }

    var body: some View {
        Group {
            if phase == .completed || dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical) {
                    stopContent(usesFlexibleSpace: false)
                }
                .scrollIndicators(.hidden)
            } else {
                stopContent(usesFlexibleSpace: true)
            }
        }
        .background(AppColor.groupedBackground)
        .accessibilityElement(children: .contain)
    }

    private func stopContent(usesFlexibleSpace: Bool) -> some View {
        VStack(spacing: AppSpacing.xLarge) {
            if usesFlexibleSpace {
                Spacer(minLength: AppSpacing.section)
            }

            Image(systemName: iconName)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.medium) {
                Text(title)
                    .font(AppTypography.screenTitle)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FoundationCard {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: AppSpacing.medium) {
                        accessibilityMetric(value: "\(completedCount)", label: "Practiced")
                        Divider()
                        accessibilityMetric(value: "\(total)", label: "Feed size")
                        Divider()
                        accessibilityMetric(value: "\(position)", label: "Last idea")
                    }
                } else {
                    HStack(spacing: AppSpacing.large) {
                        metric(value: "\(completedCount)", label: "Practiced")
                        Divider()
                        metric(value: "\(total)", label: "Feed size")
                        Divider()
                        metric(value: "\(position)", label: "Last idea")
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            if phase == .completed,
               !sessionItems.isEmpty,
               onSaveAction != nil {
                applicationCard
            }

            if usesFlexibleSpace {
                Spacer(minLength: AppSpacing.xLarge)
            }

            Button("Back to Today", action: onDismiss)
                .buttonStyle(.primaryAction)
        }
        .padding(AppSpacing.xLarge)
        .frame(maxWidth: 620)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.groupedBackground)
    }

    private var applicationCard: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("ONE ACTION FOR TODAY", systemImage: "arrow.up.forward.app.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)

                Text("What will you try next?")
                    .font(AppTypography.sectionTitle)

                Picker("Idea to apply", selection: $selectedContentUnitID) {
                    ForEach(sessionItems) { item in
                        Text(item.title).tag(Optional(item.id))
                    }
                }
                .pickerStyle(.menu)

                TextField(
                    "Write one small, observable action",
                    text: $actionText,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .padding(AppSpacing.medium)
                .background(AppColor.background)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))

                Button {
                    guard let selectedContentUnitID else {
                        return
                    }
                    didSaveAction = onSaveAction?(
                        selectedContentUnitID,
                        actionText
                    ) == true
                } label: {
                    Label(
                        didSaveAction ? "Action saved" : "Save next action",
                        systemImage: didSaveAction ? "checkmark.circle.fill" : "bookmark.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(didSaveAction ? AppColor.success : AppColor.accent)
                .disabled(
                    didSaveAction
                        || actionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
    }

    private var title: String {
        phase == .completed ? "Growth Loop complete" : "Session ended"
    }

    private var message: String {
        if phase == .completed {
            return "You reached the end of this feed. Your practice is saved and the useful ideas can return when they matter."
        }

        return "You ended at idea \(position) of \(total). Everything you chose to keep is already saved."
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

    private func accessibilityMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(value)
                .font(AppTypography.sectionTitle)
                .monospacedDigit()

            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
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

#Preview("Completed · Dark") {
    SessionStopStateView(
        phase: .completed,
        position: 3,
        total: 3,
        completedCount: 3,
        sessionItems: PreviewSupport.learningSessionPlan().items
    ) {}
    .preferredColorScheme(.dark)
}

#Preview("Stopped") {
    SessionStopStateView(
        phase: .stopped,
        position: 2,
        total: 3,
        completedCount: 1
    ) {}
}

#Preview("Completed action · AX") {
    SessionStopStateView(
        phase: .completed,
        position: 2,
        total: 2,
        completedCount: 2,
        sessionItems: PreviewSupport.learningSessionPlan().items,
        onSaveAction: { _, _ in true }
    ) {}
    .environment(\.dynamicTypeSize, .accessibility2)
}
