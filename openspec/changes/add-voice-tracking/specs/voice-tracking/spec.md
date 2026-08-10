# voice-tracking Specification

## ADDED Requirements

### Requirement: Voice tracking can be toggled from the control panel

The app SHALL provide a control to enable and disable voice tracking. While enabled, the app SHALL capture the microphone and transcribe speech; while disabled, the microphone SHALL NOT be captured.

#### Scenario: Enabling voice tracking

- **WHEN** the user enables voice tracking with an active script and permissions granted
- **THEN** the app starts listening and the control reflects the listening state

#### Scenario: Disabling voice tracking

- **WHEN** the user disables voice tracking
- **THEN** audio capture stops immediately and playback returns to manual control

### Requirement: Speech recognition runs entirely on-device

Speech SHALL be transcribed exclusively with on-device recognition. The app SHALL NOT send audio or transcripts over any network, and SHALL NOT persist audio or transcripts. If no on-device model is available for the system language, the feature SHALL report itself unavailable instead of using a server.

#### Scenario: On-device model missing

- **WHEN** the user enables voice tracking and the on-device model for the system language is not installed and cannot be obtained
- **THEN** the app shows that voice tracking is unavailable for that language and does not capture audio

### Requirement: Read words are highlighted in the overlay

While voice tracking is active, words of the script that have been read aloud SHALL be rendered in yellow in the overlay, and words not yet read SHALL keep the configured text color.

#### Scenario: Presenter reads the script

- **WHEN** the presenter reads words of the active script aloud
- **THEN** those words turn yellow in the overlay as they are recognized, in script order

#### Scenario: Recognition noise does not jump the highlight

- **WHEN** the recognizer produces words that do not match the upcoming script text
- **THEN** the highlight stays at the last confirmed position instead of jumping ahead

### Requirement: The overlay follows the reading position

While voice tracking is active, the overlay SHALL scroll automatically so the current reading position stays visible, without requiring the fixed-speed playback controls.

#### Scenario: Presenter advances through the script

- **WHEN** the highlighted position approaches the lower part of the visible area
- **THEN** the overlay scrolls smoothly so the reading position returns to a comfortable zone

#### Scenario: Voice tracking turned off mid-script

- **WHEN** the user disables voice tracking after part of the script has been read
- **THEN** the overlay stops following the voice and the manual playback controls behave as in fixed-speed mode

### Requirement: Microphone permission is requested and denial is surfaced

The first activation SHALL request microphone and speech-recognition permission. If permission is denied, the app SHALL show a clear non-listening state with a way to open System Settings, and SHALL NOT capture audio.

#### Scenario: First activation

- **WHEN** the user enables voice tracking for the first time
- **THEN** the system permission prompts appear before any audio is processed

#### Scenario: Permission denied

- **WHEN** microphone permission is denied and the user enables voice tracking
- **THEN** the control shows a denied state with a shortcut to System Settings and no audio is captured
