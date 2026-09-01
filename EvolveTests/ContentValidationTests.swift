import Foundation
import Testing
@testable import Evolve

@Suite("Content validation")
struct ContentValidationTests {
    @Test("The three MVP categories share one valid catalog schema")
    func validatesMVPFixtureCatalog() throws {
        let catalog = try MVPContentFixtures.catalog.validated()

        #expect(catalog.categories.count == 3)
        #expect(catalog.contentUnits.count == 6)
        #expect(Set(catalog.contentUnits.map(\.categoryID)).count == 3)
        #expect(catalog.contentUnits.allSatisfy { !$0.interactions.isEmpty })
    }

    @Test("A content unit needs blocks and exactly one primary interaction")
    func rejectsIncompleteContentUnit() {
        let original = MVPContentFixtures.philosophyUnit
        let invalid = ContentUnitDefinition(
            id: original.id,
            slug: original.slug,
            title: original.title,
            summary: original.summary,
            kind: original.kind,
            difficulty: original.difficulty,
            editorialStatus: original.editorialStatus,
            categoryID: original.categoryID,
            topicIDs: original.topicIDs,
            estimatedMinutes: original.estimatedMinutes,
            blocks: [],
            interactions: original.interactions.map {
                InteractionSpec(
                    id: $0.id,
                    kind: $0.kind,
                    responseKind: $0.responseKind,
                    evaluationKind: $0.evaluationKind,
                    order: $0.order,
                    prompt: $0.prompt,
                    estimatedMinutes: $0.estimatedMinutes,
                    isPrimary: false,
                    isRequired: $0.isRequired,
                    requiresOwnResponseBeforeCommunity: $0.requiresOwnResponseBeforeCommunity,
                    options: $0.options,
                    expectedResponse: $0.expectedResponse
                )
            },
            source: original.source,
            safety: original.safety
        )

        do {
            try invalid.validated()
            Issue.record("Invalid content unexpectedly passed validation.")
        } catch let error as ContentValidationError {
            let codes = Set(error.issues.map(\.code))
            #expect(codes.contains(.emptyValue))
            #expect(codes.contains(.invalidPrimaryInteraction))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Topics cannot cross category boundaries")
    func rejectsCrossCategoryTopic() {
        let original = MVPContentFixtures.programmingUnit
        let invalidUnit = ContentUnitDefinition(
            id: original.id,
            slug: original.slug,
            title: original.title,
            summary: original.summary,
            kind: original.kind,
            difficulty: original.difficulty,
            editorialStatus: original.editorialStatus,
            categoryID: original.categoryID,
            topicIDs: [MVPContentFixtures.philosophyTopicID],
            estimatedMinutes: original.estimatedMinutes,
            blocks: original.blocks,
            interactions: original.interactions,
            source: original.source,
            safety: original.safety
        )
        let invalidCatalog = ContentCatalogDefinition(
            schemaVersion: MVPContentFixtures.catalog.schemaVersion,
            catalogVersion: MVPContentFixtures.catalog.catalogVersion,
            categories: MVPContentFixtures.catalog.categories,
            topics: MVPContentFixtures.catalog.topics,
            contentUnits: [invalidUnit]
        )

        do {
            try invalidCatalog.validated()
            Issue.record("A cross-category topic unexpectedly passed validation.")
        } catch let error as ContentValidationError {
            #expect(error.issues.contains { $0.code == .categoryMismatch })
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
