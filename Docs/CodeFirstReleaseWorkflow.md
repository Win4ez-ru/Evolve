# Code-First Release Workflow

## Decision

Evolve uses the shipping SwiftUI application as the source of truth for product UI.
Figma is a lightweight reference and communication tool, not a release dependency.
No feature waits for a Figma component, screen, subscription, or MCP quota before it
can be implemented, tested, or shipped.

## Sources of truth

| Concern | Source of truth | Verification |
| --- | --- | --- |
| Colors, type, spacing, radius, elevation, motion | `Evolve/Core/DesignSystem` | Xcode Preview and simulator |
| Reusable UI | SwiftUI views in `Core/DesignSystem/Components` and feature folders | Preview and focused tests |
| Product flows | SwiftUI feature code | Simulator walkthrough |
| Product behavior and persistence | Domain and SwiftData code | Swift Testing suite |
| Release readiness | This checklist and `Scripts/verify-release.sh` | Local run and CI |
| Optional visual reference | Existing Figma file | Updated only when it reduces product risk |

## Daily loop

1. Implement the smallest complete behavior in SwiftUI.
2. Check the affected view in Xcode Preview using the in-memory preview catalog.
3. Review the change in light and dark appearance.
4. Run focused tests while iterating.
5. Run `Scripts/verify-release.sh` before a milestone or release candidate.
6. Capture a simulator screenshot only when it helps compare a visible change.
7. Update Figma only for a high-value product decision; never mirror code mechanically.

## Visual QA matrix

The critical visual set is intentionally small. These four surfaces represent the
entire first-run and daily-learning promise:

| Surface | Required checks |
| --- | --- |
| Onboarding | first launch, disabled/active Continue, long category copy |
| Today | empty progress, due review, goal-ranked finite feed plan |
| Focus Feed | regular and compact page, Recall-first page, save/useful/thought controls |
| Growth Loop ending | viewed/practiced metrics, application action, return to Today |

For every release candidate, review each surface with:

- light and dark appearance;
- the default Dynamic Type size and at least one accessibility size;
- Reduce Motion enabled for animated transitions;
- an iPhone Pro simulator and a smaller compact-width iPhone simulator;
- offline operation and a fresh local store.

Library, Progress, and Profile are reviewed in the simulator as complete flows, but
they do not require permanent Figma frames or screenshot baselines for every state.

## Minimal Figma policy

Figma work is optional and limited to:

1. Onboarding overview.
2. Today.
3. Active Focus Feed.
4. Growth Loop ending.
5. App Store screenshot composition when submission begins.

Do not spend release time on exhaustive component libraries, full state matrices,
duplicated dark-mode frames, or pixel-for-pixel synchronization with SwiftUI. The
existing tokens and foundations remain available as a reference. A Figma update is
justified only when it resolves an unclear product decision faster than a SwiftUI
prototype.

## Release gates

### P0 — required before TestFlight

- [ ] `Scripts/verify-release.sh` passes.
- [ ] First launch installs the bundled catalog and presents onboarding.
- [ ] Completing onboarding produces a goal-aware finite Focus Feed.
- [ ] A full Growth Loop persists its checkpoint, thought, useful state, and action.
- [ ] Passive scrolling alone does not create mindful minutes or a streak.
- [ ] Relaunch preserves profile, progress, review schedule, thoughts, and actions.
- [ ] Updating a prior local store repairs stale catalog category selections.
- [ ] Today, Library, Progress, and Profile have useful empty and populated states.
- [ ] Light, dark, Dynamic Type, VoiceOver labels, and Reduce Motion are reviewed.
- [ ] The app functions without a network connection or external account.
- [ ] App icon, display name, version, bundle identifier, privacy copy, and support URL are final.
- [ ] A signed archive and internal TestFlight build succeed.

### P1 — required before public App Store submission

- [ ] TestFlight feedback has no unresolved data-loss, crash, or blocked-flow issue.
- [ ] App Store description, keywords, category, age rating, and privacy answers are ready.
- [ ] Final screenshots are captured from the shipping build and composed if needed.
- [ ] Reset, share, and all destructive confirmations are reviewed on a real device.
- [ ] Launch performance and basic memory behavior are checked with Instruments.

### Post-launch

- Add analytics or crash reporting only after choosing a privacy policy and provider.
- Add accounts, sync, social features, remote media, or AI coaching only from validated demand.
- Expand Figma documentation only when collaboration or handoff actually requires it.

## Verification command

Run from the repository root:

```sh
./Scripts/verify-release.sh
```

The script runs the complete Swift Testing suite on a simulator and then compiles a
Release device build without code signing. Override the simulator when needed:

```sh
EVOLVE_DESTINATION='platform=iOS Simulator,name=iPhone 16 Pro' ./Scripts/verify-release.sh
```

Signing, archiving, TestFlight upload, privacy metadata, and App Store submission
remain explicit manual gates because they require the developer account and final
business information.
