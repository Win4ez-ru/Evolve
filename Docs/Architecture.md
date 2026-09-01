# Architecture: Focus Feed prototype

## Goals

- Deliver a finite vertical self-development feed as a native SwiftUI experience.
- Keep the first product slice local-first and independently testable.
- Separate content definitions, personal evidence, session state, and presentation.
- Preserve an explicit ending and meaningful checkpoints inside an engaging feed.
- Keep Figma, plugins, a backend, and paid services outside the build critical path.

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
│   ├── ContentRendering/
│   ├── Library/
│   ├── Progress/
│   └── Profile/
├── PreviewSupport/
└── Resources/
```

Views remain with the feature that owns them. `Core` contains shared domain,
catalog, navigation, persistence, and design infrastructure. Swift packages are
deferred until a real build boundary or reuse case justifies them.

## Current decisions

### SwiftUI is the product source of truth

The shipping SwiftUI views, Xcode Previews, simulator review, and automated tests
define the interface contract. Figma may be used selectively, but it is not a build
dependency or release gate.

### The feed is finite session state, not an endless collection

`LearningSessionPlan` converts installed content into immutable UI snapshots.
Plans target the user's selected 5-, 10-, or 15-minute duration and never exceed
15 items. `LearningSessionState` owns completed items, stop intent, progress, and
the terminal state independently from SwiftUI, so catalog updates cannot mutate a
session already in progress.

`LearningSessionView` renders those snapshots as full-screen vertical pages with
paging behavior. A separate final page summarizes viewed, practiced, and useful
items and asks the user to finish intentionally. Opening a checkpoint presents the
existing interaction shell without turning a swipe into proof of learning.

### Authored roles shape the session rhythm

Each unit exposes one of four `GrowthUnitRole` values derived from its preferred
interaction. The planner balances `learn`, `test`, `reflect`, and `do` before
applying the duration limit, while due recall remains ahead of new discovery. The
bundled catalog contains 12 original Focus & Discipline units across three topics
and two examples of each editorial pattern: learn, quiz, reflect, apply, track,
and recall.

The first deterministic ranker uses due state, the learner's goal-to-topic mapping,
learning state, and level fit. Behavioral adaptation and larger remote content
pools are a future boundary.

### Viewing, saving, usefulness, and learning are separate evidence

Saving remains orthogonal to `KnowledgeRecord` learning state. Feed impressions,
fast skips, reversible usefulness, and the finite feed ending are stored as local
product events. Practice produces a `LearningAttempt`; successful interaction
evidence can update knowledge, review, and category progress. A feed ending,
earned session, and completed Growth Loop are distinct events, so passive scrolling
does not create learning minutes or a streak.

This separation allows later ranking experiments without falsely treating passive
scrolling as mastery. Private thought bodies are not copied into analytics events.

### Growth Memory closes the loop locally

SwiftData stores catalog entities and personal state in the same local schema:

- `KnowledgeRecord` for lifecycle and saving;
- `LearningAttempt`, `ReviewSchedule`, and `DomainProgressRecord` for evidence;
- `ThoughtRecord` for private reflections linked to a source idea;
- `ApplicationAction` for pending, completed, or skipped real-life actions;
- `LocalProductEvent` for privacy-preserving product signals.

The Memory surface brings recent thoughts and actions together with saved content.
The final session state can create a linked action, and actions can later be marked
complete. Production, preview, and test containers share the schema while using
separate configurations.

### Catalog data is validated before persistence

Immutable domain definitions remain independent from SwiftData and UI. Bundled
JSON passes through schema migration, Codable decoding, and validation before any
persistent mutation. Stable UUIDs support idempotent installation and catalog
updates while preserving personal records; future schemas and downgrades are
rejected explicitly.

### Rendering and interactions remain data-driven

Session snapshots retain semantic kind, difficulty, ordered blocks, interactions,
and source provenance. Exhaustive resolvers map supported content and block kinds
to specialized or fallback SwiftUI renderers. `LearningCardShell` owns transient
responses, confidence, and deterministic local evaluation.

Code-native cards are the current media strategy. Existing media placeholders are
not video playback; real video ingestion, delivery, rights management, and offline
behavior remain future work.

### Local-first policy remains explicit

`ReviewScheduler` and `EvidenceScorer` are pure domain policies without SwiftUI or
SwiftData dependencies. Onboarding and Profile preferences are owned by the local
installation, and no anonymous remote identity is created. Accounts, sync,
notifications, remote content, UGC, moderation, creator workflows, advertising,
and AI coaching are intentionally outside this prototype.

## Dependency direction

```text
App → Features → Core
Persistence → Domain
Catalog → Domain and Persistence
Tests → App, Domain, and Persistence
PreviewSupport → App and Core
```

Feature-to-feature imports should remain exceptional. Shared behavior belongs in
domain contracts rather than screen-specific coupling.

## Current verification

- Debug application build succeeds.
- The bundled schema-version-1, catalog-version-3 file contains 12 valid Focus &
  Discipline units and installs idempotently.
- 61 Swift Testing tests cover domain, catalog, migration, persistence, rendering,
  finite duration planning, session state, review and evidence policies, thoughts,
  action lifecycle, and feed/Growth Loop events.
- The repository verification script also compiles an unsigned Release device
  build.

## Release boundary

The local prototype does not need a backend for TestFlight. Distribution still
requires a production bundle identifier, an Apple Developer team and signing
identity, and a matching App Store Connect record and metadata. Video, backend,
UGC, moderation, and adaptive ranking are product expansion work, not prerequisites
for validating this first Focus Feed.
