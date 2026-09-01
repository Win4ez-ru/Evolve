import Foundation
import OSLog
import SwiftData

@MainActor
enum PersistenceController {
    enum Availability: Equatable {
        case persistent
        case ephemeralFallback(reason: String)

        var isPersistent: Bool {
            self == .persistent
        }
    }

    struct Resolution {
        let container: ModelContainer
        let availability: Availability
    }

    private static let logger = Logger(
        subsystem: "com.evolve.app",
        category: "Persistence"
    )

    static let shared: Resolution = resolve()

    static func resolve(
        persistentStore: () throws -> ModelContainer = { try makeContainer() },
        fallbackStore: () throws -> ModelContainer = { try makeContainer(inMemory: true) }
    ) -> Resolution {
        do {
            return Resolution(
                container: try persistentStore(),
                availability: .persistent
            )
        } catch {
            let persistentStoreError = error.localizedDescription
            logger.error(
                "Persistent store unavailable; entering protected recovery mode: \(persistentStoreError, privacy: .public)"
            )

            do {
                return Resolution(
                    container: try fallbackStore(),
                    availability: .ephemeralFallback(reason: persistentStoreError)
                )
            } catch {
                fatalError("Unable to create any SwiftData container: \(error)")
            }
        }
    }

    static func makeContainer(
        inMemory: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema([
            AppInstallation.self,
            ContentCategory.self,
            ContentTopic.self,
            ContentUnit.self,
            ContentBlock.self,
            InteractionDefinition.self,
            KnowledgeRecord.self,
            LearningAttempt.self,
            LearnerProfile.self,
            ReviewSchedule.self,
            DomainProgressRecord.self,
            ThoughtRecord.self,
            ApplicationAction.self,
            LocalProductEvent.self,
            ContentCatalogReceipt.self
        ])
        let configuration: ModelConfiguration
        if let storeURL {
            precondition(!inMemory, "A disk store URL cannot be combined with an in-memory store.")
            configuration = ModelConfiguration(
                "Evolve",
                schema: schema,
                url: storeURL
            )
        } else {
            configuration = ModelConfiguration(
                "Evolve",
                schema: schema,
                isStoredInMemoryOnly: inMemory
            )
        }

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }
}
