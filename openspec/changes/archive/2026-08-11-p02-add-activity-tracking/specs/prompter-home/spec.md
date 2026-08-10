# prompter-home Delta

## MODIFIED Requirements

### Requirement: Custom sidebar navigation

The main window SHALL present a custom sidebar with Prompter, Library and My activity sections, each shown as an icon chip plus label, with the active section highlighted. Activating My activity SHALL switch the window to the slate mood background. The sidebar SHALL include an "Overlay visible" card at the bottom with the global shortcut hint and a toggle bound to overlay visibility. The last visible section SHALL be restored on the next launch.

#### Scenario: Switching sections

- **WHEN** the user clicks the Library item in the sidebar
- **THEN** the Library section becomes visible and its sidebar item is highlighted as active

#### Scenario: Opening My activity

- **WHEN** the user clicks the My activity item in the sidebar
- **THEN** the activity section becomes visible with the slate mood background and no Roll orb

#### Scenario: Toggling overlay from the sidebar card

- **WHEN** the user flips the toggle in the "Overlay visible" card
- **THEN** the overlay window shows or hides, matching the toggle state

#### Scenario: Section restored on launch

- **WHEN** the user quits while viewing Library and relaunches the app
- **THEN** the Library section is visible
