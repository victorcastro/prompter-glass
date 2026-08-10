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

The app SHALL present a list of all persisted scripts, showing each script's title and last-modified date, ordered by last-modified date with the most recently modified first.

#### Scenario: Listing existing scripts

- **WHEN** the user opens the script library with three saved scripts
- **THEN** all three scripts are listed with their titles and last-modified dates, most recently modified first

#### Scenario: Empty library

- **WHEN** the user opens the script library and no scripts exist
- **THEN** the app shows an empty-state message with an action to create the first script

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

The app SHALL let the user designate one script as the active script, which is the script rendered in the overlay window, and SHALL restore the active selection on the next launch.

#### Scenario: Selecting an active script

- **WHEN** the user selects a script and sends it to the overlay
- **THEN** the overlay renders that script's body from the beginning

#### Scenario: Active selection restored on launch

- **WHEN** the user quits with a script active and relaunches the app
- **THEN** the same script is active again

#### Scenario: Previously active script no longer exists

- **WHEN** the app launches and the previously active script has been deleted
- **THEN** no script is active and the overlay shows its empty state

