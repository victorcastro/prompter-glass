# script-management Delta

## MODIFIED Requirements

### Requirement: Select the active script

The app SHALL let the user designate one script as the active script, which is the script rendered in the overlay window, and SHALL restore the active selection on the next launch. Each library card SHALL expose a selector control that marks its script as active without opening the editor, and the selector SHALL visually indicate which script is currently active.

#### Scenario: Selecting an active script

- **WHEN** the user selects a script and sends it to the overlay
- **THEN** the overlay renders that script's body from the beginning

#### Scenario: Selecting from a card's selector

- **WHEN** the user clicks the selector on a script card
- **THEN** that script becomes the active script, its selector shows the active state, and the editor does not open

#### Scenario: Active selection restored on launch

- **WHEN** the user quits with a script active and relaunches the app
- **THEN** the same script is active again

#### Scenario: Previously active script no longer exists

- **WHEN** the app launches and the previously active script has been deleted
- **THEN** no script is active and the overlay shows its empty state

### Requirement: List scripts

The app SHALL present all persisted scripts as a grid of glass cards, ordered by last-modified date with the most recently modified first. Each card SHALL show an active-script selector, the script's title, a relative last-modified timestamp, a body preview of up to two lines, and derived metadata: word count and estimated read time.

#### Scenario: Listing existing scripts

- **WHEN** the user opens the script library with three saved scripts
- **THEN** three cards are shown with title, relative timestamp, body preview, word count and read time, most recently modified first

#### Scenario: Empty library

- **WHEN** the user opens the script library and no scripts exist
- **THEN** the app shows an empty-state message with an action to create the first script

#### Scenario: Metadata reflects the body

- **WHEN** a script's body contains 104 words
- **THEN** its card shows "104 words" and a read time of at least one minute

## ADDED Requirements

### Requirement: Card activation opens the editor

Activating a script card SHALL open that script in the editor within the Library section, and the editor SHALL provide an affordance to return to the card grid.

#### Scenario: Opening a script from its card

- **WHEN** the user clicks a script card
- **THEN** the editor opens showing that script's title and body

#### Scenario: Returning to the grid

- **WHEN** the user activates the editor's back affordance
- **THEN** the card grid is shown again and pending edits are persisted
