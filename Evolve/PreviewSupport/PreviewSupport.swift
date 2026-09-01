import Foundation
import SwiftData

@MainActor
enum PreviewSupport {
    static func environment(selectedTab: AppTab = .today) -> AppEnvironment {
        AppEnvironment(selectedTab: selectedTab)
    }

    static func modelContainer() -> ModelContainer {
        do {
            let container = try PersistenceController.makeContainer(inMemory: true)
            let catalog = LoadedContentCatalog(
                definition: MVPContentFixtures.catalog,
                sourceSchemaVersion: MVPContentFixtures.catalog.schemaVersion,
                didMigrate: false
            )
            _ = try ContentCatalogInstaller().install(
                catalog,
                sourceIdentifier: "preview",
                in: container.mainContext
            )
            return container
        } catch {
            fatalError("Unable to create preview container: \(error)")
        }
    }

    static func learningSessionPlan() -> LearningSessionPlan {
        LearningSessionPlan(
            items: [
                LearningSessionItem(
                    id: UUID(),
                    title: "The boundary of control",
                    summary: "A reflection on directing effort toward choices rather than outcomes.",
                    categoryName: "Philosophy",
                    kind: .principle,
                    difficulty: .introductory,
                    estimatedMinutes: 4,
                    blocks: MVPContentFixtures.philosophyUnit.blocks,
                    source: MVPContentFixtures.philosophyUnit.source
                ),
                LearningSessionItem(
                    id: UUID(),
                    title: "Retrieve before rereading",
                    summary: "Use an unaided attempt to reveal what is available from memory.",
                    categoryName: "Productivity & Learning",
                    kind: .technique,
                    difficulty: .foundational,
                    estimatedMinutes: 5,
                    blocks: MVPContentFixtures.productivityUnit.blocks,
                    source: MVPContentFixtures.productivityUnit.source
                )
            ]
        )
    }
}
