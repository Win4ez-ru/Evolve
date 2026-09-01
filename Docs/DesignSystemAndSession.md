# Stage 5 — Design System and Session Shell

## Product intent

The Stage 5 experience is calm, finite, and explicit. Today names the complete session before it begins. The session always exposes the current card, the total card count, a stop action, and a clear terminal state. There is no feed and no hidden continuation.

## Design foundations

The SwiftUI design system is organized around semantic roles rather than screen-specific values:

- `AppColor` defines background, surface, text, separator, accent, success, and danger roles, with a primitive palette kept underneath them.
- `AppTypography` uses Dynamic Type-aware text styles for screen titles, sections, cards, body copy, supporting text, captions, and actions.
- `AppSpacing` and `AppRadius` provide the shared geometry scale.
- `AppElevation` supplies the single restrained card shadow.
- `AppMotion` centralizes brief, calm transitions and removes them when Reduce Motion is enabled.
- `FoundationCard` and `PrimaryActionButtonStyle` are the reusable surface and primary action primitives.

Colors are semantic and automatically adapt to light and dark appearances. Text is never encoded as an image, and SF Symbols supply interface icons.

## Session contract

`LearningSessionPlan` is a value snapshot containing no more than three
`LearningSessionItem` values. Each item includes its identity, presentation
metadata, ordered content blocks, source provenance, and executable interactions.

`LearningSessionState` is the source of truth for:

- active, stopped, or completed phase;
- current item identity and position;
- completed item identities;
- normalized progress;
- advance, direct selection, and stop transitions.

The state type contains no SwiftUI dependencies, so its finite behavior is verified with unit tests.

## Navigation and accessibility

Every step presents one primary card with a free, content-driven vertical scroll.
The explicit action advances to the next card. The header and card metadata reflow
at accessibility sizes so long content, prompts, inputs, and feedback remain
reachable without truncation.

Every session exposes:

- an accessible stop button with a confirmation step;
- a textual `Card n of total` value alongside visual progress;
- descriptive card labels;
- action hints for advancing and completion;
- Reduce Motion-aware transitions.

## Stage 6 continuation

The shell delegates its content area to the universal renderer pipeline while
retaining ownership of scrolling, progress, stop, interaction completion, and the
terminal state. Renderer details and metadata policy are documented in
`ContentRendering.md`.

## Code-first visual source

The SwiftUI design system and feature views are authoritative. Xcode Previews and
simulator walkthroughs verify the actual product across appearance, Dynamic Type,
and Reduce Motion. A Figma quota or unfinished Figma component never blocks a code
change, TestFlight build, or App Store release.

## Optional Figma reference

The companion file is [Evolve — Stage 5 Learning Session](https://www.figma.com/design/2No881agwAOyT3Hx7UR6Pv). It currently contains:

- five variable collections with 51 code-linked tokens;
- seven SF Pro / SF Pro Rounded text styles that mirror `AppTypography`;
- the `Elevation/Card` effect style from `AppElevation`;
- a Starter-compatible three-page structure: Documentation, Components, and Product;
- completed Cover, Getting Started, Colors, and Typography documentation sections.

The file remains on Figma Starter and is intentionally paused as a reference. If a
future product decision benefits from Figma, work is limited to onboarding, Today,
the active session, session completion, and App Store compositions. There is no
requirement to finish the remaining foundations or mirror every SwiftUI component.
Exact existing node and style IDs remain stored in `FigmaStage5State.json`.
