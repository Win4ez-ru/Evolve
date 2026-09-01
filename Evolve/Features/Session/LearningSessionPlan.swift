import Foundation

struct LearningSessionItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let summary: String
    let categoryName: String
    let kind: ContentKind
    let difficulty: ContentDifficulty
    let estimatedMinutes: Int
    let blocks: [ContentBlockSpec]
    let interactions: [InteractionSpec]
    let source: ContentSource
    let recommendationReason: String
    let isReview: Bool

    var kindName: String {
        kind.sessionDisplayName
    }

    init(
        id: UUID,
        title: String,
        summary: String,
        categoryName: String,
        kind: ContentKind,
        difficulty: ContentDifficulty,
        estimatedMinutes: Int,
        blocks: [ContentBlockSpec],
        interactions: [InteractionSpec] = [],
        source: ContentSource,
        recommendationReason: String = "Chosen for your learning path",
        isReview: Bool = false
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.categoryName = categoryName
        self.kind = kind
        self.difficulty = difficulty
        self.estimatedMinutes = estimatedMinutes
        self.blocks = blocks
        self.interactions = interactions
        self.source = source
        self.recommendationReason = recommendationReason
        self.isReview = isReview
    }

    init(
        contentUnit unit: ContentUnit,
        categoryName: String,
        recommendationReason: String = "Chosen for your learning path",
        isReview: Bool = false
    ) {
        var interactionSnapshots = unit.orderedInteractions.map { interaction in
            InteractionSpec(
                id: interaction.id,
                kind: interaction.kind ?? .learn,
                responseKind: interaction.responseKind ?? .none,
                evaluationKind: interaction.evaluationKind ?? .completion,
                order: interaction.order,
                prompt: interaction.prompt,
                estimatedMinutes: interaction.estimatedMinutes,
                isPrimary: interaction.isPrimary,
                isRequired: interaction.isRequired,
                requiresOwnResponseBeforeCommunity: interaction.requiresOwnResponseBeforeCommunity,
                options: interaction.options,
                expectedResponse: interaction.expectedResponse
            )
        }
        if isReview && !interactionSnapshots.contains(where: { $0.kind == .recall }) {
            interactionSnapshots.append(
                InteractionSpec(
                    id: unit.id,
                    kind: .recall,
                    responseKind: .text,
                    evaluationKind: .selfAssessment,
                    order: interactionSnapshots.count,
                    prompt: "Before revealing the material, reconstruct the central idea in your own words.",
                    estimatedMinutes: 2,
                    isRequired: true
                )
            )
        }

        self.init(
            id: unit.id,
            title: unit.title,
            summary: unit.summary,
            categoryName: categoryName,
            kind: unit.kind ?? .explanation,
            difficulty: unit.difficulty ?? .introductory,
            estimatedMinutes: unit.estimatedMinutes,
            blocks: unit.orderedBlocks.map { block in
                ContentBlockSpec(
                    id: block.id,
                    kind: block.kind ?? .paragraph,
                    order: block.order,
                    content: block.content,
                    language: block.language,
                    accessibilityLabel: block.accessibilityLabel
                )
            },
            interactions: interactionSnapshots,
            source: ContentSource(
                title: unit.sourceTitle,
                creator: unit.sourceCreator,
                url: unit.sourceURL,
                license: unit.sourceLicense
            ),
            recommendationReason: recommendationReason,
            isReview: isReview
        )
    }

    var preferredInteraction: InteractionSpec? {
        if isReview, let recall = interactions.first(where: { $0.kind == .recall }) {
            return recall
        }
        return interactions.first(where: \.isPrimary) ?? interactions.first
    }
}

struct LearningSessionPlan: Equatable, Sendable {
    /// A session is intentionally finite, but large enough to feel like a real
    /// vertical feed instead of a stack of lesson cards.
    static let maximumItemCount = 15

    let items: [LearningSessionItem]

    init(items: [LearningSessionItem], limit: Int = Self.maximumItemCount) {
        self.items = Array(items.prefix(min(max(limit, 1), Self.maximumItemCount)))
    }

    init(
        items: [LearningSessionItem],
        targetMinutes: Int,
        maximumItemCount: Int = Self.maximumItemCount
    ) {
        let safeTarget = max(targetMinutes, 1)
        let safeMaximum = min(max(maximumItemCount, 1), Self.maximumItemCount)
        var selected: [LearningSessionItem] = []
        var selectedMinutes = 0

        for item in GrowthSessionPlanner.balanced(items).prefix(safeMaximum) {
            selected.append(item)
            selectedMinutes += max(item.estimatedMinutes, 1)
            if selectedMinutes >= safeTarget {
                break
            }
        }

        self.items = selected
    }

    init(
        contentUnits: [ContentUnit],
        categories: [ContentCategory],
        limit: Int = Self.maximumItemCount
    ) {
        let categoryNames = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0.name) }
        )
        let items = contentUnits.map { unit in
            LearningSessionItem(
                contentUnit: unit,
                categoryName: categoryNames[unit.categoryID] ?? "Learning"
            )
        }

        self.init(items: items, limit: limit)
    }

    var totalMinutes: Int {
        items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var isEmpty: Bool {
        items.isEmpty
    }
}

enum GrowthSessionPlanner {
    /// Keeps discovery pleasurable while ensuring that every short session has
    /// a realistic chance to contain understanding, recall, reflection, and action.
    static func balanced(_ items: [LearningSessionItem]) -> [LearningSessionItem] {
        // A scheduled return is a promise to the learner, so due recall stays
        // ahead of discovery instead of being displaced by the role rhythm.
        let reviews = items.filter(\.isReview)
        var remaining = items.filter { !$0.isReview }
        var ordered = reviews
        let rhythm: [GrowthUnitRole] = [.learn, .learn, .test, .reflect, .do]

        while !remaining.isEmpty {
            var appendedDuringPass = false
            for role in rhythm {
                guard let index = remaining.firstIndex(where: { $0.growthRole == role }) else {
                    continue
                }
                ordered.append(remaining.remove(at: index))
                appendedDuringPass = true
            }

            if !appendedDuringPass {
                ordered.append(contentsOf: remaining)
                break
            }
        }

        return ordered
    }
}

struct LearningProgressTotals: Equatable, Sendable {
    let completedSessions: Int
    let totalLearningMinutes: Int
    let currentStreak: Int
    let lastPracticeTimestamp: Double

    static let zero = LearningProgressTotals(
        completedSessions: 0,
        totalLearningMinutes: 0,
        currentStreak: 0,
        lastPracticeTimestamp: 0
    )
}

enum LearningProgressTotalsCalculator {
    static func calculate(
        from events: [LocalProductEvent],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> LearningProgressTotals {
        let completions = events.compactMap { event -> (date: Date, minutes: Int)? in
            guard event.kind == .sessionCompleted else {
                return nil
            }

            let minutes = event.numericValue.flatMap { value -> Int? in
                guard value.isFinite, value >= 0 else {
                    return nil
                }
                return Int(exactly: value.rounded(.towardZero))
            } ?? 0
            return (event.occurredAt, minutes)
        }

        guard !completions.isEmpty else {
            return .zero
        }

        let totalLearningMinutes = completions.reduce(into: 0) { total, completion in
            let addition = total.addingReportingOverflow(completion.minutes)
            total = addition.overflow ? .max : addition.partialValue
        }
        let practiceDays = Set(
            completions
                .filter { $0.date <= now }
                .map { calendar.startOfDay(for: $0.date) }
        ).sorted()

        var currentStreak = 0
        if let latestPracticeDay = practiceDays.last {
            let today = calendar.startOfDay(for: now)
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
            let isCurrent = calendar.isDate(latestPracticeDay, inSameDayAs: today)
                || yesterday.map {
                    calendar.isDate(latestPracticeDay, inSameDayAs: $0)
                } == true

            if isCurrent {
                currentStreak = 1
                if practiceDays.count > 1 {
                    for index in stride(from: practiceDays.count - 1, through: 1, by: -1) {
                        guard let precedingDay = calendar.date(
                            byAdding: .day,
                            value: -1,
                            to: practiceDays[index]
                        ), calendar.isDate(practiceDays[index - 1], inSameDayAs: precedingDay) else {
                            break
                        }
                        currentStreak += 1
                    }
                }
            }
        }

        return LearningProgressTotals(
            completedSessions: completions.count,
            totalLearningMinutes: totalLearningMinutes,
            currentStreak: currentStreak,
            lastPracticeTimestamp: practiceDays.last?.timeIntervalSince1970 ?? 0
        )
    }
}

extension LocalProductEvent {
    static func sessionCompletion(
        occurredAt: Date,
        learningMinutes: Int
    ) -> LocalProductEvent {
        // The pre-release MVP has no shipped stores using the former item-count
        // payload. From the first release onward, sessionCompleted.numericValue
        // is the recoverable estimated-minute total for that session.
        LocalProductEvent(
            kind: .sessionCompleted,
            occurredAt: occurredAt,
            numericValue: Double(max(learningMinutes, 0))
        )
    }
}

struct LearningInteractionResult: Equatable, Hashable, Sendable {
    let interactionID: UUID?
    let interactionKind: InteractionKind?
    let response: String
    let isCorrect: Bool?
    let confidence: AttemptConfidence
    let startedAt: Date
    let completedAt: Date
    let durationSeconds: Double
    let usedHint: Bool
    let difficulty: ContentDifficulty

    init(
        interactionID: UUID?,
        interactionKind: InteractionKind? = nil,
        response: String,
        isCorrect: Bool?,
        confidence: AttemptConfidence = .medium,
        startedAt: Date = .now,
        completedAt: Date = .now,
        durationSeconds: Double = 0,
        usedHint: Bool = false,
        difficulty: ContentDifficulty = .foundational
    ) {
        self.interactionID = interactionID
        self.interactionKind = interactionKind
        self.response = response
        self.isCorrect = isCorrect
        self.confidence = confidence
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.usedHint = usedHint
        self.difficulty = difficulty
    }
}

enum LearningSessionPhase: Equatable, Sendable {
    case active
    case stopped
    case completed
}

struct LearningSessionState: Equatable, Sendable {
    let plan: LearningSessionPlan
    private(set) var currentItemID: UUID?
    private(set) var completedItemIDs: Set<UUID>
    private(set) var phase: LearningSessionPhase

    init(plan: LearningSessionPlan) {
        self.plan = plan
        currentItemID = plan.items.first?.id
        completedItemIDs = []
        phase = plan.isEmpty ? .completed : .active
    }

    var currentIndex: Int? {
        guard let currentItemID else {
            return nil
        }

        return plan.items.firstIndex { $0.id == currentItemID }
    }

    var position: Int {
        (currentIndex ?? 0) + 1
    }

    var progress: Double {
        guard !plan.items.isEmpty else {
            return 1
        }

        if phase == .completed {
            return 1
        }

        return Double(position) / Double(plan.items.count)
    }

    var earnedMinutes: Int {
        plan.items
            .filter { completedItemIDs.contains($0.id) }
            .reduce(0) { $0 + max($1.estimatedMinutes, 1) }
    }

    mutating func select(itemID: UUID) {
        guard phase == .active,
              plan.items.contains(where: { $0.id == itemID }) else {
            return
        }

        currentItemID = itemID
    }

    @discardableResult
    mutating func advance() -> UUID? {
        guard phase == .active,
              let currentItemID,
              let currentIndex else {
            return nil
        }

        completedItemIDs.insert(currentItemID)
        let nextIndex = currentIndex + 1

        guard plan.items.indices.contains(nextIndex) else {
            phase = .completed
            return nil
        }

        let nextID = plan.items[nextIndex].id
        self.currentItemID = nextID
        return nextID
    }

    mutating func stop() {
        guard phase == .active else {
            return
        }

        phase = .stopped
    }

    mutating func markCompleted(itemID: UUID) {
        guard phase == .active,
              plan.items.contains(where: { $0.id == itemID }) else {
            return
        }
        completedItemIDs.insert(itemID)
    }

    mutating func finish() {
        guard phase == .active else {
            return
        }
        phase = .completed
    }
}

extension LearningSessionItem {
    var growthRole: GrowthUnitRole {
        preferredInteraction?.kind.growthUnitRole ?? .learn
    }
}

extension ContentKind {
    var sessionDisplayName: String {
        switch self {
        case .concept: "Concept"
        case .principle: "Principle"
        case .insight: "Insight"
        case .contextualQuote: "Quote"
        case .question: "Question"
        case .dilemma: "Dilemma"
        case .caseStudy: "Case study"
        case .problem: "Problem"
        case .workedExample: "Worked example"
        case .technique: "Technique"
        case .experiment: "Experiment"
        case .challenge: "Challenge"
        case .recallPrompt: "Recall"
        case .explanation: "Explanation"
        }
    }
}
