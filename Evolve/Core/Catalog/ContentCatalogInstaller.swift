import Foundation
import SwiftData

enum ContentCatalogInstallOutcome: String, Equatable, Sendable {
    case installed
    case updated
    case repaired
    case unchanged
}

struct ContentCatalogInstallationReport: Equatable, Sendable {
    let outcome: ContentCatalogInstallOutcome
    let schemaVersion: Int
    let catalogVersion: Int
    let categoryCount: Int
    let topicCount: Int
    let contentUnitCount: Int
}

enum ContentCatalogInstallationError: Error, Equatable, LocalizedError {
    case catalogDowngrade(installed: Int, incoming: Int)
    case persistenceFailed(String)

    var errorDescription: String? {
        switch self {
        case let .catalogDowngrade(installed, incoming):
            "Catalog downgrade from revision \(installed) to \(incoming) was rejected."
        case let .persistenceFailed(reason):
            "Catalog could not be persisted: \(reason)"
        }
    }
}

@MainActor
struct ContentCatalogInstaller {
    func install(
        _ loadedCatalog: LoadedContentCatalog,
        sourceIdentifier: String,
        in context: ModelContext,
        installedAt: Date = .now
    ) throws -> ContentCatalogInstallationReport {
        let definition = loadedCatalog.definition

        do {
            let receipts = try context.fetch(FetchDescriptor<ContentCatalogReceipt>())
            let receipt = receipts.first { $0.sourceIdentifier == sourceIdentifier }

            if let receipt,
               definition.catalogVersion < receipt.catalogVersion {
                throw ContentCatalogInstallationError.catalogDowngrade(
                    installed: receipt.catalogVersion,
                    incoming: definition.catalogVersion
                )
            }

            let categories = try context.fetch(FetchDescriptor<ContentCategory>())
            let topics = try context.fetch(FetchDescriptor<ContentTopic>())
            let units = try context.fetch(FetchDescriptor<ContentUnit>())
            let blocks = try context.fetch(FetchDescriptor<ContentBlock>())
            let interactions = try context.fetch(FetchDescriptor<InteractionDefinition>())
            let learnerProfiles = try context.fetch(FetchDescriptor<LearnerProfile>())

            let didRepairLearnerSelections = normalizeLearnerSelections(
                learnerProfiles,
                against: definition.categories,
                at: installedAt
            )

            let isComplete = hasExpectedIdentifiers(
                definition: definition,
                categories: categories,
                topics: topics,
                units: units,
                blocks: blocks,
                interactions: interactions
            )

            if let receipt,
               receipt.schemaVersion == definition.schemaVersion,
               receipt.catalogVersion == definition.catalogVersion,
               isComplete,
               !didRepairLearnerSelections {
                return report(for: definition, outcome: .unchanged)
            }

            let outcome: ContentCatalogInstallOutcome
            if let receipt {
                outcome = definition.catalogVersion > receipt.catalogVersion ? .updated : .repaired
            } else {
                outcome = .installed
            }

            reconcileCategories(definition.categories, existing: categories, in: context)
            reconcileTopics(definition.topics, existing: topics, in: context)
            reconcileContentUnits(definition.contentUnits, existing: units, in: context)

            if let receipt {
                receipt.update(
                    schemaVersion: definition.schemaVersion,
                    catalogVersion: definition.catalogVersion,
                    installedAt: installedAt
                )
            } else {
                context.insert(ContentCatalogReceipt(
                    sourceIdentifier: sourceIdentifier,
                    schemaVersion: definition.schemaVersion,
                    catalogVersion: definition.catalogVersion,
                    installedAt: installedAt
                ))
            }

            try context.save()
            return report(for: definition, outcome: outcome)
        } catch let error as ContentCatalogInstallationError {
            context.rollback()
            throw error
        } catch {
            context.rollback()
            throw ContentCatalogInstallationError.persistenceFailed(error.localizedDescription)
        }
    }

    /// Catalog revisions may replace editorial identifiers. Keep a completed
    /// onboarding profile pointed at enabled categories so a stale selection
    /// can never turn the Today feed into an empty screen after an update.
    private func normalizeLearnerSelections(
        _ profiles: [LearnerProfile],
        against definitions: [ContentCategoryDefinition],
        at date: Date
    ) -> Bool {
        let enabledDefinitions = definitions
            .filter(\.isEnabled)
            .sorted { $0.sortOrder < $1.sortOrder }
        let enabledIDs = Set(enabledDefinitions.map(\.id))
        guard let fallbackID = enabledDefinitions.first?.id else {
            return false
        }

        var didChange = false
        for profile in profiles where profile.completedOnboarding {
            var seen: Set<UUID> = []
            let validIDs = profile.selectedCategoryIDs.filter { id in
                enabledIDs.contains(id) && seen.insert(id).inserted
            }
            let normalizedIDs = validIDs.isEmpty ? [fallbackID] : validIDs

            guard normalizedIDs != profile.selectedCategoryIDs else {
                continue
            }
            profile.selectedCategoryIDs = normalizedIDs
            profile.updatedAt = date
            didChange = true
        }
        return didChange
    }

    private func reconcileCategories(
        _ definitions: [ContentCategoryDefinition],
        existing: [ContentCategory],
        in context: ModelContext
    ) {
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let desiredIDs = Set(definitions.map(\.id))

        for definition in definitions {
            if let model = existingByID[definition.id] {
                model.apply(definition)
            } else {
                context.insert(ContentCategory(definition: definition))
            }
        }
        for model in existing where !desiredIDs.contains(model.id) {
            context.delete(model)
        }
    }

    private func reconcileTopics(
        _ definitions: [ContentTopicDefinition],
        existing: [ContentTopic],
        in context: ModelContext
    ) {
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let desiredIDs = Set(definitions.map(\.id))

        for definition in definitions {
            if let model = existingByID[definition.id] {
                model.apply(definition)
            } else {
                context.insert(ContentTopic(definition: definition))
            }
        }
        for model in existing where !desiredIDs.contains(model.id) {
            context.delete(model)
        }
    }

    private func reconcileContentUnits(
        _ definitions: [ContentUnitDefinition],
        existing: [ContentUnit],
        in context: ModelContext
    ) {
        let existingByID = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
        let desiredIDs = Set(definitions.map(\.id))

        for definition in definitions {
            if let model = existingByID[definition.id] {
                model.applyMetadata(definition)
                reconcileBlocks(definition.blocks, for: model, in: context)
                reconcileInteractions(definition.interactions, for: model, in: context)
            } else {
                context.insert(ContentUnit(definition: definition))
            }
        }
        for model in existing where !desiredIDs.contains(model.id) {
            context.delete(model)
        }
    }

    private func reconcileBlocks(
        _ specifications: [ContentBlockSpec],
        for unit: ContentUnit,
        in context: ModelContext
    ) {
        let existingByID = Dictionary(uniqueKeysWithValues: unit.blocks.map { ($0.id, $0) })
        let desiredIDs = Set(specifications.map(\.id))

        for specification in specifications {
            if let block = existingByID[specification.id] {
                block.apply(specification)
            } else {
                let block = ContentBlock(specification: specification)
                block.contentUnit = unit
                unit.blocks.append(block)
            }
        }
        for block in unit.blocks where !desiredIDs.contains(block.id) {
            context.delete(block)
        }
    }

    private func reconcileInteractions(
        _ specifications: [InteractionSpec],
        for unit: ContentUnit,
        in context: ModelContext
    ) {
        let existingByID = Dictionary(uniqueKeysWithValues: unit.interactions.map { ($0.id, $0) })
        let desiredIDs = Set(specifications.map(\.id))

        for specification in specifications {
            if let interaction = existingByID[specification.id] {
                interaction.apply(specification)
            } else {
                let interaction = InteractionDefinition(specification: specification)
                interaction.contentUnit = unit
                unit.interactions.append(interaction)
            }
        }
        for interaction in unit.interactions where !desiredIDs.contains(interaction.id) {
            context.delete(interaction)
        }
    }

    private func hasExpectedIdentifiers(
        definition: ContentCatalogDefinition,
        categories: [ContentCategory],
        topics: [ContentTopic],
        units: [ContentUnit],
        blocks: [ContentBlock],
        interactions: [InteractionDefinition]
    ) -> Bool {
        Set(categories.map(\.id)) == Set(definition.categories.map(\.id))
            && Set(topics.map(\.id)) == Set(definition.topics.map(\.id))
            && Set(units.map(\.id)) == Set(definition.contentUnits.map(\.id))
            && Set(blocks.map(\.id)) == Set(definition.contentUnits.flatMap(\.blocks).map(\.id))
            && Set(interactions.map(\.id)) == Set(definition.contentUnits.flatMap(\.interactions).map(\.id))
    }

    private func report(
        for definition: ContentCatalogDefinition,
        outcome: ContentCatalogInstallOutcome
    ) -> ContentCatalogInstallationReport {
        ContentCatalogInstallationReport(
            outcome: outcome,
            schemaVersion: definition.schemaVersion,
            catalogVersion: definition.catalogVersion,
            categoryCount: definition.categories.count,
            topicCount: definition.topics.count,
            contentUnitCount: definition.contentUnits.count
        )
    }
}

@MainActor
struct ContentCatalogBootstrapper {
    private let decoder: ContentCatalogDecoder
    private let installer: ContentCatalogInstaller

    init(
        decoder: ContentCatalogDecoder = ContentCatalogDecoder(),
        installer: ContentCatalogInstaller = ContentCatalogInstaller()
    ) {
        self.decoder = decoder
        self.installer = installer
    }

    func install(
        from source: any ContentCatalogSource,
        in context: ModelContext,
        installedAt: Date = .now
    ) throws -> ContentCatalogInstallationReport {
        let data = try source.loadData()
        let catalog = try decoder.decode(data)
        return try installer.install(
            catalog,
            sourceIdentifier: source.identifier,
            in: context,
            installedAt: installedAt
        )
    }
}
