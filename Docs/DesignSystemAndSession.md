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

`LearningSessionPlan` is a value snapshot containing no more than three `LearningSessionItem` values. Each item includes only the metadata needed by the Stage 5 shell: identity, title, summary, category, kind, and estimated duration.

`LearningSessionState` is the source of truth for:

- active, stopped, or completed phase;
- current item identity and position;
- completed item identities;
- normalized progress;
- advance, direct selection, and stop transitions.

The state type contains no SwiftUI dependencies, so its finite behavior is verified with unit tests.

## Navigation and accessibility

Standard text sizes use vertical paging and one primary card per viewport. Accessibility Dynamic Type sizes use content-driven, view-aligned scrolling so long text remains reachable. The header and card metadata reflow at accessibility sizes rather than truncating essential content.

Every session exposes:

- an accessible stop button with a confirmation step;
- a textual `Card n of total` value alongside visual progress;
- descriptive card labels;
- action hints for advancing and completion;
- Reduce Motion-aware transitions.

## Stage 6 boundary

The shell currently displays the catalog title and summary. It does not dispatch `ContentBlockDefinition` values, run interactions, score answers, write knowledge progress, or render specialized learning cards. Those responsibilities remain intentionally deferred to Stage 6.

## Figma source

The companion file is [Evolve — Stage 5 Learning Session](https://www.figma.com/design/2No881agwAOyT3Hx7UR6Pv). It contains primitive, light semantic, dark semantic, metric, and motion variable collections. Further component construction is paused by the Figma Starter MCP call limit and can resume without recreating the foundations.
