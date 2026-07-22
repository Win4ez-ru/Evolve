import Foundation

struct LearningSessionItem: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let summary: String
    let categoryName: String
    let kindName: String
    let estimatedMinutes: Int
}

struct LearningSessionPlan: Equatable, Sendable {
    static let maximumItemCount = 3

    let items: [LearningSessionItem]

    init(items: [LearningSessionItem]) {
        self.items = Array(items.prefix(Self.maximumItemCount))
    }

    init(contentUnits: [ContentUnit], categories: [ContentCategory]) {
        let categoryNames = Dictionary(
            uniqueKeysWithValues: categories.map { ($0.id, $0.name) }
        )
        let items = contentUnits.map { unit in
            LearningSessionItem(
                id: unit.id,
                title: unit.title,
                summary: unit.summary,
                categoryName: categoryNames[unit.categoryID] ?? "Learning",
                kindName: unit.kind?.sessionDisplayName ?? "Idea",
                estimatedMinutes: unit.estimatedMinutes
            )
        }

        self.init(items: items)
    }

    var totalMinutes: Int {
        items.reduce(0) { $0 + $1.estimatedMinutes }
    }

    var isEmpty: Bool {
        items.isEmpty
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
}

private extension ContentKind {
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
