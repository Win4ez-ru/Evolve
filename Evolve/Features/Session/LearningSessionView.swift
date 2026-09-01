import SwiftData
import SwiftUI

struct LearningSessionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    @Query private var knowledgeRecords: [KnowledgeRecord]
    @Query private var reviewSchedules: [ReviewSchedule]
    @Query private var attempts: [LearningAttempt]
    @Query private var contentUnits: [ContentUnit]
    @Query private var domainProgressRecords: [DomainProgressRecord]
    @Query(sort: \LocalProductEvent.occurredAt) private var localEvents: [LocalProductEvent]

    @State private var session: LearningSessionState
    @State private var visiblePageID: UUID?
    @State private var activeSheet: GrowthFeedSheet?
    @State private var usefulItemIDs: Set<UUID> = []
    @State private var impressionItemIDs: Set<UUID> = []
    @State private var pageAppearedAt = Date.now
    @State private var showsStopConfirmation = false
    @State private var didRecordSessionStart = false
    @State private var didRecordSessionCompletion = false
    @State private var didRecordGrowthLoop = false
    @State private var persistenceFailure: PersistenceFailure?

    private let onDismiss: () -> Void

    private static let completionPageID = UUID(
        uuidString: "F0000000-0000-4000-8000-000000000001"
    )!

    init(plan: LearningSessionPlan, onDismiss: @escaping () -> Void) {
        let initialState = LearningSessionState(plan: plan)
        _session = State(initialValue: initialState)
        _visiblePageID = State(initialValue: plan.items.first?.id)
        self.onDismiss = onDismiss
    }

    var body: some View {
        Group {
            if session.phase == .active {
                activeSession
                    .transition(.opacity)
            } else {
                SessionStopStateView(
                    phase: session.phase,
                    position: session.position,
                    total: session.plan.items.count,
                    completedCount: session.completedItemIDs.count,
                    sessionItems: session.plan.items,
                    onSaveAction: saveApplicationAction,
                    onDismiss: onDismiss
                )
                .transition(.opacity)
            }
        }
        .background(AppColor.groupedBackground.ignoresSafeArea())
        .animation(AppMotion.session(reduceMotion: reduceMotion), value: session.phase)
        .confirmationDialog(
            "End this session?",
            isPresented: $showsStopConfirmation,
            titleVisibility: .visible
        ) {
            Button("End session", role: .destructive) {
                session.stop()
            }
            Button("Keep scrolling", role: .cancel) {}
        } message: {
            Text("Your progress and thoughts are already saved.")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .practice(let item):
                GrowthPracticeSheet(
                    item: item,
                    position: position(of: item.id),
                    total: session.plan.items.count
                ) { result in
                    completePractice(item: item, result: result)
                }
            case .thought(let item):
                ThoughtComposerSheet(item: item) { text in
                    saveThought(for: item, body: text)
                }
            }
        }
        .persistenceFailureAlert($persistenceFailure)
    }

    private var activeSession: some View {
        ZStack(alignment: .top) {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(session.plan.items) { item in
                        GrowthFeedPage(
                            item: item,
                            isSaved: isSaved(item.id),
                            isUseful: usefulItemIDs.contains(item.id),
                            isPracticed: session.completedItemIDs.contains(item.id),
                            onToggleSaved: { toggleSaved(item.id) },
                            onToggleUseful: { toggleUseful(item.id) },
                            onOpenThought: { activeSheet = .thought(item) },
                            onOpenPractice: { activeSheet = .practice(item) }
                        )
                        .containerRelativeFrame(.vertical)
                        .id(item.id)
                    }

                    GrowthFeedFinishPage(
                        viewedCount: impressionItemIDs.count,
                        practicedCount: session.completedItemIDs.count,
                        usefulCount: usefulItemIDs.count,
                        onFinish: completeSession
                    )
                    .containerRelativeFrame(.vertical)
                    .id(Self.completionPageID)
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $visiblePageID)
            .background(Color.black)
            .ignoresSafeArea()
            .onChange(of: visiblePageID) { oldValue, newValue in
                handlePageChange(from: oldValue, to: newValue)
            }

            GrowthFeedHeader(
                position: currentFeedPosition,
                total: session.plan.items.count,
                isAtFinish: visiblePageID == Self.completionPageID,
                onClose: { showsStopConfirmation = true }
            )
            .padding(.horizontal, AppSpacing.large)
            .padding(.top, AppSpacing.small)
        }
        .task {
            restoreUsefulSelections()
            recordSessionStartedIfNeeded()
            if let firstID = session.plan.items.first?.id {
                recordImpressionIfNeeded(firstID)
            }
        }
    }

    private var currentFeedPosition: Int {
        guard let visiblePageID,
              let index = session.plan.items.firstIndex(where: { $0.id == visiblePageID }) else {
            return session.plan.items.count
        }
        return index + 1
    }

    private func position(of itemID: UUID) -> Int {
        (session.plan.items.firstIndex(where: { $0.id == itemID }) ?? 0) + 1
    }

    private func handlePageChange(from oldID: UUID?, to newID: UUID?) {
        let now = Date.now
        if let oldID,
           oldID != Self.completionPageID,
           !session.completedItemIDs.contains(oldID),
           now.timeIntervalSince(pageAppearedAt) < 2.5 {
            recordFeedEvent(
                .feedSkipped,
                contentUnitID: oldID,
                value: now.timeIntervalSince(pageAppearedAt)
            )
        }

        pageAppearedAt = now
        guard let newID, newID != Self.completionPageID else {
            return
        }
        session.select(itemID: newID)
        recordImpressionIfNeeded(newID)
    }

    private func recordImpressionIfNeeded(_ itemID: UUID) {
        guard impressionItemIDs.insert(itemID).inserted else {
            return
        }
        recordFeedEvent(.feedImpression, contentUnitID: itemID)
    }

    private func toggleUseful(_ itemID: UUID) {
        let isNowUseful: Bool
        if usefulItemIDs.contains(itemID) {
            usefulItemIDs.remove(itemID)
            isNowUseful = false
        } else {
            usefulItemIDs.insert(itemID)
            isNowUseful = true
        }
        recordFeedEvent(
            .feedUseful,
            contentUnitID: itemID,
            value: isNowUseful ? 1 : 0
        )
    }

    private func restoreUsefulSelections() {
        let sessionIDs = Set(session.plan.items.map(\.id))
        var latestValueByItem: [UUID: Bool] = [:]

        for event in localEvents where event.kind == .feedUseful {
            guard let contentUnitID = event.contentUnitID,
                  sessionIDs.contains(contentUnitID) else {
                continue
            }
            // Legacy events had no value and represented an affirmative tap.
            latestValueByItem[contentUnitID] = event.numericValue != 0
        }

        usefulItemIDs = Set(
            latestValueByItem.compactMap { itemID, isUseful in
                isUseful ? itemID : nil
            }
        )
    }

    private func toggleSaved(_ itemID: UUID) {
        let record: KnowledgeRecord
        if let existing = knowledgeRecords.first(where: { $0.contentUnitID == itemID }) {
            record = existing
        } else {
            let created = KnowledgeRecord(contentUnitID: itemID)
            modelContext.insert(created)
            record = created
        }
        record.setSaved(!record.isSaved)
        saveContext(operation: "save this idea")
    }

    private func isSaved(_ itemID: UUID) -> Bool {
        knowledgeRecords.first(where: { $0.contentUnitID == itemID })?.isSaved == true
    }

    private func completePractice(
        item: LearningSessionItem,
        result: LearningInteractionResult
    ) -> Bool {
        guard !session.completedItemIDs.contains(item.id) else {
            return true
        }

        do {
            try persistAttempt(for: item, result: result)
            session.markCompleted(itemID: item.id)
            return true
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(
                operation: "save this practice",
                error: error
            )
            return false
        }
    }

    private func persistAttempt(
        for item: LearningSessionItem,
        result: LearningInteractionResult
    ) throws {
        let completedAt = result.completedAt
        let attempt = LearningAttempt(
            contentUnitID: item.id,
            interactionID: result.interactionID,
            interactionKind: result.interactionKind,
            response: result.response,
            isCorrect: result.isCorrect,
            confidence: result.confidence,
            startedAt: result.startedAt,
            completedAt: completedAt,
            durationSeconds: result.durationSeconds,
            usedHint: result.usedHint,
            difficulty: result.difficulty,
            estimatedMinutes: item.estimatedMinutes
        )
        modelContext.insert(attempt)

        let record: KnowledgeRecord
        if let existing = knowledgeRecords.first(where: { $0.contentUnitID == item.id }) {
            record = existing
        } else {
            let created = KnowledgeRecord(contentUnitID: item.id, createdAt: completedAt)
            modelContext.insert(created)
            record = created
        }

        if item.isReview, record.status == .scheduled {
            try record.transition(to: .reviewDue, at: completedAt)
        }

        let effectiveCorrectness: Bool?
        if result.interactionKind == .recall, result.isCorrect == nil {
            effectiveCorrectness = result.confidence == .low ? false : true
        } else {
            effectiveCorrectness = result.isCorrect
        }

        try record.recordEngagement(isCorrect: effectiveCorrectness, at: completedAt)
        updateReviewSchedule(
            for: item,
            result: result,
            effectiveCorrectness: effectiveCorrectness,
            at: completedAt
        )
        updateDomainProgress(with: attempt, item: item, at: completedAt)

        let trimmedResponse = result.response.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedResponse.isEmpty,
           result.interactionKind?.growthUnitRole == .reflect {
            modelContext.insert(
                ThoughtRecord(
                    contentUnitID: item.id,
                    body: trimmedResponse,
                    kind: .reflection,
                    createdAt: completedAt
                )
            )
            modelContext.insert(
                LocalProductEvent(
                    kind: .thoughtCreated,
                    contentUnitID: item.id,
                    occurredAt: completedAt
                )
            )
        }

        modelContext.insert(
            LocalProductEvent(
                kind: .attemptCompleted,
                contentUnitID: item.id,
                occurredAt: completedAt,
                numericValue: result.isCorrect.map { $0 ? 1.0 : 0.0 }
            )
        )

        try modelContext.save()
    }

    private func saveThought(for item: LearningSessionItem, body: String) -> Bool {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return false
        }

        modelContext.insert(
            ThoughtRecord(
                contentUnitID: item.id,
                body: trimmed,
                kind: .insight
            )
        )
        modelContext.insert(
            LocalProductEvent(kind: .thoughtCreated, contentUnitID: item.id)
        )
        return saveContext(operation: "save this thought")
    }

    private func updateReviewSchedule(
        for item: LearningSessionItem,
        result: LearningInteractionResult,
        effectiveCorrectness: Bool?,
        at date: Date
    ) {
        let existing = reviewSchedules.first { $0.contentUnitID == item.id }
        let decision = ReviewScheduler.decision(
            interactionKind: result.interactionKind,
            isCorrect: effectiveCorrectness,
            confidence: result.confidence,
            previousRepetitionCount: existing?.repetitionCount ?? 0,
            previousLapseCount: existing?.lapseCount ?? 0,
            now: date
        )

        if let existing {
            existing.apply(decision, at: date)
        } else {
            modelContext.insert(
                ReviewSchedule(
                    contentUnitID: item.id,
                    decision: decision,
                    updatedAt: date
                )
            )
        }

        modelContext.insert(
            LocalProductEvent(
                kind: .reviewScheduled,
                contentUnitID: item.id,
                occurredAt: date,
                numericValue: Double(decision.intervalDays)
            )
        )
    }

    private func updateDomainProgress(
        with newAttempt: LearningAttempt,
        item: LearningSessionItem,
        at date: Date
    ) {
        guard let unit = contentUnits.first(where: { $0.id == item.id }) else {
            return
        }

        let unitIDs = Set(
            contentUnits.filter { $0.categoryID == unit.categoryID }.map(\.id)
        )
        let categoryAttempts = attempts.filter {
            unitIDs.contains($0.contentUnitID) && $0.id != newAttempt.id
        } + [newAttempt]
        let evidence = categoryAttempts.compactMap { attempt -> LearningEvidence? in
            let kind = attempt.interactionKind ?? interactionKind(for: attempt)
            guard let kind else { return nil }
            return LearningEvidence(
                kind: kind,
                isCorrect: attempt.isCorrect,
                confidence: attempt.confidence,
                difficulty: attempt.difficulty,
                occurredAt: attempt.completedAt
            )
        }
        let summary = EvidenceScorer.summary(for: evidence, now: date)

        if let existing = domainProgressRecords.first(where: { $0.categoryID == unit.categoryID }) {
            existing.apply(summary, at: date)
        } else {
            modelContext.insert(
                DomainProgressRecord(
                    categoryID: unit.categoryID,
                    summary: summary,
                    updatedAt: date
                )
            )
        }
    }

    private func interactionKind(for attempt: LearningAttempt) -> InteractionKind? {
        contentUnits
            .first(where: { $0.id == attempt.contentUnitID })?
            .interactions
            .first(where: { $0.id == attempt.interactionID })?
            .kind
    }

    private func recordSessionStartedIfNeeded() {
        guard !didRecordSessionStart else { return }
        didRecordSessionStart = true
        modelContext.insert(
            LocalProductEvent(
                kind: .sessionStarted,
                numericValue: Double(session.plan.items.count)
            )
        )
        if !saveContext(operation: "start this session") {
            didRecordSessionStart = false
        }
    }

    private func completeSession() {
        guard !didRecordSessionCompletion else {
            session.finish()
            return
        }

        let now = Date.now
        modelContext.insert(
            LocalProductEvent(
                kind: .feedCompleted,
                occurredAt: now,
                numericValue: Double(impressionItemIDs.count)
            )
        )
        didRecordSessionCompletion = true

        let earnedMinutes = session.earnedMinutes

        if earnedMinutes > 0 {
            modelContext.insert(
                LocalProductEvent.sessionCompletion(
                    occurredAt: now,
                    learningMinutes: earnedMinutes
                )
            )
            modelContext.insert(
                LocalProductEvent(
                    kind: .growthLoopCompleted,
                    occurredAt: now,
                    numericValue: Double(session.completedItemIDs.count)
                )
            )
            didRecordGrowthLoop = true
        }

        guard saveContext(operation: "complete this session") else {
            didRecordSessionCompletion = false
            didRecordGrowthLoop = false
            return
        }
        session.finish()
    }

    private func recordFeedEvent(
        _ kind: LocalEventKind,
        contentUnitID: UUID,
        value: Double? = nil
    ) {
        modelContext.insert(
            LocalProductEvent(
                kind: kind,
                contentUnitID: contentUnitID,
                numericValue: value
            )
        )
        _ = saveContext(operation: "update your feed")
    }

    private func saveApplicationAction(contentUnitID: UUID, note: String) -> Bool {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        modelContext.insert(
            ApplicationAction(contentUnitID: contentUnitID, note: trimmed)
        )
        modelContext.insert(
            LocalProductEvent(kind: .applicationCreated, contentUnitID: contentUnitID)
        )
        let recordsGrowthLoop = !didRecordGrowthLoop
        if recordsGrowthLoop {
            modelContext.insert(
                LocalProductEvent(kind: .growthLoopCompleted, contentUnitID: contentUnitID)
            )
        }
        guard saveContext(operation: "save this next action") else {
            return false
        }
        if recordsGrowthLoop {
            didRecordGrowthLoop = true
        }
        return true
    }

    @discardableResult
    private func saveContext(operation: String) -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            persistenceFailure = PersistenceFailure(operation: operation, error: error)
            return false
        }
    }
}

private enum GrowthFeedSheet: Identifiable {
    case practice(LearningSessionItem)
    case thought(LearningSessionItem)

    var id: String {
        switch self {
        case .practice(let item): "practice-\(item.id.uuidString)"
        case .thought(let item): "thought-\(item.id.uuidString)"
        }
    }
}

private struct GrowthFeedHeader: View {
    let position: Int
    let total: Int
    let isAtFinish: Bool
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.24), in: Circle())
            }
            .accessibilityLabel("End session")

            VStack(alignment: .leading, spacing: 5) {
                Text(isAtFinish ? "SESSION COMPLETE" : "FOCUS FEED")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.22))
                        Capsule()
                            .fill(.white)
                            .frame(
                                width: proxy.size.width
                                    * (isAtFinish ? 1 : Double(position) / Double(max(total, 1)))
                            )
                    }
                }
                .frame(height: 3)
            }

            Text(isAtFinish ? "✓" : "\(position)/\(total)")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 34, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct GrowthFeedPage: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let item: LearningSessionItem
    let isSaved: Bool
    let isUseful: Bool
    let isPracticed: Bool
    let onToggleSaved: () -> Void
    let onToggleUseful: () -> Void
    let onOpenThought: () -> Void
    let onOpenPractice: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let usesCompactLayout = proxy.size.height < 780 || dynamicTypeSize.isAccessibilitySize

            ZStack {
                background

                feedContent(compact: usesCompactLayout)
                    .padding(.horizontal, usesCompactLayout ? AppSpacing.large : AppSpacing.xLarge)
                    .padding(.bottom, usesCompactLayout ? AppSpacing.medium : AppSpacing.xLarge)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func feedContent(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? AppSpacing.small : AppSpacing.large) {
            Spacer(minLength: compact ? 68 : 88)

            Label(item.growthRole.title.uppercased(), systemImage: item.growthRole.systemImage)
                .font(.system(size: compact ? 11 : 12, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.white.opacity(0.78))

            VStack(alignment: .leading, spacing: compact ? AppSpacing.xSmall : AppSpacing.medium) {
                Text(item.title)
                    .font(.system(size: compact ? 30 : 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(compact ? 2 : 4)
                    .minimumScaleFactor(0.78)

                Text(item.summary)
                    .font((compact ? Font.body : Font.title3).weight(.medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(compact ? 3 : 5)
                    .minimumScaleFactor(0.82)
            }

            if let keyIdea, !dynamicTypeSize.isAccessibilitySize {
                Text(keyIdea)
                    .font(compact ? .subheadline : .body)
                    .foregroundStyle(.white.opacity(0.88))
                    .lineSpacing(compact ? 2 : 4)
                    .lineLimit(compact ? 3 : 6)
                    .padding(compact ? AppSpacing.medium : AppSpacing.large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 22))
            }

            if let prompt = item.preferredInteraction?.prompt,
               !dynamicTypeSize.isAccessibilitySize {
                Label(prompt, systemImage: "arrow.turn.down.right")
                    .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(compact ? 2 : 3)
            }

            Spacer(minLength: compact ? 0 : AppSpacing.medium)

            if compact {
                compactActions
            } else {
                regularActions
            }

            HStack {
                if !compact {
                    Text(item.source.creator)
                    Spacer()
                }
                Label(compact ? "Swipe up" : "Swipe for the next idea", systemImage: "chevron.up")
            }
            .font(.caption)
            .foregroundStyle(.white.opacity(0.62))
            .lineLimit(1)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
    }

    private var regularActions: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.medium) {
            VStack(spacing: AppSpacing.medium) {
                feedButton(
                    title: isSaved ? "Saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark",
                    action: onToggleSaved
                )
                feedButton(
                    title: isUseful ? "Useful" : "Useful?",
                    systemImage: isUseful ? "hand.thumbsup.fill" : "hand.thumbsup",
                    action: onToggleUseful
                )
                feedButton(
                    title: "Thought",
                    systemImage: "quote.bubble",
                    action: onOpenThought
                )
            }

            practiceButton(minHeight: 58)
        }
    }

    private var compactActions: some View {
        VStack(spacing: AppSpacing.small) {
            practiceButton(minHeight: 48)

            HStack(spacing: AppSpacing.small) {
                compactFeedButton(
                    title: isSaved ? "Saved" : "Save",
                    systemImage: isSaved ? "bookmark.fill" : "bookmark",
                    action: onToggleSaved
                )
                compactFeedButton(
                    title: isUseful ? "Useful" : "Useful?",
                    systemImage: isUseful ? "hand.thumbsup.fill" : "hand.thumbsup",
                    action: onToggleUseful
                )
                compactFeedButton(
                    title: "Thought",
                    systemImage: "quote.bubble",
                    action: onOpenThought
                )
            }
        }
    }

    private func practiceButton(minHeight: CGFloat) -> some View {
        Button {
            guard !isPracticed else { return }
            onOpenPractice()
        } label: {
            HStack {
                Image(systemName: isPracticed ? "checkmark.circle.fill" : item.growthRole.systemImage)
                Text(isPracticed ? "Completed" : item.growthRole.actionTitle)
                Spacer()
                if !isPracticed {
                    Image(systemName: "arrow.up.right")
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.horizontal, AppSpacing.large)
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .background(.white, in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(isPracticed)
        .opacity(isPracticed ? 0.78 : 1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private func compactFeedButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    private var keyIdea: String? {
        item.blocks
            .sorted { $0.order < $1.order }
            .first(where: { [.paragraph, .callout, .quote].contains($0.kind) })?
            .content
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: item.growthRole.colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(.white.opacity(0.10))
                .frame(width: 330, height: 330)
                .offset(x: 150, y: -240)
            Circle()
                .fill(.black.opacity(0.12))
                .frame(width: 270, height: 270)
                .offset(x: -150, y: 280)
        }
        .ignoresSafeArea()
    }

    private func feedButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.black.opacity(0.22), in: Circle())
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

private struct GrowthFeedFinishPage: View {
    let viewedCount: Int
    let practicedCount: Int
    let usefulCount: Int
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.07, blue: 0.18),
                    Color(red: 0.24, green: 0.17, blue: 0.48)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: AppSpacing.xLarge) {
                Spacer()

                Image(systemName: practicedCount > 0 ? "checkmark.seal.fill" : "pause.circle.fill")
                    .font(.system(size: 58, weight: .semibold))
                    .foregroundStyle(.mint)

                VStack(spacing: AppSpacing.medium) {
                    Text("Your feed has an ending")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text(
                        practicedCount > 0
                            ? "You turned attention into evidence. Choose one next action before you leave."
                            : "You explored the session. Practice one idea next time to close a full Growth Loop."
                    )
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                }

                HStack(spacing: AppSpacing.small) {
                    metric("\(viewedCount)", "viewed")
                    metric("\(practicedCount)", "practiced")
                    metric("\(usefulCount)", "useful")
                }

                Button("Finish intentionally", action: onFinish)
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(.white, in: RoundedRectangle(cornerRadius: 20))
                    .buttonStyle(.plain)

                Spacer()
            }
            .padding(AppSpacing.xLarge)
        }
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: AppSpacing.xSmall) {
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.62))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.large)
        .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct GrowthPracticeSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: LearningSessionItem
    let position: Int
    let total: Int
    let onComplete: (LearningInteractionResult) -> Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                LearningCardShell(
                    item: item,
                    position: position,
                    total: total,
                    isCompleted: false,
                    actionTitle: "Save and return to feed"
                ) { result in
                    if onComplete(result) {
                        dismiss()
                    }
                }
                .padding(AppSpacing.large)
            }
            .background(AppColor.groupedBackground)
            .navigationTitle(item.growthRole.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct ThoughtComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var thoughtText = ""

    let item: LearningSessionItem
    let onSave: (String) -> Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: AppSpacing.xLarge) {
                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Label("PRIVATE GROWTH MEMORY", systemImage: "lock.fill")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColor.accent)
                    Text("What does this mean for you?")
                        .font(AppTypography.screenTitle)
                    Text(item.title)
                        .font(AppTypography.supporting)
                        .foregroundStyle(AppColor.textSecondary)
                }

                TextField(
                    "Write a thought, decision, or question",
                    text: $thoughtText,
                    axis: .vertical
                )
                .lineLimit(5...10)
                .padding(AppSpacing.large)
                .background(AppColor.surface, in: RoundedRectangle(cornerRadius: AppRadius.large))

                Button("Save to my memory") {
                    if onSave(thoughtText) { dismiss() }
                }
                .buttonStyle(.primaryAction)
                .disabled(thoughtText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding(AppSpacing.xLarge)
            .background(AppColor.groupedBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private extension GrowthUnitRole {
    var title: String {
        switch self {
        case .learn: "Learn"
        case .test: "Test"
        case .do: "Do"
        case .reflect: "Reflect"
        }
    }

    var actionTitle: String {
        switch self {
        case .learn: "Make it stick"
        case .test: "Test myself"
        case .do: "Try this today"
        case .reflect: "Reflect now"
        }
    }

    var systemImage: String {
        switch self {
        case .learn: "lightbulb.fill"
        case .test: "checkmark.bubble.fill"
        case .do: "figure.run"
        case .reflect: "quote.bubble.fill"
        }
    }

    var colors: [Color] {
        switch self {
        case .learn:
            [Color(red: 0.17, green: 0.15, blue: 0.48), Color(red: 0.42, green: 0.28, blue: 0.76)]
        case .test:
            [Color(red: 0.04, green: 0.32, blue: 0.40), Color(red: 0.05, green: 0.58, blue: 0.55)]
        case .do:
            [Color(red: 0.43, green: 0.16, blue: 0.14), Color(red: 0.86, green: 0.39, blue: 0.20)]
        case .reflect:
            [Color(red: 0.23, green: 0.10, blue: 0.34), Color(red: 0.57, green: 0.25, blue: 0.55)]
        }
    }
}

#Preview("Growth feed") {
    LearningSessionView(plan: PreviewSupport.learningSessionPlan()) {}
        .preferredColorScheme(.dark)
}
