# Tasks: fix-app-review-rejection

## 1. Sandbox entitlement (guideline 2.4.5) — do this first, it gates the rest

- [x] 1.1 Remove `com.apple.security.temporary-exception.mach-lookup.global-name` from `PrompterGlass.entitlements`, leaving `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input`
- [x] 1.2 Build a signed, sandboxed Release build and confirm voice tracking reaches the listening state on it — covered by `VoiceTrackingSandboxUITests`, see `verification.md`
- [x] 1.2b Read a script aloud on that build and confirm the yellow highlight follows the voice — verified by hand on 2026-08-28, transcription and highlighting both correct
- [x] 1.3 Capture the sandbox log during that run and record whether any denial affects functionality — no `audioanalyticsd` traffic at all; the one denial (`cmio.registerassistantservice`) is the camera subsystem and harms nothing, see `verification.md`
- [x] 1.4 Not required: 1.2 passes with `SpeechAnalyzer` under the plain sandbox
- [x] 1.5 Add a repository check that fails on any `temporary-exception` key in the entitlements file, and wire it into `.github/workflows/pr-main.yml`

## 2. Voice tracking controller (guideline 2.1)

- [x] 2.1 Extend `VoiceTranscriptionSession.SessionError` with `modelUnavailable` and `audioEngineFailed`; throw the accurate case at each failure point instead of letting errors collapse
- [x] 2.2 Report the model-installation phase from `VoiceTranscriptionSession.start` before awaiting `downloadAndInstall()`
- [x] 2.3 Replace `VoiceTrackingController.State.unavailable` with `unavailable(Reason)` and add `noScript` and `downloadingModel`; keep `isActive` true only for `requestingPermission`, `downloadingModel`, `preparing`, `listening`
- [x] 2.4 Enter `noScript` when `setEnabled(true)` is called with no active script text, without touching the microphone
- [x] 2.5 Bound activation with a timeout covering model installation and session start; on expiry stop the session and enter `unavailable(.modelUnavailable)`
- [x] 2.6 Add `retry()` that clears the failed state and re-runs activation
- [x] 2.7 Unit tests: `noScript` path, download phase reported, timeout produces a failure state, each error maps to its own reason, retry reaches listening

## 3. Prompter section UI (guideline 2.1)

- [x] 3.1 Remove `disabled: !environment.playback.hasContent` from the voice tracking `FeatureRow`
- [x] 3.2 Render a status line per state: `noScript` (with a button that opens the script library), `requestingPermission`, `downloadingModel` (labeled with the language), `denied` (existing System Settings link), `unavailable(reason)` (reason-specific copy plus Retry)
- [x] 3.3 Add accessibility identifiers for the new states in `ControlIdentifier`
- [x] 3.4 UI test: with an empty library, the voice toggle is hittable and the no-script status appears
- [x] 3.5 UI test: the unavailable state exposes a Retry control

## 4. First-run sample script

- [x] 4.1 Seed one sample script when the store is empty on first launch, guarded by a one-time flag so deletion is permanent
- [x] 4.2 Unit tests: seeds on an empty first launch, does not seed when scripts exist, does not reseed after deletion

## 5. Support website (guideline 1.5)

- [x] 5.1 Add `docs/support.html`: contact email, response expectation, how to report a bug and what to include, system requirements (macOS 26+), known limitations, FAQ (microphone permission, voice tracking language, on-device privacy), secondary link to GitHub Issues
- [x] 5.2 Link Support from the navigation and footer of `index.html`, `privacy.html` and `terms.html`
- [x] 5.3 Verify every link on the site resolves, including the repository links, and confirm the published page at `https://victorcastro.github.io/prompter-glass/support.html` (returns 200 since #10 merged)
- [x] 5.4 Add a Support section to `README.md` pointing at the same page

## 6. Release and resubmission

- [x] 6.0 Draft the reply to App Review, one paragraph per guideline — `app-review-reply.md`
- [x] 6.1 Set `MARKETING_VERSION = 1.1.1` and increment the build number for every configuration
- [x] 6.2 Add the 1.1.1 changelog entry naming the fix for each rejected guideline

The remaining steps happen in App Store Connect and are handled directly by the developer, not
tracked here: the clean-Mac re-check, the Support URL field, uploading build 1.1.1 (2), sending
the reply drafted in `app-review-reply.md`, and resubmitting.
