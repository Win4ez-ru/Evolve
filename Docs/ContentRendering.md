# Stage 6 — Universal Content Rendering

## Goal

Render validated `ContentUnit` and `ContentBlock` data inside the finite Stage 5 session without introducing category-specific screens. Adding a new material should normally be an editorial catalog change, not a navigation or view-controller change.

## Data flow

```text
SwiftData ContentUnit
    → immutable LearningSessionItem snapshot
    → ContentRendererResolver
    → specialized or standard unit renderer
    → exhaustive ContentBlockRenderer
```

The session snapshot now retains semantic kind, difficulty, ordered blocks, and source provenance. A catalog update cannot alter an in-progress session, while every renderer receives the complete data required for presentation.

## Unit dispatch

`ContentRendererResolver` is UI-independent and exhaustively maps every `ContentKind`:

- concept → `ConceptContentRenderer`;
- principle → `PrincipleContentRenderer`;
- dilemma → `DilemmaContentRenderer`;
- problem → `ProblemContentRenderer`;
- worked example → `WorkedExampleContentRenderer`;
- every other supported kind → `StandardContentRenderer`.

The standard renderer is a deliberate forward-compatible presentation, not an empty state. New content of an existing kind can therefore ship entirely through catalog data. A genuinely new semantic kind requires one explicit compiler-checked resolver decision.

## Block dispatch

`ContentBlockRenderer` supports every Stage 3 block:

- headings and paragraphs;
- editorial quotes;
- horizontally scrollable, selectable code with language metadata;
- formulas;
- callouts;
- accessible image, audio, and video placeholders.

Media remains deterministic and local in this stage. Remote loading, playback, and interactive controls are deferred until their product and caching contracts are defined.

## Metadata and accessibility

Every learning card visibly exposes difficulty, material kind, source title, creator, and an optional source link. License metadata remains in the immutable snapshot and is included in the source accessibility description without making the compact learning card unnecessarily tall. The source becomes a native `Link` only when the validated catalog supplies an HTTP or HTTPS URL.

All content uses Dynamic Type-aware typography and semantic colors. Long code and formulas scroll horizontally rather than shrinking. Catalog accessibility labels override literal code or formula speech when supplied. Media placeholders use SF Symbols and keep their editorial description available to assistive technologies.

## Catalog revision 2

The Stage 6 bundled catalog contains six universal materials across the same three categories. Three new data-only examples exercise concept, dilemma, and worked-example dispatch. Together with the existing principle and problem/code examples, the catalog demonstrates all six required renderer families.

Catalog revision 2 contains:

- 3 categories;
- 3 topics;
- 6 content units;
- 14 content blocks;
- 10 declarative interaction definitions.

The first finite Today session is still capped at three cards. Its alphabetical snapshot currently demonstrates concept, dilemma, and problem/code rendering without changing the Stage 5 session contract.

## Stage 7 boundary

Stage 6 does not render response controls, reveal expected answers, score work, persist attempts, or transition personal learning state. Interaction definitions remain data until the Stage 7 interaction engine consumes them.

## Verification

- Production build: passed with code signing disabled for the generic iOS destination.
- Universal renderer resolver coverage: 4 dedicated tests passed.
- Complete Swift Testing suite: 28 of 28 tests in 10 suites passed on iPhone 17 Pro, iOS 26.0.1.
- Runtime catalog revision 2: installed and then confirmed idempotent.
- Visual QA: Today, concept, dilemma, problem/code, and completion states reviewed in light and dark appearances.
- Accessibility QA: renderer layouts and the scrollable terminal state reviewed through Accessibility 5 Dynamic Type.

## Visual source

The SwiftUI renderer implementation is authoritative and continues the semantic
tokens and native component language documented during Stage 5. Figma is now an
optional reference for selected product decisions; account limits do not block
renderer implementation, visual QA, or release verification.
