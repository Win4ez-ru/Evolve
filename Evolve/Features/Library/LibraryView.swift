import SwiftData
import SwiftUI

struct LibraryView: View {
    @Query(sort: \ContentCategory.sortOrder) private var categories: [ContentCategory]
    @Query(sort: \ContentUnit.title) private var contentUnits: [ContentUnit]
    @Query(sort: \KnowledgeRecord.lastTransitionAt, order: .reverse)
    private var knowledgeRecords: [KnowledgeRecord]
    @Query(sort: \ThoughtRecord.updatedAt, order: .reverse)
    private var thoughts: [ThoughtRecord]
    @Query(sort: \ApplicationAction.createdAt, order: .reverse)
    private var applicationActions: [ApplicationAction]

    @State private var searchText = ""
    @State private var selectedFilter: LibraryFilter = .all
    @State private var selectedCategoryID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                overview
                growthMemory
                categoryPicker
                filterPicker

                if filteredUnits.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: AppSpacing.medium) {
                        ForEach(filteredUnits) { unit in
                            NavigationLink {
                                LibraryDetailView(
                                    unit: unit,
                                    categoryName: categoryName(for: unit.categoryID)
                                )
                            } label: {
                                libraryRow(unit)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("My Growth")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search ideas and topics"
        )
    }

    private var overview: some View {
        FoundationCard {
            HStack(spacing: AppSpacing.large) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColor.accent.opacity(0.12))
                        .frame(width: 58, height: 58)

                    Image(systemName: "brain.head.profile.fill")
                        .font(.title2)
                        .foregroundStyle(AppColor.accent)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Your growth memory")
                        .font(AppTypography.cardTitle)

                    Text("\(thoughts.count) thoughts · \(openActionCount) open actions · \(savedCount) saved")
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
        }
    }

    private var growthMemory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("From your feed")
                    .font(AppTypography.sectionTitle)

                Spacer()

                NavigationLink("Open memory") {
                    GrowthMemoryView()
                }
                .font(AppTypography.caption)
            }

            if thoughts.isEmpty && applicationActions.isEmpty {
                FoundationCard {
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        Image(systemName: "quote.bubble.fill")
                            .foregroundStyle(AppColor.accent)

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Your feed can remember for you")
                                .font(AppTypography.cardTitle)
                            Text("Save a thought or choose an action during a session. Evolve will keep it connected to the idea that sparked it.")
                                .font(AppTypography.supporting)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                }
            } else {
                VStack(spacing: AppSpacing.small) {
                    ForEach(Array(thoughts.prefix(2))) { thought in
                        memoryRow(
                            icon: "quote.bubble.fill",
                            title: thought.body,
                            detail: "Thought · \(thought.updatedAt.formatted(.relative(presentation: .named)))",
                            color: AppColor.accent
                        )
                    }

                    ForEach(Array(applicationActions.filter { $0.status == .planned }.prefix(2))) { action in
                        memoryRow(
                            icon: "arrow.up.forward.app.fill",
                            title: action.note,
                            detail: "Next action · \(action.createdAt.formatted(.relative(presentation: .named)))",
                            color: .orange
                        )
                    }
                }
            }
        }
    }

    private func memoryRow(
        icon: String,
        title: String,
        detail: String,
        color: Color
    ) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(title)
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(3)
                Text(detail)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer(minLength: AppSpacing.small)
        }
        .padding(AppSpacing.large)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private var openActionCount: Int {
        applicationActions.count { $0.status == .planned }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: AppSpacing.small) {
                categoryChip(title: "All topics", categoryID: nil)

                ForEach(categories) { category in
                    categoryChip(title: category.name, categoryID: category.id)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private var filterPicker: some View {
        Picker("Library filter", selection: $selectedFilter) {
            ForEach(LibraryFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.medium) {
            Image(systemName: selectedFilter == .saved ? "bookmark" : "magnifyingglass")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(AppColor.accent)

            Text(selectedFilter == .saved ? "Nothing saved yet" : "No ideas found")
                .font(AppTypography.sectionTitle)

            Text(
                selectedFilter == .saved
                    ? "Open any idea and tap the bookmark to keep it close."
                    : "Try another word, category, or filter."
            )
            .font(AppTypography.body)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.section)
    }

    private func libraryRow(_ unit: ContentUnit) -> some View {
        let record = record(for: unit.id)

        return HStack(alignment: .top, spacing: AppSpacing.large) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(color(for: unit.categoryID).opacity(0.13))
                    .frame(width: 50, height: 50)

                Image(systemName: icon(for: unit.kind))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color(for: unit.categoryID))
            }

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(categoryName(for: unit.categoryID).uppercased())
                        .font(AppTypography.caption)
                        .foregroundStyle(color(for: unit.categoryID))

                    Spacer(minLength: AppSpacing.small)

                    if record?.isSaved == true {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(AppColor.accent)
                            .accessibilityLabel("Saved")
                    }
                }

                Text(unit.title)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(unit.summary)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)

                HStack(spacing: AppSpacing.medium) {
                    Label("\(unit.estimatedMinutes) min", systemImage: "clock")

                    if let status = record?.status, status != .eligible {
                        Label(status.displayName, systemImage: status.systemImage)
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColor.textSecondary)
                .padding(.top, AppSpacing.large)
        }
        .padding(AppSpacing.large)
        .background(AppColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(AppColor.separator.opacity(0.35), lineWidth: 0.5)
        }
    }

    private var filteredUnits: [ContentUnit] {
        contentUnits.filter { unit in
            let matchesSearch = searchText.isEmpty
                || unit.title.localizedCaseInsensitiveContains(searchText)
                || unit.summary.localizedCaseInsensitiveContains(searchText)
                || categoryName(for: unit.categoryID)
                    .localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategoryID == nil
                || selectedCategoryID == unit.categoryID
            let record = record(for: unit.id)
            let matchesFilter: Bool

            switch selectedFilter {
            case .all:
                matchesFilter = true
            case .saved:
                matchesFilter = record?.isSaved == true
            case .practicing:
                matchesFilter = record?.status.map {
                    $0 != .eligible && $0 != .mastered
                } ?? false
            case .mastered:
                matchesFilter = record?.status == .mastered
            }

            return matchesSearch && matchesCategory && matchesFilter
        }
    }

    private var savedCount: Int {
        knowledgeRecords.filter(\.isSaved).count
    }

    private var activeCount: Int {
        knowledgeRecords.filter {
            guard let status = $0.status else {
                return false
            }
            return status != .eligible && status != .mastered
        }.count
    }

    private func categoryChip(title: String, categoryID: UUID?) -> some View {
        let isSelected = selectedCategoryID == categoryID

        return Button {
            selectedCategoryID = categoryID
        } label: {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(isSelected ? Color.white : AppColor.textPrimary)
                .padding(.horizontal, AppSpacing.large)
                .frame(minHeight: 38)
                .background(isSelected ? AppColor.accent : AppColor.surface)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func record(for contentUnitID: UUID) -> KnowledgeRecord? {
        knowledgeRecords.first { $0.contentUnitID == contentUnitID }
    }

    private func categoryName(for categoryID: UUID) -> String {
        categories.first(where: { $0.id == categoryID })?.name ?? "Learning"
    }

    private func color(for categoryID: UUID) -> Color {
        guard let index = categories.firstIndex(where: { $0.id == categoryID }) else {
            return AppColor.accent
        }

        switch index % 3 {
        case 0: return AppColor.accent
        case 1: return .mint
        default: return .orange
        }
    }

    private func icon(for kind: ContentKind?) -> String {
        switch kind {
        case .concept, .explanation: "lightbulb.fill"
        case .principle, .insight: "sparkles"
        case .contextualQuote: "quote.bubble.fill"
        case .question, .dilemma: "questionmark.bubble.fill"
        case .caseStudy, .workedExample: "rectangle.and.text.magnifyingglass"
        case .problem, .challenge: "puzzlepiece.fill"
        case .technique, .experiment: "wand.and.stars"
        case .recallPrompt: "brain.head.profile.fill"
        case nil: "book.closed.fill"
        }
    }
}

private enum LibraryFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case practicing
    case mastered

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .saved: "Saved"
        case .practicing: "Active"
        case .mastered: "Mastered"
        }
    }
}

private struct LibraryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var knowledgeRecords: [KnowledgeRecord]
    @Query(sort: \LearningAttempt.completedAt, order: .reverse)
    private var attempts: [LearningAttempt]
    @Query(sort: \ReviewSchedule.nextReviewAt) private var reviewSchedules: [ReviewSchedule]
    @Query(sort: \ApplicationAction.createdAt, order: .reverse)
    private var applicationActions: [ApplicationAction]

    @State private var presentsSession = false
    @State private var persistenceFailure: PersistenceFailure?

    let unit: ContentUnit
    let categoryName: String

    private var item: LearningSessionItem {
        LearningSessionItem(contentUnit: unit, categoryName: categoryName)
    }

    private var record: KnowledgeRecord? {
        knowledgeRecords.first { $0.contentUnitID == unit.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    Text(categoryName.uppercased())
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)

                    Text(unit.title)
                        .font(AppTypography.screenTitle)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(unit.summary)
                        .font(AppTypography.body)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: AppSpacing.medium) {
                        Label("\(unit.estimatedMinutes) min", systemImage: "clock")
                        Label(item.kindName, systemImage: "square.stack.3d.up.fill")
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
                }

                FoundationCard {
                    ContentUnitRenderer(item: item)
                }

                FoundationCard {
                    ContentMetadataView(item: item)
                }

                personalState

                if !unitAttempts.isEmpty {
                    practiceHistory
                }

                if !unitActions.isEmpty {
                    actionsSection
                }

                Button {
                    presentsSession = true
                } label: {
                    Label("Practice this idea", systemImage: "play.fill")
                }
                .buttonStyle(.primaryAction)
            }
            .padding(AppSpacing.xLarge)
        }
        .background(AppColor.groupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: toggleSaved) {
                    Image(systemName: record?.isSaved == true ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(record?.isSaved == true ? "Remove bookmark" : "Save idea")
            }
        }
        .fullScreenCover(isPresented: $presentsSession) {
            LearningSessionView(plan: LearningSessionPlan(items: [item])) {
                presentsSession = false
            }
        }
        .persistenceFailureAlert($persistenceFailure)
    }

    private var personalState: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Label("YOUR KNOWLEDGE RECORD", systemImage: "person.text.rectangle.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)

                HStack(spacing: AppSpacing.large) {
                    personalMetric(
                        value: record?.status?.displayName ?? "New",
                        label: "Current state"
                    )
                    Divider()
                    personalMetric(
                        value: "\(unitAttempts.count)",
                        label: "Attempts"
                    )
                }

                if let schedule = unitSchedule {
                    Divider()

                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        Image(systemName: schedule.nextReviewAt <= .now ? "clock.arrow.circlepath" : "calendar")
                            .foregroundStyle(AppColor.accent)

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(schedule.nextReviewAt <= .now ? "Ready to recall" : "Next review")
                                .font(AppTypography.cardTitle)

                            Text(
                                schedule.nextReviewAt <= .now
                                    ? "The planned interval has passed. Recall before rereading."
                                    : "\(schedule.nextReviewAt.formatted(date: .abbreviated, time: .omitted)) · \(schedule.reason?.title ?? "Scheduled")"
                            )
                            .font(AppTypography.supporting)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var practiceHistory: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Practice history")
                .font(AppTypography.sectionTitle)

            VStack(spacing: AppSpacing.small) {
                ForEach(unitAttempts.prefix(6)) { attempt in
                    HStack(alignment: .top, spacing: AppSpacing.medium) {
                        Image(systemName: attemptIcon(attempt))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(attempt.isCorrect == false ? AppColor.accent : AppColor.success)
                            .frame(width: 34, height: 34)
                            .background(
                                (attempt.isCorrect == false ? AppColor.accent : AppColor.success)
                                    .opacity(0.10)
                            )
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text(attempt.interactionKind.map(interactionName) ?? "Practice")
                                .font(AppTypography.cardTitle)

                            Text(
                                "\(attempt.completedAt.formatted(date: .abbreviated, time: .shortened)) · \(attempt.confidence.title)"
                            )
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColor.textSecondary)

                            if !attempt.response.isEmpty {
                                Text(attempt.response)
                                    .font(AppTypography.supporting)
                                    .foregroundStyle(AppColor.textSecondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer()
                    }
                    .padding(AppSpacing.medium)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Actions from this idea")
                .font(AppTypography.sectionTitle)

            ForEach(unitActions) { action in
                Label(action.note, systemImage: action.completedAt == nil ? "arrow.up.right.circle" : "checkmark.circle.fill")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.textPrimary)
                    .padding(AppSpacing.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
        }
    }

    private var unitAttempts: [LearningAttempt] {
        attempts.filter { $0.contentUnitID == unit.id }
    }

    private var unitSchedule: ReviewSchedule? {
        reviewSchedules.first { $0.contentUnitID == unit.id }
    }

    private var unitActions: [ApplicationAction] {
        applicationActions.filter { $0.contentUnitID == unit.id }
    }

    private func personalMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(value)
                .font(AppTypography.cardTitle)
                .fixedSize(horizontal: false, vertical: true)
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func attemptIcon(_ attempt: LearningAttempt) -> String {
        if attempt.isCorrect == false {
            return "arrow.clockwise"
        }
        if attempt.interactionKind == .recall {
            return "brain.head.profile.fill"
        }
        return "checkmark"
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

    private func toggleSaved() {
        let activeRecord: KnowledgeRecord
        if let record {
            activeRecord = record
        } else {
            let created = KnowledgeRecord(contentUnitID: unit.id)
            modelContext.insert(created)
            activeRecord = created
        }

        activeRecord.setSaved(!activeRecord.isSaved)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "update this bookmark",
                error: error
            )
        }
    }
}

private struct GrowthMemoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ThoughtRecord.updatedAt, order: .reverse)
    private var thoughts: [ThoughtRecord]
    @Query(sort: \ApplicationAction.createdAt, order: .reverse)
    private var actions: [ApplicationAction]
    @Query private var contentUnits: [ContentUnit]

    @State private var persistenceFailure: PersistenceFailure?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                memorySummary

                memorySection(
                    title: "Thoughts",
                    emptyText: "Thoughts you capture from the feed will return here."
                ) {
                    ForEach(thoughts) { thought in
                        thoughtRow(thought)
                    }
                }

                memorySection(
                    title: "Actions",
                    emptyText: "Choose one observable action at the end of a Growth Loop."
                ) {
                    ForEach(actions) { action in
                        actionRow(action)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xLarge)
            .padding(.bottom, AppSpacing.section)
        }
        .background(AppColor.groupedBackground)
        .navigationTitle("Growth Memory")
        .navigationBarTitleDisplayMode(.large)
        .persistenceFailureAlert($persistenceFailure)
    }

    private var memorySummary: some View {
        FoundationCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Label("PRIVATE · ON THIS DEVICE", systemImage: "lock.shield.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)

                Text("The ideas you made your own")
                    .font(AppTypography.sectionTitle)

                Text("Evolve keeps each thought and action connected to the content that sparked it. This becomes your personal evidence of change.")
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private func memorySection<Content: View>(
        title: String,
        emptyText: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text(title)
                .font(AppTypography.sectionTitle)

            let isEmpty = title == "Thoughts" ? thoughts.isEmpty : actions.isEmpty
            if isEmpty {
                Text(emptyText)
                    .font(AppTypography.supporting)
                    .foregroundStyle(AppColor.textSecondary)
                    .padding(AppSpacing.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
            } else {
                VStack(spacing: AppSpacing.small, content: content)
            }
        }
    }

    private func thoughtRow(_ thought: ThoughtRecord) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Label(thought.kind.title, systemImage: "quote.bubble.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.accent)
                Spacer()
                Text(thought.updatedAt, style: .date)
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Text(thought.body)
                .font(AppTypography.body)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let sourceTitle = sourceTitle(for: thought.contentUnitID) {
                Text("From “\(sourceTitle)”")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(AppSpacing.large)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func actionRow(_ action: ApplicationAction) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Image(systemName: action.status == .completed ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(action.status == .completed ? AppColor.success : .orange)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(action.note)
                    .font(AppTypography.body)
                    .strikethrough(action.status == .completed)

                if let sourceTitle = sourceTitle(for: action.contentUnitID) {
                    Text("From “\(sourceTitle)”")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.textSecondary)
                }

                if action.status == .planned {
                    Button("Mark as done") {
                        complete(action)
                    }
                    .font(AppTypography.caption)
                    .buttonStyle(.bordered)
                    .tint(AppColor.accent)
                }
            }

            Spacer(minLength: AppSpacing.small)
        }
        .padding(AppSpacing.large)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.medium))
    }

    private func sourceTitle(for contentUnitID: UUID?) -> String? {
        guard let contentUnitID else { return nil }
        return contentUnits.first(where: { $0.id == contentUnitID })?.title
    }

    private func complete(_ action: ApplicationAction) {
        action.complete()
        modelContext.insert(
            LocalProductEvent(
                kind: .actionCompleted,
                contentUnitID: action.contentUnitID
            )
        )

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "complete this action",
                error: error
            )
        }
    }
}

private extension ThoughtKind {
    var title: String {
        switch self {
        case .reflection: "Reflection"
        case .insight: "Insight"
        case .decision: "Decision"
        }
    }
}

private extension KnowledgeStatus {
    var displayName: String {
        switch self {
        case .eligible: "Ready"
        case .surfaced, .viewed: "Seen"
        case .engaged: "Practiced"
        case .scheduled: "Learning"
        case .reviewDue: "Review due"
        case .recalled: "Recalled"
        case .remediation: "Revisit"
        case .mastered: "Mastered"
        }
    }

    var systemImage: String {
        switch self {
        case .eligible, .surfaced, .viewed: "eye"
        case .engaged, .scheduled: "circle.dotted"
        case .reviewDue, .remediation: "arrow.clockwise"
        case .recalled: "brain.head.profile"
        case .mastered: "checkmark.seal.fill"
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(PreviewSupport.modelContainer())
}
