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

    static func makeRecordKey(ownerKey: String, contentUnitID: UUID) -> String {
        "\(ownerKey):\(contentUnitID.uuidString.lowercased())"
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
