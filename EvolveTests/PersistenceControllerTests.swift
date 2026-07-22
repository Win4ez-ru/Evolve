import SwiftData
import Testing
@testable import Evolve

@Suite("Persistence")
@MainActor
struct PersistenceControllerTests {
    @Test("The in-memory store persists an installation record")
    func persistsInstallationRecord() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let installation = AppInstallation(schemaVersion: 1)

        context.insert(installation)
        try context.save()

        let records = try context.fetch(FetchDescriptor<AppInstallation>())

        #expect(records.count == 1)
        #expect(records.first?.id == installation.id)
        #expect(records.first?.schemaVersion == 1)
    }
}
