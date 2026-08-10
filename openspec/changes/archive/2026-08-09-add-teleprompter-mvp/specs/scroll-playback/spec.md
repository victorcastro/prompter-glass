## ADDED Requirements

### Requirement: Start scrolling

The app SHALL allow the user to start automatic scrolling of the active script in the overlay, and scrolling SHALL begin from the top of the script when started from the stopped state.

#### Scenario: Starting from stopped

- **WHEN** playback is stopped and the user starts scrolling
- **THEN** the script scrolls upward continuously from its first line at the configured speed

#### Scenario: Starting with no active script

- **WHEN** no script is active and the user starts scrolling
- **THEN** playback does not start and the overlay keeps showing its empty state

### Requirement: Pause and resume scrolling

The app SHALL allow the user to pause scrolling, which freezes the script at its current position, and to resume from exactly that position.

#### Scenario: Pausing

- **WHEN** the script is scrolling and the user pauses
- **THEN** the script stops moving and stays at its current position

#### Scenario: Resuming

- **WHEN** playback is paused and the user resumes
- **THEN** scrolling continues from the position where it was paused, not from the top

### Requirement: Stop scrolling

The app SHALL allow the user to stop scrolling, which halts movement and returns the script to its first line.

#### Scenario: Stopping while playing

- **WHEN** the script is scrolling and the user stops playback
- **THEN** scrolling halts and the script is shown from its first line again

#### Scenario: Stopping while paused

- **WHEN** playback is paused and the user stops it
- **THEN** the script is shown from its first line again and remains stationary

### Requirement: Scrolling stops at the end of the script

Scrolling SHALL stop automatically when the end of the script reaches the bottom of the visible area, without scrolling past the content.

#### Scenario: Reaching the end

- **WHEN** the last line of the script has scrolled into view and scrolling would move past it
- **THEN** scrolling stops automatically and the last line remains visible

### Requirement: Adjustable scroll speed

The app SHALL let the user adjust the scroll speed within a defined range, SHALL apply a speed change immediately including while scrolling, and SHALL persist the chosen speed across launches.

#### Scenario: Increasing speed while scrolling

- **WHEN** the script is scrolling and the user increases the scroll speed
- **THEN** the script immediately scrolls faster from its current position, with no jump in position

#### Scenario: Speed is clamped to the supported range

- **WHEN** the user attempts to set a speed outside the supported range
- **THEN** the speed is clamped to the nearest supported value

#### Scenario: Speed persists across launches

- **WHEN** the user sets a scroll speed, quits the app and relaunches it
- **THEN** the same scroll speed is in effect

### Requirement: Scroll speed is frame-rate independent

The distance the script scrolls SHALL depend on elapsed time rather than on the number of rendered frames, so that dropped frames do not slow the scroll down.

#### Scenario: Frames are dropped during playback

- **WHEN** the system drops rendered frames while the script is scrolling
- **THEN** the script has advanced by the same distance after a given elapsed time as it would have without dropped frames

### Requirement: Adjustable font size

The app SHALL let the user adjust the font size of the script in the overlay within a defined range, SHALL apply the change immediately, and SHALL persist the chosen size across launches.

#### Scenario: Changing font size

- **WHEN** the user increases the font size
- **THEN** the overlay text is rendered larger and reflows to the overlay width immediately

#### Scenario: Changing font size while scrolling

- **WHEN** the user changes the font size while the script is scrolling
- **THEN** scrolling continues without stopping and the reading position remains on the same passage of text

#### Scenario: Font size persists across launches

- **WHEN** the user sets a font size, quits the app and relaunches it
- **THEN** the overlay renders the script at the same font size
