# Tasks: p02-add-activity-tracking

## 1. Model and recorder

- [ ] 1.1 Create `Features/Activity/PromptSession.swift` (SwiftData model per design D1) and add it to the schema in `App/ModelContainerFactory.swift`
- [ ] 1.2 Expose `confirmedWordCount` on `VoiceTrackingController`, updated alongside `highlightedUTF16Length` from `ScriptAligner.confirmedCount`
- [ ] 1.3 Create `Features/Activity/SessionRecorder.swift`: pure lifecycle state machine (injected clock, on-air accumulation excluding pauses, running-max word count, <5s discard) with unit tests in `PrompterGlassTests/Features/Activity/SessionRecorderTests.swift`
- [ ] 1.4 Wire the recorder into `AppEnvironment` (toggleRolling/stopPlayback/setOverlayVisible/selectScript/didReachEnd/termination) persisting finished drafts as `PromptSession`

## 2. Metrics and export

- [ ] 2.1 Create `Features/Activity/ActivityMetrics.swift` (30-day aggregation per design D4: weighted average wpm, pace bars, time on air, previous-period delta, top-3 scripts, retakes) with unit tests covering every spec scenario
- [ ] 2.2 Create `Features/Activity/ActivityCSV.swift` (header + row per session, ISO-8601 dates, quoted/escaped titles, empty wpm without voice) with unit tests

## 3. Activity section UI

- [ ] 3.1 Add `AppSection.activity` (title, clock icon, `.slate` mood) and its sidebar entry in `SidebarView`
- [ ] 3.2 Create `Features/Activity/ActivitySectionView.swift`: title row with "Last 30 days", three `GlassCard`s (Delivery pace with capsule bar chart, Time on air with delta and top scripts, Retakes avoided with Export button) and empty state; no transport controls
- [ ] 3.3 Hook "Export report" to `NSSavePanel` writing `ActivityCSV` output, and add "Clear activity data" with destructive `confirmationDialog` deleting all sessions
- [ ] 3.4 Add `activity.*` accessibility identifiers and update `PrompterGlassUITests` queries where the new section affects existing flows (do not run UI tests — the user runs them)

## 4. Verification

- [ ] 4.1 Run swiftformat + swiftlint and fix violations
- [ ] 4.2 Run unit tests (`PrompterGlassTests`) and fix failures
- [ ] 4.3 Manual pass against the mockup: record sessions with and without voice, verify cards, delta, export file contents and clear-all flow
