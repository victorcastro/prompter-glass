# voice-tracking Specification

## MODIFIED Requirements

### Requirement: Voice tracking can be toggled from the control panel

The app SHALL provide a control to enable and disable voice tracking. The control SHALL remain interactive at all times, including when no script is active and when permissions have been denied. While enabled and listening, the app SHALL capture the microphone and transcribe speech; otherwise the microphone SHALL NOT be captured. Whenever the control is turned on and the app does not reach the listening state, the app SHALL display the reason it did not.

#### Scenario: Enabling voice tracking

- **WHEN** the user enables voice tracking with an active script and permissions granted
- **THEN** the app starts listening and the control reflects the listening state

#### Scenario: Disabling voice tracking

- **WHEN** the user disables voice tracking
- **THEN** audio capture stops immediately and playback returns to manual control

#### Scenario: No active script

- **WHEN** the user turns on voice tracking and no script is active, or the active script has no readable text
- **THEN** the control responds, no audio is captured, and the app states that a script must be picked first and offers a way to open the library

#### Scenario: Freshly installed app

- **WHEN** the user turns on voice tracking as the first action after installing and launching the app
- **THEN** the control responds with a visible state change — listening, a labeled progress state, or a stated reason — and never appears inert

### Requirement: Speech recognition runs entirely on-device

Speech SHALL be transcribed exclusively with on-device recognition. The app SHALL NOT send audio or transcripts over any network, and SHALL NOT persist audio or transcripts. If no on-device model is available for the system language, the feature SHALL report itself unavailable instead of using a server. Obtaining an on-device model from the system SHALL be reported as its own state while it is in progress.

#### Scenario: On-device model missing

- **WHEN** the user enables voice tracking and the on-device model for the system language is not installed and cannot be obtained
- **THEN** the app shows that voice tracking is unavailable for that language and does not capture audio

#### Scenario: On-device model is being installed

- **WHEN** enabling voice tracking requires the system to install the speech model for the current language
- **THEN** the app shows a labeled progress state naming the download while it runs, and starts listening when it completes

### Requirement: Voice tracking runs inside the app sandbox without temporary exceptions

Voice tracking SHALL function with the App Sandbox enabled using only `com.apple.security.app-sandbox` and `com.apple.security.device.audio-input`. The app SHALL NOT ship any `com.apple.security.temporary-exception.*` entitlement.

#### Scenario: Sandboxed release build

- **WHEN** a signed, sandboxed Release build of the app is launched on a Mac and voice tracking is enabled with a script and microphone permission granted
- **THEN** the app captures audio, transcribes on-device and highlights the read words, with no temporary exception entitlement present in the build

## ADDED Requirements

### Requirement: Activation failures are specific and recoverable

When voice tracking cannot start, the app SHALL report the specific reason — no active script, permission denied, language not supported, speech model unavailable, or audio input failure — and SHALL offer a way to try again for reasons that can be retried. The app SHALL NOT attribute a failure to the language unless the language is the cause.

#### Scenario: Audio input fails

- **WHEN** the audio engine cannot start or no usable input format is available
- **THEN** the app reports an audio input problem, not a language problem, and offers Retry

#### Scenario: Retry after a failure

- **WHEN** the user chooses Retry after a failure and the cause has been resolved
- **THEN** voice tracking starts and reaches the listening state without relaunching the app

### Requirement: Activation is bounded in time

Enabling voice tracking SHALL reach a terminal state — listening or a stated failure — within a bounded time. The app SHALL NOT remain in a progress state indefinitely.

#### Scenario: Model installation stalls

- **WHEN** the speech model installation does not complete within the bounded time
- **THEN** the app leaves the progress state, reports that the speech model could not be obtained, and offers Retry
