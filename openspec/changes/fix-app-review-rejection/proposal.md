# Proposal: fix-app-review-rejection

## Why

Apple rejected the first Mac App Store submission of PrompterGlass 1.1.0 (submission `6e72be71-5aa7-436c-9187-ad38e527b376`, reviewed 2026-08-19 on a MacBook Air M3 running macOS 26.6.2) with three findings:

1. **Guideline 1.5 — Safety / Developer Information.** The Support URL (`https://github.com/victorcastro/prompter-glass/issues`) is not a support website. The page resolves, but it is a bug tracker that requires a GitHub account and carries no contact information or support instructions.
2. **Guideline 2.4.5(i) — Performance / Hardware Compatibility.** The temporary entitlement exception `com.apple.security.temporary-exception.mach-lookup.global-name` (`com.apple.audioanalyticsd`) was not granted and will not be granted. The app cannot ship with it.
3. **Guideline 2.1(a) — Performance / App Completeness.** "The Voice tracking toggle was unresponsive."

Finding 3 reproduces from the code: the voice tracking row is rendered with `disabled: !environment.playback.hasContent` (`PrompterSectionView.swift:73`), and `hasContent` is only true once a script with renderable text is selected. A reviewer opening a freshly installed app has an empty library, so the toggle is inert and nothing on screen explains why. Two further paths produce the same symptom even with a script: the first activation blocks inside `AssetInventory.assetInstallationRequest(...).downloadAndInstall()` behind an unlabeled spinner with no timeout, and every failure from `VoiceTranscriptionSession.start` collapses into `state = .unavailable`, whose only copy is "Voice tracking unavailable for this language" — wrong for a model download failure, a device failure, or a sandbox denial.

## What Changes

- **Support website.** A real support page is added to the GitHub Pages site (`docs/support.html`) with contact email, expected response time, how to report a bug, system requirements and a short FAQ. The Support URL in App Store Connect points at that page instead of the issue tracker. The repository URLs already published on the site are verified against the live repository.
- **Sandbox entitlements.** `com.apple.security.temporary-exception.mach-lookup.global-name` is removed from `PrompterGlass.entitlements`. Voice tracking must work under the plain sandbox with `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input` only. A repository sanity check fails the build if any `temporary-exception` key reappears.
- **Voice tracking is never a dead control.** The toggle stops being disabled. When there is no active script it stays interactive and turning it on surfaces an explicit "Pick a script first" state instead of doing nothing.
- **Honest activation states.** `VoiceTrackingController.State` distinguishes the reasons it is not listening: `noScript`, `requestingPermission`, `downloadingModel`, `preparing`, `listening`, `denied`, `unavailable(reason)`. The UI shows a labeled progress row while a speech model downloads and a specific message plus a Retry action for each failure reason.
- **Activation cannot hang.** Model installation and session start are bounded by a timeout; on expiry the controller returns to a failed state with a retry path rather than leaving a spinner on screen.
- **A first-run script exists.** A sample script is seeded into an empty library on first launch, so voice tracking, playback and the overlay are all reachable immediately after install — for the reviewer and for every new user.
- **Release housekeeping.** `MARKETING_VERSION` moves to 1.1.1, the changelog gains a 1.1.1 entry, and a reply to App Review documents what changed per guideline.

## Capabilities

### New Capabilities

- `app-store-distribution`: what the Mac App Store submission must satisfy outside the app UI — the support website, the sandbox entitlement policy, and the release metadata that goes with a resubmission.

### Modified Capabilities

- `voice-tracking`: the toggle is always interactive; activation states are explicit and each failure carries its own message and retry; activation is bounded by a timeout.
- `prompter-home`: the voice tracking row explains why it cannot start, instead of appearing disabled.
- `script-management`: an empty library is seeded with a sample script on first launch.

## Impact

- **Code**: `Features/VoiceTracking/VoiceTrackingController.swift` (state machine, timeout, reasons), `Features/VoiceTracking/VoiceTranscriptionSession.swift` (typed errors, download phase callback), `MainWindow/PrompterSectionView.swift` (row no longer disabled, status view per state), `MainWindow/ControlIdentifier.swift` (identifiers for the new states), `App/ModelContainerFactory.swift` or `App/AppEnvironment.swift` (first-run seed).
- **Project**: `PrompterGlass.entitlements` loses the temporary exception; `MARKETING_VERSION = 1.1.1`; build number incremented for the resubmission.
- **Docs**: new `docs/support.html`, linked from the site navigation and footers; `CHANGELOG.md` 1.1.1 entry; README support pointer.
- **CI**: `.github/workflows/pr-main.yml` gains an entitlements check rejecting `temporary-exception` keys.
- **Tests**: controller tests for `noScript`, download timeout, failure reasons and retry; a UI test asserting the toggle is hittable with an empty library and reports why it cannot start.
- **External, not in the repo**: the Support URL field in App Store Connect, and the reply to App Review. Both are manual steps listed in tasks.
- **No breaking changes**: behavior with a script selected and permissions granted is unchanged.
