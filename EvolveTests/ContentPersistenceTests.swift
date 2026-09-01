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
        #expect(units.count == 6)
        #expect(blocks.count == 14)
        #expect(interactions.count == 10)

        let programming = units.first { $0.slug == "predict-reduce-result" }
        #expect(programming?.kind == .problem)
        #expect(programming?.growthRole == .test)
        #expect(programming?.orderedBlocks.first?.kind == .code)
        #expect(programming?.orderedInteractions.first?.kind == .solve)
        #expect(programming?.orderedInteractions.first?.isPrimary == true)

        let philosophy = units.first { $0.slug == "control-boundary" }
        #expect(philosophy?.growthRole == .reflect)
    }

    @Test("Growth roles are derived from primary interaction semantics")
    func derivesGrowthUnitRoles() {
        #expect(InteractionKind.learn.growthUnitRole == .learn)
        #expect(InteractionKind.quiz.growthUnitRole == .test)
        #expect(InteractionKind.apply.growthUnitRole == .do)
        #expect(InteractionKind.reflect.growthUnitRole == .reflect)
        #expect(MVPContentFixtures.programmingUnit.growthRole == .test)
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

    @Test("A completed interaction persists an attempt and schedules the idea")
    func persistsLearningAttempt() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let completedAt = Date(timeIntervalSince1970: 1_710_000_000)
        let contentUnitID = MVPContentFixtures.programmingUnit.id
        let record = KnowledgeRecord(
            contentUnitID: contentUnitID,
            createdAt: completedAt
        )
        let attempt = LearningAttempt(
            contentUnitID: contentUnitID,
            interactionID: MVPContentFixtures.programmingUnit.interactions.first?.id,
            response: "12",
            isCorrect: true,
            completedAt: completedAt,
            estimatedMinutes: 6
        )

        try record.recordEngagement(isCorrect: true, at: completedAt)
        context.insert(record)
        context.insert(attempt)
        try context.save()

        let attempts = try context.fetch(FetchDescriptor<LearningAttempt>())
        let persistedAttempt = try #require(attempts.first)

        #expect(record.status == .scheduled)
        #expect(persistedAttempt.response == "12")
        #expect(persistedAttempt.isCorrect == true)
        #expect(persistedAttempt.estimatedMinutes == 6)
    }

    @Test("An attempt keeps the evidence needed for local adaptation")
    func persistsExpandedAttemptEvidence() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let startedAt = Date(timeIntervalSince1970: 1_720_000_000)
        let completedAt = startedAt.addingTimeInterval(92)
        let attempt = LearningAttempt(
            contentUnitID: MVPContentFixtures.programmingUnit.id,
            interactionID: MVPContentFixtures.programmingUnit.interactions.first?.id,
            interactionKind: .solve,
            response: "12",
            isCorrect: true,
            confidence: .high,
            startedAt: startedAt,
            completedAt: completedAt,
            durationSeconds: 92,
            usedHint: true,
            difficulty: .intermediate,
            estimatedMinutes: 6
        )

        context.insert(attempt)
        try context.save()

        let persisted = try #require(context.fetch(FetchDescriptor<LearningAttempt>()).first)
        #expect(persisted.interactionKind == .solve)
        #expect(persisted.confidence == .high)
        #expect(persisted.startedAt == startedAt)
        #expect(persisted.durationSeconds == 92)
        #expect(persisted.usedHint)
        #expect(persisted.difficulty == .intermediate)
    }

    @Test("A learner profile and review schedule survive a local store round trip")
    func persistsProfileAndReviewSchedule() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let categoryID = MVPContentFixtures.catalog.categories[0].id
        let now = Date(timeIntervalSince1970: 1_730_000_000)
        let profile = LearnerProfile(
            selectedCategoryIDs: [categoryID],
            learningGoal: .rememberWhatMatters,
            learnerLevel: .starting,
            createdAt: now
        )
        let decision = ReviewScheduler.decision(
            interactionKind: .learn,
            isCorrect: nil,
            confidence: .medium,
            previousRepetitionCount: 0,
            previousLapseCount: 0,
            now: now
        )
        let schedule = ReviewSchedule(
            contentUnitID: MVPContentFixtures.philosophyUnit.id,
            decision: decision,
            updatedAt: now
        )

        context.insert(profile)
        context.insert(schedule)
        try context.save()

        let storedProfile = try #require(context.fetch(FetchDescriptor<LearnerProfile>()).first)
        let storedSchedule = try #require(context.fetch(FetchDescriptor<ReviewSchedule>()).first)
        #expect(storedProfile.learningGoal == .rememberWhatMatters)
        #expect(storedProfile.learnerLevel == .starting)
        #expect(storedProfile.selectedCategoryIDs == [categoryID])
        #expect(storedSchedule.intervalDays == 1)
        #expect(storedSchedule.reason == .firstPractice)
    }

    @Test("A thought persists its origin, kind, and latest body")
    func persistsThoughtRecord() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_740_000_000)
        let updatedAt = createdAt.addingTimeInterval(90)
        let unitID = MVPContentFixtures.philosophyUnit.id
        let thought = ThoughtRecord(
            contentUnitID: unitID,
            body: "I can choose the next response.",
            kind: .insight,
            createdAt: createdAt
        )
        thought.update(
            body: "I can choose one calm response.",
            at: updatedAt
        )

        context.insert(thought)
        try context.save()

        let stored = try #require(context.fetch(FetchDescriptor<ThoughtRecord>()).first)
        #expect(stored.contentUnitID == unitID)
        #expect(stored.kind == .insight)
        #expect(stored.body == "I can choose one calm response.")
        #expect(stored.createdAt == createdAt)
        #expect(stored.updatedAt == updatedAt)
    }

    @Test("An application action exposes an explicit lifecycle")
    func persistsApplicationActionLifecycle() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let createdAt = Date(timeIntervalSince1970: 1_750_000_000)
        let updatedAt = createdAt.addingTimeInterval(10)
        let completedAt = createdAt.addingTimeInterval(20)
        let skippedAt = createdAt.addingTimeInterval(30)
        let action = ApplicationAction(
            contentUnitID: MVPContentFixtures.productivityUnit.id,
            note: "Start for two minutes.",
            createdAt: createdAt
        )

        #expect(action.status == .planned)
        action.update(note: "Start the outline for two minutes.", at: updatedAt)
        #expect(action.updatedAt == updatedAt)

        action.complete(at: completedAt)
        #expect(action.status == .completed)
        #expect(action.completedAt == completedAt)
        #expect(action.skippedAt == nil)

        action.skip(at: skippedAt)
        #expect(action.status == .skipped)
        #expect(action.completedAt == nil)
        #expect(action.skippedAt == skippedAt)

        context.insert(action)
        try context.save()

        let stored = try #require(context.fetch(FetchDescriptor<ApplicationAction>()).first)
        #expect(stored.note == "Start the outline for two minutes.")
        #expect(stored.status == .skipped)
        #expect(stored.skippedAt == skippedAt)

        let legacyCompletedAction = ApplicationAction(
            contentUnitID: MVPContentFixtures.philosophyUnit.id,
            note: "Already completed.",
            createdAt: createdAt,
            completedAt: completedAt
        )
        #expect(legacyCompletedAction.status == .completed)
        #expect(legacyCompletedAction.updatedAt == completedAt)

        legacyCompletedAction.statusRawValue = nil
        legacyCompletedAction.updatedAt = nil
        #expect(legacyCompletedAction.status == .completed)
    }

    @Test("Feed and growth-loop event kinds persist without private payloads")
    func persistsGrowthLoopEvents() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let kinds: [LocalEventKind] = [
            .feedImpression,
            .feedSkipped,
            .feedUseful,
            .feedCompleted,
            .thoughtCreated,
            .actionCompleted,
            .growthLoopCompleted
        ]

        for kind in kinds {
            context.insert(LocalProductEvent(kind: kind))
        }
        try context.save()

        let storedRawValues = try context.fetch(FetchDescriptor<LocalProductEvent>())
            .compactMap(\.kind)
            .map(\.rawValue)
            .sorted()
        #expect(storedRawValues == kinds.map(\.rawValue).sorted())
    }

    @Test("Evidence progress, application actions, and product events persist together")
    func persistsProductFeedbackModels() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let categoryID = MVPContentFixtures.catalog.categories[0].id
        let unitID = MVPContentFixtures.philosophyUnit.id
        let summary = EvidenceSummary(
            score: 0.62,
            evidenceCount: 3,
            strongEvidenceCount: 2,
            strongestKind: .recall
        )
        let progress = DomainProgressRecord(categoryID: categoryID, summary: summary)
        let action = ApplicationAction(contentUnitID: unitID, note: "Use this before tomorrow's meeting.")
        let event = LocalProductEvent(kind: .applicationCreated, contentUnitID: unitID)

        context.insert(progress)
        context.insert(action)
        context.insert(event)
        try context.save()

        let storedProgress = try #require(context.fetch(FetchDescriptor<DomainProgressRecord>()).first)
        let storedAction = try #require(context.fetch(FetchDescriptor<ApplicationAction>()).first)
        let storedEvent = try #require(context.fetch(FetchDescriptor<LocalProductEvent>()).first)
        #expect(storedProgress.score == 0.62)
        #expect(storedProgress.strongEvidenceCount == 2)
        #expect(storedProgress.strongestKind == .recall)
        #expect(storedAction.note.contains("meeting"))
        #expect(storedEvent.kind == .applicationCreated)
    }
}
