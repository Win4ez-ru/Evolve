import Foundation
import Testing
@testable import Evolve

@Suite("Bounded learning session")
struct LearningSessionTests {
    @Test("A plan never becomes an infinite feed")
    func planClampsItemsToThree() {
        let items = (0..<6).map(makeItem)

        let plan = LearningSessionPlan(items: items)

        #expect(plan.items.count == LearningSessionPlan.maximumItemCount)
        #expect(plan.items.map(\.title) == ["Card 0", "Card 1", "Card 2"])
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

    @Test("An empty plan is safely complete")
    func emptyPlanIsComplete() {
        let state = LearningSessionState(plan: LearningSessionPlan(items: []))

        #expect(state.phase == .completed)
        #expect(state.progress == 1)
        #expect(state.currentItemID == nil)
    }

    private func makeItem(_ index: Int) -> LearningSessionItem {
        LearningSessionItem(
            id: UUID(uuidString: String(format: "30000000-0000-4000-8000-%012d", index + 1))!,
            title: "Card \(index)",
            summary: "Summary \(index)",
            categoryName: "Category",
            kindName: "Idea",
            estimatedMinutes: index + 1
        )
    }
}
