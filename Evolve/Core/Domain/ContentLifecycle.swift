import Foundation

enum ContentLifecycleError: Error, Equatable, Sendable {
    case invalidEditorialTransition(from: EditorialStatus, to: EditorialStatus)
    case invalidKnowledgeTransition(from: KnowledgeStatus, to: KnowledgeStatus)
}

enum EditorialTransitionPolicy {
    static func canTransition(from current: EditorialStatus, to next: EditorialStatus) -> Bool {
        switch current {
        case .draft:
            next == .review
        case .review:
            next == .draft || next == .approved
        case .approved:
            next == .review || next == .published
        case .published:
            next == .deprecated
        case .deprecated:
            false
        }
    }

    static func requireTransition(from current: EditorialStatus, to next: EditorialStatus) throws {
        guard canTransition(from: current, to: next) else {
            throw ContentLifecycleError.invalidEditorialTransition(from: current, to: next)
        }
    }
}

enum KnowledgeTransitionPolicy {
    static func canTransition(from current: KnowledgeStatus, to next: KnowledgeStatus) -> Bool {
        switch current {
        case .eligible:
            next == .surfaced
        case .surfaced:
            next == .viewed
        case .viewed:
            next == .engaged || next == .scheduled
        case .engaged:
            next == .scheduled
        case .scheduled:
            next == .reviewDue
        case .reviewDue:
            next == .recalled || next == .remediation
        case .recalled:
            next == .scheduled || next == .mastered
        case .remediation:
            next == .engaged || next == .scheduled
        case .mastered:
            next == .reviewDue
        }
    }

    static func requireTransition(from current: KnowledgeStatus, to next: KnowledgeStatus) throws {
        guard canTransition(from: current, to: next) else {
            throw ContentLifecycleError.invalidKnowledgeTransition(from: current, to: next)
        }
    }
}
