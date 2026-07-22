import Foundation
import SwiftData
import Testing
@testable import Evolve

@Suite("Content persistence")
@MainActor
struct ContentPersistenceTests {
    @Test("A validated catalog persists without category-specific models")
    func persistsUniversalCatalog() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let catalog = try ContentModelFactory.makeCatalog(from: MVPContentFixtures.catalog)

        catalog.categories.forEach(context.insert)
        catalog.topics.forEach(context.insert)
        catalog.contentUnits.forEach(context.insert)
        try context.save()

        let categories = try context.fetch(FetchDescriptor<ContentCategory>())
        let topics = try context.fetch(FetchDescriptor<ContentTopic>())
        let units = try context.fetch(FetchDescriptor<ContentUnit>())
        let blocks = try context.fetch(FetchDescriptor<ContentBlock>())
        let interactions = try context.fetch(FetchDescriptor<InteractionDefinition>())

        #expect(categories.count == 3)
        #expect(topics.count == 3)
        #expect(units.count == 3)
        #expect(blocks.count == 6)
        #expect(interactions.count == 7)

        let programming = units.first { $0.slug == "predict-reduce-result" }
        #expect(programming?.kind == .problem)
        #expect(programming?.orderedBlocks.first?.kind == .code)
        #expect(programming?.orderedInteractions.first?.kind == .solve)
        #expect(programming?.orderedInteractions.first?.isPrimary == true)
    }

    @Test("A knowledge record keeps saving orthogonal to learning state")
    func persistsKnowledgeState() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let record = KnowledgeRecord(
            contentUnitID: MVPContentFixtures.philosophyUnit.id,
            createdAt: createdAt
        )

        record.setSaved(true, at: createdAt.addingTimeInterval(10))
        try record.transition(to: .surfaced, at: createdAt.addingTimeInterval(20))
        try record.transition(to: .viewed, at: createdAt.addingTimeInterval(30))
        try record.transition(to: .engaged, at: createdAt.addingTimeInterval(40))
        try record.transition(to: .scheduled, at: createdAt.addingTimeInterval(50))

        context.insert(record)
        try context.save()

        let records = try context.fetch(FetchDescriptor<KnowledgeRecord>())
        let persisted = try #require(records.first)

        #expect(persisted.status == .scheduled)
        #expect(persisted.isSaved)
        #expect(persisted.savedAt == createdAt.addingTimeInterval(10))
        #expect(persisted.lastEngagedAt == createdAt.addingTimeInterval(40))
    }
}
