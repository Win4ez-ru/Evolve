# Stage 4 Seed Catalog

## Goal

Ship a small, validated local catalog with the app and install it into SwiftData without risking previously valid content or personal learning state.

## Data flow

```text
Bundle JSON
    → schema migration
    → Codable decoding
    → domain validation
    → revision check
    → SwiftData reconciliation
    → installation receipt
```

No SwiftData mutation occurs before decoding and validation both succeed.

## Two version numbers

- `schemaVersion` changes when the JSON shape changes. The decoder migrates supported older shapes before decoding.
- `catalogVersion` changes whenever editorial content changes. The installer uses it for idempotency and rejects a lower revision than the one already installed.

Every content edit must increment `catalogVersion`. Stable UUIDs must not be regenerated for existing categories, topics, content units, blocks, or interactions.

## Components

- `BundleContentCatalogSource` reads `ContentCatalog.v1.json` from the app bundle.
- `DataContentCatalogSource` supplies deterministic data to tests and future import adapters.
- `ContentCatalogMigrator` inspects the JSON header and applies ordered schema migrations.
- `ContentCatalogDecoder` decodes and runs the Stage 3 domain validator.
- `ContentCatalogInstaller` reconciles validated entities and stores a `ContentCatalogReceipt`.
- `ContentCatalogBootstrapper` composes the pipeline used by the app at launch.

## Migration policy

The initial migration demonstrates schema `0 → 1`. It adds default standard safety metadata to legacy units and introduces `catalogVersion` when absent.

Future schema changes must add one explicit migration step per version. Unknown newer schemas and legacy versions without a migration path are rejected.

## Installation policy

- First valid revision: `installed`.
- Same complete revision: `unchanged`; no writes are performed.
- Higher revision: `updated` by stable identifier.
- Same revision with missing stored entities: `repaired`.
- Lower revision: rejected as a downgrade.

Categories, topics, content units, blocks, and interactions are reconciled by stable UUID. `KnowledgeRecord` entities are not catalog-owned and remain intact during catalog updates.

If persistence fails, the model context is rolled back. If bundle loading, migration, decoding, or validation fails, the app logs the rejection and keeps the last valid local catalog.

## Bundled sample

`Evolve/Resources/Seed/ContentCatalog.v1.json` uses schema version 1 and catalog revision 2. It includes six materials across the MVP categories:

- Philosophy: principle and concept materials.
- Productivity & Learning: technique and dilemma materials.
- Programming Basics: problem/code and worked-example materials.

The content is an internal functional sample, not a production editorial release.

## Stage boundary

Stage 4 owns the loading and migration contract. Stage 6 consumes the installed blocks through universal renderers; interaction execution, review scheduling, and backend sync remain later responsibilities.

## Verification

- JSON syntax validation passed.
- Debug simulator build passed.
- 20 of 20 tests passed on iPhone 17 Pro, iOS 26.5.
- Tests cover bundle loading, schema migration, syntax errors, domain errors, future schemas, idempotency, repair/update rules, downgrade protection, and preservation of personal state.
- Two consecutive launches over the previous app installation succeeded.
