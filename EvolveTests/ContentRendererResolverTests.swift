import Foundation
import SwiftData
import Testing
@testable import Evolve

@Suite("Universal content rendering")
@MainActor
struct ContentRendererResolverTests {
    @Test("Specialized content kinds select specialized renderers")
    func routesSpecializedContentKinds() {
        #expect(ContentRendererResolver.unitRenderer(for: .concept) == .concept)
        #expect(ContentRendererResolver.unitRenderer(for: .principle) == .principle)
        #expect(ContentRendererResolver.unitRenderer(for: .dilemma) == .dilemma)
        #expect(ContentRendererResolver.unitRenderer(for: .problem) == .problem)
        #expect(ContentRendererResolver.unitRenderer(for: .workedExample) == .workedExample)
    }

    @Test("Every other content kind has a stable universal fallback")
    func routesOtherKindsToStandardRenderer() {
        let specialized: Set<ContentKind> = [
            .concept,
            .principle,
            .dilemma,
            .problem,
            .workedExample
        ]

        for kind in ContentKind.allCases where !specialized.contains(kind) {
            #expect(ContentRendererResolver.unitRenderer(for: kind) == .standard)
        }
    }

    @Test("Every block kind selects a renderer without screen-specific logic")
    func routesEveryBlockKind() {
        let expectations: [ContentBlockKind: ContentBlockRendererKind] = [
            .heading: .heading,
            .paragraph: .paragraph,
            .quote: .quote,
            .code: .code,
            .formula: .formula,
            .image: .media,
            .audio: .media,
            .video: .media,
            .callout: .callout
        ]

        for kind in ContentBlockKind.allCases {
            #expect(ContentRendererResolver.blockRenderer(for: kind) == expectations[kind])
        }
    }

    @Test("A session snapshot keeps blocks, source, and difficulty")
    func sessionSnapshotRetainsRendererData() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let catalog = try ContentModelFactory.makeCatalog(from: MVPContentFixtures.catalog)

        catalog.categories.forEach(context.insert)
        catalog.topics.forEach(context.insert)
        catalog.contentUnits.forEach(context.insert)
        try context.save()

        let units = try context.fetch(
            FetchDescriptor<ContentUnit>(
                sortBy: [SortDescriptor(\ContentUnit.title)]
            )
        )
        let categories = try context.fetch(FetchDescriptor<ContentCategory>())
        let plan = LearningSessionPlan(contentUnits: units, categories: categories)
        let first = try #require(plan.items.first)

        #expect(first.kind == .concept)
        #expect(first.difficulty == .foundational)
        #expect(first.blocks.map(\.kind) == [.heading, .paragraph, .quote])
        #expect(first.source.title == "Stage 6 renderer fixture")
    }
}
