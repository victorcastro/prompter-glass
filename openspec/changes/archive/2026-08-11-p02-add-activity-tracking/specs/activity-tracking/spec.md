# activity-tracking Delta

## ADDED Requirements

### Requirement: Record a session per playback run

The app SHALL record one activity session per playback run, capturing the script identity and title snapshot, the start time, the accumulated on-air time excluding pauses, whether voice tracking was used, the confirmed spoken-word count, and whether the scroll reached the end of the script. A session SHALL open when playback leaves the stopped state and SHALL close on manual stop, on reaching the end, on hiding the overlay, on switching the active script, or on app termination. Sessions shorter than 5 seconds SHALL be discarded.

#### Scenario: Rolling to the end without stopping

- **WHEN** the user rolls a script and the scroll reaches the end without a manual stop
- **THEN** a session is recorded with the script's title, the accumulated on-air time and the reached-end flag set

#### Scenario: Pauses do not count as on-air time

- **WHEN** the user pauses playback for a while and then resumes and stops
- **THEN** the recorded on-air time covers only the time actually playing

#### Scenario: Hiding the overlay mid-run

- **WHEN** the user hides the overlay while playback is running
- **THEN** the session closes at that moment without the reached-end flag

#### Scenario: Very short run

- **WHEN** a playback run lasts less than 5 seconds
- **THEN** no session is recorded

### Requirement: Sessions persist across launches

Activity sessions SHALL be persisted locally with SwiftData in the same store as scripts and SHALL be retained indefinitely, surviving app relaunches and deletion or renaming of the originating script.

#### Scenario: History survives relaunch

- **WHEN** the user records sessions, quits and relaunches the app
- **THEN** the activity section shows the same history

#### Scenario: History survives script deletion

- **WHEN** the user deletes a script that has recorded sessions
- **THEN** those sessions remain in the history under the script's snapshotted title

### Requirement: Thirty-day activity metrics

The activity section SHALL aggregate sessions from the trailing 30 days into: an average delivery pace in words per minute computed only from voice-tracked sessions, a per-session pace bar chart, the total time on air, a delta of time on air versus the previous 30-day period shown only when that period has data, a top-3 breakdown of scripts by accumulated time, and a count of retakes avoided (sessions that reached the end of the script).

#### Scenario: Average pace from voice sessions only

- **WHEN** the last 30 days contain sessions with and without voice tracking
- **THEN** the average wpm reflects only the voice-tracked sessions while time on air includes all sessions

#### Scenario: Delta against the previous period

- **WHEN** both the current and the previous 30-day windows contain sessions
- **THEN** the time-on-air card shows the signed difference between the two windows

#### Scenario: No previous-period data

- **WHEN** the previous 30-day window has no sessions
- **THEN** no delta is shown

#### Scenario: Retakes avoided

- **WHEN** three sessions in the window reached the end of their script without a manual stop
- **THEN** the retakes-avoided card shows 3

#### Scenario: Empty history

- **WHEN** no sessions exist
- **THEN** the section shows an empty state inviting the user to roll a script instead of zeroed cards

### Requirement: Export the activity report as CSV

The app SHALL export the recorded sessions as a CSV file chosen through a save panel, with a header row and one row per session containing the ISO-8601 start time, script title, on-air seconds, spoken words, words per minute (empty for sessions without voice tracking), a voice-tracking flag and a reached-end flag.

#### Scenario: Exporting the report

- **WHEN** the user activates "Export report" and confirms a destination
- **THEN** a CSV file is written with one row per recorded session

#### Scenario: Titles with commas or quotes

- **WHEN** a session's script title contains commas or quotation marks
- **THEN** the CSV escapes the title so the file stays parseable

### Requirement: Clear all activity data

The app SHALL provide a destructive action that deletes every recorded session after an explicit confirmation, and cancelling the confirmation SHALL leave the history untouched.

#### Scenario: Confirmed clearing

- **WHEN** the user activates the clear action and confirms
- **THEN** all sessions are deleted and the section shows its empty state

#### Scenario: Cancelled clearing

- **WHEN** the user activates the clear action and cancels
- **THEN** the history remains unchanged
