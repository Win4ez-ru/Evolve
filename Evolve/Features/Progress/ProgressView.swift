import Charts
import SwiftData
import SwiftUI

struct ProgressView: View {
    @Query(sort: \LearningAttempt.completedAt, order: .reverse)
    private var attempts: [LearningAttempt]
    @Query(sort: \KnowledgeRecord.lastTransitionAt, order: .reverse)
    private var knowledgeRecords: [KnowledgeRecord]
    @Query(sort: \ContentUnit.title) private var contentUnits: [ContentUnit]
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query(sort: \ReviewSchedule.nextReviewAt) private var reviewSchedules: [ReviewSchedule]
    @Query private var applicationActions: [ApplicationAction]
    @Query private var localEvents: [LocalProductEvent]
    @Query private var thoughts: [ThoughtRecord]

    @AppStorage("evolve.currentStreak") private var currentStreak = 0
    @AppStorage("evolve.dailyGoalMinutes") private var dailyGoalMinutes = 12

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                summaryCard
                metricGrid
                categoryProgress
                weeklyChart
                milestones
                recentPractice
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
    }

    private var summaryCard: some View {
        FoundationCard {
            HStack(spacing: AppSpacing.xLarge) {
                ZStack {
                    Circle()
                        .stroke(AppColor.accent.opacity(0.12), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: evidenceProgress)
                        .stroke(
                            AngularGradient(
                                colors: [AppColor.accent, .mint, AppColor.accent],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(Int(evidenceProgress * 100))%")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()

                        Text("evidence")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .frame(width: 116, height: 116)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Evidence-weighted learning progress")
                .accessibilityValue("\(Int(evidenceProgress * 100)) percent")

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label("YOUR PATH", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)

                    Text(progressHeadline)
                        .font(AppTypography.sectionTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(progressMessage)
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var metricGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: AppSpacing.medium),
                GridItem(.flexible(), spacing: AppSpacing.medium)
            ],
            spacing: AppSpacing.medium
        ) {
            metricCard(
                value: "\(dueReviewCount)",
                label: "reviews due",
                detail: dueReviewCount == 0 ? "Queue is clear" : "Recall before rereading",
                icon: "clock.arrow.circlepath",
                color: AppColor.accent
            )
            metricCard(
                value: "\(growthLoopCount)",
                label: "Growth Loops",
                detail: "\(growthLoopsThisWeek) this week",
                icon: "arrow.trianglehead.2.clockwise.rotate.90.circle.fill",
                color: AppColor.accent
            )
            metricCard(
                value: "\(practicedCount)",
                label: "ideas active",
                detail: "\(thoughts.count) personal thoughts",
                icon: "brain.head.profile.fill",
                color: .mint
            )
            metricCard(
                value: accuracyText,
                label: "recall score",
                detail: objectiveAttempts.isEmpty ? "Complete a quiz" : "\(objectiveAttempts.count) checked",
                icon: "scope",
                color: .blue
            )
        }
    }

    private var categoryProgress: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Evidence by direction")
                    .font(AppTypography.sectionTitle)

                Text("Recall and application count more than opening a card.")
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
            }

            ForEach(categoryEvidence) { item in
                FoundationCard {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.name)
                                .font(AppTypography.cardTitle)

                            Spacer()

                            Text("\(Int(item.summary.score * 100))%")
                                .font(AppTypography.sectionTitle)
                                .monospacedDigit()
                                .foregroundStyle(AppColor.accent)
                        }

                        SwiftUI.ProgressView(value: item.summary.score)
                            .tint(AppColor.accent)

                        Text(evidenceExplanation(item.summary))
                            .font(AppTypography.supporting)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private var weeklyChart: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("This week")
                            .font(AppTypography.sectionTitle)

                        Text("\(minutesThisWeek) mindful minutes")
                            .font(AppTypography.supporting)
                            .foregroundStyle(AppColor.textSecondary)
                    }

                    Spacer()

                    Text(weeklyGoalStatus)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)
                }

                Chart(weeklyActivity) { day in
                    BarMark(
                        x: .value("Day", day.label),
                        y: .value("Minutes", max(Double(day.minutes), 0.35))
                    )
                    .foregroundStyle(
                        day.minutes > 0
                            ? LinearGradient(
                                colors: [AppColor.accent, Color.mint],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            : LinearGradient(
                                colors: [
                                    AppColor.separator.opacity(0.25),
                                    AppColor.separator.opacity(0.25)
                                ],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                    )
                    .cornerRadius(6)
                }
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let label = value.as(String.self) {
                                Text(label)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                }
                .frame(height: 150)
                .accessibilityLabel("Learning activity over the last seven days")
            }
        }
    }

    private var milestones: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Milestones")
                .font(AppTypography.sectionTitle)

            ScrollView(.horizontal) {
                HStack(spacing: AppSpacing.medium) {
                    milestone(
                        title: "First step",
                        subtitle: "Complete one Growth Loop",
                        icon: "figure.walk.motion",
                        isUnlocked: growthLoopCount >= 1
                    )
                    milestone(
                        title: "Memory returned",
                        subtitle: "Complete one Recall",
                        icon: "brain.head.profile.fill",
                        isUnlocked: attempts.contains { $0.interactionKind == .recall }
                    )
                    milestone(
                        title: "Idea in motion",
                        subtitle: "Save one real action",
                        icon: "arrow.up.forward.app.fill",
                        isUnlocked: !applicationActions.isEmpty
                    )
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var recentPractice: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Recent practice")
                .font(AppTypography.sectionTitle)

            if attempts.isEmpty {
                Text("Your completed ideas will appear here after the first session.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(.vertical, AppSpacing.large)
            } else {
                VStack(spacing: AppSpacing.small) {
                    ForEach(attempts.prefix(4)) { attempt in
                        HStack(spacing: AppSpacing.medium) {
                            Image(systemName: attempt.isCorrect == false ? "arrow.clockwise" : "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(attempt.isCorrect == false ? AppColor.accent : AppColor.success)
                                .frame(width: 34, height: 34)
                                .background(
                                    (attempt.isCorrect == false ? AppColor.accent : AppColor.success)
                                        .opacity(0.11)
                                )
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                                Text(title(for: attempt.contentUnitID))
                                    .font(AppTypography.cardTitle)
                                    .lineLimit(1)

                                Text(
                                    attempt.completedAt.formatted(
                                        .relative(presentation: .named)
                                    )
                                )
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                            }

                            Spacer()

                            Text("+\(attempt.estimatedMinutes) min")
                                .font(AppTypography.caption)
                                .foregroundStyle(AppColor.textSecondary)
                                .monospacedDigit()
                        }
                        .padding(AppSpacing.medium)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                    }
                }
            }
        }
    }

    private var practicedCount: Int {
        knowledgeRecords.filter {
            guard let status = $0.status else {
                return false
            }
            return status != .eligible && status != .surfaced
        }.count
    }

    private var growthLoopCount: Int {
        localEvents.count { $0.kind == .growthLoopCompleted }
    }

    private var growthLoopsThisWeek: Int {
        let calendar = Calendar.autoupdatingCurrent
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: .now)?.start else {
            return 0
        }
        return localEvents.count {
            $0.kind == .growthLoopCompleted && $0.occurredAt >= weekStart
        }
    }

    private var evidenceProgress: Double {
        guard !categoryEvidence.isEmpty else {
            return 0
        }
        return categoryEvidence.reduce(0) { $0 + $1.summary.score }
            / Double(categoryEvidence.count)
    }

    private var dueReviewCount: Int {
        reviewSchedules.filter { $0.nextReviewAt <= .now }.count
    }

    private var categoryEvidence: [CategoryEvidence] {
        categories.map { category in
            let unitIDs = Set(
                contentUnits
                    .filter { $0.categoryID == category.id }
                    .map(\.id)
            )
            let samples = attempts
                .filter { unitIDs.contains($0.contentUnitID) }
                .compactMap(evidenceSample)

            return CategoryEvidence(
                id: category.id,
                name: category.name,
                summary: EvidenceScorer.summary(for: samples)
            )
        }
    }

    private var objectiveAttempts: [LearningAttempt] {
        attempts.filter { $0.isCorrect != nil }
    }

    private var accuracyText: String {
        guard !objectiveAttempts.isEmpty else {
            return "—"
        }
        let correct = objectiveAttempts.filter { $0.isCorrect == true }.count
        return "\(Int((Double(correct) / Double(objectiveAttempts.count)) * 100))%"
    }

    private var weeklyActivity: [ActivityDay] {
        let calendar = Calendar.autoupdatingCurrent
        let today = calendar.startOfDay(for: .now)

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset - 6, to: today),
                  let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else {
                return nil
            }

            let minutes = attempts
                .filter { $0.completedAt >= date && $0.completedAt < nextDate }
                .reduce(0) { $0 + $1.estimatedMinutes }

            return ActivityDay(
                date: date,
                label: date.formatted(.dateTime.weekday(.narrow)),
                minutes: minutes
            )
        }
    }

    private var minutesThisWeek: Int {
        weeklyActivity.reduce(0) { $0 + $1.minutes }
    }

    private var weeklyGoalStatus: String {
        let weeklyGoal = dailyGoalMinutes * 5
        guard weeklyGoal > 0 else {
            return "ON TRACK"
        }
        return minutesThisWeek >= weeklyGoal
            ? "GOAL REACHED"
            : "\(max(weeklyGoal - minutesThisWeek, 0)) MIN TO GO"
    }

    private var progressHeadline: String {
        switch evidenceProgress {
        case 0: "Your practice starts here"
        case 0..<0.35: "Early evidence is taking shape"
        case 0.35..<0.7: "Recall is becoming more available"
        default: "Your evidence is growing stronger"
        }
    }

    private var progressMessage: String {
        attempts.isEmpty
            ? "Complete a short Growth Loop to create the first piece of learning evidence."
            : "\(strongEvidenceCount) strong outcomes, \(thoughts.count) thoughts, and \(growthLoopCount) completed loops."
    }

    private var strongEvidenceCount: Int {
        categoryEvidence.reduce(0) { $0 + $1.summary.strongEvidenceCount }
    }

    private func evidenceSample(_ attempt: LearningAttempt) -> LearningEvidence? {
        let kind = attempt.interactionKind ?? interactionKind(for: attempt)
        guard let kind else {
            return nil
        }
        return LearningEvidence(
            kind: kind,
            isCorrect: attempt.isCorrect,
            confidence: attempt.confidence,
            difficulty: attempt.difficulty,
            occurredAt: attempt.completedAt
        )
    }

    private func interactionKind(for attempt: LearningAttempt) -> InteractionKind? {
        contentUnits
            .first(where: { $0.id == attempt.contentUnitID })?
            .interactions
            .first(where: { $0.id == attempt.interactionID })?
            .kind
    }

    private func evidenceExplanation(_ summary: EvidenceSummary) -> String {
        guard summary.evidenceCount > 0 else {
            return "No evidence yet. A completed interaction will begin this path."
        }
        if summary.strongEvidenceCount == 0 {
            return "\(summary.evidenceCount) early attempts. A delayed Recall or applied action will carry more weight."
        }
        let kind = summary.strongestKind.map(interactionName) ?? "active practice"
        return "\(summary.strongEvidenceCount) strong outcomes from \(summary.evidenceCount) attempts. Strongest signal: \(kind)."
    }

    private func interactionName(_ kind: InteractionKind) -> String {
        switch kind {
        case .learn: "Learn"
        case .reflect: "Reflect"
        case .discuss: "Discuss"
        case .solve: "Solve"
        case .prove: "Prove"
        case .practice: "Practice"
        case .apply: "Apply"
        case .observe: "Observe"
        case .explain: "Explain"
        case .recall: "Recall"
        case .quiz: "Quiz"
        case .build: "Build"
        case .track: "Track"
        }
    }

    private func metricCard(
        value: String,
        label: String,
        detail: String,
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()

                Text(label)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary.opacity(0.78))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
        .padding(AppSpacing.large)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
    }

    private func milestone(
        title: String,
        subtitle: String,
        icon: String,
        isUnlocked: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Image(systemName: isUnlocked ? icon : "lock.fill")
                .font(.title3)
                .foregroundStyle(isUnlocked ? AppColor.accent : AppColor.textSecondary)

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(isUnlocked ? AppColor.textPrimary : AppColor.textSecondary)

                Text(subtitle)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 142, height: 138, alignment: .topLeading)
        .padding(AppSpacing.large)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .opacity(isUnlocked ? 1 : 0.62)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isUnlocked ? "Unlocked" : "Locked")
    }

    private func title(for contentUnitID: UUID) -> String {
        contentUnits.first(where: { $0.id == contentUnitID })?.title ?? "Learning idea"
    }
}

private struct ActivityDay: Identifiable {
    let date: Date
    let label: String
    let minutes: Int

    var id: Date { date }
}

private struct CategoryEvidence: Identifiable {
    let id: UUID
    let name: String
    let summary: EvidenceSummary
}

#Preview {
    NavigationStack {
        ProgressView()
    }
    .modelContainer(PreviewSupport.modelContainer())
}
