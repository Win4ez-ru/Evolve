import Foundation
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

    @Test("User learning data survives closing and reopening the disk store")
    func userStateSurvivesContainerRecreation() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EvolvePersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }

        let storeURL = directory.appendingPathComponent("Evolve.store")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let categoryID = MVPContentFixtures.catalog.categories[0].id
        let contentUnitID = MVPContentFixtures.philosophyUnit.id
        let attemptID = UUID()

        try seedUserState(
            storeURL: storeURL,
            categoryID: categoryID,
            contentUnitID: contentUnitID,
            attemptID: attemptID,
            now: now
        )

        let reopenedContainer = try PersistenceController.makeContainer(storeURL: storeURL)
        let reopenedContext = ModelContext(reopenedContainer)

        let profile = try #require(reopenedContext.fetch(FetchDescriptor<LearnerProfile>()).first)
        let attempt = try #require(reopenedContext.fetch(FetchDescriptor<LearningAttempt>()).first)
        let knowledge = try #require(reopenedContext.fetch(FetchDescriptor<KnowledgeRecord>()).first)
        let schedule = try #require(reopenedContext.fetch(FetchDescriptor<ReviewSchedule>()).first)
        let progress = try #require(reopenedContext.fetch(FetchDescriptor<DomainProgressRecord>()).first)
        let thought = try #require(reopenedContext.fetch(FetchDescriptor<ThoughtRecord>()).first)
        let action = try #require(reopenedContext.fetch(FetchDescriptor<ApplicationAction>()).first)
        let events = try reopenedContext.fetch(FetchDescriptor<LocalProductEvent>())
        let event = try #require(events.first)
        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: now
        )

        #expect(profile.completedOnboarding)
        #expect(profile.selectedCategoryIDs == [categoryID])
        #expect(attempt.id == attemptID)
        #expect(attempt.response == "A reopened store keeps this answer.")
        #expect(knowledge.status == .scheduled)
        #expect(schedule.nextReviewAt > now)
        #expect(progress.evidenceCount == 1)
        #expect(thought.body == "Keep the first response deliberate.")
        #expect(thought.kind == .reflection)
        #expect(action.note == "Use the idea after relaunch.")
        #expect(action.status == .completed)
        #expect(action.completedAt == now.addingTimeInterval(120))
        #expect(event.kind == .sessionCompleted)
        #expect(totals.completedSessions == 1)
        #expect(totals.totalLearningMinutes == 9)
        #expect(totals.currentStreak == 1)
    }

    @Test("A persistent store failure enters explicit recovery mode")
    func persistentStoreFailureEntersRecoveryMode() throws {
        struct ExpectedFailure: Error {}

        let resolution = PersistenceController.resolve(
            persistentStore: { throw ExpectedFailure() },
            fallbackStore: { try PersistenceController.makeContainer(inMemory: true) }
        )

        switch resolution.availability {
        case .persistent:
            Issue.record("Expected an ephemeral fallback after the persistent store failed.")
        case .ephemeralFallback(let reason):
            #expect(!reason.isEmpty)
        }
    }

    private func seedUserState(
        storeURL: URL,
        categoryID: UUID,
        contentUnitID: UUID,
        attemptID: UUID,
        now: Date
    ) throws {
        let container = try PersistenceController.makeContainer(storeURL: storeURL)
        let context = ModelContext(container)
        let profile = LearnerProfile(
            selectedCategoryIDs: [categoryID],
            learningGoal: .rememberWhatMatters,
            learnerLevel: .starting,
            createdAt: now
        )
        let attempt = LearningAttempt(
            id: attemptID,
            contentUnitID: contentUnitID,
            interactionID: nil,
            interactionKind: .learn,
            response: "A reopened store keeps this answer.",
            isCorrect: true,
            confidence: .high,
            startedAt: now,
            completedAt: now.addingTimeInterval(60),
            durationSeconds: 60,
            difficulty: .foundational,
            estimatedMinutes: 3
        )
        let knowledge = KnowledgeRecord(contentUnitID: contentUnitID, createdAt: now)
        try knowledge.recordEngagement(isCorrect: true, at: now)
        let decision = ReviewScheduler.decision(
            interactionKind: .learn,
            isCorrect: true,
            confidence: .high,
            previousRepetitionCount: 0,
            previousLapseCount: 0,
            now: now
        )
        let schedule = ReviewSchedule(
            contentUnitID: contentUnitID,
            decision: decision,
            updatedAt: now
        )
        let progress = DomainProgressRecord(
            categoryID: categoryID,
            summary: EvidenceSummary(
                score: 0.4,
                evidenceCount: 1,
                strongEvidenceCount: 1,
                strongestKind: .learn
            ),
            updatedAt: now
        )
        let action = ApplicationAction(
            contentUnitID: contentUnitID,
            note: "Use the idea after relaunch.",
            createdAt: now
        )
        action.complete(at: now.addingTimeInterval(120))
        let thought = ThoughtRecord(
            contentUnitID: contentUnitID,
            body: "Keep the first response deliberate.",
            createdAt: now
        )
        let event = LocalProductEvent.sessionCompletion(
            occurredAt: now,
            learningMinutes: 9
        )

        context.insert(profile)
        context.insert(attempt)
        context.insert(knowledge)
        context.insert(schedule)
        context.insert(progress)
        context.insert(thought)
        context.insert(action)
        context.insert(event)
        try context.save()
    }
}
