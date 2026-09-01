import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var attempts: [LearningAttempt]
    @Query private var knowledgeRecords: [KnowledgeRecord]
    @Query private var learnerProfiles: [LearnerProfile]
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query private var reviewSchedules: [ReviewSchedule]
    @Query private var domainProgressRecords: [DomainProgressRecord]
    @Query private var thoughts: [ThoughtRecord]
    @Query private var applicationActions: [ApplicationAction]
    @Query private var localEvents: [LocalProductEvent]

    @AppStorage("evolve.displayName") private var displayName = ""
    @AppStorage("evolve.dailyGoalMinutes") private var dailyGoalMinutes = 12
    @AppStorage("evolve.preferredSessionMinutes") private var preferredSessionMinutes = 5
    @AppStorage("evolve.appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("evolve.completedSessions") private var completedSessions = 0
    @AppStorage("evolve.totalLearningMinutes") private var totalLearningMinutes = 0
    @AppStorage("evolve.currentStreak") private var currentStreak = 0
    @AppStorage("evolve.lastPracticeTimestamp") private var lastPracticeTimestamp = 0.0

    @State private var showsResetConfirmation = false
    @State private var persistenceFailure: PersistenceFailure?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                identityCard
                learningPathSettings
                practiceSettings
                appearanceSettings
                dataSection
                about
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog(
            "Reset all learning progress?",
            isPresented: $showsResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset progress", role: .destructive, action: resetProgress)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saved ideas, practice history, streaks, and session totals will be removed from this device.")
        }
        .persistenceFailureAlert($persistenceFailure)
    }

    private var learningPathSettings: some View {
        settingsSection(title: "Learning path") {
            Group {
                if let profile = learnerProfiles.first {
                    NavigationLink {
                        LearnerPreferencesView(
                            profile: profile,
                            categories: categories
                        )
                    } label: {
                        HStack(spacing: AppSpacing.medium) {
                            settingLabel(
                                icon: "scope",
                                title: profile.learningGoal?.title ?? "Learning goal",
                                subtitle: "\(profile.selectedCategoryIDs.count) interests · \(profile.learnerLevel?.title ?? "Growing")"
                            )

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColor.textSecondary)
                        }
                        .padding(.vertical, AppSpacing.large)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Complete onboarding to shape your learning path.")
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.vertical, AppSpacing.large)
                }
            }
        }
    }

    private var identityCard: some View {
        FoundationCard {
            HStack(spacing: AppSpacing.large) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColor.accent, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)

                    Text(initials)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("Your learning space")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)

                    TextField("What should Evolve call you?", text: $displayName)
                        .font(AppTypography.sectionTitle)
                        .textInputAutocapitalization(.words)

                    Text("Private, local, and shaped by your pace.")
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private var practiceSettings: some View {
        settingsSection(title: "Practice") {
            VStack(spacing: 0) {
                settingRow(
                    icon: "timer",
                    title: "Daily intention",
                    subtitle: "\(dailyGoalMinutes) mindful minutes"
                ) {
                    Stepper(
                        "\(dailyGoalMinutes) minutes",
                        value: $dailyGoalMinutes,
                        in: 5...30,
                        step: 1
                    )
                    .labelsHidden()
                }

                Divider().padding(.leading, 52)

                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    settingLabel(
                        icon: "rectangle.stack.fill",
                        title: "Feed duration",
                        subtitle: "A clear ending after about \(preferredSessionMinutes) minutes"
                    )

                    Picker("Feed duration", selection: $preferredSessionMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Preferred feed duration")
                }
                .padding(.vertical, AppSpacing.large)
            }
        }
    }

    private var appearanceSettings: some View {
        settingsSection(title: "Appearance") {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                settingLabel(
                    icon: "circle.lefthalf.filled",
                    title: "Color mode",
                    subtitle: "Match your device or choose a quiet theme"
                )

                Picker("Appearance", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { option in
                        Text(option.title).tag(option.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, AppSpacing.large)
        }
    }

    private var dataSection: some View {
        settingsSection(title: "Your data") {
            VStack(spacing: 0) {
                ShareLink(item: progressSummary) {
                    HStack(spacing: AppSpacing.medium) {
                        settingLabel(
                            icon: "square.and.arrow.up",
                            title: "Share a progress snapshot",
                            subtitle: "A text summary with no private responses"
                        )

                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(.vertical, AppSpacing.large)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 52)

                Button(role: .destructive) {
                    showsResetConfirmation = true
                } label: {
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(AppColor.danger)
                            .frame(width: 36, height: 36)
                            .background(AppColor.danger.opacity(0.10))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Reset learning progress")
                                .font(AppTypography.cardTitle)
                                .foregroundStyle(AppColor.danger)

                            Text("Keep the app and begin again")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.vertical, AppSpacing.large)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var about: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "leaf.fill")
                .foregroundStyle(AppColor.accent)

            Text("Evolve")
                .font(AppTypography.cardTitle)

            Text("Learn deliberately. Reflect honestly. Grow steadily.")
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)

            Text(versionDescription)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large)
    }

    private var versionDescription: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (version, build) {
        case let (.some(version), .some(build)):
            return "Version \(version) (\(build))"
        case let (.some(version), .none):
            return "Version \(version)"
        default:
            return "Version unavailable"
        }
    }

    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.sectionTitle)

            content()
                .padding(.horizontal, AppSpacing.large)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                        .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
                }
        }
    }

    private func settingRow<Trailing: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            settingLabel(icon: icon, title: title, subtitle: subtitle)
            Spacer(minLength: AppSpacing.small)
            trailing()
        }
        .padding(.vertical, AppSpacing.large)
    }

    private func settingLabel(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .foregroundStyle(AppColor.accent)
                .frame(width: 36, height: 36)
                .background(AppColor.accent.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.cardTitle)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var initials: String {
        let parts = displayName
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
        let result = String(parts).uppercased()
        return result.isEmpty ? "E" : result
    }

    private var progressSummary: String {
        """
        My Evolve progress

        \(localEvents.count { $0.kind == .growthLoopCompleted }) completed Growth Loops
        \(totalLearningMinutes) mindful learning minutes
        \(currentStreak)-day current streak
        \(knowledgeRecords.filter { $0.status != .eligible }.count) ideas practiced
        \(thoughts.count) personal thoughts

        Scroll intentionally. Apply one idea. Keep growing.
        """
    }

    private func resetProgress() {
        for attempt in attempts {
            modelContext.delete(attempt)
        }
        for record in knowledgeRecords {
            modelContext.delete(record)
        }
        for schedule in reviewSchedules {
            modelContext.delete(schedule)
        }
        for progress in domainProgressRecords {
            modelContext.delete(progress)
        }
        for thought in thoughts {
            modelContext.delete(thought)
        }
        for action in applicationActions {
            modelContext.delete(action)
        }
        for event in localEvents {
            modelContext.delete(event)
        }
        do {
            try modelContext.save()
            completedSessions = 0
            totalLearningMinutes = 0
            currentStreak = 0
            lastPracticeTimestamp = 0
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "reset learning progress",
                error: error
            )
        }
    }
}

private struct LearnerPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let profile: LearnerProfile
    let categories: [ContentCategory]

    @State private var selectedCategoryIDs: Set<UUID>
    @State private var goal: LearningGoal
    @State private var level: LearnerLevel
    @State private var persistenceFailure: PersistenceFailure?

    init(profile: LearnerProfile, categories: [ContentCategory]) {
        self.profile = profile
        self.categories = categories
        _selectedCategoryIDs = State(initialValue: Set(profile.selectedCategoryIDs))
        _goal = State(initialValue: profile.learningGoal ?? .applyIdeas)
        _level = State(initialValue: profile.learnerLevel ?? .growing)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                preferenceSection(title: "Interests") {
                    VStack(spacing: AppSpacing.small) {
                        ForEach(categories) { category in
                            let isSelected = selectedCategoryIDs.contains(category.id)

                            Button {
                                if isSelected {
                                    selectedCategoryIDs.remove(category.id)
                                } else {
                                    selectedCategoryIDs.insert(category.id)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                        Text(category.name)
                                            .font(AppTypography.cardTitle)
                                            .foregroundStyle(AppColor.textPrimary)

                                        Text(category.overview)
                                            .font(AppTypography.caption)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .multilineTextAlignment(.leading)
                                    }

                                    Spacer()

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(isSelected ? AppColor.accent : AppColor.textSecondary)
                                }
                                .padding(AppSpacing.large)
                                .background(isSelected ? AppColor.accent.opacity(0.08) : AppColor.surface)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                preferenceSection(title: "Goal") {
                    Picker("Learning goal", selection: $goal) {
                        ForEach(LearningGoal.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.large)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }

                preferenceSection(title: "Starting point") {
                    Picker("Experience", selection: $level) {
                        ForEach(LearnerLevel.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(AppSpacing.large)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }

                Button("Save learning path", action: save)
                    .buttonStyle(.primaryAction)
                    .disabled(selectedCategoryIDs.isEmpty)
            }
            .padding(AppSpacing.xLarge)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("Learning path")
        .navigationBarTitleDisplayMode(.inline)
        .persistenceFailureAlert($persistenceFailure)
    }

    private func preferenceSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.sectionTitle)
            content()
        }
    }

    private func save() {
        profile.update(
            selectedCategoryIDs: Array(selectedCategoryIDs),
            learningGoal: goal,
            learnerLevel: level
        )
        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "save your learning path",
                error: error
            )
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
    .modelContainer(PreviewSupport.modelContainer())
}
