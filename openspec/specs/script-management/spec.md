# script-management Specification

## Purpose
TBD - created by archiving change add-teleprompter-mvp. Update Purpose after archive.
## Requirements
### Requirement: Create a script

The app SHALL allow the user to create a new teleprompter script consisting of a title and a plain-text body.

#### Scenario: Creating a script from the library

- **WHEN** the user triggers "New Script" from the script library
- **THEN** the app creates a script with an empty body and a default title, persists it, and opens it in the editor with the title field focused

#### Scenario: Creating a script with no title entered

- **WHEN** the user creates a script and leaves the title empty
- **THEN** the app persists the script with the default title "Untitled Script" rather than an empty title

### Requirement: Edit a script

The app SHALL allow the user to edit the title and body of an existing script, and SHALL persist the edits without requiring an explicit save action.

#### Scenario: Editing the body

- **WHEN** the user types into the body of an open script and stops typing
- **THEN** the app persists the new body and updates the script's `updatedAt` timestamp

#### Scenario: Edits survive relaunch

- **WHEN** the user edits a script and then quits and relaunches the app
- **THEN** the script list shows the edited title and opening the script shows the edited body

#### Scenario: Editing the active script during playback

- **WHEN** the user edits the body of the script currently shown in the overlay
- **THEN** the overlay reflects the updated text

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

### Requirement: Delete a script

The app SHALL allow the user to delete a script, and SHALL ask for confirmation before deleting.

#### Scenario: Confirmed deletion

- **WHEN** the user deletes a script and confirms the prompt
- **THEN** the script is removed from persistent storage and disappears from the list

#### Scenario: Cancelled deletion

- **WHEN** the user deletes a script and cancels the prompt
- **THEN** the script remains in the list and in persistent storage

#### Scenario: Deleting the script currently in the overlay

- **WHEN** the user deletes the script that is currently displayed in the overlay
- **THEN** playback stops and the overlay shows its empty state instead of the deleted text

### Requirement: Persist scripts with SwiftData

The app SHALL persist scripts locally using SwiftData, and each script SHALL carry a stable unique identifier, a title, a body, a creation timestamp and a last-modified timestamp.

#### Scenario: Scripts survive relaunch

- **WHEN** the user creates scripts and relaunches the app
- **THEN** every script is present with its identifier, title, body and timestamps unchanged

#### Scenario: Identifier is stable across edits

- **WHEN** a script's title and body are edited
- **THEN** the script's unique identifier is unchanged

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

### Requirement: Pending edits never write to a deleted script

An autosave or editor-dismissal commit SHALL NOT write to a script that has been deleted from persistent storage; committing pending edits for a deleted script SHALL be a no-op.

#### Scenario: Deleting the script while its editor has pending edits

- **WHEN** the user edits a script and deletes it before the pending autosave commits
- **THEN** the deletion completes without any write to the deleted script object and without crashing

#### Scenario: Editor dismissed after its script was deleted

- **WHEN** the editor for a script disappears because that script was deleted
- **THEN** the dismissal commit is skipped and the app remains stable

### Requirement: Corrupt persistent store recovers instead of crashing

If the persistent store cannot be opened at launch, the app SHALL recover by recreating an empty store and launching with an empty script library, rather than terminating. Recreation SHALL be attempted only when the store is unreadable, never on a healthy store.

#### Scenario: Store file is corrupt at launch

- **WHEN** the app launches and the SwiftData store cannot be opened
- **THEN** the app recreates an empty store and launches showing an empty script library

#### Scenario: Healthy store at launch

- **WHEN** the app launches and the store opens normally
- **THEN** existing scripts load unchanged and no recovery path runs

### Requirement: Card activation opens the editor

Activating a script card SHALL open that script in the editor within the Library section, and the editor SHALL provide an affordance to return to the card grid.

#### Scenario: Opening a script from its card

- **WHEN** the user clicks a script card
- **THEN** the editor opens showing that script's title and body

#### Scenario: Returning to the grid

- **WHEN** the user activates the editor's back affordance
- **THEN** the card grid is shown again and pending edits are persisted
