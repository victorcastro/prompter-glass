# script-management Delta

## MODIFIED Requirements

### Requirement: List scripts

The app SHALL present all persisted scripts as a grid of glass cards, ordered by last-modified date with the most recently modified first. Each card SHALL show an icon chip, the script's title, a relative last-modified timestamp, a body preview of up to two lines, and derived metadata: word count and estimated read time.

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
