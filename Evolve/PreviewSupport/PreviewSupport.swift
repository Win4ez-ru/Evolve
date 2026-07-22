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
}
