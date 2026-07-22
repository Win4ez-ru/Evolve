import Foundation

struct ContentValidationIssue: Equatable, Sendable {
    enum Code: String, Sendable {
        case emptyValue
        case invalidSlug
        case invalidURL
        case invalidDuration
        case invalidOrder
        case duplicateIdentifier
        case duplicateSlug
        case missingReference
        case categoryMismatch
        case invalidPrimaryInteraction
        case invalidInteractionConfiguration
    }

    let code: Code
    let path: String
    let message: String
}

struct ContentValidationError: Error, Equatable, LocalizedError, Sendable {
    let issues: [ContentValidationIssue]

    var errorDescription: String? {
        issues
            .map { "\($0.path): \($0.message)" }
            .joined(separator: "\n")
    }
}

enum ContentValidator {
    static func validate(_ unit: ContentUnitDefinition) throws {
        let issues = validationIssues(for: unit)

        if !issues.isEmpty {
            throw ContentValidationError(issues: issues)
        }
    }

    static func validate(_ catalog: ContentCatalogDefinition) throws {
        var issues: [ContentValidationIssue] = []

        if catalog.schemaVersion <= 0 {
            issues.append(issue(.emptyValue, "schemaVersion", "Schema version must be positive."))
        }

        if catalog.catalogVersion <= 0 {
            issues.append(issue(.emptyValue, "catalogVersion", "Catalog version must be positive."))
        }

        if catalog.categories.isEmpty {
            issues.append(issue(.emptyValue, "categories", "At least one category is required."))
        }

        appendDuplicateIssues(
            values: catalog.categories.map(\.id),
            code: .duplicateIdentifier,
            path: "categories.id",
            message: "Category identifiers must be unique.",
            to: &issues
        )
        appendDuplicateIssues(
            values: catalog.categories.map(\.slug),
            code: .duplicateSlug,
            path: "categories.slug",
            message: "Category slugs must be unique.",
            to: &issues
        )

        for (index, category) in catalog.categories.enumerated() {
            let path = "categories[\(index)]"
            validateSlug(category.slug, path: "\(path).slug", issues: &issues)
            validateRequired(category.name, path: "\(path).name", issues: &issues)
            validateRequired(category.overview, path: "\(path).overview", issues: &issues)

            if category.sortOrder < 0 {
                issues.append(issue(.invalidOrder, "\(path).sortOrder", "Sort order cannot be negative."))
            }
        }

        appendDuplicateIssues(
            values: catalog.topics.map(\.id),
            code: .duplicateIdentifier,
            path: "topics.id",
            message: "Topic identifiers must be unique.",
            to: &issues
        )
        appendDuplicateIssues(
            values: catalog.topics.map(\.slug),
            code: .duplicateSlug,
            path: "topics.slug",
            message: "Topic slugs must be unique.",
            to: &issues
        )

        let categoryIDs = Set(catalog.categories.map(\.id))
        for (index, topic) in catalog.topics.enumerated() {
            let path = "topics[\(index)]"
            validateSlug(topic.slug, path: "\(path).slug", issues: &issues)
            validateRequired(topic.name, path: "\(path).name", issues: &issues)
            validateRequired(topic.overview, path: "\(path).overview", issues: &issues)

            if !categoryIDs.contains(topic.categoryID) {
                issues.append(issue(
                    .missingReference,
                    "\(path).categoryID",
                    "Topic references an unknown category."
                ))
            }
        }

        appendDuplicateIssues(
            values: catalog.contentUnits.map(\.id),
            code: .duplicateIdentifier,
            path: "contentUnits.id",
            message: "Content identifiers must be unique.",
            to: &issues
        )
        appendDuplicateIssues(
            values: catalog.contentUnits.map(\.slug),
            code: .duplicateSlug,
            path: "contentUnits.slug",
            message: "Content slugs must be unique.",
            to: &issues
        )

        let topicsByID = Dictionary(uniqueKeysWithValues: catalog.topics.map { ($0.id, $0) })
        for (index, unit) in catalog.contentUnits.enumerated() {
            let path = "contentUnits[\(index)]"
            issues.append(contentsOf: validationIssues(for: unit, rootPath: path))

            if !categoryIDs.contains(unit.categoryID) {
                issues.append(issue(
                    .missingReference,
                    "\(path).categoryID",
                    "Content references an unknown category."
                ))
            }

            for topicID in unit.topicIDs {
                guard let topic = topicsByID[topicID] else {
                    issues.append(issue(
                        .missingReference,
                        "\(path).topicIDs",
                        "Content references an unknown topic."
                    ))
                    continue
                }

                if topic.categoryID != unit.categoryID {
                    issues.append(issue(
                        .categoryMismatch,
                        "\(path).topicIDs",
                        "Every topic must belong to the content category."
                    ))
                }
            }
        }

        if !issues.isEmpty {
            throw ContentValidationError(issues: issues)
        }
    }

    private static func validationIssues(
        for unit: ContentUnitDefinition,
        rootPath: String = "contentUnit"
    ) -> [ContentValidationIssue] {
        var issues: [ContentValidationIssue] = []

        validateSlug(unit.slug, path: "\(rootPath).slug", issues: &issues)
        validateRequired(unit.title, path: "\(rootPath).title", issues: &issues)
        validateRequired(unit.summary, path: "\(rootPath).summary", issues: &issues)

        if unit.topicIDs.isEmpty {
            issues.append(issue(.emptyValue, "\(rootPath).topicIDs", "At least one topic is required."))
        }
        appendDuplicateIssues(
            values: unit.topicIDs,
            code: .duplicateIdentifier,
            path: "\(rootPath).topicIDs",
            message: "Topic references must be unique.",
            to: &issues
        )

        if unit.estimatedMinutes <= 0 {
            issues.append(issue(
                .invalidDuration,
                "\(rootPath).estimatedMinutes",
                "Estimated duration must be positive."
            ))
        }

        if unit.blocks.isEmpty {
            issues.append(issue(.emptyValue, "\(rootPath).blocks", "At least one content block is required."))
        }
        appendDuplicateIssues(
            values: unit.blocks.map(\.id),
            code: .duplicateIdentifier,
            path: "\(rootPath).blocks.id",
            message: "Block identifiers must be unique.",
            to: &issues
        )
        validateContiguousOrders(
            unit.blocks.map(\.order),
            path: "\(rootPath).blocks.order",
            issues: &issues
        )

        for (index, block) in unit.blocks.enumerated() {
            validateRequired(
                block.content,
                path: "\(rootPath).blocks[\(index)].content",
                issues: &issues
            )
        }

        if unit.interactions.isEmpty {
            issues.append(issue(
                .emptyValue,
                "\(rootPath).interactions",
                "At least one interaction is required."
            ))
        }
        appendDuplicateIssues(
            values: unit.interactions.map(\.id),
            code: .duplicateIdentifier,
            path: "\(rootPath).interactions.id",
            message: "Interaction identifiers must be unique.",
            to: &issues
        )
        validateContiguousOrders(
            unit.interactions.map(\.order),
            path: "\(rootPath).interactions.order",
            issues: &issues
        )

        let primaryCount = unit.interactions.count(where: \.isPrimary)
        if primaryCount != 1 {
            issues.append(issue(
                .invalidPrimaryInteraction,
                "\(rootPath).interactions",
                "Exactly one interaction must be primary."
            ))
        }

        for (index, interaction) in unit.interactions.enumerated() {
            let path = "\(rootPath).interactions[\(index)]"
            validateRequired(interaction.prompt, path: "\(path).prompt", issues: &issues)

            if interaction.estimatedMinutes <= 0 {
                issues.append(issue(
                    .invalidDuration,
                    "\(path).estimatedMinutes",
                    "Interaction duration must be positive."
                ))
            }

            if [.singleChoice, .multipleChoice].contains(interaction.responseKind),
               interaction.options.count < 2 {
                issues.append(issue(
                    .invalidInteractionConfiguration,
                    "\(path).options",
                    "Choice interactions require at least two options."
                ))
            }

            if interaction.evaluationKind == .exactMatch,
               isBlank(interaction.expectedResponse) {
                issues.append(issue(
                    .invalidInteractionConfiguration,
                    "\(path).expectedResponse",
                    "Exact-match evaluation requires an expected response."
                ))
            }

            if interaction.requiresOwnResponseBeforeCommunity,
               interaction.kind != .discuss {
                issues.append(issue(
                    .invalidInteractionConfiguration,
                    "\(path).requiresOwnResponseBeforeCommunity",
                    "The own-response gate is only valid for discussion."
                ))
            }
        }

        validateRequired(unit.source.title, path: "\(rootPath).source.title", issues: &issues)
        validateRequired(unit.source.creator, path: "\(rootPath).source.creator", issues: &issues)

        if let url = unit.source.url,
           !["http", "https"].contains(url.scheme?.lowercased()) {
            issues.append(issue(
                .invalidURL,
                "\(rootPath).source.url",
                "Source URL must use HTTP or HTTPS."
            ))
        }

        if unit.safety.level != .standard, isBlank(unit.safety.notice) {
            issues.append(issue(
                .emptyValue,
                "\(rootPath).safety.notice",
                "Caution and restricted content require a safety notice."
            ))
        }

        return issues
    }

    private static func validateRequired(
        _ value: String,
        path: String,
        issues: inout [ContentValidationIssue]
    ) {
        if isBlank(value) {
            issues.append(issue(.emptyValue, path, "Value cannot be empty."))
        }
    }

    private static func validateSlug(
        _ slug: String,
        path: String,
        issues: inout [ContentValidationIssue]
    ) {
        let allowed = Set("abcdefghijklmnopqrstuvwxyz0123456789-")
        let isValid = !slug.isEmpty
            && slug.first != "-"
            && slug.last != "-"
            && !slug.contains("--")
            && slug.allSatisfy(allowed.contains)

        if !isValid {
            issues.append(issue(
                .invalidSlug,
                path,
                "Use lowercase ASCII letters, numbers, and single hyphens."
            ))
        }
    }

    private static func validateContiguousOrders(
        _ orders: [Int],
        path: String,
        issues: inout [ContentValidationIssue]
    ) {
        guard !orders.isEmpty else { return }

        if orders.sorted() != Array(0..<orders.count) {
            issues.append(issue(
                .invalidOrder,
                path,
                "Order values must be unique and contiguous, starting at zero."
            ))
        }
    }

    private static func appendDuplicateIssues<Value: Hashable>(
        values: [Value],
        code: ContentValidationIssue.Code,
        path: String,
        message: String,
        to issues: inout [ContentValidationIssue]
    ) {
        if Set(values).count != values.count {
            issues.append(issue(code, path, message))
        }
    }

    private static func isBlank(_ value: String?) -> Bool {
        value?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }

    private static func issue(
        _ code: ContentValidationIssue.Code,
        _ path: String,
        _ message: String
    ) -> ContentValidationIssue {
        ContentValidationIssue(code: code, path: path, message: message)
    }
}

extension ContentUnitDefinition {
    @discardableResult
    func validated() throws -> Self {
        try ContentValidator.validate(self)
        return self
    }
}

extension ContentCatalogDefinition {
    @discardableResult
    func validated() throws -> Self {
        try ContentValidator.validate(self)
        return self
    }
}
