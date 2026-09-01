# Evolve Product Definition

## Status

This document defines the approved product direction and the contract for the
current prototype. The repository now implements the first local-first vertical
Growth Feed slice for Focus & Discipline: finite paging, active checkpoints,
private thoughts, linked actions, local recall, and Growth Memory. Video, remote
content operations, accounts, UGC, and large-scale adaptive ranking remain later
stages rather than requirements for validating this loop.

## Product formula

**Evolve is a goal-aware vertical self-development feed that turns short-form
attention into a useful thought, a concrete action, and evidence of progress.**

The product formula is:

```text
vertical discovery + active checkpoints + personal growth memory
= engaging self-development that carries into real life
```

The user promise is: **a feed after which something useful remains.**

TikTok and Instagram primarily learn what holds attention. Evolve should learn
what the user wants to change, what they found useful, what they remembered, and
what they applied. Vertical presentation is the interaction model, not the moat.

## Product principle

Evolve must not optimize itself into the same passive doomscrolling loop it is
intended to replace. Time spent and swipe count may be diagnostic business
metrics, but neither is the product's north star. The system should optimize for
useful returns and completed Growth Loops.

Sessions are intentional and have a visible ending. A user may choose to continue
after a summary, but the product should never hide completion in order to create
accidental usage.

## Initial audience and beachhead

The initial audience is people aged roughly 18–30, especially students and young
professionals, who already consume short-form content and want to develop
themselves but struggle to sustain books or traditional courses.

The first content beachhead is **focus and discipline**. It is narrow enough to
author and evaluate consistently, is relevant to the target audience, and avoids
the safety burden of medical, therapeutic, or financial advice.

The initial job to be done is:

> When I reach for short-form content, help me make a small amount of progress on
> a goal without requiring the energy of starting a course.

## Core experience: the Growth Loop

The target loop is:

```text
goal → relevant content → active understanding → thought or action
     → later recall or follow-up → visible progress
```

A complete target session works as follows:

1. The user enters with an active goal and chooses a 5, 10, or 15 minute session.
2. Evolve presents a goal-aware vertical sequence of short Growth Units.
3. After several units, an active checkpoint asks the user to recall, choose,
   explain, reflect, or commit to a small action.
4. The session ends with a concise summary and one retained outcome: a thought,
   decision, question, rule, or action.
5. Evolve later resurfaces relevant material, the user's own thought, or the
   action outcome to close the loop.

The first prototype may support one short session length before all three choices
are exposed. Finite duration and an explicit terminal state are product contracts;
an exact number of cards is not.

## Growth Units and vertical formats

A Growth Unit is the smallest ranked item in the feed. It must be independently
understandable and tied to at least one user goal or skill.

Supported product formats may include:

- short video;
- animated or illustrated explanation;
- full-screen text or visual story;
- scenario or dilemma with a choice;
- carousel-like sequence;
- mini-quiz or recall prompt;
- short exercise, checklist, or experiment;
- contextual reflection or action prompt.

Video is an important format, but it is not mandatory for every unit. The first
interaction prototype should reuse code-native cards, choices, and text responses
so the Growth Loop can be tested without a media platform, external subscription,
or remote content service. Real media playback and preloading are a later,
separate acceptance slice and must be complete before Evolve is presented as a
video-first product.

## Personal growth memory

Thoughts are not a separate blank diary. They should arise in context and remain
connected to the content, goal, or action that produced them.

The target memory can retain:

- a thought in the user's own words;
- a decision or personal rule;
- a question to revisit;
- a small next action;
- the outcome of a previous action;
- a recall or usefulness signal.

Over time, Evolve should show a coherent history:

```text
what I wanted → what I learned → what I decided → what I tried → what changed
```

For the first prototype, persisting a contextual reflection and one linked action
is sufficient. Automatic clustering, AI summaries, and a full knowledge graph are
not MVP requirements.

## Personalization contract

Initial ranking should stay explainable. Candidate inputs are:

- active goal and chosen interests;
- learner level and due recall;
- prior exposure and completion;
- explicit usefulness feedback;
- saved thoughts and actions;
- recall quality and action completion;
- requests for more or less of a topic.

Watch duration may help interpret an item, but it must not dominate ranking. Each
recommendation should be able to expose a human-readable reason such as “supports
your focus goal” or “you wanted to revisit this idea.”

The first prototype remains on-device and deterministic. Server-side ranking and
cross-user collaborative signals are later stages, not hidden MVP dependencies.

## Content policy

The launch catalog is editorially curated. Open publishing is explicitly outside
the MVP.

Every published Growth Unit must:

1. teach a concrete concept, skill, distinction, or behavior;
2. state a source, name an author, or clearly label personal experience;
3. contain an active learning outcome such as recall, reflection, a choice, or an
   action;
4. have documented content rights and accurate attribution;
5. pass the applicable safety review before publication.

The catalog should reject:

- empty motivation, quote spam, and “success” aesthetics without substance;
- clickbait that withholds the promised explanation;
- guaranteed outcomes, manipulative urgency, and get-rich-quick claims;
- pseudo-psychology and unqualified medical, mental-health, legal, or financial
  advice;
- unsafe challenges, harassment, hate, sexual exploitation, or deceptive content;
- unattributed copying and material without known publication rights.

The existing editorial lifecycle remains appropriate:

```text
Draft → Review → Approved → Published → Deprecated
```

Safety level, provenance, and rights are publication gates, not optional metadata.

## MVP scope

The first prototype slice is intentionally narrow:

- one beachhead: focus and discipline;
- a small, rights-cleared editorial catalog;
- a full-screen vertical, one-item-at-a-time interaction;
- a finite session and explicit completion summary;
- at least one active checkpoint inside the session;
- contextual reflection and one linked action;
- on-device learner profile, attempts, recall, and progress;
- source and “why shown” information;
- no mandatory network connection, Figma workflow, plugin, or paid third-party
  service.

The following are non-goals for the first prototype:

- open UGC, comments, direct messages, follows, or public profiles;
- authentication, cloud sync, or cross-device history;
- a creator payout system;
- advertisements or subscriptions;
- AI coaching or automatic psychological interpretation;
- a large remote video catalog;
- medical, therapeutic, financial, or other high-risk guidance.

## Metrics

### North-star metric

**Weekly Completed Growth Loops**: the number of weekly sessions in which a user
reaches an active checkpoint and retains an outcome, followed by recall, action
follow-up, or another useful return when applicable.

### Primary product metrics

- first-session and weekly session completion rate;
- percentage of sessions producing a saved thought or action;
- seven-day useful return rate;
- action follow-up and completion rate;
- delayed recall quality;
- explicit usefulness rating per unit and per session;
- percentage of recommendations with a successful “why shown” match.

### Content quality metrics

- checkpoint completion and correctness where objective evaluation exists;
- saves, thoughtful responses, and actions per impression;
- later recall or successful resurfacing;
- “show me less” and report rates;
- editorial corrections and safety incidents.

### Guardrails

- raw watch time and swipes per session are not success metrics on their own;
- session overruns should be visible rather than silently encouraged;
- private thoughts must not be used for advertising targeting;
- content should not earn distribution through outrage or compulsion signals alone.

Metric thresholds should be set after the first internal baseline rather than
invented before real users complete the loop.

## UGC roadmap

### Stage 0 — editorial catalog

Evolve authors, licenses, or commissions every published unit. All content passes
review before inclusion. This is the MVP stage.

### Stage 1 — invited creators

Vetted creators submit through structured templates. Sources, rights, goal tags,
and an active checkpoint are required. Publication remains pre-moderated.

### Stage 2 — trusted creator program

Creators earn faster review through a quality and safety history. Ranking and
revenue share should reward useful outcomes, not raw views alone.

### Stage 3 — limited community submissions

Community submissions enter as drafts, never instant public posts. This stage
requires reporting, blocking, review queues, appeals, creator identity controls,
and operational moderation capacity.

Open TikTok-style publishing is not unlocked merely by implementing an upload
button. It requires both product-market fit and a sustainable moderation system.

## Monetization roadmap

### Before retention is proven

Do not add ads. Validate repeated useful sessions, content economics, and the
Growth Loop first.

### Premium

A future subscription may offer an ad-free experience, deeper goal paths,
advanced personal memory, offline media, exports, and richer progress analysis.
The free product must retain a complete useful loop.

### Sponsorship and advertising

Sponsored Growth Units may appear only after quality and retention are proven.
They must be clearly labeled, pass the same content standards, and preferably
appear at session boundaries rather than interrupting an active exercise. Suitable
categories include books, education, career tools, and reputable productivity
products. Gambling, pseudo-health, and get-rich-quick advertising are excluded.

Private reflections, sensitive goals, and inferred vulnerabilities must never be
advertising audiences.

### Later options

Curated courses, book affiliates, expert programs, creator revenue sharing, and
B2B learning paths can be evaluated after the core consumer loop works.

## Delivery strategy

SwiftUI, Xcode Previews, simulator and device QA, automated tests, and the release
gate are the implementation path. Figma remains an optional aid for a decision
that is cheaper to resolve visually; it is not a source-of-truth dependency.
Plugins, connector quotas, external subscriptions, and design-tool limits must not
block the prototype or TestFlight.

The local catalog and local ranking are deliberate prototype constraints. A
backend should be introduced only when validated needs such as remote catalog
delivery, media operations, sync, creator workflows, or experimentation justify
its privacy and operational cost.

## Locked decisions and open decisions

Locked for the prototype:

- vertical, goal-aware discovery is the primary daily interaction;
- sessions have an explicit ending and retained outcome;
- active checkpoints distinguish Evolve from a passive useful-content feed;
- thoughts are contextual personal memory, not an isolated diary;
- the catalog is curated and local-first;
- watch time is not the north star;
- Figma and third-party subscriptions are optional.

Still open:

- the final public name and positioning copy;
- the exact first-session duration and number of units;
- the initial mix of code-native units and real video;
- the remote media and backend architecture after prototype validation;
- subscription price, ad timing, and creator economics.
