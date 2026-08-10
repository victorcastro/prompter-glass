# Proposal: harden-audit-fixes

## Why

A software audit of the teleprompter MVP found memory-lifecycle defects (a CADisplayLink retain cycle, overlay teardown that is never invoked, an autosave commit racing script deletion) and robustness gaps (a fatal crash on SwiftData store corruption, CI that never compiles or tests the app). These are latent crashes and leaks in the core playback and persistence paths and should be fixed before building further features on top of them.

## What Changes

- Break the CADisplayLink retain cycle in `DisplayLinkDriver` (weak-target proxy or equivalent) so the driver deallocates deterministically, and re-arm the link when its source view dies so `isRunning` never lies.
- Invoke overlay teardown on app termination and flush the debounced overlay-frame save, so the last window position/size always persists across quits.
- Guard `ScriptEditorView` autosave/commit so it never writes to a `Script` that was deleted from the model context.
- Remove the duplicate `onDisplayViewChange(nil)` callback fired by both `OverlayPresenter.tearDown` and `OverlayWindowController.tearDown`.
- Replace the `fatalError` on `ModelContainer` creation with recovery: destroy the corrupt store and recreate it, launching with an empty library instead of crashing.
- Isolate `ScrollPlaybackEngine` to `@MainActor`, matching its callers and eliminating the theoretical data race.
- Add a `macos` CI job running `xcodebuild test` so unit and UI tests actually gate PRs.
- Repo/CI hygiene: remove tracked `xcuserdata` from the git index, pin GitHub Actions by SHA, set `ENABLE_USER_SCRIPT_SANDBOXING = YES`, derive script-row accessibility identifiers from the script UUID instead of its title.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `scroll-playback`: playback resources (display link) SHALL be released deterministically when playback stops or the overlay closes; the driver's running state SHALL stay consistent when the source view disappears mid-playback.
- `overlay-window`: the overlay frame SHALL persist across app quit even when the quit happens within the save-debounce window; overlay teardown SHALL run at app termination.
- `script-management`: deleting the active script SHALL never result in a write to the deleted model object; a corrupt persistent store SHALL be recovered (recreated empty) instead of crashing the app at launch.

## Impact

- **Code**: `DisplayLinkDriver`, `ScrollPlaybackController`, `ScrollPlaybackEngine`, `OverlayPresenter`, `OverlayWindowController`, `ScriptEditorView`, `MainWindowView`, `PrompterGlassApp`, `ScriptLibraryView` (accessibility IDs).
- **Tests**: new unit tests for driver lifecycle, teardown-on-terminate, deleted-script commit guard, store recovery; UI test identifiers migrate from title-based to UUID-based.
- **CI**: `.github/workflows/pr-main.yml` gains a `macos` build+test job; existing jobs get SHA-pinned actions.
- **Repo**: `git rm --cached` on `PrompterGlass.xcodeproj/xcuserdata/**`; project setting `ENABLE_USER_SCRIPT_SANDBOXING` flipped to YES.
- **No breaking changes** for users; persisted preferences and scripts are untouched (store recreation only occurs when the store is already unreadable).
