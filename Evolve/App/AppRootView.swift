import Foundation
import SwiftData
import SwiftUI

struct AppRootView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(\.scenePhase) private var scenePhase
    @Query private var learnerProfiles: [LearnerProfile]
    @Query private var localEvents: [LocalProductEvent]
    @AppStorage("evolve.appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("evolve.completedSessions") private var completedSessions = 0
    @AppStorage("evolve.totalLearningMinutes") private var totalLearningMinutes = 0
    @AppStorage("evolve.currentStreak") private var currentStreak = 0
    @AppStorage("evolve.lastPracticeTimestamp") private var lastPracticeTimestamp = 0.0
    @State private var showsOnboarding = false

    var body: some View {
        @Bindable var environment = environment

        TabView(selection: $environment.selectedTab) {
            Tab(
                AppTab.today.title,
                systemImage: AppTab.today.systemImage,
                value: AppTab.today
            ) {
                NavigationStack {
                    TodayView()
                }
            }

            Tab(
                AppTab.library.title,
                systemImage: AppTab.library.systemImage,
                value: AppTab.library
            ) {
                NavigationStack {
                    LibraryView()
                }
            }

            Tab(
                AppTab.progress.title,
                systemImage: AppTab.progress.systemImage,
                value: AppTab.progress
            ) {
                NavigationStack {
                    ProgressView()
                }
            }

            Tab(
                AppTab.profile.title,
                systemImage: AppTab.profile.systemImage,
                value: AppTab.profile
            ) {
                NavigationStack {
                    ProfileView()
                }
            }
        }
        .tint(AppColor.accent)
        .preferredColorScheme(
            AppAppearance(rawValue: appearance)?.colorScheme
        )
        .task {
            showsOnboarding = learnerProfiles.first?.completedOnboarding != true
        }
        .task(id: completionEventIDs) {
            reconcileLearningProgressTotals()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                reconcileLearningProgressTotals()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            reconcileLearningProgressTotals()
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingView {
                showsOnboarding = false
            }
            .interactiveDismissDisabled()
        }
    }

    private var completionEventIDs: [UUID] {
        localEvents
            .filter { $0.kind == .sessionCompleted }
            .map(\.id)
            .sorted { $0.uuidString < $1.uuidString }
    }

    private func reconcileLearningProgressTotals() {
        let totals = LearningProgressTotalsCalculator.calculate(from: localEvents)
        completedSessions = totals.completedSessions
        totalLearningMinutes = totals.totalLearningMinutes
        currentStreak = totals.currentStreak
        lastPracticeTimestamp = totals.lastPracticeTimestamp
    }
}

private struct OnboardingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query private var learnerProfiles: [LearnerProfile]

    @AppStorage("evolve.preferredSessionMinutes") private var preferredSessionMinutes = 5
    @AppStorage("evolve.dailyGoalMinutes") private var dailyGoalMinutes = 12

    @State private var step = 0
    @State private var selectedCategoryIDs: Set<UUID> = []
    @State private var goal: LearningGoal = .applyIdeas
    @State private var level: LearnerLevel = .growing
    @State private var persistenceFailure: PersistenceFailure?

    let onComplete: () -> Void

    init(initialStep: Int = 0, onComplete: @escaping () -> Void) {
        _step = State(initialValue: initialStep)
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if step > 0 {
                    Button {
                        withAnimation(AppMotion.session(reduceMotion: reduceMotion)) {
                            step -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Previous step")
                } else {
                    Color.clear.frame(width: 44, height: 44)
                }

                SwiftUI.ProgressView(value: Double(step + 1), total: 4)
                    .tint(AppColor.accent)

                Text("\(step + 1)/4")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: 64)
            }
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.medium)

            ScrollView {
                Group {
                    switch step {
                    case 0: welcomeStep
                    case 1: interestsStep
                    case 2: goalStep
                    default: paceStep
                    }
                }
                .padding(AppSpacing.xLarge)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }

            Button(step == 3 ? "Build my learning path" : "Continue") {
                if step == 3 {
                    completeOnboarding()
                } else {
                    withAnimation(AppMotion.session(reduceMotion: reduceMotion)) {
                        step += 1
                    }
                }
            }
            .buttonStyle(.primaryAction)
            .disabled(step == 1 && selectedCategoryIDs.isEmpty)
            .padding(AppSpacing.xLarge)
        }
        .background(AppColor.groupedBackground.ignoresSafeArea())
        .persistenceFailureAlert($persistenceFailure)
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppColor.accent, Color.mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 220)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Scroll less.\nKeep more.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))

                Text("Evolve turns a vertical feed into one useful thought, one real action, and progress you can see.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            FoundationCard {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    onboardingPrinciple("A feed shaped by your goal", icon: "scope")
                    onboardingPrinciple("Your thoughts become personal memory", icon: "quote.bubble.fill")
                    onboardingPrinciple("Every session ends with a next step", icon: "figure.walk.motion")
                }
            }
        }
    }

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            onboardingTitle(
                "Where do you want to grow first?",
                supporting: "We are starting with one focused path and will expand it carefully."
            )

            VStack(spacing: AppSpacing.medium) {
                ForEach(categories) { category in
                    let isSelected = selectedCategoryIDs.contains(category.id)

                    Button {
                        if isSelected {
                            selectedCategoryIDs.remove(category.id)
                        } else {
                            selectedCategoryIDs.insert(category.id)
                        }
                    } label: {
                        HStack(spacing: AppSpacing.large) {
                            Image(systemName: categoryIcon(category.sortOrder))
                                .font(.title2)
                                .foregroundStyle(isSelected ? AppColor.onAccent : AppColor.accent)
                                .frame(width: 52, height: 52)
                                .background(isSelected ? AppColor.accent : AppColor.accent.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

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
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            onboardingTitle(
                "What should focus change for you?",
                supporting: "Your answer shapes the examples, practices, and actions in the feed."
            )

            VStack(spacing: AppSpacing.medium) {
                ForEach(LearningGoal.allCases) { option in
                    let isSelected = goal == option

                    Button {
                        goal = option
                    } label: {
                        HStack(alignment: .top, spacing: AppSpacing.large) {
                            Image(systemName: isSelected ? "scope" : "circle.dashed")
                                .font(.title3)
                                .foregroundStyle(AppColor.accent)

                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text(option.title)
                                    .font(AppTypography.cardTitle)
                                    .foregroundStyle(AppColor.textPrimary)

                                Text(option.supportingText)
                                    .font(AppTypography.supporting)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .multilineTextAlignment(.leading)
                            }

                            Spacer()
                        }
                        .padding(AppSpacing.large)
                        .background(isSelected ? AppColor.accent.opacity(0.10) : AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                                .stroke(isSelected ? AppColor.accent : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(isSelected ? "Selected" : "Not selected")
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }

    private var paceStep: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            onboardingTitle(
                "Choose your session",
                supporting: "The feed has a clear ending. You can always choose to return later."
            )

            FoundationCard {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    Text("Starting point")
                        .font(AppTypography.cardTitle)

                    Picker("Learning experience", selection: $level) {
                        ForEach(LearnerLevel.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Divider()

                    Text("Minutes per session")
                        .font(AppTypography.cardTitle)

                    Picker("Minutes per session", selection: $preferredSessionMinutes) {
                        Text("5 min").tag(5)
                        Text("10 min").tag(10)
                        Text("15 min").tag(15)
                    }
                    .pickerStyle(.segmented)

                    Divider()

                    Stepper(
                        "\(dailyGoalMinutes) mindful minutes a day",
                        value: $dailyGoalMinutes,
                        in: 5...30
                    )
                    .font(AppTypography.body)
                }
            }

            Label(
                "Your choices stay on this device.",
                systemImage: "lock.shield.fill"
            )
            .font(AppTypography.supporting)
            .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func onboardingTitle(_ title: String, supporting: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.screenTitle)
                .fixedSize(horizontal: false, vertical: true)

            Text(supporting)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func onboardingPrinciple(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(AppTypography.body)
            .foregroundStyle(AppColor.textPrimary)
    }

    private func categoryIcon(_ order: Int) -> String {
        switch order % 3 {
        case 0: "brain.head.profile.fill"
        case 1: "bolt.fill"
        default: "chevron.left.forwardslash.chevron.right"
        }
    }

    private func completeOnboarding() {
        guard !selectedCategoryIDs.isEmpty else {
            return
        }

        if let profile = learnerProfiles.first {
            profile.update(
                selectedCategoryIDs: Array(selectedCategoryIDs),
                learningGoal: goal,
                learnerLevel: level
            )
        } else {
            modelContext.insert(
                LearnerProfile(
                    selectedCategoryIDs: Array(selectedCategoryIDs),
                    learningGoal: goal,
                    learnerLevel: level
                )
            )
        }
        modelContext.insert(LocalProductEvent(kind: .onboardingCompleted))

        do {
            try modelContext.save()
            onComplete()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "complete onboarding",
                error: error
            )
        }
    }
}

#Preview("Onboarding · Light") {
    AppRootView()
        .environment(PreviewSupport.environment())
        .modelContainer(PreviewSupport.modelContainer())
        .preferredColorScheme(.light)
}

#Preview("Onboarding · Dark") {
    AppRootView()
        .environment(PreviewSupport.environment())
        .modelContainer(PreviewSupport.modelContainer())
        .preferredColorScheme(.dark)
}

#Preview("Onboarding goal · AX") {
    OnboardingView(initialStep: 2) {}
        .modelContainer(PreviewSupport.modelContainer())
        .environment(\.dynamicTypeSize, .accessibility2)
}
