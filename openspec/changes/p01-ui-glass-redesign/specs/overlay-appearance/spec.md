# overlay-appearance Delta

## MODIFIED Requirements

### Requirement: Adjustable text color

The app SHALL let the user choose the color of the overlay's unspoken script text, SHALL apply the change immediately, and SHALL persist the chosen color across launches. The chosen color SHALL render the current reading zone at full opacity and the upcoming text dimmed, and SHALL NOT affect the spoken-text highlight color.

#### Scenario: Choosing a text color

- **WHEN** the user picks a text color
- **THEN** the overlay renders the current reading zone in that color immediately and the upcoming text in a dimmed variant of it

#### Scenario: Text color persists across launches

- **WHEN** the user picks a text color, quits the app and relaunches it
- **THEN** the overlay renders the script in the same color

#### Scenario: Stored color cannot be read

- **WHEN** the app launches and the stored text color is missing or unreadable
- **THEN** the overlay falls back to the default text color instead of failing to render

## ADDED Requirements

### Requirement: Neutral gray backdrop

The overlay background SHALL be a neutral gray surface whose opacity the user controls, replacing the pure black backdrop, with rounded corners.

#### Scenario: Backdrop at mid opacity

- **WHEN** the background opacity is set to a mid value
- **THEN** the overlay draws a translucent gray backdrop through which the content behind remains recognizable

### Requirement: Overlay status bar

The overlay SHALL show a top status bar containing: a playback state pill reading "Paused" or "Rolling", an amber voice pill visible only while voice tracking is active, a meta line with the current scroll speed, estimated time left and "click-through" when click-through is enabled, and a drag-handle affordance.

#### Scenario: Paused with voice ready

- **WHEN** playback is paused and voice tracking is active
- **THEN** the status bar shows the "Paused" pill and the amber voice pill

#### Scenario: Voice tracking off

- **WHEN** voice tracking is not active
- **THEN** no voice pill is shown in the status bar

#### Scenario: Time left updates while rolling

- **WHEN** playback is rolling
- **THEN** the meta line's time-left value decreases as the script scrolls

### Requirement: Reading guide line

The overlay SHALL draw a subtle horizontal guide line at a fixed reading height in the upper-middle of the viewport, indicating where the current line of the script sits while scrolling.

#### Scenario: Guide visible over the backdrop

- **WHEN** the overlay shows a script
- **THEN** a thin horizontal guide line is visible across the overlay at the reading height, beneath the text

### Requirement: Three-state script text hierarchy

The overlay SHALL render script text in three visual states: text already spoken in the amber highlight with a soft glow, the current reading zone in the full-opacity text color, and upcoming text dimmed. Without voice tracking, no spoken state is shown and the current/upcoming states still apply relative to the guide line.

#### Scenario: Voice tracking highlights spoken text

- **WHEN** voice tracking confirms words have been spoken
- **THEN** those words render in amber with a glow, the current zone renders at full opacity, and text further down renders dimmed

#### Scenario: No voice tracking

- **WHEN** voice tracking is inactive during playback
- **THEN** the text at the guide line renders at full opacity and text further down renders dimmed, with no amber highlight
