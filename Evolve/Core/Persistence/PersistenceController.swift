import OSLog
import SwiftData

@MainActor
enum PersistenceController {
    private static let logger = Logger(
        subsystem: "com.evolve.app",
        category: "Persistence"
    )

    static let shared: ModelContainer = {
        do {
            return try makeContainer()
        } catch {
            logger.error(
                "Persistent store unavailable; using an in-memory fallback: \(error.localizedDescription, privacy: .public)"
            )

            do {
                return try makeContainer(inMemory: true)
            } catch {
                fatalError("Unable to create any SwiftData container: \(error)")
            }
        }
    }()

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            AppInstallation.self,
            ContentCategory.self,
            ContentTopic.self,
            ContentUnit.self,
            ContentBlock.self,
            InteractionDefinition.self,
            KnowledgeRecord.self,
            ContentCatalogReceipt.self
        ])
        let configuration = ModelConfiguration(
            "Evolve",
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
