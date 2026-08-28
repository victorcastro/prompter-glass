# Tasks: fix-app-review-rejection

## 1. Sandbox entitlement (guideline 2.4.5) — do this first, it gates the rest

- [x] 1.1 Remove `com.apple.security.temporary-exception.mach-lookup.global-name` from `PrompterGlass.entitlements`, leaving `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input`
- [ ] 1.2 Archive a signed, sandboxed Release build and run it on a Mac (macOS 26): enable voice tracking with a script and granted microphone permission, confirm audio capture, on-device transcription and yellow highlighting all work
- [ ] 1.3 Capture the sandbox log during that run (`log stream --predicate 'sender == "Sandbox"'`) and record whether any denial affects functionality
- [ ] 1.4 If and only if 1.2 fails because of the removed lookup, port `VoiceTranscriptionSession` to the on-device `SFSpeechRecognizer` path and repeat 1.2
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
- [x] 5.3 Verify every link on the site resolves, including the repository links (done locally; the published page can only be confirmed after merge) at `https://victorcastro.github.io/prompter-glass/support.html`
- [x] 5.4 Add a Support section to `README.md` pointing at the same page

## 6. Release and resubmission

- [x] 6.1 Set `MARKETING_VERSION = 1.1.1` and increment the build number for every configuration
- [x] 6.2 Add the 1.1.1 changelog entry naming the fix for each rejected guideline
- [ ] 6.3 Re-verify on a clean Mac: install the Release build, run `tccutil reset Microphone dev.victorcastro.prompter-glass` and `tccutil reset SpeechRecognition dev.victorcastro.prompter-glass`, launch, and click the voice toggle as the first action — it must respond visibly
- [ ] 6.4 Update the Support URL in App Store Connect to the new support page (manual, outside the repository)
- [ ] 6.5 Upload the new build, attach it to the submission, and reply to App Review with one paragraph per guideline: 1.5 the new support page URL, 2.4.5 the exception removed and voice tracking verified under the plain sandbox, 2.1 the toggle is always interactive, states are explicit, and a sample script ships so the feature is reachable on first launch
- [ ] 6.6 Resubmit for review
