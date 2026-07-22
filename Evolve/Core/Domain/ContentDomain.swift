import Foundation

enum ContentKind: String, CaseIterable, Codable, Sendable {
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

enum ContentBlockKind: String, CaseIterable, Codable, Sendable {
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

enum ContentDifficulty: Int, CaseIterable, Codable, Sendable {
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

struct ContentSource: Codable, Equatable, Sendable {
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

struct ContentBlockSpec: Identifiable, Codable, Equatable, Sendable {
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

struct InteractionSpec: Identifiable, Codable, Equatable, Sendable {
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
