# Verification: fix-app-review-rejection

Evidence for the tasks that can only be answered by running the app, gathered on
2026-08-28 (macOS 26.6.2, MacBook Pro J516s, Xcode 26.6).

## Task 1.1 — the shipped build carries no temporary exception

A signed, sandboxed Release build of the branch:

```
CFBundleShortVersionString  1.1.1
CFBundleVersion             2

codesign -d --entitlements :-
  com.apple.security.app-sandbox
  com.apple.security.device.audio-input
  com.apple.security.files.user-selected.read-only
  com.apple.security.get-task-allow      (development signing only; absent in a store build)
```

No `com.apple.security.temporary-exception.*` key. For contrast, the build Apple rejected —
still installed as `/Applications/PrompterGlass.app`, version 1.1.0 (1) — carries
`com.apple.security.temporary-exception.mach-lookup.global-name → com.apple.audioanalyticsd`.

## Task 1.2 — voice tracking starts under the plain sandbox

`VoiceTrackingSandboxUITests.testVoiceTrackingStartsUnderTheSandbox` drives the Release-signed,
sandboxed app: it creates a script, enables voice tracking, and requires the app to reach the
listening state without any failure row. It passes in 12.8 s.

```
TEST_RUNNER_PROMPTERGLASS_SANDBOX_AUDIO_CHECK=1 xcodebuild \
  -project PrompterGlass.xcodeproj -scheme PrompterGlass \
  -configuration Release ENABLE_TESTABILITY=YES -destination 'platform=macOS' \
  -only-testing:PrompterGlassUITests/VoiceTrackingSandboxUITests test
```

Reaching `listening` means `SpeechAnalyzer` started and `AVAudioEngine` is running, which is
precisely what the removed entitlement was suspected of gating. `ENABLE_TESTABILITY=YES` is
needed only so the unit-test target still compiles in the Release configuration; it does not
change the entitlements or the sandbox.

What this does **not** cover: that live speech produces the yellow highlight. That needs a person
reading aloud, and stays a manual check.

## Task 1.3 — sandbox log during that run

Captured with `log stream --predicate 'senderImagePath CONTAINS "Sandbox" OR eventMessage
CONTAINS "deny" OR subsystem == "com.apple.speech"'`.

- **Zero mentions of `audioanalyticsd`.** The removed lookup is never even attempted, which
  explains why removing the exception changes nothing functionally.
- `localspeechrecognition` launches on the app's behalf and runs — on-device recognition is
  alive under the plain sandbox. Its own denials (`user-preference-read com.apple.triald`) are
  internal to that Apple daemon, not to this app.
- CoreAudio reports the input path is available for `dev.victorcastro.prompter-glass`.
- The app's only sandbox denial is:

  ```
  PrompterGlass deny(1) mach-lookup com.apple.cmio.registerassistantservice
      AudioInputDevices.available() (AudioInputDevices.swift:15)
  ```

  CMIO is the CoreMedia I/O (camera) subsystem. Enumerating input devices makes the frameworks
  probe it; the app has no camera entitlement and does not want one. Audio input, transcription
  and device selection all work with this denial present — it also appeared in the 1.1.0 build.
  No entitlement is warranted for it.

## Task 1.4 — port to SFSpeechRecognizer

Not required. Task 1.2 shows the current `SpeechAnalyzer` implementation works without the
exception.

## Still manual

- Reading a script aloud on the Release build and confirming the yellow highlight (rest of 1.2).
- Task 6.3, the clean-Mac first-click check.
- Tasks 6.4, 6.5 and 6.6 in App Store Connect.
