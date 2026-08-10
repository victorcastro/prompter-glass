# overlay-window Delta

## MODIFIED Requirements

### Requirement: Overlay position and size persist across launches

The app SHALL save the overlay's frame when it is moved or resized and SHALL restore that frame the next time the overlay is shown, including after a relaunch. Any pending debounced frame save SHALL be flushed when the app terminates, so a move or resize immediately before quitting is never lost.

#### Scenario: Frame restored after relaunch

- **WHEN** the user moves and resizes the overlay, quits the app, and relaunches it
- **THEN** the overlay is shown at the same position and size

#### Scenario: Overlay appears directly at its restored frame

- **WHEN** the overlay is shown at launch with a saved frame
- **THEN** it appears at that frame without first appearing elsewhere and jumping

#### Scenario: Saved frame is off-screen

- **WHEN** the app launches and the saved frame does not intersect any connected display
- **THEN** the app discards the saved frame and shows the overlay centered on the main display at the default size

#### Scenario: First launch with no saved frame

- **WHEN** the overlay is shown for the first time and no frame has been saved
- **THEN** the app shows the overlay at its default size of 800 by 600 points, docked to the top of the main display and centred horizontally

#### Scenario: First launch on a very wide display

- **WHEN** the overlay is shown for the first time on an ultrawide display
- **THEN** the default size stays 800 by 600 rather than scaling with the screen, so the overlay does not open far wider than a readable column

#### Scenario: Quit within the save debounce window

- **WHEN** the user moves or resizes the overlay and quits the app before the debounced save fires
- **THEN** the final frame is persisted during termination and restored on the next launch

## ADDED Requirements

### Requirement: Overlay tears down on app termination

The app SHALL run the overlay teardown path when the application terminates, releasing the overlay window and emitting the display-view-cleared callback exactly once.

#### Scenario: App quits with overlay visible

- **WHEN** the app terminates while the overlay is visible
- **THEN** overlay teardown runs, the pending frame save is flushed, and the display-view-cleared callback fires exactly once
