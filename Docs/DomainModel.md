# Stage 3 Domain Model

## Goal

Represent taxonomy, learning content, available interactions, editorial state, and personal knowledge state without depending on a screen or a category-specific code path.

## Layers

### Domain definitions

`Core/Domain` contains immutable `Codable`, `Equatable`, and `Sendable` value types. These types are the boundary used by the versioned JSON catalog implemented in Stage 4.

- `ContentCatalogDefinition` is the versioned catalog root.
- `ContentCategoryDefinition` and `ContentTopicDefinition` form the taxonomy.
- `ContentUnitDefinition` describes one semantic learning unit.
- `ContentBlockSpec` describes ordered text, quote, code, formula, media, or callout blocks.
- `InteractionSpec` declares what the learner can do without implementing the interaction UI.
- `ContentSource` and `ContentSafety` keep provenance and safety constraints in the schema.

### SwiftData entities

`Core/Persistence/ContentModels.swift` maps validated definitions into local entities:

- `ContentCategory`;
- `ContentTopic`;
- `ContentUnit`;
- `ContentBlock`;
- `InteractionDefinition`;
- `KnowledgeRecord`.

Taxonomy references use stable UUIDs. Content units own blocks and interaction definitions through cascade relationships. This avoids category-specific model classes and keeps identifiers suitable for later seed updates and backend synchronization.

## Independent lifecycles

Editorial state:

```text
Draft → Review → Approved → Published → Deprecated
```

Personal learning state:

```text
Eligible → Surfaced → Viewed → Engaged → Scheduled → Review Due
                                                ├→ Recalled → Mastered
                                                └→ Remediation
```

A mastered item can become due again as memory decays. `Saved` is intentionally an independent property of `KnowledgeRecord`, because saving does not prove understanding and may occur at any learning state.

## Validation rules

Validation runs before persistence and reports structured issues with a code and path. It checks:

- stable, unique identifiers and slugs;
- valid category and topic references;
- category consistency for every topic assigned to a content unit;
- contiguous block and interaction ordering;
- exactly one primary interaction;
- response and evaluation configuration;
- source provenance and safety notices;
- positive durations and required text.

## Cross-category proof

`MVPContentFixtures` expresses three deliberately different examples through the same schema:

- Philosophy: Principle → Reflect + Explain.
- Productivity & Learning: Technique → Observe + Apply + Track.
- Programming Basics: Problem + code block → Solve + Recall.

The fixtures are model and test data only. They are not the production content catalog.

## Stage boundary

Stage 3 does not include JSON files, catalog installation, seed migrations, content rendering, the vertical session, interaction execution, scoring, review scheduling, backend, or AI. Versioned local seed loading is Stage 4.

## Verification

- Debug simulator build passed.
- 12 of 12 tests passed on iPhone 17 Pro, iOS 26.5.
- Tests cover validation failures, both lifecycle policies, SwiftData relationships, universal catalog persistence, and personal state persistence.
