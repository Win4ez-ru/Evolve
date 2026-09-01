import Foundation
import SwiftData
import Testing
@testable import Evolve

@Suite("Content catalog installation")
@MainActor
struct ContentCatalogInstallationTests {
    @Test("Installing the same revision twice is idempotent")
    func installsIdempotently() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let source = try source(for: MVPContentFixtures.catalog)
        let bootstrapper = ContentCatalogBootstrapper()

        let first = try bootstrapper.install(from: source, in: context)
        let second = try bootstrapper.install(from: source, in: context)

        #expect(first.outcome == .installed)
        #expect(second.outcome == .unchanged)
        #expect(try context.fetchCount(FetchDescriptor<ContentCategory>()) == 3)
        #expect(try context.fetchCount(FetchDescriptor<ContentUnit>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<ContentCatalogReceipt>()) == 1)
    }

    @Test("A missing stored unit is repaired without a revision change")
    func repairsIncompleteCatalog() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let source = try source(for: MVPContentFixtures.catalog)
        let bootstrapper = ContentCatalogBootstrapper()

        _ = try bootstrapper.install(from: source, in: context)
        let units = try context.fetch(FetchDescriptor<ContentUnit>())
        context.delete(try #require(units.first))
        try context.save()

        let report = try bootstrapper.install(from: source, in: context)

        #expect(report.outcome == .repaired)
        #expect(try context.fetchCount(FetchDescriptor<ContentUnit>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<ContentBlock>()) == 14)
        #expect(try context.fetchCount(FetchDescriptor<InteractionDefinition>()) == 10)
    }

    @Test("A newer catalog updates content and preserves personal state")
    func upgradesWithoutLosingKnowledgeRecords() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let bootstrapper = ContentCatalogBootstrapper()

        _ = try bootstrapper.install(
            from: try source(for: MVPContentFixtures.catalog),
            in: context
        )

        let record = KnowledgeRecord(contentUnitID: MVPContentFixtures.philosophyUnit.id)
        record.setSaved(true)
        context.insert(record)
        try context.save()

        let upgradedCatalog = makeCatalog(
            version: 3,
            firstTitle: "The boundary of control — revised"
        )
        let report = try bootstrapper.install(
            from: try source(for: upgradedCatalog),
            in: context
        )

        let units = try context.fetch(FetchDescriptor<ContentUnit>())
        let records = try context.fetch(FetchDescriptor<KnowledgeRecord>())

        #expect(report.outcome == .updated)
        #expect(units.first { $0.id == MVPContentFixtures.philosophyUnit.id }?.title == "The boundary of control — revised")
        #expect(records.count == 1)
        #expect(records.first?.isSaved == true)
    }

    @Test("A catalog ID replacement keeps an onboarded learner in the feed")
    func repairsStaleCategorySelection() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let bootstrapper = ContentCatalogBootstrapper()

        _ = try bootstrapper.install(
            from: try source(for: MVPContentFixtures.catalog),
            in: context
        )

        let oldCategoryID = try #require(MVPContentFixtures.catalog.categories.first?.id)
        let profile = LearnerProfile(
            selectedCategoryIDs: [oldCategoryID],
            learningGoal: .applyIdeas,
            learnerLevel: .growing
        )
        context.insert(profile)
        try context.save()

        let bundledData = try BundleContentCatalogSource(bundle: .main).loadData()
        let bundledCatalog = try ContentCatalogDecoder().decode(bundledData).definition
        let upgradedSource = DataContentCatalogSource(
            identifier: "test-catalog",
            data: bundledData
        )

        let update = try bootstrapper.install(from: upgradedSource, in: context)
        let newCategoryID = try #require(bundledCatalog.categories.first?.id)

        #expect(update.outcome == .updated)
        #expect(profile.selectedCategoryIDs == [newCategoryID])

        profile.selectedCategoryIDs = [UUID()]
        try context.save()

        let repair = try bootstrapper.install(from: upgradedSource, in: context)

        #expect(repair.outcome == .repaired)
        #expect(profile.selectedCategoryIDs == [newCategoryID])
    }

    @Test("A catalog downgrade is rejected without changing stored content")
    func rejectsDowngrade() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let bootstrapper = ContentCatalogBootstrapper()
        let versionThree = makeCatalog(version: 3, firstTitle: "Revision three")

        _ = try bootstrapper.install(
            from: try source(for: versionThree),
            in: context
        )

        do {
            _ = try bootstrapper.install(
                from: try source(for: MVPContentFixtures.catalog),
                in: context
            )
            Issue.record("A catalog downgrade unexpectedly succeeded.")
        } catch let error as ContentCatalogInstallationError {
            #expect(error == .catalogDowngrade(installed: 3, incoming: 2))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }

        let units = try context.fetch(FetchDescriptor<ContentUnit>())
        #expect(units.first { $0.id == MVPContentFixtures.philosophyUnit.id }?.title == "Revision three")
    }

    private func source(
        for catalog: ContentCatalogDefinition
    ) throws -> DataContentCatalogSource {
        DataContentCatalogSource(
            identifier: "test-catalog",
            data: try JSONEncoder().encode(catalog)
        )
    }

    private func makeCatalog(
        version: Int,
        firstTitle: String
    ) -> ContentCatalogDefinition {
        let base = MVPContentFixtures.catalog
        let units = base.contentUnits.enumerated().map { index, unit in
            ContentUnitDefinition(
                id: unit.id,
                slug: unit.slug,
                title: index == 0 ? firstTitle : unit.title,
                summary: unit.summary,
                kind: unit.kind,
                difficulty: unit.difficulty,
                editorialStatus: unit.editorialStatus,
                categoryID: unit.categoryID,
                topicIDs: unit.topicIDs,
                estimatedMinutes: unit.estimatedMinutes,
                blocks: unit.blocks,
                interactions: unit.interactions,
                source: unit.source,
                safety: unit.safety
            )
        }

        return ContentCatalogDefinition(
            schemaVersion: base.schemaVersion,
            catalogVersion: version,
            categories: base.categories,
            topics: base.topics,
            contentUnits: units
        )
    }
}
