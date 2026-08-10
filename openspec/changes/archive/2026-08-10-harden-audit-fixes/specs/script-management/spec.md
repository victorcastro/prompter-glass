# script-management Delta

## ADDED Requirements

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
