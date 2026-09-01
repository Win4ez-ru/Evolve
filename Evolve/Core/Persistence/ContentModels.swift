import Foundation
import SwiftData

@Model
final class ContentCategory {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var name: String
    var overview: String
    var sortOrder: Int
    var isEnabled: Bool

    init(definition: ContentCategoryDefinition) {
        id = definition.id
        slug = definition.slug
        name = definition.name
        overview = definition.overview
        sortOrder = definition.sortOrder
        isEnabled = definition.isEnabled
    }

    func apply(_ definition: ContentCategoryDefinition) {
        slug = definition.slug
        name = definition.name
        overview = definition.overview
        sortOrder = definition.sortOrder
        isEnabled = definition.isEnabled
    }
}

@Model
final class ContentTopic {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var categoryID: UUID
    var name: String
    var overview: String

    init(definition: ContentTopicDefinition) {
        id = definition.id
        slug = definition.slug
        categoryID = definition.categoryID
        name = definition.name
        overview = definition.overview
    }

    func apply(_ definition: ContentTopicDefinition) {
        slug = definition.slug
        categoryID = definition.categoryID
        name = definition.name
        overview = definition.overview
    }
}

@Model
final class ContentUnit {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var slug: String
    var title: String
    var summary: String
    var kindRawValue: String
    var difficultyRawValue: Int
    var editorialStatusRawValue: String
    var categoryID: UUID
    var topicIDs: [UUID]
    var estimatedMinutes: Int
    var sourceTitle: String
    var sourceCreator: String
    var sourceURLString: String?
    var sourceLicense: String?
    var safetyLevelRawValue: String
    var safetyNotice: String?
    var requiresExpertReview: Bool

    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.contentUnit)
    var blocks: [ContentBlock] = []

    @Relationship(deleteRule: .cascade, inverse: \InteractionDefinition.contentUnit)
    var interactions: [InteractionDefinition] = []

    var kind: ContentKind? {
        ContentKind(rawValue: kindRawValue)
    }

    var growthRole: GrowthUnitRole? {
        orderedInteractions
            .first(where: \.isPrimary)?
            .kind?
            .growthUnitRole
    }

    var difficulty: ContentDifficulty? {
        ContentDifficulty(rawValue: difficultyRawValue)
    }

    var editorialStatus: EditorialStatus? {
        EditorialStatus(rawValue: editorialStatusRawValue)
    }

    var safetyLevel: SafetyLevel? {
        SafetyLevel(rawValue: safetyLevelRawValue)
    }

    var sourceURL: URL? {
        sourceURLString.flatMap(URL.init(string:))
    }

    var orderedBlocks: [ContentBlock] {
        blocks.sorted { $0.order < $1.order }
    }

    var orderedInteractions: [InteractionDefinition] {
        interactions.sorted { $0.order < $1.order }
    }

    init(definition: ContentUnitDefinition) {
        id = definition.id
        slug = definition.slug
        title = definition.title
        summary = definition.summary
        kindRawValue = definition.kind.rawValue
        difficultyRawValue = definition.difficulty.rawValue
        editorialStatusRawValue = definition.editorialStatus.rawValue
        categoryID = definition.categoryID
        topicIDs = definition.topicIDs
        estimatedMinutes = definition.estimatedMinutes
        sourceTitle = definition.source.title
        sourceCreator = definition.source.creator
        sourceURLString = definition.source.url?.absoluteString
        sourceLicense = definition.source.license
        safetyLevelRawValue = definition.safety.level.rawValue
        safetyNotice = definition.safety.notice
        requiresExpertReview = definition.safety.requiresExpertReview

        blocks = definition.blocks.map(ContentBlock.init(specification:))
        interactions = definition.interactions.map(InteractionDefinition.init(specification:))

        for block in blocks {
            block.contentUnit = self
        }
        for interaction in interactions {
            interaction.contentUnit = self
        }
    }

    func applyMetadata(_ definition: ContentUnitDefinition) {
        slug = definition.slug
        title = definition.title
        summary = definition.summary
        kindRawValue = definition.kind.rawValue
        difficultyRawValue = definition.difficulty.rawValue
        editorialStatusRawValue = definition.editorialStatus.rawValue
        categoryID = definition.categoryID
        topicIDs = definition.topicIDs
        estimatedMinutes = definition.estimatedMinutes
        sourceTitle = definition.source.title
        sourceCreator = definition.source.creator
        sourceURLString = definition.source.url?.absoluteString
        sourceLicense = definition.source.license
        safetyLevelRawValue = definition.safety.level.rawValue
        safetyNotice = definition.safety.notice
        requiresExpertReview = definition.safety.requiresExpertReview
    }
}

@Model
final class ContentBlock {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var order: Int
    var content: String
    var language: String?
    var accessibilityLabel: String?
    var contentUnit: ContentUnit?

    var kind: ContentBlockKind? {
        ContentBlockKind(rawValue: kindRawValue)
    }

    init(specification: ContentBlockSpec) {
        id = specification.id
        kindRawValue = specification.kind.rawValue
        order = specification.order
        content = specification.content
        language = specification.language
        accessibilityLabel = specification.accessibilityLabel
    }

    func apply(_ specification: ContentBlockSpec) {
        kindRawValue = specification.kind.rawValue
        order = specification.order
        content = specification.content
        language = specification.language
        accessibilityLabel = specification.accessibilityLabel
    }
}

@Model
final class InteractionDefinition {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var responseKindRawValue: String
    var evaluationKindRawValue: String
    var order: Int
    var prompt: String
    var estimatedMinutes: Int
    var isPrimary: Bool
    var isRequired: Bool
    var requiresOwnResponseBeforeCommunity: Bool
    var options: [String]
    var expectedResponse: String?
    var contentUnit: ContentUnit?

    var kind: InteractionKind? {
        InteractionKind(rawValue: kindRawValue)
    }

    var responseKind: InteractionResponseKind? {
        InteractionResponseKind(rawValue: responseKindRawValue)
    }

    var evaluationKind: InteractionEvaluationKind? {
        InteractionEvaluationKind(rawValue: evaluationKindRawValue)
    }

    init(specification: InteractionSpec) {
        id = specification.id
        kindRawValue = specification.kind.rawValue
        responseKindRawValue = specification.responseKind.rawValue
        evaluationKindRawValue = specification.evaluationKind.rawValue
        order = specification.order
        prompt = specification.prompt
        estimatedMinutes = specification.estimatedMinutes
        isPrimary = specification.isPrimary
        isRequired = specification.isRequired
        requiresOwnResponseBeforeCommunity = specification.requiresOwnResponseBeforeCommunity
        options = specification.options
        expectedResponse = specification.expectedResponse
    }

    func apply(_ specification: InteractionSpec) {
        kindRawValue = specification.kind.rawValue
        responseKindRawValue = specification.responseKind.rawValue
        evaluationKindRawValue = specification.evaluationKind.rawValue
        order = specification.order
        prompt = specification.prompt
        estimatedMinutes = specification.estimatedMinutes
        isPrimary = specification.isPrimary
        isRequired = specification.isRequired
        requiresOwnResponseBeforeCommunity = specification.requiresOwnResponseBeforeCommunity
        options = specification.options
        expectedResponse = specification.expectedResponse
    }
}

enum ContentModelError: Error, Equatable {
    case invalidStoredKnowledgeStatus(String)
}

@Model
final class KnowledgeRecord {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var recordKey: String
    var ownerKey: String
    var contentUnitID: UUID
    var statusRawValue: String
    var isSaved: Bool
    var savedAt: Date?
    var surfacedAt: Date?
    var firstViewedAt: Date?
    var lastEngagedAt: Date?
    var lastReviewedAt: Date?
    var lastTransitionAt: Date

    var status: KnowledgeStatus? {
        KnowledgeStatus(rawValue: statusRawValue)
    }

    init(
        id: UUID = UUID(),
        ownerKey: String = "local",
        contentUnitID: UUID,
        status: KnowledgeStatus = .eligible,
        createdAt: Date = .now
    ) {
        self.id = id
        recordKey = Self.makeRecordKey(ownerKey: ownerKey, contentUnitID: contentUnitID)
        self.ownerKey = ownerKey
        self.contentUnitID = contentUnitID
        statusRawValue = status.rawValue
        isSaved = false
        lastTransitionAt = createdAt
    }

    func transition(to next: KnowledgeStatus, at date: Date = .now) throws {
        guard let current = status else {
            throw ContentModelError.invalidStoredKnowledgeStatus(statusRawValue)
        }

        try KnowledgeTransitionPolicy.requireTransition(from: current, to: next)
        statusRawValue = next.rawValue
        lastTransitionAt = date

        switch next {
        case .surfaced:
            surfacedAt = surfacedAt ?? date
        case .viewed:
            firstViewedAt = firstViewedAt ?? date
        case .engaged:
            lastEngagedAt = date
        case .recalled, .remediation, .mastered:
            lastReviewedAt = date
        case .eligible, .scheduled, .reviewDue:
            break
        }
    }

    func setSaved(_ saved: Bool, at date: Date = .now) {
        isSaved = saved
        savedAt = saved ? date : nil
    }

    func recordView(at date: Date = .now) throws {
        switch status {
        case .eligible:
            try transition(to: .surfaced, at: date)
            try transition(to: .viewed, at: date)
        case .surfaced:
            try transition(to: .viewed, at: date)
        case .viewed, .engaged, .scheduled, .reviewDue, .recalled, .remediation, .mastered:
            firstViewedAt = firstViewedAt ?? date
        case nil:
            throw ContentModelError.invalidStoredKnowledgeStatus(statusRawValue)
        }
    }

    func recordEngagement(isCorrect: Bool?, at date: Date = .now) throws {
        try recordView(at: date)

        switch status {
        case .viewed:
            try transition(to: .engaged, at: date)
            try transition(to: .scheduled, at: date)
        case .engaged:
            try transition(to: .scheduled, at: date)
        case .reviewDue:
            try transition(to: isCorrect == false ? .remediation : .recalled, at: date)
        case .recalled:
            try transition(to: isCorrect == false ? .scheduled : .mastered, at: date)
        case .remediation:
            try transition(to: .engaged, at: date)
            try transition(to: .scheduled, at: date)
        case .eligible, .surfaced, .scheduled, .mastered:
            lastEngagedAt = date
            lastTransitionAt = date
        case nil:
            throw ContentModelError.invalidStoredKnowledgeStatus(statusRawValue)
        }
    }

    static func makeRecordKey(ownerKey: String, contentUnitID: UUID) -> String {
        "\(ownerKey):\(contentUnitID.uuidString.lowercased())"
    }
}

@Model
final class LearningAttempt {
    @Attribute(.unique) var id: UUID
    var contentUnitID: UUID
    var interactionID: UUID?
    var interactionKindRawValue: String?
    var response: String
    var isCorrect: Bool?
    var confidenceRawValue: Int?
    var startedAt: Date?
    var completedAt: Date
    var durationSeconds: Double
    var usedHint: Bool
    var difficultyRawValue: Int?
    var estimatedMinutes: Int

    var interactionKind: InteractionKind? {
        interactionKindRawValue.flatMap(InteractionKind.init(rawValue:))
    }

    var confidence: AttemptConfidence {
        confidenceRawValue.flatMap(AttemptConfidence.init(rawValue:)) ?? .medium
    }

    var difficulty: ContentDifficulty {
        difficultyRawValue.flatMap(ContentDifficulty.init(rawValue:)) ?? .foundational
    }

    init(
        id: UUID = UUID(),
        contentUnitID: UUID,
        interactionID: UUID?,
        interactionKind: InteractionKind? = nil,
        response: String,
        isCorrect: Bool?,
        confidence: AttemptConfidence = .medium,
        startedAt: Date? = nil,
        completedAt: Date = .now,
        durationSeconds: Double = 0,
        usedHint: Bool = false,
        difficulty: ContentDifficulty? = nil,
        estimatedMinutes: Int
    ) {
        self.id = id
        self.contentUnitID = contentUnitID
        self.interactionID = interactionID
        interactionKindRawValue = interactionKind?.rawValue
        self.response = response
        self.isCorrect = isCorrect
        confidenceRawValue = confidence.rawValue
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.durationSeconds = durationSeconds
        self.usedHint = usedHint
        difficultyRawValue = difficulty?.rawValue
        self.estimatedMinutes = estimatedMinutes
    }
}

@Model
final class LearnerProfile {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var ownerKey: String
    var selectedCategoryIDs: [UUID]
    var learningGoalRawValue: String
    var learnerLevelRawValue: String
    var completedOnboarding: Bool
    var createdAt: Date
    var updatedAt: Date

    var learningGoal: LearningGoal? {
        LearningGoal(rawValue: learningGoalRawValue)
    }

    var learnerLevel: LearnerLevel? {
        LearnerLevel(rawValue: learnerLevelRawValue)
    }

    init(
        id: UUID = UUID(),
        ownerKey: String = "local",
        selectedCategoryIDs: [UUID],
        learningGoal: LearningGoal,
        learnerLevel: LearnerLevel,
        completedOnboarding: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.ownerKey = ownerKey
        self.selectedCategoryIDs = selectedCategoryIDs
        learningGoalRawValue = learningGoal.rawValue
        learnerLevelRawValue = learnerLevel.rawValue
        self.completedOnboarding = completedOnboarding
        self.createdAt = createdAt
        updatedAt = createdAt
    }

    func update(
        selectedCategoryIDs: [UUID],
        learningGoal: LearningGoal,
        learnerLevel: LearnerLevel,
        at date: Date = .now
    ) {
        self.selectedCategoryIDs = selectedCategoryIDs
        learningGoalRawValue = learningGoal.rawValue
        learnerLevelRawValue = learnerLevel.rawValue
        completedOnboarding = true
        updatedAt = date
    }
}

@Model
final class ReviewSchedule {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var recordKey: String
    var ownerKey: String
    var contentUnitID: UUID
    var nextReviewAt: Date
    var intervalDays: Int
    var repetitionCount: Int
    var lapseCount: Int
    var reasonRawValue: String
    var updatedAt: Date

    var reason: ReviewReason? {
        ReviewReason(rawValue: reasonRawValue)
    }

    init(
        id: UUID = UUID(),
        ownerKey: String = "local",
        contentUnitID: UUID,
        decision: ReviewDecision,
        updatedAt: Date = .now
    ) {
        self.id = id
        recordKey = Self.makeRecordKey(ownerKey: ownerKey, contentUnitID: contentUnitID)
        self.ownerKey = ownerKey
        self.contentUnitID = contentUnitID
        nextReviewAt = decision.nextReviewAt
        intervalDays = decision.intervalDays
        repetitionCount = decision.repetitionCount
        lapseCount = decision.lapseCount
        reasonRawValue = decision.reason.rawValue
        self.updatedAt = updatedAt
    }

    var isDue: Bool {
        nextReviewAt <= .now
    }

    func apply(_ decision: ReviewDecision, at date: Date = .now) {
        nextReviewAt = decision.nextReviewAt
        intervalDays = decision.intervalDays
        repetitionCount = decision.repetitionCount
        lapseCount = decision.lapseCount
        reasonRawValue = decision.reason.rawValue
        updatedAt = date
    }

    static func makeRecordKey(ownerKey: String, contentUnitID: UUID) -> String {
        "\(ownerKey):\(contentUnitID.uuidString.lowercased())"
    }
}

@Model
final class DomainProgressRecord {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var recordKey: String
    var ownerKey: String
    var categoryID: UUID
    var score: Double
    var evidenceCount: Int
    var strongEvidenceCount: Int
    var strongestKindRawValue: String?
    var updatedAt: Date

    var strongestKind: InteractionKind? {
        strongestKindRawValue.flatMap(InteractionKind.init(rawValue:))
    }

    init(
        id: UUID = UUID(),
        ownerKey: String = "local",
        categoryID: UUID,
        summary: EvidenceSummary,
        updatedAt: Date = .now
    ) {
        self.id = id
        recordKey = Self.makeRecordKey(ownerKey: ownerKey, categoryID: categoryID)
        self.ownerKey = ownerKey
        self.categoryID = categoryID
        score = summary.score
        evidenceCount = summary.evidenceCount
        strongEvidenceCount = summary.strongEvidenceCount
        strongestKindRawValue = summary.strongestKind?.rawValue
        self.updatedAt = updatedAt
    }

    func apply(_ summary: EvidenceSummary, at date: Date = .now) {
        score = summary.score
        evidenceCount = summary.evidenceCount
        strongEvidenceCount = summary.strongEvidenceCount
        strongestKindRawValue = summary.strongestKind?.rawValue
        updatedAt = date
    }

    static func makeRecordKey(ownerKey: String, categoryID: UUID) -> String {
        "\(ownerKey):\(categoryID.uuidString.lowercased())"
    }
}

@Model
final class ThoughtRecord {
    @Attribute(.unique) var id: UUID
    var contentUnitID: UUID?
    var body: String
    var kindRawValue: String
    var createdAt: Date
    var updatedAt: Date

    var kind: ThoughtKind {
        ThoughtKind(rawValue: kindRawValue) ?? .reflection
    }

    init(
        id: UUID = UUID(),
        contentUnitID: UUID?,
        body: String,
        kind: ThoughtKind = .reflection,
        createdAt: Date = .now
    ) {
        self.id = id
        self.contentUnitID = contentUnitID
        self.body = body
        kindRawValue = kind.rawValue
        self.createdAt = createdAt
        updatedAt = createdAt
    }

    func update(body: String, at date: Date = .now) {
        self.body = body
        updatedAt = date
    }
}

@Model
final class ApplicationAction {
    @Attribute(.unique) var id: UUID
    var contentUnitID: UUID
    var note: String
    var createdAt: Date
    var completedAt: Date?
    var skippedAt: Date?
    // Optional on disk so stores created by the pre-Growth-Loop build can be
    // migrated by SwiftData without inventing required values for old rows.
    var statusRawValue: String?
    var updatedAt: Date?

    var status: ActionStatus {
        if completedAt != nil {
            return .completed
        }
        if skippedAt != nil {
            return .skipped
        }
        return statusRawValue.flatMap(ActionStatus.init(rawValue:)) ?? .planned
    }

    init(
        id: UUID = UUID(),
        contentUnitID: UUID,
        note: String,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.contentUnitID = contentUnitID
        self.note = note
        self.createdAt = createdAt
        self.completedAt = completedAt
        skippedAt = nil
        statusRawValue = completedAt == nil
            ? ActionStatus.planned.rawValue
            : ActionStatus.completed.rawValue
        updatedAt = completedAt ?? createdAt
    }

    func update(note: String, at date: Date = .now) {
        self.note = note
        updatedAt = date
    }

    func complete(at date: Date = .now) {
        statusRawValue = ActionStatus.completed.rawValue
        completedAt = date
        skippedAt = nil
        updatedAt = date
    }

    func skip(at date: Date = .now) {
        statusRawValue = ActionStatus.skipped.rawValue
        completedAt = nil
        skippedAt = date
        updatedAt = date
    }
}

@Model
final class LocalProductEvent {
    @Attribute(.unique) var id: UUID
    var kindRawValue: String
    var contentUnitID: UUID?
    var occurredAt: Date
    var numericValue: Double?

    var kind: LocalEventKind? {
        LocalEventKind(rawValue: kindRawValue)
    }

    init(
        id: UUID = UUID(),
        kind: LocalEventKind,
        contentUnitID: UUID? = nil,
        occurredAt: Date = .now,
        numericValue: Double? = nil
    ) {
        self.id = id
        kindRawValue = kind.rawValue
        self.contentUnitID = contentUnitID
        self.occurredAt = occurredAt
        self.numericValue = numericValue
    }
}

@Model
final class ContentCatalogReceipt {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var sourceIdentifier: String
    var schemaVersion: Int
    var catalogVersion: Int
    var installedAt: Date

    init(
        id: UUID = UUID(),
        sourceIdentifier: String,
        schemaVersion: Int,
        catalogVersion: Int,
        installedAt: Date = .now
    ) {
        self.id = id
        self.sourceIdentifier = sourceIdentifier
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.installedAt = installedAt
    }

    func update(
        schemaVersion: Int,
        catalogVersion: Int,
        installedAt: Date
    ) {
        self.schemaVersion = schemaVersion
        self.catalogVersion = catalogVersion
        self.installedAt = installedAt
    }
}

struct PersistedContentCatalog {
    let categories: [ContentCategory]
    let topics: [ContentTopic]
    let contentUnits: [ContentUnit]
}

enum ContentModelFactory {
    static func makeCatalog(from definition: ContentCatalogDefinition) throws -> PersistedContentCatalog {
        try definition.validated()

        return PersistedContentCatalog(
            categories: definition.categories.map(ContentCategory.init(definition:)),
            topics: definition.topics.map(ContentTopic.init(definition:)),
            contentUnits: definition.contentUnits.map(ContentUnit.init(definition:))
        )
    }
}
