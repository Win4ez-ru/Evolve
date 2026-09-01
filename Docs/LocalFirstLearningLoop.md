# Local-First Learning Loop

Evolve treats learning as a finite cycle that produces evidence and a useful next
step. The cycle works entirely on device and does not require an account, network,
or server-side recommendation system.

## Product loop

1. Onboarding records interests, a learning goal, experience level, and preferred
   5-, 10-, or 15-minute session.
2. Today selects due reviews first, then ranks material by the learner's goal
   topic, learning state, and nearest useful difficulty.
3. A bounded full-screen vertical feed targets the selected duration, never
   exceeds 15 ideas, and clearly ends.
4. Each page offers save, reversible usefulness, a private thought, and an active
   checkpoint. Review pages start with Recall and keep the reference material
   hidden until the learner has attempted retrieval.
5. Each result persists the response, interaction type, correctness, confidence,
   timing, hint use, difficulty, and estimated effort.
6. A deterministic scheduler creates the next review date. Failed or low-confidence
   recall returns to remediation; successful recall expands the interval.
7. Evidence-based Progress weights recall, solving, applying, and explaining more
   strongly than passive reading. It never converts a bookmark into mastery.
8. The terminal state invites one small, observable real-life action. Thoughts,
   actions, and saved ideas remain visible together in Growth Memory.

## Stored local data

| Model | Purpose |
| --- | --- |
| `LearnerProfile` | Interests, goal, experience level, onboarding completion |
| `LearningAttempt` | Complete practice evidence and timing |
| `ReviewSchedule` | Next review, interval, repetitions, lapses, reason |
| `DomainProgressRecord` | Cached evidence summary per category |
| `ApplicationAction` | Learner-authored next action linked to an idea |
| `ThoughtRecord` | Private thought linked to its source idea |
| `LocalProductEvent` | Small event journal for local QA and future analytics mapping |
| `KnowledgeRecord` | Learning lifecycle plus a separate saved flag |

All personal data can be reset from Profile. Catalog content remains installed so
the app is immediately usable after a reset.

## Deterministic scheduling contract

- First completed practice schedules recall for the next day.
- Successful Recall uses 1, 3, 7, 14, 30, and 60-day base intervals.
- High confidence receives a bounded interval bonus.
- Incorrect or low-confidence Recall schedules next-day remediation and records a
  lapse.
- Dates and reasons are persisted, which is the boundary required for future local
  notifications without making notifications part of this MVP.

## Evidence contract

Evidence is scored from the interaction type, correctness or self-assessment,
confidence, content difficulty, and age. Recall is strongest; solve, quiz, prove,
apply, practice, build, and explain also contribute substantial evidence. Passive
learning contributes a small amount and saving contributes none.

The score is a product signal, not a psychological diagnosis. It is deliberately
simple, explainable, testable, and replaceable by a future versioned policy.

## Verification

- Debug simulator and unsigned Release device builds succeed.
- 61 Swift Testing tests pass across 13 suites.
- Catalog-ID repair, scheduler, evidence weighting, attempt/profile/thought/action
  persistence, finite planning, earned minutes, and local feed signals have direct
  coverage.
- The Focus Feed is visually checked on a Pro-size iPhone, a compact iPhone SE,
  and maximum Accessibility Dynamic Type.
- The complete flow remains compatible with the iOS 18 deployment target.
