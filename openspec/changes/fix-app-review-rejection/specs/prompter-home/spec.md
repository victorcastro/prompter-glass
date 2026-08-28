# prompter-home Specification

## MODIFIED Requirements

### Requirement: Feature status rows

The Prompter section SHALL list feature rows for voice tracking and click-through, each with an icon chip, the feature name and its current state, and interacting with a row SHALL toggle that feature where applicable. Feature rows SHALL NOT be presented as disabled controls; when a feature cannot start, the row SHALL remain interactive and the section SHALL show the reason together with the action that resolves it.

#### Scenario: Voice tracking row reflects state

- **WHEN** voice tracking is active
- **THEN** the voice tracking row shows the amber icon chip and an active state description

#### Scenario: Voice tracking row with an empty library

- **WHEN** no script is active and the user interacts with the voice tracking row
- **THEN** the row responds, the section states that a script must be picked first, and a control opens the script library

#### Scenario: Voice tracking row while the speech model installs

- **WHEN** the speech model for the current language is being installed
- **THEN** the section shows a labeled progress row naming what is being downloaded, instead of an unlabeled spinner
