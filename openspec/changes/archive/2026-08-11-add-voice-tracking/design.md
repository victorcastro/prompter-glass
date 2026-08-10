# Design: add-voice-tracking

## Context

PrompterGlass 1.0 scrolls the script at a fixed, user-set speed driven by `ScrollPlaybackEngine` (time-based offset) and `DisplayLinkDriver`. The overlay renders the script as a single SwiftUI `Text`. The app is fully offline, sandboxed, and its privacy policy states that no data leaves the Mac — any speech feature must preserve that.

Deployment target is macOS 26.0, which makes the new `SpeechAnalyzer`/`SpeechTranscriber` APIs (WWDC25, Speech framework) available: fully on-device streaming transcription with word-level timing, no server fallback.

## Goals / Non-Goals

**Goals**

- Follow the presenter's voice through the active script with word-level granularity, robust to skipped/repeated/misrecognized words.
- Highlight read words in yellow without breaking the existing text layout.
- Drive the scroll from the reading position while voice tracking is on.
- Keep everything on-device; never enable a network path.

**Non-Goals**

- No dictation or script editing by voice.
- No multi-language mixing within one script (recognition locale = system locale).
- No persistence of audio or transcripts — both are discarded as processed.
- No change to manual playback behavior when voice tracking is off.

## Decisions

### D1: SpeechAnalyzer + SpeechTranscriber, on-device only

`SpeechTranscriber` configured for on-device transcription with volatile (partial) results. `AVAudioEngine` input node feeds the analyzer's input sequence. If the on-device model for the system locale is not installed, we request it via the assets API (`AssetInventory`) with UI feedback; we never fall back to server-based recognition.

*Alternative considered:* legacy `SFSpeechRecognizer` with `requiresOnDeviceRecognition`. Rejected — the new API is the supported path on macOS 26, gives better streaming ergonomics and timing metadata.

### D2: Aligner as a pure, testable core

`ScriptAligner` is a pure Swift type: input = script tokenized into normalized words (lowercased, diacritics folded, punctuation stripped); state = last confirmed word index; operation = align an incoming transcript fragment against a sliding window (~20 words ahead, ~5 behind) using per-word fuzzy equality (exact, prefix, or small edit distance). It returns the new confirmed index. Skips ahead only when 2+ consecutive window words match, which tolerates recognition noise, filler words, and small improvisations without jumping.

This type contains all the tricky logic and has zero framework dependencies — the bulk of new unit tests target it.

### D3: Highlighting via AttributedString on the existing Text

`OverlayView` keeps a single `Text`, now built from an `AttributedString` where words `0..<confirmedIndex` get `foregroundColor: .yellow`. The rest keep the user's text color. Layout, font, spacing and geometry reporting are unchanged, so content-height tracking and frame persistence keep working. Highlight color is fixed yellow in 1.1.0 (not a preference).

### D4: Voice mode drives the engine through the existing offset

`ScrollPlaybackEngine` gains a target-offset mode: `VoiceTrackingController` maps the confirmed word index to a fractional position in the script, converts it to a target offset (using existing content/viewport heights), and the engine eases toward it on the same display-link tick (clamped speed so the scroll stays smooth, keeping the reading position around the upper third of the viewport). Manual mode is untouched; toggling voice tracking off returns to fixed-speed behavior.

*Alternative considered:* bypassing the engine and setting the offset directly from the recognizer. Rejected — reuses no smoothing, breaks pause/stop semantics and the existing tests' mental model.

### D5: Permissions and failure states are explicit UI states

`VoiceTrackingController` exposes a state: `idle`, `requestingPermission`, `downloadingModel`, `listening`, `denied(reason)`, `unavailable(reason)`. The control panel renders the toggle plus a compact status line; `denied` includes a button that deep-links to System Settings (Privacy & Security → Microphone). The toggle never silently fails.

### D6: Defaults change, stored values win

`OverlayPreferencesStore.Defaults.backgroundOpacity` becomes 0.80. The getter already falls back to the default only when no value is stored, so existing users keep their chosen opacity. White stays the coded default text color (`RGBAColor.white`), now stated in the spec.

### D7: Privacy story stays true

Entitlement `com.apple.security.device.audio-input`; Info.plist usage strings state that audio is processed on-device and never stored or transmitted. The published privacy policy gains a "Microphone" section saying exactly that. No other network-facing change exists, so "no network connections" remains accurate.

## Risks / Trade-offs

- [Recognition quality varies by locale/model] → recognition locale follows the system; if no on-device model exists, the feature reports `unavailable` instead of degrading silently.
- [Fuzzy alignment can lag or jump on heavy improvisation] → sliding window bounds the search; requiring consecutive matches to advance biases toward lagging (safe) rather than jumping ahead; manual controls remain available as an escape hatch.
- [AttributedString rebuild per recognized word could be costly on long scripts] → rebuild only when the confirmed index changes, and cache the tokenization; scripts are teleprompter-sized (thousands of words, not megabytes).
- [Mac App Store review: microphone justification] → usage strings and review notes explain the teleprompter-following feature plainly.
- [CI is Linux-only and cannot compile Speech] → unchanged; tests run locally as established for this repo.

## Migration Plan

Single feature branch, one PR. No data migration: preferences keep stored values; only the fallback default changes. Version bump to 1.1.0 in the same PR, changelog entry under `[1.1.0]`, privacy policy page updated together with the code so the site and the binary ship the same story.

## Open Questions

- Whether the yellow highlight should also dim already-read text slightly for contrast — deferred; plain yellow foreground in 1.1.0.
- Exact easing constants for voice-driven scroll (to be tuned by hand during implementation; not spec-relevant).
