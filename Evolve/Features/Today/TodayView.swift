import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query(sort: \ContentTopic.name) private var topics: [ContentTopic]
    @Query(sort: \ContentUnit.title) private var contentUnits: [ContentUnit]
    @Query(sort: \KnowledgeRecord.lastTransitionAt, order: .reverse)
    private var knowledgeRecords: [KnowledgeRecord]
    @Query(sort: \LearningAttempt.completedAt, order: .reverse)
    private var attempts: [LearningAttempt]
    @Query(sort: \ReviewSchedule.nextReviewAt) private var reviewSchedules: [ReviewSchedule]
    @Query private var learnerProfiles: [LearnerProfile]

    @State private var presentsSession = false
    @State private var persistenceFailure: PersistenceFailure?

    @AppStorage("evolve.displayName") private var displayName = ""
    @AppStorage("evolve.dailyGoalMinutes") private var dailyGoalMinutes = 12
    @AppStorage("evolve.preferredSessionMinutes") private var preferredSessionMinutes = 5
    @AppStorage("evolve.currentStreak") private var currentStreak = 0

    private let now: Date

    init(now: Date = .now) {
        self.now = now
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                header
                focusCard
                dailyProgress
                reviewOverview
                todayPlan
                closingThought
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.top, AppSpacing.large)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(isPresented: $presentsSession) {
            LearningSessionView(plan: sessionPlan) {
                presentsSession = false
            }
        }
        .task {
            refreshDueReviews()
        }
        .persistenceFailureAlert($persistenceFailure)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(greeting)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)

                Text(displayName.isEmpty ? "Ready to evolve?" : displayName)
                    .font(AppTypography.screenTitle)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.small)

            ZStack {
                Circle()
                    .fill(AppColor.accent.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: "leaf.fill")
                    .font(.title2)
                    .foregroundStyle(AppColor.accent)
            }
            .accessibilityHidden(true)
        }
    }

    private var focusCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
            HStack(alignment: .top) {
                Label("TODAY’S FOCUS", systemImage: "sparkles")
                    .font(AppTypography.caption)
                    .foregroundStyle(.white.opacity(0.82))

                Spacer()

                Text("\(sessionPlan.totalMinutes) MIN")
                    .font(AppTypography.caption)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.82))
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Scroll with purpose.\nLeave with a next step.")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(focusSupportingText)
                    .font(AppTypography.body)
                    .foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AppSpacing.large) {
                heroMetric(value: "\(sessionPlan.items.count)", label: "feed cards")
                heroMetric(value: "\(currentStreak)", label: "day streak")
            }

            Button {
                presentsSession = true
            } label: {
                HStack {
                    Text(attemptsToday.isEmpty ? "Open today’s Focus Feed" : "Continue your Growth Loop")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(AppTypography.action)
                .foregroundStyle(AppColor.heroActionForeground)
                .padding(.horizontal, AppSpacing.large)
                .frame(minHeight: 52)
                .background(AppColor.heroActionBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(sessionPlan.isEmpty)
            .accessibilityHint(
                "Opens a finite vertical feed with \(sessionPlan.items.count) growth cards"
            )
        }
        .padding(AppSpacing.xLarge)
        .background {
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [
                        Color(red: 0.23, green: 0.18, blue: 0.62),
                        Color(red: 0.44, green: 0.32, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 210, height: 210)
                    .offset(x: 76, y: -96)

                Circle()
                    .fill(Color.mint.opacity(0.18))
                    .frame(width: 130, height: 130)
                    .offset(x: 62, y: 168)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .shadow(color: AppColor.accent.opacity(0.22), radius: 26, y: 14)
    }

    private var reviewOverview: some View {
        NavigationLink {
            ReviewQueueView()
        } label: {
            HStack(spacing: AppSpacing.large) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill((dueReviewCount > 0 ? AppColor.accent : Color.mint).opacity(0.12))
                        .frame(width: 54, height: 54)

                    Image(systemName: dueReviewCount > 0 ? "clock.arrow.circlepath" : "calendar.badge.checkmark")
                        .font(.title3)
                        .foregroundStyle(dueReviewCount > 0 ? AppColor.accent : .mint)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(dueReviewCount > 0 ? "\(dueReviewCount) ready to recall" : "Review queue is clear")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(nextReviewDescription)
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: AppSpacing.small)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(AppSpacing.large)
            .background(AppColor.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens your complete review schedule")
    }

    private var dailyProgress: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("Daily rhythm")
                            .font(AppTypography.cardTitle)

                        Text("\(minutesToday) of \(dailyGoalMinutes) mindful minutes")
                            .font(AppTypography.supporting)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()

                    Text("\(Int(goalProgress * 100))%")
                        .font(AppTypography.sectionTitle)
                        .monospacedDigit()
                        .foregroundStyle(goalProgress >= 1 ? AppColor.success : AppColor.accent)
                }

                SwiftUI.ProgressView(value: goalProgress)
                    .tint(goalProgress >= 1 ? AppColor.success : AppColor.accent)
                    .accessibilityLabel("Daily learning goal")
                    .accessibilityValue("\(Int(goalProgress * 100)) percent")

                HStack(spacing: AppSpacing.small) {
                    Image(systemName: goalProgress >= 1 ? "checkmark.seal.fill" : "circle.dotted")
                        .foregroundStyle(goalProgress >= 1 ? AppColor.success : AppColor.accent)

                    Text(
                        goalProgress >= 1
                            ? "Goal reached. Let the ideas settle."
                            : "\(max(dailyGoalMinutes - minutesToday, 0)) minutes will complete today’s intention."
                    )
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private var todayPlan: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Inside today’s feed")
                    .font(AppTypography.sectionTitle)

                Spacer()

                Text("FINITE BY DESIGN")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            VStack(spacing: AppSpacing.small) {
                ForEach(Array(sessionPlan.items.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: AppSpacing.medium) {
                        ZStack {
                            Circle()
                                .fill(categoryColor(for: index).opacity(0.14))
                                .frame(width: 42, height: 42)

                            Image(systemName: item.kind.systemImage)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(categoryColor(for: index))
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(item.title)
                                .font(AppTypography.cardTitle)
                                .fixedSize(horizontal: false, vertical: true)

                            Text("\(item.categoryName) · \(item.estimatedMinutes) min")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)

                            Label(
                                item.recommendationReason,
                                systemImage: item.isReview ? "clock.arrow.circlepath" : "sparkles"
                            )
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.accent)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: AppSpacing.small)

                        Text("\(index + 1)")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .padding(AppSpacing.large)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
            }
        }
    }

    private var closingThought: some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: "quote.opening")
                .foregroundStyle(AppColor.accent)

            Text("A useful feed should leave you with more than something to save: one thing to try.")
                .font(AppTypography.supporting)
                .italic()
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.small)
    }

    private var sessionPlan: LearningSessionPlan {
        let categoryNames = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0.name) }
        )
        let items = prioritizedContentUnits.map { unit in
            LearningSessionItem(
                contentUnit: unit,
                categoryName: categoryNames[unit.categoryID] ?? "Learning",
                recommendationReason: recommendationReason(for: unit),
                isReview: isReview(unit.id)
            )
        }
        return LearningSessionPlan(items: items, targetMinutes: preferredSessionMinutes)
    }

    private var prioritizedContentUnits: [ContentUnit] {
        let recordsByID = Dictionary(
            uniqueKeysWithValues: knowledgeRecords.map { ($0.contentUnitID, $0) }
        )

        let selectedCategoryIDs = Set(learnerProfiles.first?.selectedCategoryIDs ?? [])
        let relevantUnits = selectedCategoryIDs.isEmpty
            ? contentUnits
            : contentUnits.filter { selectedCategoryIDs.contains($0.categoryID) }

        return relevantUnits.sorted { first, second in
            let firstPriority = priority(for: recordsByID[first.id]?.status)
            let secondPriority = priority(for: recordsByID[second.id]?.status)

            if firstPriority == secondPriority {
                let firstGoalPriority = goalTopicPriority(for: first)
                let secondGoalPriority = goalTopicPriority(for: second)
                if firstGoalPriority != secondGoalPriority {
                    return firstGoalPriority < secondGoalPriority
                }

                let firstDifficultyDistance = difficultyDistance(for: first)
                let secondDifficultyDistance = difficultyDistance(for: second)
                if firstDifficultyDistance != secondDifficultyDistance {
                    return firstDifficultyDistance < secondDifficultyDistance
                }
                return first.title.localizedStandardCompare(second.title) == .orderedAscending
            }
            return firstPriority < secondPriority
        }
    }

    private var dueReviewCount: Int {
        reviewSchedules.filter { $0.nextReviewAt <= now }.count
    }

    private var nextReviewDescription: String {
        if dueReviewCount > 0 {
            return "Due ideas are placed before new material."
        }
        guard let next = reviewSchedules.first else {
            return "Complete a practice and Evolve will schedule a return."
        }
        return "Next recall \(next.nextReviewAt.formatted(.relative(presentation: .named)))."
    }

    private var focusSupportingText: String {
        if dueReviewCount > 0 {
            return "A focused mix of recall, discovery, and one useful next step."
        }
        if let goal = learnerProfiles.first?.learningGoal {
            return "Selected to help you \(goal.title.lowercased())."
        }
        return "A vertical session shaped around focus, action, and ideas worth remembering."
    }

    private var attemptsToday: [LearningAttempt] {
        attempts.filter { Calendar.autoupdatingCurrent.isDateInToday($0.completedAt) }
    }

    private var minutesToday: Int {
        attemptsToday.reduce(0) { $0 + $1.estimatedMinutes }
    }

    private var goalProgress: Double {
        guard dailyGoalMinutes > 0 else {
            return 1
        }
        return min(Double(minutesToday) / Double(dailyGoalMinutes), 1)
    }

    private var greeting: String {
        let hour = Calendar.autoupdatingCurrent.component(.hour, from: now)
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    private func priority(for status: KnowledgeStatus?) -> Int {
        switch status {
        case .reviewDue, .remediation: 0
        case nil, .eligible, .surfaced, .viewed: 1
        case .engaged, .scheduled, .recalled: 2
        case .mastered: 3
        }
    }

    private func isReview(_ contentUnitID: UUID) -> Bool {
        if reviewSchedules.contains(where: {
            $0.contentUnitID == contentUnitID && $0.nextReviewAt <= now
        }) {
            return true
        }
        let status = knowledgeRecords.first { $0.contentUnitID == contentUnitID }?.status
        return status == .reviewDue || status == .remediation
    }

    private func recommendationReason(for unit: ContentUnit) -> String {
        if let schedule = reviewSchedules.first(where: {
            $0.contentUnitID == unit.id && $0.nextReviewAt <= now
        }) {
            return "Due recall · \(schedule.reason?.title ?? "Ready to strengthen")"
        }
        if knowledgeRecords.first(where: { $0.contentUnitID == unit.id })?.status == .remediation {
            return "A supportive retry after a difficult attempt"
        }
        if let goal = learnerProfiles.first?.learningGoal {
            if let preferredTopicID, unit.topicIDs.contains(preferredTopicID) {
                return "Matched to your goal · \(goal.title)"
            }
            if let level = learnerProfiles.first?.learnerLevel {
                return "Balances your \(level.title.lowercased()) session"
            }
            return "Balances your goal-focused session"
        }
        return "A fresh idea from a chosen interest"
    }

    private var preferredTopicID: UUID? {
        guard let slug = learnerProfiles.first?.learningGoal?.preferredTopicSlug else {
            return nil
        }
        return topics.first(where: { $0.slug == slug })?.id
    }

    private func goalTopicPriority(for unit: ContentUnit) -> Int {
        guard let preferredTopicID else {
            return 0
        }
        return unit.topicIDs.contains(preferredTopicID) ? 0 : 1
    }

    private func difficultyDistance(for unit: ContentUnit) -> Int {
        let target: Int
        switch learnerProfiles.first?.learnerLevel {
        case .starting:
            target = ContentDifficulty.introductory.rawValue
        case .growing:
            target = ContentDifficulty.foundational.rawValue
        case .experienced:
            target = ContentDifficulty.intermediate.rawValue
        case nil:
            target = ContentDifficulty.foundational.rawValue
        }
        return abs(unit.difficultyRawValue - target)
    }

    private func refreshDueReviews() {
        do {
            for schedule in reviewSchedules where schedule.nextReviewAt <= now {
                guard let record = knowledgeRecords.first(where: {
                    $0.contentUnitID == schedule.contentUnitID
                }) else {
                    continue
                }
                if record.status == .scheduled || record.status == .mastered {
                    try record.transition(to: .reviewDue, at: now)
                }
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "prepare your reviews",
                error: error
            )
        }
    }

    private func heroMetric(value: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xSmall) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.white)

            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.white.opacity(0.72))
        }
    }

    private func categoryColor(for index: Int) -> Color {
        switch index % 3 {
        case 0: AppColor.accent
        case 1: .mint
        default: .orange
        }
    }
}

private struct ReviewQueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReviewSchedule.nextReviewAt) private var schedules: [ReviewSchedule]
    @Query(sort: \ContentUnit.title) private var contentUnits: [ContentUnit]
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query private var knowledgeRecords: [KnowledgeRecord]

    @State private var selectedItem: LearningSessionItem?
    @State private var persistenceFailure: PersistenceFailure?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                queueSummary

                if schedules.isEmpty {
                    emptyQueue
                } else {
                    if !dueSchedules.isEmpty {
                        scheduleSection(
                            title: "Ready now",
                            supporting: "Recall before rereading",
                            schedules: dueSchedules
                        )
                    }

                    if !upcomingSchedules.isEmpty {
                        scheduleSection(
                            title: "Coming back later",
                            supporting: "Spacing gives memory room to work",
                            schedules: upcomingSchedules
                        )
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("Review queue")
        .navigationBarTitleDisplayMode(.large)
        .task {
            refreshDueStates()
        }
        .fullScreenCover(item: $selectedItem) { item in
            LearningSessionView(plan: LearningSessionPlan(items: [item])) {
                selectedItem = nil
            }
        }
        .persistenceFailureAlert($persistenceFailure)
    }

    private var queueSummary: some View {
        FoundationCard {
            HStack(spacing: AppSpacing.large) {
                ZStack {
                    Circle()
                        .fill(AppColor.accent.opacity(0.12))
                        .frame(width: 62, height: 62)

                    Text("\(dueSchedules.count)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(AppColor.accent)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(dueSchedules.isEmpty ? "Nothing due" : "Ideas ready to recall")
                        .font(AppTypography.sectionTitle)

                    Text("A review appears only when its planned interval has passed.")
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var emptyQueue: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 38))
                .foregroundStyle(AppColor.accent)

            Text("Your first return will appear here")
                .font(AppTypography.sectionTitle)

            Text("Practice an idea from Today or Library to create a private review schedule.")
                .font(AppTypography.body)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.section)
    }

    private func scheduleSection(
        title: String,
        supporting: String,
        schedules: [ReviewSchedule]
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.sectionTitle)

                Text(supporting)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
            }

            ForEach(schedules) { schedule in
                if let unit = contentUnits.first(where: { $0.id == schedule.contentUnitID }) {
                    Button {
                        selectedItem = LearningSessionItem(
                            contentUnit: unit,
                            categoryName: categoryName(for: unit.categoryID),
                            recommendationReason: schedule.reason?.title ?? "Scheduled recall",
                            isReview: true
                        )
                    } label: {
                        reviewRow(schedule: schedule, unit: unit)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func reviewRow(schedule: ReviewSchedule, unit: ContentUnit) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.large) {
            Image(systemName: schedule.nextReviewAt <= .now ? "brain.head.profile.fill" : "calendar")
                .font(.headline)
                .foregroundStyle(AppColor.accent)
                .frame(width: 44, height: 44)
                .background(AppColor.accent.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(unit.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(categoryName(for: unit.categoryID))
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Text(reviewTiming(schedule))
                    .font(AppTypography.caption)
                    .foregroundStyle(schedule.nextReviewAt <= .now ? AppColor.accent : AppColor.textSecondary)
            }

            Spacer()

            Image(systemName: schedule.nextReviewAt <= .now ? "play.fill" : "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppColor.accent)
                .padding(.top, AppSpacing.medium)
        }
        .padding(AppSpacing.large)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private var dueSchedules: [ReviewSchedule] {
        schedules.filter { $0.nextReviewAt <= .now }
    }

    private var upcomingSchedules: [ReviewSchedule] {
        schedules.filter { $0.nextReviewAt > .now }
    }

    private func categoryName(for id: UUID) -> String {
        categories.first(where: { $0.id == id })?.name ?? "Learning"
    }

    private func reviewTiming(_ schedule: ReviewSchedule) -> String {
        if schedule.nextReviewAt <= .now {
            return "Ready now · interval \(schedule.intervalDays)d"
        }
        return "Returns \(schedule.nextReviewAt.formatted(.relative(presentation: .named)))"
    }

    private func refreshDueStates() {
        do {
            for schedule in dueSchedules {
                guard let record = knowledgeRecords.first(where: {
                    $0.contentUnitID == schedule.contentUnitID
                }) else {
                    continue
                }
                if record.status == .scheduled || record.status == .mastered {
                    try record.transition(to: .reviewDue)
                }
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "prepare your review queue",
                error: error
            )
        }
    }
}

private extension ContentKind {
    var systemImage: String {
        switch self {
        case .concept, .explanation: "lightbulb.fill"
        case .principle, .insight: "sparkles"
        case .contextualQuote: "quote.bubble.fill"
        case .question, .dilemma: "questionmark.bubble.fill"
        case .caseStudy, .workedExample: "rectangle.and.text.magnifyingglass"
        case .problem, .challenge: "puzzlepiece.fill"
        case .technique, .experiment: "wand.and.stars"
        case .recallPrompt: "brain.head.profile.fill"
        }
    }
}

#Preview("Today · Light") {
    NavigationStack {
        TodayView(now: Date(timeIntervalSince1970: 1_750_000_000))
    }
    .modelContainer(PreviewSupport.modelContainer())
    .preferredColorScheme(.light)
}

#Preview("Today · Dark") {
    NavigationStack {
        TodayView(now: Date(timeIntervalSince1970: 1_750_000_000))
    }
    .modelContainer(PreviewSupport.modelContainer())
    .preferredColorScheme(.dark)
}
