# script-management Specification

## ADDED Requirements

### Requirement: A sample script is seeded on first launch

On the first launch of a fresh installation, when the script store is empty, the app SHALL create one sample script so that playback, the overlay and voice tracking are usable immediately. The seed SHALL run at most once per installation and SHALL NOT recreate the sample after the user deletes it. The sample script SHALL be editable and deletable like any other script.

#### Scenario: First launch after install

- **WHEN** the app launches for the first time with an empty script store
- **THEN** one sample script exists and is selectable, and the prompter controls operate on it

#### Scenario: User deletes every script

- **WHEN** the user deletes all scripts, including the sample, and relaunches the app
- **THEN** the library stays empty and the sample is not recreated

#### Scenario: Existing library

- **WHEN** the app launches with scripts already stored
- **THEN** no sample script is created
