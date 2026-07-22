# Architecture Through Stage 5

## Goals

- Provide a small, compiling foundation for future product stages.
- Keep feature UI close to the feature that owns it.
- Centralize only truly shared navigation, persistence, and design primitives.
- Make previews and tests independent from the production database.

## Structure

```text
Evolve/
├── App/
├── Core/
│   ├── Domain/
│   ├── Catalog/
│   ├── DesignSystem/
│   ├── Navigation/
│   └── Persistence/
├── Features/
│   ├── Today/
│   ├── Session/
│   ├── Library/
│   ├── Progress/
│   └── Profile/
├── PreviewSupport/
└── Resources/
```

## Decisions

### Feature-oriented organization

Views live with their product feature. Core contains only shared infrastructure and UI primitives. Individual Swift packages are deferred until build boundaries or reuse justify them.

### Observation for application state

`AppEnvironment` owns lightweight, session-scoped application state such as the selected root tab. SwiftUI receives it through the type-based environment.

### SwiftData behind a container factory

`PersistenceController` creates the same schema with production or in-memory configurations. This keeps tests and previews deterministic while leaving room for repositories in later stages.

### Semantic design tokens

System backgrounds, labels, separators, Dynamic Type fonts, and SF Symbols remain semantic. System indigo is the temporary accent until brand exploration produces a validated palette.

### Domain definitions before persistence

Immutable domain definitions are independent from SwiftData and UI. They can be decoded and validated before being mapped into persistent entities. SwiftData models store validated catalog data and personal state without becoming the transport format.

### Stable taxonomy references

Categories, topics, and content use stable UUIDs and slugs. Content units own their blocks and interaction definitions, while taxonomy references remain identifier-based. This makes the future seed importer and sync layer explicit and avoids category-specific entity graphs.

### Saving is not learning progress

`KnowledgeRecord` stores an exclusive learning state and a separate saved flag. This prevents a bookmark from being treated as proof of understanding while supporting saving at any point in the lifecycle.

### Validate before mutation

The bundled JSON passes through migration, Codable decoding, and domain validation before SwiftData is changed. Catalog revisions are reconciled by stable UUID, and a receipt makes repeat launches idempotent. Unsupported schemas, invalid content, and catalog downgrades are rejected while the last valid local catalog remains available.

### Session plans are finite snapshots

`LearningSessionPlan` converts installed catalog entities into lightweight, UI-facing values and clamps the initial learning path to three cards. `LearningSessionState` owns selection, completion, stop, and progress independently from SwiftUI. A catalog update therefore cannot mutate a session that is already in progress, and the UI always knows its exact ending.

### Adaptive session presentation

At standard Dynamic Type sizes, cards use vertical page snapping so one bounded card is the primary focus. Accessibility sizes switch to view-aligned scrolling with content-driven height, adaptive metadata layout, and an abbreviated header. This preserves every title and summary instead of forcing text into a fixed viewport.

### Stage boundary for content rendering

Stage 5 provides the shell, navigation, progress, stop, and completion states only. It deliberately presents catalog summaries rather than interpreting block payloads or interaction definitions. Renderer dispatch and learning interactions remain the responsibility of Stage 6.

## Dependency direction

```text
App → Features → Core
Persistence → Domain
Catalog → Domain and Persistence
Tests → App, Domain, and Persistence
PreviewSupport → App and Core
```

Feature-to-feature imports should be avoided. Cross-feature behavior will be expressed through domain contracts introduced with the universal content model.

## Stage 2 verification

- Debug build: passed.
- Swift Testing suite: 5 of 5 tests passed.
- Runtime smoke check: passed on iPhone 17 Pro, iOS 26.5.
- Visual check: Today screen, root tab bar, semantic colors, and Dynamic Type layout reviewed.

## Stage 3 verification

- Universal catalog validation: passed.
- Three-category SwiftData persistence: passed.
- Editorial and knowledge lifecycle tests: passed.
- Complete Swift Testing suite: 12 of 12 tests passed on iPhone 17 Pro, iOS 26.5.

## Stage 4 verification

- Bundled JSON decoding and validation: passed.
- Legacy schema migration and future-schema rejection: passed.
- Idempotent installation, catalog update, and downgrade protection: passed.
- Personal-state preservation across updates: passed.
- Complete Swift Testing suite: 20 of 20 tests passed on iPhone 17 Pro, iOS 26.5.

## Stage 5 verification

- Finite three-card session planning and state transitions: passed.
- Vertical paging, explicit progress, stop confirmation, and completion state: reviewed.
- Light appearance, dark appearance, and the largest accessibility Dynamic Type size: reviewed on iPhone 17 Pro, iOS 26.5.
- Complete Swift Testing suite: 24 of 24 tests passed on iPhone 17 Pro, iOS 26.5.
