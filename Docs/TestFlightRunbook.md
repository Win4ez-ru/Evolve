# Evolve TestFlight Runbook

This document separates the code-complete release work from the account actions
that require an enrolled Apple Developer team.

## Target

The next release milestone is an **internal TestFlight build** for at least one
App Store Connect user. External TestFlight and a public App Store release are
separate milestones and require additional review and public-facing content.

## Current readiness

### Ready in the repository

- Local-first iOS application with no required account, backend, analytics SDK,
  advertising SDK, or network dependency.
- Version `1.0.0`, build `1`, iOS 18.0 minimum, iPhone device family.
- 1024×1024 RGB app icon without transparency.
- Privacy manifest declaring no tracking or collected data and the approved
  `CA92.1` reason for app-only UserDefaults access.
- `ITSAppUsesNonExemptEncryption = NO`; the app contains no custom or non-exempt
  encryption.
- Repeatable unit/integration, persistence, simulator, and unsigned Release gate
  in `Scripts/verify-release.sh`.
- Ready-to-finalize App Store/TestFlight copy in `Docs/AppStoreMetadataDraft.md`
  and privacy/support copy in `Docs/PrivacyAndSupportDraft.md`.

### Must be decided by the developer

| Item | Current value | Release action |
| --- | --- | --- |
| Public app name | `Evolve` working name | Confirm availability or choose the final name |
| Bundle ID | `com.evolve.app` placeholder | Replace with an identifier owned by the Apple team |
| SKU | Not created | Suggested internal value: `EVOLVE-IOS-001` |
| Primary language | English UI | Use English unless localization is completed |
| Category | Education | Confirm in App Store Connect |
| Feedback email | Not provided | Add an address monitored during the beta |
| Apple team | Not configured | Select the enrolled team in Signing & Capabilities |

Do not register the suggested SKU or a bundle identifier until the final public
identity is chosen. Bundle IDs cannot be transferred between teams casually, and
the App Store name should not be treated as reserved until App Store Connect
accepts it.

## Local release gate

From the repository root:

```sh
./Scripts/verify-release.sh
```

Before uploading a candidate, also complete this manual path on a physical iPhone:

1. Delete the previous build and install a clean build.
2. Complete all four onboarding steps.
3. Verify Today produces the selected finite 5-, 10-, or 15-minute Focus Feed.
4. Swipe through the feed, complete at least one checkpoint, save a private
   thought, reach the explicit ending, and save a concrete application action.
5. Force-quit and relaunch.
6. Verify profile, attempt history, review schedule, action, minutes, sessions,
   and streak remain correct.
7. Repeat the critical path with VoiceOver and Reduce Motion enabled.
8. Confirm reset removes learning progress only after confirmation.
9. Repeat the session while the device is offline.

Any crash, data loss, blocked flow, unreadable accessibility state, or false save
confirmation is a release blocker.

## Create the App Store Connect record

This requires the Account Holder, Admin, or App Manager role and an active Apple
Developer Program membership.

1. Register the final explicit Bundle ID in Certificates, Identifiers & Profiles.
2. In Xcode, select the Evolve target and choose the enrolled Team under Signing
   & Capabilities.
3. Replace `com.evolve.app` with the registered Bundle ID in both Debug and Release.
4. In App Store Connect, create a new iOS app record using:
   - final app name;
   - primary language: English;
   - registered Bundle ID;
   - SKU: `EVOLVE-IOS-001` or another stable internal identifier;
   - user access appropriate for the team.
5. Confirm agreements or account notices shown by Apple. Only the Account Holder
   should accept new legal agreements.

## Archive and upload

1. Increment `CURRENT_PROJECT_VERSION` for every new upload.
2. Select `Any iOS Device (arm64)` in Xcode.
3. Run Product → Archive.
4. In Organizer, run Validate App and resolve every error.
5. Choose Distribute App → App Store Connect → Upload.
6. Wait for build processing and confirm that privacy and export-compliance status
   are complete.

Do not reuse a build number after Apple has processed an upload, even if that build
is later expired.

## Internal TestFlight information

### Beta description

> A finite, local-first vertical feed that turns short ideas into reflection,
> practice, recall, real actions, and visible progress. No account or network
> connection is required.

### What to test

> Start from a clean install. Complete onboarding, open the Focus Feed, swipe to
> its ending, complete checkpoints, save one thought and one next action, then
> force-quit and reopen the app.
> Check that progress and the scheduled review remain available. Please also try
> Dark Mode, larger text, VoiceOver, offline use, and Reset Learning Progress.

### Privacy answer

Select **Data Not Collected** while the shipping binary remains local-only and has
no analytics, advertising, account, backend, or third-party data-collection SDK.
Re-audit this answer whenever any SDK or network service is added.

### Export compliance

The current target declares that it does not use non-exempt encryption. If future
code adds custom cryptography or a third-party security library, re-evaluate the
declaration before uploading.

## External TestFlight is a later gate

Before inviting people outside the App Store Connect team:

- provide the required beta contact and review information;
- complete the first TestFlight Beta App Review;
- publish working privacy and support URLs;
- confirm the original Evolve editorial catalog and rights notice in the candidate;
- decide whether English-only UI is acceptable for the tester audience;
- resolve all P0/P1 feedback from the internal group.

App Store screenshots and the complete public listing are useful for external beta
and required for public release, but they do not block the first internal build.
