# Design: harden-audit-fixes

## Context

A code audit of the teleprompter MVP surfaced defects in three areas:

1. **Playback lifecycle.** `CADisplayLink` retains its `target` strongly. `DisplayLinkDriver` passes `self` as target and stores the link, forming a retain cycle while the link is active; the `deinit` that would invalidate the link can never run while the cycle exists. Separately, when the link is created against the overlay's `NSHostingView` and that view is destroyed (overlay torn down mid-playback), ticks stop but `isRunning` still reports `true`.
2. **Teardown and persistence.** `OverlayPresenter.tearDown()` exists but no production code path calls it. The overlay frame save is debounced by 300 ms in `OverlayWindowController.scheduleFrameSave()`, so a move/resize followed by quit within the debounce window loses the frame.
3. **Persistence robustness.** `ScriptEditorView.onDisappear` commits pending edits into its `Script` model object even when the disappearance was caused by deleting that script, writing into a deleted SwiftData object. `PrompterGlassApp.makeModelContainer` calls `fatalError` when the store cannot be opened, so a corrupt store bricks the app.

Process gaps: CI runs lint/format/sanity on Ubuntu only — the Swift code is never compiled and no tests run on PRs; `xcuserdata` is tracked in git; actions are pinned by tag, not SHA; `ENABLE_USER_SCRIPT_SANDBOXING = NO`; script-row accessibility identifiers are derived from mutable, non-unique titles.

## Goals / Non-Goals

**Goals**

- Deterministic deallocation of the display-link driver; running state that always reflects reality.
- Overlay frame persisted on every quit path, including quits inside the debounce window.
- No writes to deleted SwiftData objects; app launches even with a corrupt store.
- CI compiles the app and runs the test suites on macOS.

**Non-Goals**

- No behavioral changes to playback, editing, or the overlay UX.
- No store migration work — recovery for an unreadable store is destroy-and-recreate, nothing more.
- No Swift 6 language-mode migration; only the `ScrollPlaybackEngine` actor isolation is addressed.

## Decisions

### D1: Weak-target proxy for CADisplayLink

`DisplayLinkDriver` gains a private `final class WeakTickTarget` that holds `weak var driver` and exposes the `@objc` tick selector, forwarding to the driver. The link retains the proxy, the proxy holds the driver weakly, so the cycle is broken and `deinit { displayLink?.invalidate() }` becomes reachable and effective.

*Alternative considered:* requiring callers to always call `stop()` before release. Rejected — that is the current implicit contract and it is exactly what the audit showed nobody upholds; ownership-based correctness beats convention.

### D2: Re-arm the link when the source view dies

`WeakTickTarget` forwarding plus a check in `tick`: if the link was created from a view (`source()` returned non-nil at `start()`) and `source()` now returns `nil`, the driver invalidates the current link and restarts against `NSScreen.main`, preserving playback. If restart fails, it transitions to stopped so `isRunning` is truthful.

*Alternative considered:* observing `NSView` window/superview changes. Rejected — more moving parts for the same guarantee; the tick callback is already a natural heartbeat.

### D3: Teardown and frame flush on app termination

`PrompterGlassApp` observes `NSApplication.willTerminateNotification` (via `NotificationCenter` in `AppEnvironment` or the App's scene phase equivalent) and calls `overlay.tearDown()`. `OverlayWindowController.tearDown()` already cancels `saveTask` and calls `persistFrame()` synchronously — that existing code becomes the flush path. The duplicate `onDisplayViewChange?(nil)` is removed from `OverlayPresenter.tearDown()` (the controller already emits it).

*Alternative considered:* `NSApplicationDelegateAdaptor` with `applicationWillTerminate`. Acceptable, but a notification observer inside `AppEnvironment` keeps the SwiftUI `App` free of AppKit delegate scaffolding and is unit-testable by posting the notification.

### D4: Deletion-safe editor commit

`ScriptEditorView.commit()` guards on the model's liveness before writing: `script.modelContext != nil && !script.isDeleted`. `MainWindowView.delete(_:)` already nils the selection before `modelContext.delete(script)`; the guard makes the subsequent `onDisappear` commit a no-op instead of a write into a deleted object.

*Alternative considered:* cancelling the commit from the delete path via a callback. Rejected — the editor owns its save lifecycle; a local liveness guard is simpler and covers every disappearance path, not just deletion.

### D5: Store recovery instead of fatalError

`makeModelContainer` on catch: log the error, delete the store files at the default `ModelConfiguration` URL (`.store`, `-shm`, `-wal` siblings), retry container creation once. Only if the retry also fails does the app abort — at that point something is wrong beyond data corruption.

*Alternative considered:* renaming the corrupt store aside for later inspection instead of deleting. Nice-to-have; deferred to keep scope tight, and noted in Open Questions.

### D6: `@MainActor` on ScrollPlaybackEngine

Every caller (`ScrollPlaybackController`, `OverlayView`, tests) already runs on the main actor. Annotating the engine removes the theoretical race and pre-clears strict-concurrency adoption. Unit tests get `@MainActor` where needed.

### D7: CI macos job

New `test` job in `pr-main.yml` on `macos-latest` (or newest available runner image compatible with the deployment target): `xcodebuild test -project PrompterGlass.xcodeproj -scheme PrompterGlass -destination 'platform=macOS'`, with UI tests included; if UI tests prove flaky on shared runners, they split into a separate non-required job rather than being deleted. All `uses:` entries across jobs get SHA pins with version comments.

## Risks / Trade-offs

- [CADisplayLink from `NSScreen.main` after view death may run at a different refresh rate than the overlay's display] → acceptable: the engine is time-based (frame-rate independent by spec), so scroll distance is unaffected.
- [Deleting the store on first open failure destroys user scripts] → only reachable when the store is already unreadable (data effectively lost); recovery yields a working app instead of a crash loop. Recreation is attempted exactly once to avoid deleting a healthy store on a transient error.
- [macOS CI runners with a toolchain matching deployment target macOS 26.5 may lag] → pin the runner image and Xcode version explicitly in the job; if unavailable, gate on build + unit tests and mark UI tests continue-on-error until the image catches up.
- [SHA-pinned actions go stale] → version comment next to each pin; optionally Dependabot for actions later.

## Migration Plan

Single PR, no data migration. `git rm --cached PrompterGlass.xcodeproj/xcuserdata -r` lands in the same PR. UI tests that referenced title-based accessibility identifiers are updated to UUID-based identifiers in the same commit that changes the app side, keeping the suite green at every commit.

## Open Questions

- Whether to move the corrupt store aside (timestamped rename) instead of deleting, for post-mortem debugging — deferred, default is delete.
- Exact macOS runner image / Xcode version available on GitHub-hosted runners for the deployment target; resolved when the CI job is written.
