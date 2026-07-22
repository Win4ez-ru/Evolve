import Foundation

enum MVPContentFixtures {
    static let philosophyCategoryID = id("10000000-0000-4000-8000-000000000001")
    static let productivityCategoryID = id("10000000-0000-4000-8000-000000000002")
    static let programmingCategoryID = id("10000000-0000-4000-8000-000000000003")

    static let philosophyTopicID = id("20000000-0000-4000-8000-000000000001")
    static let productivityTopicID = id("20000000-0000-4000-8000-000000000002")
    static let programmingTopicID = id("20000000-0000-4000-8000-000000000003")

    static let catalog = ContentCatalogDefinition(
        schemaVersion: 1,
        catalogVersion: 1,
        categories: [
            ContentCategoryDefinition(
                id: philosophyCategoryID,
                slug: "philosophy",
                name: "Philosophy",
                overview: "Ideas that sharpen judgment and support deliberate reflection.",
                sortOrder: 0
            ),
            ContentCategoryDefinition(
                id: productivityCategoryID,
                slug: "productivity-learning",
                name: "Productivity & Learning",
                overview: "Methods for learning intentionally and applying useful ideas.",
                sortOrder: 1
            ),
            ContentCategoryDefinition(
                id: programmingCategoryID,
                slug: "programming-basics",
                name: "Programming Basics",
                overview: "Foundational reasoning skills for reading and writing code.",
                sortOrder: 2
            )
        ],
        topics: [
            ContentTopicDefinition(
                id: philosophyTopicID,
                categoryID: philosophyCategoryID,
                slug: "judgment-and-control",
                name: "Judgment & Control",
                overview: "Separating personal choices from external events."
            ),
            ContentTopicDefinition(
                id: productivityTopicID,
                categoryID: productivityCategoryID,
                slug: "active-learning",
                name: "Active Learning",
                overview: "Turning exposure into retrieval, observation, and action."
            ),
            ContentTopicDefinition(
                id: programmingTopicID,
                categoryID: programmingCategoryID,
                slug: "program-reasoning",
                name: "Program Reasoning",
                overview: "Predicting program behavior before running it."
            )
        ],
        contentUnits: [
            philosophyUnit,
            productivityUnit,
            programmingUnit
        ]
    )

    static let philosophyUnit = ContentUnitDefinition(
        id: id("30000000-0000-4000-8000-000000000001"),
        slug: "control-boundary",
        title: "The boundary of control",
        summary: "A reflection on directing effort toward choices rather than outcomes.",
        kind: .principle,
        difficulty: .introductory,
        editorialStatus: .published,
        categoryID: philosophyCategoryID,
        topicIDs: [philosophyTopicID],
        estimatedMinutes: 4,
        blocks: [
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000001"),
                kind: .paragraph,
                order: 0,
                content: "Some outcomes depend on our choices; others also depend on circumstances and other people. Clear action starts by naming the difference."
            ),
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000002"),
                kind: .callout,
                order: 1,
                content: "The purpose is not passivity. It is to spend effort where a deliberate choice is still possible."
            )
        ],
        interactions: [
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000001"),
                kind: .reflect,
                responseKind: .text,
                evaluationKind: .selfAssessment,
                order: 0,
                prompt: "Which part of a current situation is genuinely yours to choose?",
                estimatedMinutes: 2,
                isPrimary: true,
                isRequired: true
            ),
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000002"),
                kind: .explain,
                responseKind: .text,
                evaluationKind: .selfAssessment,
                order: 1,
                prompt: "Explain the boundary of control in your own words.",
                estimatedMinutes: 2
            )
        ],
        source: fixtureSource
    )

    static let productivityUnit = ContentUnitDefinition(
        id: id("30000000-0000-4000-8000-000000000002"),
        slug: "retrieve-before-rereading",
        title: "Retrieve before rereading",
        summary: "Use an unaided attempt to reveal what is actually available from memory.",
        kind: .technique,
        difficulty: .foundational,
        editorialStatus: .published,
        categoryID: productivityCategoryID,
        topicIDs: [productivityTopicID],
        estimatedMinutes: 5,
        blocks: [
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000003"),
                kind: .paragraph,
                order: 0,
                content: "Before reopening notes, write down what you remember. The gaps in the attempt make the next review more focused."
            ),
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000004"),
                kind: .callout,
                order: 1,
                content: "A difficult attempt is useful evidence, not a failure signal."
            )
        ],
        interactions: [
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000003"),
                kind: .observe,
                responseKind: .text,
                evaluationKind: .completion,
                order: 0,
                prompt: "Notice when you reach for notes before attempting to remember.",
                estimatedMinutes: 1,
                isPrimary: true,
                isRequired: true
            ),
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000004"),
                kind: .apply,
                responseKind: .text,
                evaluationKind: .completion,
                order: 1,
                prompt: "Choose one topic and schedule a two-minute retrieval attempt.",
                estimatedMinutes: 2
            ),
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000005"),
                kind: .track,
                responseKind: .measurement,
                evaluationKind: .completion,
                order: 2,
                prompt: "Record how many key points you recalled before reviewing.",
                estimatedMinutes: 1
            )
        ],
        source: fixtureSource
    )

    static let programmingUnit = ContentUnitDefinition(
        id: id("30000000-0000-4000-8000-000000000003"),
        slug: "predict-reduce-result",
        title: "Predict the result",
        summary: "Trace a small reduction before asking the computer for the answer.",
        kind: .problem,
        difficulty: .foundational,
        editorialStatus: .published,
        categoryID: programmingCategoryID,
        topicIDs: [programmingTopicID],
        estimatedMinutes: 4,
        blocks: [
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000005"),
                kind: .code,
                order: 0,
                content: "let values = [2, 4, 6]\nlet total = values.reduce(0, +)\nprint(total)",
                language: "swift",
                accessibilityLabel: "Swift code that reduces the values two, four, and six into a total."
            ),
            ContentBlockSpec(
                id: id("40000000-0000-4000-8000-000000000006"),
                kind: .paragraph,
                order: 1,
                content: "Follow the accumulator after each element, then choose the printed value."
            )
        ],
        interactions: [
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000006"),
                kind: .solve,
                responseKind: .singleChoice,
                evaluationKind: .choice,
                order: 0,
                prompt: "What does the program print?",
                estimatedMinutes: 2,
                isPrimary: true,
                isRequired: true,
                options: ["6", "10", "12", "24"],
                expectedResponse: "12"
            ),
            InteractionSpec(
                id: id("50000000-0000-4000-8000-000000000007"),
                kind: .recall,
                responseKind: .text,
                evaluationKind: .selfAssessment,
                order: 1,
                prompt: "Without looking back, describe the two inputs a reduction needs.",
                estimatedMinutes: 2
            )
        ],
        source: fixtureSource
    )

    private static let fixtureSource = ContentSource(
        title: "Stage 3 model fixture",
        creator: "Evolve Editorial",
        license: "Internal sample — not production catalog content"
    )

    private static func id(_ value: String) -> UUID {
        guard let id = UUID(uuidString: value) else {
            preconditionFailure("Invalid fixture UUID: \(value)")
        }
        return id
    }
}
