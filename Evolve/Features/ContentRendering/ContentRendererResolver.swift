import Foundation

enum ContentUnitRendererKind: String, Equatable, Sendable {
    case concept
    case principle
    case dilemma
    case problem
    case workedExample
    case standard
}

enum ContentBlockRendererKind: String, Equatable, Sendable {
    case heading
    case paragraph
    case quote
    case code
    case formula
    case media
    case callout
}

enum ContentRendererResolver {
    static func unitRenderer(for kind: ContentKind) -> ContentUnitRendererKind {
        switch kind {
        case .concept:
            .concept
        case .principle:
            .principle
        case .dilemma:
            .dilemma
        case .problem:
            .problem
        case .workedExample:
            .workedExample
        case .insight,
             .contextualQuote,
             .question,
             .caseStudy,
             .technique,
             .experiment,
             .challenge,
             .recallPrompt,
             .explanation:
            .standard
        }
    }

    static func blockRenderer(for kind: ContentBlockKind) -> ContentBlockRendererKind {
        switch kind {
        case .heading:
            .heading
        case .paragraph:
            .paragraph
        case .quote:
            .quote
        case .code:
            .code
        case .formula:
            .formula
        case .image, .audio, .video:
            .media
        case .callout:
            .callout
        }
    }
}
