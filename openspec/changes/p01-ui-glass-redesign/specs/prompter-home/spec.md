# prompter-home Delta

## ADDED Requirements

### Requirement: Custom sidebar navigation

The main window SHALL present a custom sidebar with Prompter and Library sections, each shown as an icon chip plus label, with the active section highlighted. The sidebar SHALL include an "Overlay visible" card at the bottom with the global shortcut hint and a toggle bound to overlay visibility. The last visible section SHALL be restored on the next launch.

#### Scenario: Switching sections

- **WHEN** the user clicks the Library item in the sidebar
- **THEN** the Library section becomes visible and its sidebar item is highlighted as active

#### Scenario: Toggling overlay from the sidebar card

- **WHEN** the user flips the toggle in the "Overlay visible" card
- **THEN** the overlay window shows or hides, matching the toggle state

#### Scenario: Section restored on launch

- **WHEN** the user quits while viewing Library and relaunches the app
- **THEN** the Library section is visible

### Requirement: Active script hero

The Prompter section SHALL show the active script's title, word count and an estimated on-air duration derived from the word count. When no script is active it SHALL show an empty state prompting the user to pick a script from the Library.

#### Scenario: Active script summary

- **WHEN** a script with 104 words is active and the user opens the Prompter section
- **THEN** the section shows the script title, "104 words" and an estimated on-air duration

#### Scenario: No active script

- **WHEN** no script is active and the user opens the Prompter section
- **THEN** an empty state directs the user to the Library

### Requirement: Feature status rows

The Prompter section SHALL list feature rows for voice tracking and click-through, each with an icon chip, the feature name and its current state, and interacting with a row SHALL toggle that feature where applicable.

#### Scenario: Voice tracking row reflects state

- **WHEN** voice tracking is active
- **THEN** the voice tracking row shows the amber icon chip and an active state description

### Requirement: Playback controls in the Prompter section

The Prompter section SHALL host the playback controls: a slider bar with speed, text size and backdrop opacity (each showing its current value), and a Roll orb as the primary control that starts scrolling when idle and pauses it when rolling. A stop control SHALL remain available while playback can be stopped. Microphone selection, overlay size and text color SHALL remain reachable from this section.

#### Scenario: Rolling from the orb

- **WHEN** a script with content is active and the user activates the Roll orb
- **THEN** overlay scrolling starts and the orb reflects the rolling state

#### Scenario: Pausing from the orb

- **WHEN** playback is rolling and the user activates the Roll orb
- **THEN** scrolling pauses

#### Scenario: Adjusting a slider

- **WHEN** the user drags the speed slider
- **THEN** the displayed value updates and the overlay scroll speed changes immediately
