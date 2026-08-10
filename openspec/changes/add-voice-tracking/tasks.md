# Tasks: add-voice-tracking

## 1. Project plumbing

- [x] 1.1 Add com.apple.security.device.audio-input entitlement to the app target
- [x] 1.2 Add NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription Info.plist strings (on-device wording)
- [x] 1.3 Bump MARKETING_VERSION to 1.1.0

## 2. Appearance defaults

- [x] 2.1 Change OverlayPreferencesStore.Defaults.backgroundOpacity to 0.80
- [x] 2.2 Update unit tests for the new default and verify stored values still win

## 3. Aligner core

- [x] 3.1 Implement ScriptTokenizer: normalized word tokens with original ranges for highlighting
- [x] 3.2 Implement ScriptAligner: sliding-window fuzzy alignment advancing a confirmed word index
- [x] 3.3 Unit tests: exact reading, skipped words, repeated words, filler noise, no-match stays put, consecutive-match advance rule

## 4. Speech capture and transcription

- [x] 4.1 Implement AudioCaptureService with AVAudioEngine feeding SpeechAnalyzer input
- [x] 4.2 Implement SpeechTranscriptionService using on-device SpeechTranscriber with volatile results; model availability check via AssetInventory
- [x] 4.3 Implement permission handling (microphone + speech) with explicit states

## 5. Tracking controller and playback integration

- [x] 5.1 Implement VoiceTrackingController state machine (idle, requestingPermission, downloadingModel, listening, denied, unavailable) wiring capture → transcription → aligner
- [x] 5.2 Add target-offset mode to ScrollPlaybackEngine with smooth easing toward the reading position
- [x] 5.3 Map confirmed word index to scroll offset and keep the reading zone in the upper third of the viewport
- [x] 5.4 Unit tests: controller state transitions, engine target-offset easing, index-to-offset mapping

## 6. UI

- [x] 6.1 OverlayView: build the script Text from AttributedString, read words in yellow, rebuild only on index change
- [x] 6.2 ControlPanelView: voice-tracking toggle with status line and System Settings shortcut on denied
- [x] 6.3 Accessibility identifiers for the new controls; UI test covering toggle visibility and denied state rendering

## 7. Docs and release

- [x] 7.1 CHANGELOG entry for 1.1.0
- [x] 7.2 Privacy policy: add Microphone section (on-device, never stored or transmitted) in docs/privacy.html and PRIVACY.md summary
- [x] 7.3 README: add voice tracking to Features

## 8. Verification

- [x] 8.1 Full unit test suite green locally (UI tests excluded per repo practice unless requested)
- [x] 8.2 SwiftLint --strict and SwiftFormat --lint clean
- [x] 8.3 Manual smoke test: read a script aloud, verify highlight follows and scroll eases; verify denied-permission state
