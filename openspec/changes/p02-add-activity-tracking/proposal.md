# Proposal: p02-add-activity-tracking

## Why

The p01 glass redesign implements two of the three sections in the reference design; "My activity" is missing because the app records nothing — playback and voice tracking state live in memory and vanish on quit. Users rehearsing scripts have no way to see their delivery pace, how much time they have spent on air, or how often they finished a take without stopping.

## What Changes

- Record a session for every playback run: which script, when it started, accumulated on-air time (pauses excluded), whether voice tracking was used, how many words were confirmed spoken, and whether the scroll reached the end without a manual stop.
- Persist sessions with SwiftData alongside scripts, retained indefinitely so month-over-month comparisons are possible.
- Add a "My activity" section (slate mood, no Roll orb) with three stat cards over the last 30 days: delivery pace (average wpm from voice-tracked sessions plus a per-session bar chart), time on air (total, delta vs the previous 30 days, top scripts breakdown), and retakes avoided (sessions that reached the end without stopping).
- Export the report as CSV via a save panel (one row per session).
- Provide a destructive "clear all activity data" action with confirmation.
- Expose the confirmed-word count from voice tracking so sessions can compute real wpm.

## Capabilities

### New Capabilities

- `activity-tracking`: session recording during playback, persisted activity history, 30-day aggregated metrics with previous-period delta, CSV export and full data clearing.

### Modified Capabilities

- `prompter-home`: the custom sidebar gains a third "My activity" section with its own slate mood.

## Impact

- New `Features/Activity/` group: `PromptSession` model, `SessionRecorder`, `ActivityMetrics`, CSV builder, `ActivitySectionView`.
- `App/ModelContainerFactory.swift`: `PromptSession` joins the SwiftData schema.
- `App/AppEnvironment.swift`: owns the recorder and feeds it playback/voice/overlay lifecycle events.
- `Features/VoiceTracking/VoiceTrackingController.swift`: exposes `confirmedWordCount`.
- `MainWindow/AppSection.swift`, `MainWindow/SidebarView.swift`: third section entry.
- No changes to overlay behavior or existing preferences.
