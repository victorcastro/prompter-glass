# Tasks: harden-audit-fixes

## 1. Playback display link lifecycle

- [x] 1.1 Add weak-target proxy inside DisplayLinkDriver so CADisplayLink no longer retains the driver; keep invalidate in deinit
- [x] 1.2 Detect dead source view in the tick path and re-arm the link from NSScreen.main, transitioning to stopped if re-arm fails
- [x] 1.3 Unit tests: driver deallocates while running (weak reference goes nil, no further ticks); isRunning consistency when source returns nil

## 2. Overlay teardown and frame flush on termination

- [x] 2.1 Observe NSApplication.willTerminateNotification in AppEnvironment and call overlay.tearDown()
- [x] 2.2 Remove duplicate onDisplayViewChange(nil) from OverlayPresenter.tearDown (controller already emits it)
- [x] 2.3 Unit tests: posting the termination notification tears down the overlay, flushes the pending frame save, and fires the display-view-cleared callback exactly once

## 3. Deletion-safe editor commit

- [x] 3.1 Guard ScriptEditorView.commit() on script liveness (modelContext != nil && !isDeleted)
- [x] 3.2 Unit test: apply/commit on a deleted Script is a no-op and does not crash

## 4. Store recovery at launch

- [x] 4.1 Replace fatalError in makeModelContainer with destroy-and-recreate recovery (single retry; abort only if retry fails)
- [x] 4.2 Unit test: container creation recovers from an unreadable store file and yields an empty, working container

## 5. Concurrency isolation

- [x] 5.1 Annotate ScrollPlaybackEngine with @MainActor and adjust tests/callers as needed
- [x] 5.2 Build with strict concurrency checks enabled locally to confirm no new warnings in touched files

## 6. CI and repo hygiene

- [x] 6.1 CI stays Linux-only by owner decision: the macos xcodebuild job was added, then removed; tests run locally before merging
- [x] 6.2 Actions pinned by version tag (@v5) by owner decision; SHA pinning was applied and then reverted
- [x] 6.3 Remove tracked xcuserdata from the git index (git rm --cached -r)
- [x] 6.4 ENABLE_USER_SCRIPT_SANDBOXING stays NO: the SwiftLint run-script build phase must read .swiftlint.yml and all sources, which the script sandbox forbids (verified: YES breaks the build)

## 7. Accessibility identifier hardening

- [x] 7.1 Replace title-derived script-row accessibility identifiers with static identifiers (library.rowTitle / library.rowDate) in ScriptLibraryView
- [x] 7.2 Update UI tests to resolve rows by static identifier plus label matching

## 8. Verification

- [x] 8.1 Run full unit and UI test suites locally; all green
- [x] 8.2 SwiftLint --strict and SwiftFormat --lint pass on touched files
