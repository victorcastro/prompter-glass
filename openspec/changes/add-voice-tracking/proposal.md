# Proposal: add-voice-tracking

## Why

Reading from a teleprompter still requires the presenter to manage scroll speed by hand, which breaks the flow of a recording when they speed up, slow down, or improvise. Version 1.1.0 makes the prompter follow the presenter: on-device speech recognition tracks what has been read aloud, highlights it, and can drive the scroll — while keeping the app's core promise that nothing ever leaves the Mac.

## What Changes

- **Voice tracking**: a control-panel toggle starts capturing the microphone with `AVAudioEngine` and transcribing it on-device with the macOS 26 `SpeechAnalyzer`/`SpeechTranscriber` APIs (Speech framework). No network is used at any point.
- **Read-position highlighting**: the live transcript is fuzzily aligned against the active script using a sliding window anchored at the last confirmed position; words already read are rendered in yellow in the overlay.
- **Voice-driven scrolling**: while voice tracking is active, the overlay scrolls to keep the current reading position in view, replacing the fixed-speed scroll; manual play/pause/stop keeps working exactly as today when voice tracking is off.
- **Permissions flow**: first activation requests microphone and speech-recognition permission; the UI shows a clear state when permission is denied, with a shortcut to System Settings.
- **New appearance defaults**: default background opacity changes from 0.55 to 0.80; the default text color stays white (ratified).
- **Housekeeping**: `com.apple.security.device.audio-input` entitlement, `NSMicrophoneUsageDescription` and `NSSpeechRecognitionUsageDescription` strings, `MARKETING_VERSION` bump to 1.1.0, changelog entry, and a privacy-policy note that the microphone is processed entirely on-device.

## Capabilities

### New Capabilities

- `voice-tracking`: on-device speech recognition that follows the presenter through the active script — activation and permissions, read-position highlighting, and voice-driven scrolling.

### Modified Capabilities

- `overlay-appearance`: the default background opacity becomes 0.80 (was 0.55); the default text color is explicitly specified as white. Only defaults change — the adjustable ranges and persistence behavior stay the same.

## Impact

- **Code**: new `Features/VoiceTracking/` (audio capture, transcriber, script aligner, tracking controller); changes in `OverlayView` (attributed highlighting), `ControlPanelView` (toggle + permission state), `ScrollPlaybackEngine`/`ScrollPlaybackController` (position-driven scrolling mode), `OverlayPreferencesStore` (new default).
- **Project**: audio-input entitlement, two usage-description Info.plist keys, `MARKETING_VERSION = 1.1.0`.
- **Docs**: CHANGELOG 1.1.0 entry; privacy policy gains an on-device microphone section (site + repo).
- **Tests**: unit tests for the aligner (the core algorithm), tracking controller state machine, and new defaults; existing playback/appearance tests updated where defaults changed.
- **No breaking changes**: users who never enable voice tracking see identical behavior except the new background-opacity default (existing persisted values are respected).
