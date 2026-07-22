import Testing
@testable import Evolve

@Suite("Content lifecycle")
struct ContentLifecycleTests {
    @Test("Editorial content follows the review and publication gate")
    func validatesEditorialTransitions() throws {
        try EditorialTransitionPolicy.requireTransition(from: .draft, to: .review)
        try EditorialTransitionPolicy.requireTransition(from: .review, to: .approved)
        try EditorialTransitionPolicy.requireTransition(from: .approved, to: .published)
        try EditorialTransitionPolicy.requireTransition(from: .published, to: .deprecated)

        #expect(!EditorialTransitionPolicy.canTransition(from: .draft, to: .published))
        #expect(!EditorialTransitionPolicy.canTransition(from: .deprecated, to: .published))
    }

    @Test("Mastery requires delayed recall evidence")
    func validatesKnowledgeTransitions() throws {
        let path: [(KnowledgeStatus, KnowledgeStatus)] = [
            (.eligible, .surfaced),
            (.surfaced, .viewed),
            (.viewed, .engaged),
            (.engaged, .scheduled),
            (.scheduled, .reviewDue),
            (.reviewDue, .recalled),
            (.recalled, .mastered),
            (.mastered, .reviewDue)
        ]

        for transition in path {
            try KnowledgeTransitionPolicy.requireTransition(
                from: transition.0,
                to: transition.1
            )
        }

        #expect(!KnowledgeTransitionPolicy.canTransition(from: .viewed, to: .mastered))
        #expect(!KnowledgeTransitionPolicy.canTransition(from: .eligible, to: .recalled))
    }
}
