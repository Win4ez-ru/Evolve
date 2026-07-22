# Evolve

Evolve is a native iOS product that turns short learning material into reflection, practice, delayed recall, and verified progress.

## Current scope

This repository contains the completed foundations through **Stage 5 — Design System & Session Shell**:

- SwiftUI application shell;
- four root destinations;
- Observation-based app environment;
- SwiftData production, preview, and test containers;
- semantic design tokens and reusable surfaces;
- a UI-independent, versioned content schema;
- categories, topics, content blocks, and interaction definitions;
- editorial and personal knowledge lifecycle policies;
- structured content validation;
- a versioned three-category JSON catalog;
- schema migration and explicit decoding errors;
- idempotent SwiftData installation with downgrade protection;
- preservation of personal state across catalog revisions;
- a calm semantic design system for light and dark appearances;
- a finite three-card Today plan and vertically paged learning session;
- explicit session progress, stop confirmation, and terminal states;
- accessibility layouts for the full Dynamic Type range and Reduce Motion;
- Swift Testing coverage.

Content block rendering, the interaction engine, backend, social features, and AI are intentionally not implemented yet.

## Requirements

- Xcode 26.6 or newer;
- Swift 6.3 toolchain;
- iOS 18.0 deployment target.

## Run

1. Open `Evolve.xcodeproj`.
2. Select the `Evolve` scheme.
3. Choose an iPhone simulator running iOS 18 or newer.
4. Build and run.

## Verify

Run the `Evolve` scheme tests in Xcode. The test target checks app foundations, domain validation, catalog migration and installation, lifecycle transitions, and in-memory SwiftData persistence.

The current Stage 5 build was verified on an iPhone 17 Pro simulator running iOS 26.5:

- application build succeeded;
- all 24 tests passed;
- the bundled catalog installed on first launch and remained idempotent;
- catalog upgrades preserved personal knowledge records;
- session planning never exceeds three cards and has deterministic stop and completion behavior;
- Today and the session were reviewed in light, dark, and maximum accessibility Dynamic Type configurations;
- the production target remains compatible with iOS 18.0 and newer.

## Architecture

See `Docs/Architecture.md` for application boundaries, `Docs/DomainModel.md` for the universal schema, `Docs/SeedCatalog.md` for the Stage 4 loading and migration contract, and `Docs/DesignSystemAndSession.md` for the Stage 5 visual and session contracts.
