# Design: p02-add-activity-tracking

## Context

The app (post p01) has: `ScrollPlaybackEngine` with `.stopped/.playing/.paused` states, `didReachEnd` and voice-driven scrolling; `VoiceTrackingController` wrapping `ScriptAligner` (monotonic `confirmedCount`, currently only surfaced as `highlightedUTF16Length`); `AppEnvironment` orchestrating playback/voice/overlay lifecycle; SwiftData persistence via `ModelContainerFactory` (single `Script` model, corrupt-store recovery); a custom sidebar with `AppSection` (`prompter`, `library`) where `Theme.Mood.slate` is already reserved for this section. Nothing about a run of the prompter is persisted.

User decisions: all playback counts toward time-on-air and retakes; wpm comes only from voice-tracked sessions; CSV export; full retention plus a clear-all button; no Roll orb in this section (already true — the transport lives in `PrompterSectionView`).

## Goals / Non-Goals

**Goals:**
- Persist one `PromptSession` per playback run with enough data to derive every mockup metric.
- Pure, unit-testable aggregation (`ActivityMetrics`) and CSV building.
- "My activity" section matching the mockup with slate mood, three stat cards, export and clear actions.

**Non-Goals:**
- Countdown/mirror (p03), charts framework dependencies, per-day analytics beyond the mockup, iCloud sync, automatic pruning (retention is intentionally unlimited).

## Decisions

### D1 — `PromptSession` SwiftData model
Fields: `id: UUID` (unique), `scriptID: UUID?`, `scriptTitle: String` (snapshot so history survives script deletion/rename), `startedAt: Date`, `onAirSeconds: Double`, `spokenWordCount: Int`, `usedVoiceTracking: Bool`, `reachedEnd: Bool`. Joins the schema in `ModelContainerFactory` next to `Script` (same container, recovery path unchanged). Alternative — separate store for activity — rejected: one container keeps recovery/testing simple and sessions are tiny.

### D2 — `SessionRecorder` as a pure state machine driven by `AppEnvironment`
A struct/final class with no SwiftData knowledge: it receives lifecycle events (`playbackStarted(script:usedVoice:)`, `paused`, `resumed`, `stopped(reachedEnd:)`) and timestamps (injected clock for tests) and yields a finished `SessionDraft` that `AppEnvironment` converts into a persisted `PromptSession`. On-air time accumulates only while playing — pauses excluded. A session opens when the engine leaves `.stopped` (Roll or voice start) and closes on: manual stop, `didReachEnd`, overlay hidden, script switch, or app termination (`prepareForTermination`). Sessions shorter than 5 seconds are discarded as noise. Rationale: `AppEnvironment` already owns every one of those transitions (`toggleRolling`, `stopPlayback`, `setOverlayVisible`, `selectScript`, termination observer), so wiring is localized; the recorder itself stays deterministic and unit-testable.

### D3 — Word count from the aligner
`VoiceTrackingController` gains `private(set) var confirmedWordCount` updated alongside `highlightedUTF16Length` from `ScriptAligner.confirmedCount`. The recorder samples it at session close; `usedVoiceTracking` is true if voice tracking was active at any point during the session. wpm per session = `spokenWordCount / (onAirSeconds / 60)` computed in `ActivityMetrics`, never stored.

### D4 — `ActivityMetrics` pure aggregation
`ActivityMetrics(sessions:now:)` computes, for the trailing 30 days: `averageWPM` (voice sessions only, duration-weighted), `paceBars` (last 12 voice sessions' wpm, oldest first, flagged recent for the iris tint on the newest three), `timeOnAirSeconds`, `deltaSeconds` vs the previous 30-day window, `topScripts` (top 3 by accumulated seconds, using the title snapshot), and `retakesAvoided` (`reachedEnd == true`). Labels reuse `ScriptMetrics.formatted(seconds:)`. All Date math takes an injected `now` so tests are deterministic.

### D5 — CSV export
`ActivityCSV.render(sessions:)` produces a header plus one row per session: ISO-8601 start, script title (quoted/escaped), on-air seconds, spoken words, wpm (empty when not voice-tracked), voice flag, reached-end flag. UI runs `NSSavePanel` (default name `prompter-activity.csv`) and writes UTF-8. Renderer is pure and unit-tested; the panel is thin glue.

### D6 — `ActivitySectionView`
`AppSection.activity` (title "My activity", `clock` icon chip, `.slate` mood — switching sections animates via the existing 400 ms `MoodBackground` transition). Layout mirrors the mockup: title row ("My activity" + "Last 30 days" trailing in `textTertiary`), three `GlassCard`s in an adaptive row — Delivery pace (big iris wpm figure + custom bar chart of `Capsule`s, gray bars with the newest three in iris; no charts dependency), Time on air (large duration, iris delta line with ▲/▼, top-3 script rows), Retakes avoided (large count, caption, "Export report" button) — plus a "Clear activity data" control (destructive, `confirmationDialog`, deletes all `PromptSession`s). Empty history shows a friendly empty state instead of zeroed cards. No transport/orb in this section. Accessibility identifiers under `activity.*` (`activity.export`, `activity.clear`, `activity.confirmClear`, `activity.pace`, `activity.timeOnAir`, `activity.retakes`); UI tests are updated but executed by the user.

## Risks / Trade-offs

- [Session boundaries drift if a new engine consumer bypasses `AppEnvironment`] → recorder wiring lives only in `AppEnvironment`; design note that new playback entry points must route through it.
- [Unbounded retention grows the store] → sessions are a few hundred bytes; clear-all button is the pressure valve. Revisit pruning only if real usage shows problems.
- [`confirmedWordCount` resets when voice tracking restarts mid-session] → recorder keeps a running maximum per session instead of trusting the last sample.
- [Delta misleading when the previous window has no data] → delta hidden unless the previous 30-day window contains at least one session.
- [Archive ordering: the `prompter-home` MODIFIED delta targets a spec still living inside unarchived p01] → archive p01 before applying/archiving p02.

## Migration Plan

Additive schema change (new model) — SwiftData lightweight migration handles it; existing stores open unchanged. Rollback = revert branch; sessions table is ignored by older builds.

## Open Questions

- None blocking. Bar-chart bucket choice (per-session vs per-day) fixed as per-session to match the mockup's irregular bars.
