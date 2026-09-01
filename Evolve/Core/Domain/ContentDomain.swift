import Foundation

enum ContentKind: String, CaseIterable, Codable, Hashable, Sendable {
    case concept
    case principle
    case insight
    case contextualQuote = "contextual_quote"
    case question
    case dilemma
    case caseStudy = "case"
    case problem
    case workedExample = "worked_example"
    case technique
    case experiment
    case challenge
    case recallPrompt = "recall_prompt"
    case explanation
}

enum ContentBlockKind: String, CaseIterable, Codable, Hashable, Sendable {
    case heading
    case paragraph
    case quote
    case code
    case formula
    case image
    case audio
    case video
    case callout
}

enum InteractionKind: String, CaseIterable, Codable, Sendable {
    case learn
    case reflect
    case discuss
    case solve
    case prove
    case practice
    case apply
    case observe
    case explain
    case recall
    case quiz
    case build
    case track
}

enum GrowthUnitRole: String, CaseIterable, Codable, Hashable, Sendable {
    case learn
    case test
    case `do`
    case reflect
}

extension InteractionKind {
    var growthUnitRole: GrowthUnitRole {
        switch self {
        case .learn:
            .learn
        case .solve, .prove, .recall, .quiz:
            .test
        case .practice, .apply, .build, .track:
            .do
        case .reflect, .discuss, .observe, .explain:
            .reflect
        }
    }
}

enum InteractionResponseKind: String, CaseIterable, Codable, Sendable {
    case none
    case text
    case singleChoice = "single_choice"
    case multipleChoice = "multiple_choice"
    case number
    case code
    case measurement
}

enum InteractionEvaluationKind: String, CaseIterable, Codable, Sendable {
    case completion
    case selfAssessment = "self_assessment"
    case exactMatch = "exact_match"
    case choice
}

enum ContentDifficulty: Int, CaseIterable, Codable, Hashable, Sendable {
    case introductory = 1
    case foundational = 2
    case intermediate = 3
    case advanced = 4
    case expert = 5
}

enum EditorialStatus: String, CaseIterable, Codable, Sendable {
    case draft
    case review
    case approved
    case published
    case deprecated
}

enum KnowledgeStatus: String, CaseIterable, Codable, Sendable {
    case eligible
    case surfaced
    case viewed
    case engaged
    case scheduled
    case reviewDue = "review_due"
    case recalled
    case remediation
    case mastered
}

enum LearningGoal: String, CaseIterable, Codable, Identifiable, Sendable {
    case thinkClearly = "think_clearly"
    case buildUsefulSkills = "build_useful_skills"
    case applyIdeas = "apply_ideas"
    case rememberWhatMatters = "remember_what_matters"

    var id: Self { self }

    var title: String {
        switch self {
        case .thinkClearly: "Protect my attention"
        case .buildUsefulSkills: "Start without overthinking"
        case .applyIdeas: "Finish what I planned"
        case .rememberWhatMatters: "Reduce phone pulls"
        }
    }

    var supportingText: String {
        switch self {
        case .thinkClearly: "Create longer stretches of undivided attention."
        case .buildUsefulSkills: "Make the first useful move feel smaller and easier."
        case .applyIdeas: "Turn daily intentions into observable completed work."
        case .rememberWhatMatters: "Notice distraction triggers and add friction before reacting."
        }
    }

    /// The first catalog is intentionally narrow, so a goal maps to the topic
    /// that should be ranked first rather than hiding the rest of the feed.
    var preferredTopicSlug: String {
        switch self {
        case .thinkClearly, .rememberWhatMatters:
            "attention-environment"
        case .buildUsefulSkills:
            "starting-momentum"
        case .applyIdeas:
            "consistency-recovery"
        }
    }
}

enum LearnerLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case starting
    case growing
    case experienced

    var id: Self { self }

    var title: String {
        switch self {
        case .starting: "Starting out"
        case .growing: "Building momentum"
        case .experienced: "Experienced learner"
        }
    }
}

enum AttemptConfidence: Int, CaseIterable, Codable, Identifiable, Sendable {
    case low = 1
    case medium = 2
    case high = 3

    var id: Self { self }

    var title: String {
        switch self {
        case .low: "Need review"
        case .medium: "Unsure"
        case .high: "Solid"
        }
    }
}

enum ReviewReason: String, CaseIterable, Codable, Sendable {
    case firstPractice = "first_practice"
    case successfulRecall = "successful_recall"
    case reinforcement
    case remediation

    var title: String {
        switch self {
        case .firstPractice: "First recall"
        case .successfulRecall: "Strengthen the memory"
        case .reinforcement: "Keep it available"
        case .remediation: "Try again with support"
        }
    }
}

enum LocalEventKind: String, CaseIterable, Codable, Sendable {
    case onboardingCompleted = "onboarding_completed"
    case sessionStarted = "session_started"
    case attemptCompleted = "attempt_completed"
    case reviewScheduled = "review_scheduled"
    case sessionCompleted = "session_completed"
    case applicationCreated = "application_created"
    case feedImpression = "feed_impression"
    case feedSkipped = "feed_skipped"
    case feedUseful = "feed_useful"
    case feedCompleted = "feed_completed"
    case thoughtCreated = "thought_created"
    case actionCompleted = "action_completed"
    case growthLoopCompleted = "growth_loop_completed"
}

enum ThoughtKind: String, CaseIterable, Codable, Sendable {
    case reflection
    case insight
    case decision
}

enum ActionStatus: String, CaseIterable, Codable, Sendable {
    case planned
    case completed
    case skipped
}

struct ReviewDecision: Equatable, Sendable {
    let nextReviewAt: Date
    let intervalDays: Int
    let repetitionCount: Int
    let lapseCount: Int
    let reason: ReviewReason
    let treatsAttemptAsSuccess: Bool
}

enum ReviewScheduler {
    private static let successfulIntervals = [1, 3, 7, 14, 30, 60]

    static func decision(
        interactionKind: InteractionKind?,
        isCorrect: Bool?,
        confidence: AttemptConfidence,
        previousRepetitionCount: Int,
        previousLapseCount: Int,
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> ReviewDecision {
        let isRecall = interactionKind == .recall
        let failedRecall = isRecall && (isCorrect == false || confidence == .low)

        let intervalDays: Int
        let repetitionCount: Int
        let lapseCount: Int
        let reason: ReviewReason
        let treatsAttemptAsSuccess: Bool

        if failedRecall {
            intervalDays = 1
            repetitionCount = max(previousRepetitionCount - 1, 0)
            lapseCount = previousLapseCount + 1
            reason = .remediation
            treatsAttemptAsSuccess = false
        } else if isRecall {
            repetitionCount = previousRepetitionCount + 1
            lapseCount = previousLapseCount
            let index = min(max(repetitionCount - 1, 0), successfulIntervals.count - 1)
            let baseInterval = successfulIntervals[index]
            intervalDays = confidence == .high ? min(baseInterval + max(baseInterval / 3, 1), 90) : baseInterval
            reason = .successfulRecall
            treatsAttemptAsSuccess = true
        } else {
            intervalDays = 1
            repetitionCount = max(previousRepetitionCount, 0)
            lapseCount = previousLapseCount
            reason = previousRepetitionCount == 0 ? .firstPractice : .reinforcement
            treatsAttemptAsSuccess = isCorrect != false
        }

        let nextReviewAt = calendar.date(
            byAdding: .day,
            value: intervalDays,
            to: now
        ) ?? now.addingTimeInterval(TimeInterval(intervalDays * 86_400))

        return ReviewDecision(
            nextReviewAt: nextReviewAt,
            intervalDays: intervalDays,
            repetitionCount: repetitionCount,
            lapseCount: lapseCount,
            reason: reason,
            treatsAttemptAsSuccess: treatsAttemptAsSuccess
        )
    }
}

struct LearningEvidence: Equatable, Sendable {
    let kind: InteractionKind
    let isCorrect: Bool?
    let confidence: AttemptConfidence
    let difficulty: ContentDifficulty
    let occurredAt: Date
}

struct EvidenceSummary: Equatable, Sendable {
    let score: Double
    let evidenceCount: Int
    let strongEvidenceCount: Int
    let strongestKind: InteractionKind?
}

enum EvidenceScorer {
    static func summary(
        for evidence: [LearningEvidence],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> EvidenceSummary {
        guard !evidence.isEmpty else {
            return EvidenceSummary(
                score: 0,
                evidenceCount: 0,
                strongEvidenceCount: 0,
                strongestKind: nil
            )
        }

        let weighted = evidence.map { sample -> (InteractionKind, Double) in
            let correctness: Double
            switch sample.isCorrect {
            case .some(true): correctness = 1
            case .some(false): correctness = 0.08
            case .none: correctness = sample.confidence == .high ? 0.78 : sample.confidence == .medium ? 0.62 : 0.35
            }

            let confidence = 0.72 + (Double(sample.confidence.rawValue) * 0.09)
            let difficulty = 0.82 + (Double(sample.difficulty.rawValue - 1) * 0.06)
            let age = calendar.dateComponents([.day], from: sample.occurredAt, to: now).day ?? 0
            let freshness = max(0.72, 1 - (Double(max(age, 0)) * 0.006))
            return (
                sample.kind,
                sample.kind.evidenceWeight * correctness * confidence * difficulty * freshness
            )
        }

        let total = weighted.reduce(0) { $0 + $1.1 }
        let strongest = weighted.max { $0.1 < $1.1 }?.0
        let strongCount = evidence.filter {
            ($0.kind == .recall || $0.kind == .solve || $0.kind == .quiz || $0.kind == .apply)
                && $0.isCorrect != false
                && $0.confidence != .low
        }.count

        return EvidenceSummary(
            score: min(total / 3, 1),
            evidenceCount: evidence.count,
            strongEvidenceCount: strongCount,
            strongestKind: strongest
        )
    }
}

private extension InteractionKind {
    var evidenceWeight: Double {
        switch self {
        case .recall: 1
        case .solve, .quiz, .prove: 0.88
        case .apply, .practice, .build, .track: 0.82
        case .explain: 0.72
        case .reflect, .observe: 0.56
        case .learn, .discuss: 0.24
        }
    }
}

enum SafetyLevel: String, CaseIterable, Codable, Sendable {
    case standard
    case caution
    case restricted
}

struct ContentCategoryDefinition: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let slug: String
    let name: String
    let overview: String
    let sortOrder: Int
    let isEnabled: Bool

    init(
        id: UUID = UUID(),
        slug: String,
        name: String,
        overview: String,
        sortOrder: Int,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.overview = overview
        self.sortOrder = sortOrder
        self.isEnabled = isEnabled
    }
}

struct ContentTopicDefinition: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let categoryID: UUID
    let slug: String
    let name: String
    let overview: String

    init(
        id: UUID = UUID(),
        categoryID: UUID,
        slug: String,
        name: String,
        overview: String
    ) {
        self.id = id
        self.categoryID = categoryID
        self.slug = slug
        self.name = name
        self.overview = overview
    }
}

struct ContentSource: Codable, Hashable, Sendable {
    let title: String
    let creator: String
    let url: URL?
    let license: String?

    init(
        title: String,
        creator: String,
        url: URL? = nil,
        license: String? = nil
    ) {
        self.title = title
        self.creator = creator
        self.url = url
        self.license = license
    }
}

struct ContentSafety: Codable, Equatable, Sendable {
    let level: SafetyLevel
    let notice: String?
    let requiresExpertReview: Bool

    init(
        level: SafetyLevel = .standard,
        notice: String? = nil,
        requiresExpertReview: Bool = false
    ) {
        self.level = level
        self.notice = notice
        self.requiresExpertReview = requiresExpertReview
    }
}

struct ContentBlockSpec: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let kind: ContentBlockKind
    let order: Int
    let content: String
    let language: String?
    let accessibilityLabel: String?

    init(
        id: UUID = UUID(),
        kind: ContentBlockKind,
        order: Int,
        content: String,
        language: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.order = order
        self.content = content
        self.language = language
        self.accessibilityLabel = accessibilityLabel
    }
}

struct InteractionSpec: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: UUID
    let kind: InteractionKind
    let responseKind: InteractionResponseKind
    let evaluationKind: InteractionEvaluationKind
    let order: Int
    let prompt: String
    let estimatedMinutes: Int
    let isPrimary: Bool
    let isRequired: Bool
    let requiresOwnResponseBeforeCommunity: Bool
    let options: [String]
    let expectedResponse: String?

    init(
        id: UUID = UUID(),
        kind: InteractionKind,
        responseKind: InteractionResponseKind,
        evaluationKind: InteractionEvaluationKind,
        order: Int,
        prompt: String,
        estimatedMinutes: Int,
        isPrimary: Bool = false,
        isRequired: Bool = false,
        requiresOwnResponseBeforeCommunity: Bool = false,
        options: [String] = [],
        expectedResponse: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.responseKind = responseKind
        self.evaluationKind = evaluationKind
        self.order = order
        self.prompt = prompt
        self.estimatedMinutes = estimatedMinutes
        self.isPrimary = isPrimary
        self.isRequired = isRequired
        self.requiresOwnResponseBeforeCommunity = requiresOwnResponseBeforeCommunity
        self.options = options
        self.expectedResponse = expectedResponse
    }
}

struct ContentUnitDefinition: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let kind: ContentKind
    let difficulty: ContentDifficulty
    let editorialStatus: EditorialStatus
    let categoryID: UUID
    let topicIDs: [UUID]
    let estimatedMinutes: Int
    let blocks: [ContentBlockSpec]
    let interactions: [InteractionSpec]
    let source: ContentSource
    let safety: ContentSafety

    var growthRole: GrowthUnitRole? {
        interactions.first(where: \.isPrimary)?.kind.growthUnitRole
    }

    init(
        id: UUID = UUID(),
        slug: String,
        title: String,
        summary: String,
        kind: ContentKind,
        difficulty: ContentDifficulty,
        editorialStatus: EditorialStatus,
        categoryID: UUID,
        topicIDs: [UUID],
        estimatedMinutes: Int,
        blocks: [ContentBlockSpec],
        interactions: [InteractionSpec],
        source: ContentSource,
        safety: ContentSafety = ContentSafety()
    ) {
        self.id = id
        self.slug = slug
        self.title = title
        self.summary = summary
        self.kind = kind
        self.difficulty = difficulty
        self.editorialStatus = editorialStatus
        self.categoryID = categoryID
        self.topicIDs = topicIDs
        self.estimatedMinutes = estimatedMinutes
        self.blocks = blocks
        self.interactions = interactions
        self.source = source
        self.safety = safety
    }
}

struct ContentCatalogDefinition: Codable, Equatable, Sendable {
    let schemaVersion: Int
    let catalogVersion: Int
    let categories: [ContentCategoryDefinition]
    let topics: [ContentTopicDefinition]
    let contentUnits: [ContentUnitDefinition]

    init(
        schemaVersion: Int,
        catalogVersion: Int,
        categories: [ContentCategoryDefinition],
        topics: [ContentTopicDefinition],
        contentUnits: [ContentUnitDefinition]
    ) {
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.categories = categories
        self.topics = topics
        self.contentUnits = contentUnits
    }
}
