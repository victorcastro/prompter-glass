# Design: fix-app-review-rejection

## Context

Three rejections, three independent root causes. Only one of them (2.1) is a real defect in the app; the other two are distribution facts that the binary and the store listing have to satisfy.

## Decision 1 — Guideline 1.5: a support page, not the issue tracker

The submitted Support URL is live and public (`https://github.com/victorcastro/prompter-glass/issues` returns 200, issues are enabled), so this is not a broken link. Apple's objection is that a GitHub issue list is not a support website: it demands an account to write anything, offers no contact route, and states no expectations.

The site already published from `docs/` (`https://victorcastro.github.io/prompter-glass/`, live) is the natural home. A `support.html` page is added there with:

- a contact email that a user can write to without any account (the address already used in the privacy policy),
- a stated response window,
- how to report a bug, including what to include,
- system requirements (macOS 26 or later) and the known limitations already listed in the changelog,
- a short FAQ covering the microphone permission and voice tracking,
- a secondary link to GitHub Issues for users who prefer it.

Alternative rejected: pointing the Support URL at the site's home page. It carries no support content today, which invites the same rejection.

## Decision 2 — Guideline 2.4.5(i): remove the temporary exception

`com.apple.security.temporary-exception.mach-lookup.global-name` for `com.apple.audioanalyticsd` was added in the same commit as voice tracking (`9326421`). Apple states plainly it will not be granted, so there is nothing to negotiate: it comes out.

The open question is whether on-device `SpeechAnalyzer`/`SpeechTranscriber` still works under the plain sandbox with only `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input`. The expectation is yes: the `audioanalyticsd` lookup is a telemetry side channel of the audio stack, and its denial is logged by the sandbox without failing capture or transcription. That expectation is verified empirically, not assumed — the verification runs on a signed, sandboxed Release build, not a debug run, because a debug run can mask sandbox behavior.

If verification shows transcription genuinely depends on the denied lookup, the fallback is to re-implement on the public `SFSpeechRecognizer` on-device path, which is designed for sandboxed apps. Shipping the exception is not an option in any branch.

To keep the exception from returning, a repository check greps the entitlements file for `temporary-exception` and fails. It belongs in CI rather than in a reviewer's memory because the failure mode is a rejected submission weeks later.

## Decision 3 — Guideline 2.1(a): why the toggle looked dead, and what replaces it

The reviewer's sentence is one symptom with several possible sources, and all of them are fixed rather than guessed between.

**Source A — the toggle is literally disabled.** `PrompterSectionView.swift:73` passes `disabled: !environment.playback.hasContent`, and `hasContent` requires an active script with renderable text (`AppEnvironment.refreshPlaybackAvailability`). On a fresh install the library is empty, so the control cannot be actuated and the row says only "off". This is the most likely thing the reviewer hit, because it needs no permissions, no audio and no network to reproduce: install, open, click.

Fix: the row stays interactive. Turning it on with no usable script puts the controller in `noScript` and the status line reads that a script must be picked, with a control that opens the library. A disabled control that does not say why is the defect; a control that answers is not.

**Source B — the activation blocks with no explanation.** `VoiceTranscriptionSession.start` awaits `AssetInventory.assetInstallationRequest(...)?.downloadAndInstall()` before anything else happens. On a machine that has never used this locale's speech model that is a download of unknown length, and the UI shows a bare `ProgressView`. Fix: the session reports a download phase before it starts waiting, the controller exposes `downloadingModel`, and the UI labels it ("Downloading the speech model for <language>…"). The wait is bounded; on expiry the state becomes a failure with Retry.

**Source C — every failure claims to be a language problem.** `catch { state = .unavailable }` maps a missing model, an unavailable audio format, a device failure and a sandbox denial to one message about the language. Fix: `SessionError` gains cases (`localeNotSupported`, `modelUnavailable`, `audioFormatUnavailable`, `audioEngineFailed`), `unavailable` carries the reason, and each reason has its own sentence. Wrong copy is how a bug becomes unreportable.

**Supporting change — seed a sample script.** An empty library makes every downstream feature unreachable and hides playback, the overlay and voice tracking behind a step the reviewer has no reason to take. One seeded script on first launch (only when the store is genuinely empty, so it never reappears after the user deletes it) removes that cliff for everyone.

## State machine

```
idle ──enable──▶ noScript                (no active script with text)
             ├─▶ requestingPermission ──denied──▶ denied
             │                          └─granted─┐
             ├─▶ downloadingModel ──timeout/error──▶ unavailable(reason)
             ├─▶ preparing ──error──▶ unavailable(reason)
             └─▶ listening ──disable/stop──▶ idle
```

`isActive` stays true only for `requestingPermission`, `downloadingModel`, `preparing` and `listening`. `noScript`, `denied` and `unavailable` are inactive, so the toggle springs back to off — which is correct only because the status line now says why.

## Verification

The 2.1 fix is verified the way the reviewer met it: a Release build, installed on a Mac where the app has never run, with `tccutil reset Microphone dev.victorcastro.PrompterGlass` and `tccutil reset SpeechRecognition dev.victorcastro.PrompterGlass` executed first, and the speech model for the system language removed if present. Clicking the voice toggle as the very first action after launch must produce a visible, explanatory response.

## Risks

- The empirical entitlement test is the gate for the whole submission; if it fails, Decision 2's fallback expands the change considerably. It is therefore the first task.
- The seeded sample script must not resurrect itself for existing users who deleted everything; the seed is guarded by a one-time flag, not only by an empty store.
