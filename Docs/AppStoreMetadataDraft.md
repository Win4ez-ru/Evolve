# Evolve App Store Metadata Draft

This draft is intentionally English-first because the shipping UI is currently
English. Replace every `{{PLACEHOLDER}}` and confirm the final public name before
creating the App Store Connect record.

## App identity

| Field | Draft |
| --- | --- |
| App name | `Evolve` |
| Subtitle | `Scroll. Learn. Apply.` |
| Primary language | English (U.S.) |
| Primary category | Education |
| Secondary category | Productivity |
| SKU | `EVOLVE-IOS-001` |
| Copyright | `2026 {{DEVELOPER_NAME}}` |
| Privacy Policy URL | `{{PRIVACY_POLICY_URL}}` |
| Support URL | `{{SUPPORT_URL}}` |
| Marketing URL | Optional |

Treat the name, SKU, category, and Bundle ID as proposals until App Store Connect
accepts the final identity.

## Promotional text

Replace passive scrolling with a finite feed of useful ideas, private reflection,
real action, scheduled recall, and visible progress.

## Description

Evolve is a finite vertical feed for people who want their screen time to leave
something useful behind. Short ideas lead into reflection, practice, recall, and
a concrete next action instead of an endless loop.

SCROLL WITH PURPOSE

Choose your goal, experience level, and a 5-, 10-, or 15-minute session. Evolve
builds a goal-aware Focus Feed, brings due recall forward, and always shows a
clear ending.

PRACTICE, DON'T JUST READ

Each card can be saved, marked useful, turned into a private thought, or opened as
an active checkpoint. Reflection, recall, choices, tracking, and small real-world
practices create stronger evidence than a view or swipe alone.

REMEMBER WHAT MATTERS

Deterministic review scheduling brings ideas back when they are due. Successful
recall advances the schedule; difficult attempts create a clear remediation path.

TURN LEARNING INTO ACTION

Finish a Growth Loop by choosing one concrete way to apply an idea. Growth Memory
keeps your thoughts, saved ideas, open actions, recall schedule, and progress
together on the device.

PRIVATE BY DEFAULT

No account is required. The core learning loop works offline, and learning data
stays on the device. The current version contains no ads, analytics, tracking,
backend sync, or third-party data-collection SDKs.

## Keywords

`self development,focus,discipline,attention,learning,reflection,habits,progress,offline`

## TestFlight beta description

A finite, local-first vertical feed that turns short ideas into reflection,
practice, recall, real actions, and visible progress. No account or network
connection is required.

## What to Test

Start from a clean install. Complete onboarding, open the Focus Feed, swipe to its
ending, complete checkpoints, save one thought and one next action, then
force-quit and reopen the app.
Check that progress and the scheduled review remain available. Please also try
Dark Mode, larger text, VoiceOver, offline use, and Reset Learning Progress.

## Beta review information

| Field | Draft |
| --- | --- |
| Feedback email | `{{SUPPORT_EMAIL}}` |
| Contact first name | `{{REVIEW_CONTACT_FIRST_NAME}}` |
| Contact last name | `{{REVIEW_CONTACT_LAST_NAME}}` |
| Contact phone | `{{REVIEW_CONTACT_PHONE}}` |
| Contact email | `{{REVIEW_CONTACT_EMAIL}}` |
| Sign-in required | No |

### Review notes

Evolve does not require an account, login, subscription, or network connection.
All core data is stored locally. To exercise the main path, complete onboarding,
open the Focus Feed from Today, finish at least one checkpoint, save a thought and
next action, reach the finite ending, and reopen the app. Profile contains the
progress reset control. The bundled Focus & Discipline catalog is original Evolve
editorial content.

## App Privacy answer

Select **Data Not Collected** only while the uploaded binary remains consistent
with the current local-first implementation: no analytics, advertising, accounts,
backend, tracking, or third-party collection SDKs. Re-audit after every dependency
or networking change.

## Before pasting into App Store Connect

- Confirm that the public name and Bundle ID belong to the enrolled Apple team.
- Replace all placeholders and publish the privacy/support pages.
- Verify every claim against the exact uploaded binary.
- Complete the age-rating questionnaire from the final catalog content.
- Confirm that the original editorial catalog and its rights notice match the
  uploaded binary.
- Recheck character limits in App Store Connect after the final name is chosen.
