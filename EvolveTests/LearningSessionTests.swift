import Foundation
import Testing
@testable import Evolve

@Suite("Finite growth session")
struct LearningSessionTests {
    @Test("A plan keeps the vertical feed finite")
    func planClampsItemsToMaximum() {
        let items = (0..<20).map(makeItem)

        let plan = LearningSessionPlan(items: items)

        #expect(plan.items.count == LearningSessionPlan.maximumItemCount)
        #expect(plan.items.first?.title == "Card 0")
        #expect(plan.items.last?.title == "Card 14")
    }

    @Test("A learner can choose a shorter finite session")
    func planRespectsPreferredLength() {
        let items = (0..<6).map(makeItem)

        let plan = LearningSessionPlan(items: items, limit: 2)

        #expect(plan.items.count == 2)
        #expect(plan.items.map(\.title) == ["Card 0", "Card 1"])
    }

    @Test("A time-boxed plan stops after reaching its intended duration")
    func planRespectsTargetMinutes() {
        let items = (0..<8).map { index in
            LearningSessionItem(
                id: UUID(),
                title: "Minute \(index)",
                summary: "Summary",
                categoryName: "Focus",
                kind: .concept,
                difficulty: .introductory,
                estimatedMinutes: 1,
                blocks: [
                    ContentBlockSpec(kind: .paragraph, order: 0, content: "Body")
                ],
                source: ContentSource(title: "Test", creator: "Evolve Tests")
            )
        }

        let plan = LearningSessionPlan(items: items, targetMinutes: 5)

        #expect(plan.items.count == 5)
        #expect(plan.totalMinutes == 5)
    }

    @Test("Due recall remains ahead of new discovery")
    func dueReviewKeepsPriority() {
        let due = LearningSessionItem(
            id: UUID(),
            title: "Due recall",
            summary: "Return now",
            categoryName: "Focus",
            kind: .recallPrompt,
            difficulty: .foundational,
            estimatedMinutes: 1,
            blocks: [],
            source: ContentSource(title: "Test", creator: "Evolve Tests"),
            isReview: true
        )
        let plan = LearningSessionPlan(
            items: [makeItem(0), makeItem(1), due],
            targetMinutes: 2
        )

        #expect(plan.items.first?.id == due.id)
    }

    @Test("Advancing reaches a clear completion state")
    func advancingCompletesFinitePlan() {
        let plan = LearningSessionPlan(items: (0..<3).map(makeItem))
        var state = LearningSessionState(plan: plan)

        #expect(state.phase == .active)
        #expect(state.position == 1)
        #expect(state.advance() == plan.items[1].id)
        #expect(state.position == 2)
        #expect(state.advance() == plan.items[2].id)
        #expect(state.position == 3)
        #expect(state.advance() == nil)
        #expect(state.phase == .completed)
        #expect(state.completedItemIDs.count == 3)
        #expect(state.progress == 1)
    }

    @Test("Stopping preserves the current position")
    func stoppingPreservesPosition() {
        let plan = LearningSessionPlan(items: (0..<3).map(makeItem))
        var state = LearningSessionState(plan: plan)

        state.select(itemID: plan.items[1].id)
        state.stop()

        #expect(state.phase == .stopped)
        #expect(state.position == 2)
        #expect(state.advance() == nil)
    }

    @Test("Feed items can be completed independently before the session ends")
    func feedCompletionIsIndependentFromPosition() {
        let plan = LearningSessionPlan(items: (0..<3).map(makeItem))
        var state = LearningSessionState(plan: plan)

        state.select(itemID: plan.items[1].id)
        state.markCompleted(itemID: plan.items[1].id)

        #expect(state.currentItemID == plan.items[1].id)
        #expect(state.completedItemIDs == [plan.items[1].id])

        state.finish()
        #expect(state.phase == .completed)
    }

    @Test("Only practiced cards earn mindful minutes")
    func earnedMinutesRequirePractice() {
        let plan = LearningSessionPlan(items: (0..<3).map(makeItem))
        var state = LearningSessionState(plan: plan)

        #expect(state.earnedMinutes == 0)

        state.markCompleted(itemID: plan.items[1].id)

        #expect(state.earnedMinutes == plan.items[1].estimatedMinutes)
    }

    @Test("An empty plan is safely complete")
    func emptyPlanIsComplete() {
        let state = LearningSessionState(plan: LearningSessionPlan(items: []))

        #expect(state.phase == .completed)
        #expect(state.progress == 1)
        #expect(state.currentItemID == nil)
    }

    @Test("A review card prefers recall over its editorial primary interaction")
    func reviewPrefersRecall() throws {
        let primaryID = UUID()
        let recallID = UUID()
        let item = LearningSessionItem(
            id: UUID(),
            title: "Recall first",
            summary: "A review snapshot",
            categoryName: "Learning",
            kind: .concept,
            difficulty: .foundational,
            estimatedMinutes: 4,
            blocks: [],
            interactions: [
                InteractionSpec(
                    id: primaryID,
                    kind: .learn,
                    responseKind: .none,
                    evaluationKind: .completion,
                    order: 0,
                    prompt: "Read",
                    estimatedMinutes: 1,
                    isPrimary: true
                ),
                InteractionSpec(
                    id: recallID,
                    kind: .recall,
                    responseKind: .text,
                    evaluationKind: .selfAssessment,
                    order: 1,
                    prompt: "Reconstruct",
                    estimatedMinutes: 2
                )
            ],
            source: ContentSource(title: "Test", creator: "Evolve Tests"),
            isReview: true
        )

        #expect(try #require(item.preferredInteraction).id == recallID)
    }

    private func makeItem(_ index: Int) -> LearningSessionItem {
        LearningSessionItem(
            id: UUID(uuidString: String(format: "30000000-0000-4000-8000-%012d", index + 1))!,
            title: "Card \(index)",
            summary: "Summary \(index)",
            categoryName: "Category",
            kind: .concept,
            difficulty: .introductory,
            estimatedMinutes: index + 1,
            blocks: [
                ContentBlockSpec(
                    kind: .paragraph,
                    order: 0,
                    content: "Body \(index)"
                )
            ],
            source: ContentSource(
                title: "Test source",
                creator: "Evolve Tests"
            )
        )
    }
}

@Suite("Persisted learning totals")
@MainActor
struct LearningProgressTotalsTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("Completion events are the source of truth for count and minutes")
    func completionEventsRestoreCountAndMinutes() {
        let events = [
            completion(year: 2026, month: 8, day: 1, hour: 9, minutes: 5),
            completion(year: 2026, month: 8, day: 1, hour: 18, minutes: 7),
            LocalProductEvent(kind: .sessionStarted, numericValue: 99)
        ]

        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 1, hour: 20),
            calendar: calendar
        )

        #expect(totals.completedSessions == 2)
        #expect(totals.totalLearningMinutes == 12)
        #expect(totals.currentStreak == 1)
        #expect(
            totals.lastPracticeTimestamp
                == date(year: 2026, month: 8, day: 1).timeIntervalSince1970
        )
    }

    @Test("Practice on the next calendar day extends the streak")
    func nextDayExtendsStreak() {
        let events = [
            completion(year: 2026, month: 8, day: 1, minutes: 3),
            completion(year: 2026, month: 8, day: 2, minutes: 4),
            completion(year: 2026, month: 8, day: 3, minutes: 5)
        ]

        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 3, hour: 20),
            calendar: calendar
        )

        #expect(totals.currentStreak == 3)
    }

    @Test("A calendar gap resets the rebuilt streak")
    func calendarGapResetsStreak() {
        let events = [
            completion(year: 2026, month: 8, day: 1, minutes: 3),
            completion(year: 2026, month: 8, day: 2, minutes: 4),
            completion(year: 2026, month: 8, day: 5, minutes: 5),
            completion(year: 2026, month: 8, day: 6, minutes: 6)
        ]

        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 6, hour: 20),
            calendar: calendar
        )

        #expect(totals.currentStreak == 2)
        #expect(totals.completedSessions == 4)
        #expect(totals.totalLearningMinutes == 18)
    }

    @Test("Reconciliation is idempotent")
    func reconciliationIsIdempotent() {
        let events = [
            completion(year: 2026, month: 8, day: 10, minutes: 8),
            completion(year: 2026, month: 8, day: 11, minutes: 9)
        ]

        let first = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 11, hour: 20),
            calendar: calendar
        )
        let repeated = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 11, hour: 20),
            calendar: calendar
        )

        #expect(repeated == first)
        #expect(repeated.completedSessions == 2)
        #expect(repeated.totalLearningMinutes == 17)
        #expect(repeated.currentStreak == 2)
    }

    @Test("Yesterday keeps a consecutive streak active")
    func yesterdayKeepsStreakActive() {
        let events = [
            completion(year: 2026, month: 8, day: 8, minutes: 3),
            completion(year: 2026, month: 8, day: 9, minutes: 4)
        ]

        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 10, hour: 8),
            calendar: calendar
        )

        #expect(totals.currentStreak == 2)
    }

    @Test("A stale streak expires and future timestamps cannot dominate it")
    func staleAndFuturePracticeDoNotCreateCurrentStreak() {
        let events = [
            completion(year: 2026, month: 8, day: 1, minutes: 3),
            completion(year: 2026, month: 8, day: 2, minutes: 4),
            completion(year: 2026, month: 8, day: 20, minutes: 5)
        ]

        let totals = LearningProgressTotalsCalculator.calculate(
            from: events,
            now: date(year: 2026, month: 8, day: 10, hour: 8),
            calendar: calendar
        )

        #expect(totals.completedSessions == 3)
        #expect(totals.totalLearningMinutes == 12)
        #expect(totals.currentStreak == 0)
        #expect(
            totals.lastPracticeTimestamp
                == date(year: 2026, month: 8, day: 2).timeIntervalSince1970
        )
    }

    @Test("A completion event stores recoverable session minutes")
    func completionEventStoresMinutes() {
        let completedAt = date(year: 2026, month: 8, day: 11, hour: 12)

        let event = LocalProductEvent.sessionCompletion(
            occurredAt: completedAt,
            learningMinutes: 11
        )

        #expect(event.kind == .sessionCompleted)
        #expect(event.occurredAt == completedAt)
        #expect(event.numericValue == 11)
    }

    private func completion(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minutes: Int
    ) -> LocalProductEvent {
        .sessionCompletion(
            occurredAt: date(year: year, month: month, day: day, hour: hour),
            learningMinutes: minutes
        )
    }

    private func date(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
}

@Suite("Review scheduling")
struct ReviewSchedulerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("First practice creates a one-day recall")
    func firstPracticeSchedulesTomorrow() {
        let decision = ReviewScheduler.decision(
            interactionKind: .learn,
            isCorrect: nil,
            confidence: .medium,
            previousRepetitionCount: 0,
            previousLapseCount: 0,
            now: now,
            calendar: calendar
        )

        #expect(decision.intervalDays == 1)
        #expect(decision.repetitionCount == 0)
        #expect(decision.reason == .firstPractice)
        #expect(decision.treatsAttemptAsSuccess)
        #expect(decision.nextReviewAt == calendar.date(byAdding: .day, value: 1, to: now))
    }

    @Test("Successful recall expands the interval")
    func successfulRecallExpandsInterval() {
        let decision = ReviewScheduler.decision(
            interactionKind: .recall,
            isCorrect: true,
            confidence: .medium,
            previousRepetitionCount: 2,
            previousLapseCount: 1,
            now: now,
            calendar: calendar
        )

        #expect(decision.intervalDays == 7)
        #expect(decision.repetitionCount == 3)
        #expect(decision.lapseCount == 1)
        #expect(decision.reason == .successfulRecall)
    }

    @Test("High-confidence recall earns a small interval bonus")
    func highConfidenceAddsBonus() {
        let medium = ReviewScheduler.decision(
            interactionKind: .recall,
            isCorrect: true,
            confidence: .medium,
            previousRepetitionCount: 3,
            previousLapseCount: 0,
            now: now,
            calendar: calendar
        )
        let high = ReviewScheduler.decision(
            interactionKind: .recall,
            isCorrect: true,
            confidence: .high,
            previousRepetitionCount: 3,
            previousLapseCount: 0,
            now: now,
            calendar: calendar
        )

        #expect(medium.intervalDays == 14)
        #expect(high.intervalDays > medium.intervalDays)
    }

    @Test("Failed recall creates remediation and records a lapse")
    func failedRecallCreatesRemediation() {
        let decision = ReviewScheduler.decision(
            interactionKind: .recall,
            isCorrect: false,
            confidence: .low,
            previousRepetitionCount: 3,
            previousLapseCount: 1,
            now: now,
            calendar: calendar
        )

        #expect(decision.intervalDays == 1)
        #expect(decision.repetitionCount == 2)
        #expect(decision.lapseCount == 2)
        #expect(decision.reason == .remediation)
        #expect(!decision.treatsAttemptAsSuccess)
    }
}

@Suite("Evidence scoring")
struct EvidenceScorerTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("Recall counts more strongly than passive learning")
    func recallOutweighsLearning() {
        let learn = EvidenceScorer.summary(
            for: [sample(kind: .learn, isCorrect: nil, confidence: .high)],
            now: now
        )
        let recall = EvidenceScorer.summary(
            for: [sample(kind: .recall, isCorrect: true, confidence: .high)],
            now: now
        )

        #expect(recall.score > learn.score)
        #expect(recall.strongEvidenceCount == 1)
        #expect(recall.strongestKind == .recall)
    }

    @Test("Incorrect low-confidence evidence remains visible but weak")
    func incorrectEvidenceIsWeak() {
        let summary = EvidenceScorer.summary(
            for: [sample(kind: .solve, isCorrect: false, confidence: .low)],
            now: now
        )

        #expect(summary.evidenceCount == 1)
        #expect(summary.strongEvidenceCount == 0)
        #expect(summary.score > 0)
        #expect(summary.score < 0.1)
    }

    @Test("An empty evidence set produces a stable zero summary")
    func emptyEvidenceIsZero() {
        let summary = EvidenceScorer.summary(for: [], now: now)

        #expect(summary.score == 0)
        #expect(summary.evidenceCount == 0)
        #expect(summary.strongestKind == nil)
    }

    private func sample(
        kind: InteractionKind,
        isCorrect: Bool?,
        confidence: AttemptConfidence
    ) -> LearningEvidence {
        LearningEvidence(
            kind: kind,
            isCorrect: isCorrect,
            confidence: confidence,
            difficulty: .intermediate,
            occurredAt: now
        )
    }
}
