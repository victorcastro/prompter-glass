## 1. Project Foundation

- [x] 1.1 Delete the Xcode template `Item.swift` model and strip the template body from `ContentView.swift`
- [x] 1.2 Create the source folder structure under `PrompterGlass/`: `Models/`, `Persistence/`, `Overlay/`, `Playback/`, `Views/`
- [x] 1.3 Verify SwiftLint and SwiftFormat run clean on the source tree; CI runs both, so no local wrapper is added
- [x] 1.4 Confirm the deployment target is macOS 26.5 and the bundle identifier is `dev.victorcastro.PrompterGlass`

## 2. Script Management

- [x] 2.1 Add the `Script` SwiftData `@Model`: `id`, `title`, `body`, `createdAt`, `updatedAt`
- [x] 2.2 Configure the `ModelContainer` in `PrompterGlassApp` and inject the `ModelContext` into the view hierarchy
- [x] 2.3 Write Swift Testing unit tests for the `Script` model using an in-memory `ModelContainer`: creation defaults, stable `id` across edits, `updatedAt` bump on edit
- [x] 2.4 Build the script library view: `@Query` sorted by `updatedAt` descending, showing title and last-modified date
- [x] 2.5 Add the empty state with a "create your first script" action
- [x] 2.6 Implement create: new script with the default title `Untitled Script`, opened in the editor with the title field focused
- [x] 2.7 Build the script editor: title field and plain-text body editor, autosaving with a debounce and bumping `updatedAt`
- [x] 2.8 Implement delete with a confirmation prompt, and stop playback plus clear the overlay when the deleted script is the active one
- [x] 2.9 Add active-script selection, persisting `lastOpenedScriptID` and falling back to no active script when that id no longer resolves
- [x] 2.10 Write XCTest UI coverage for the create / edit / list / delete flow

## 3. Preferences Store

- [x] 3.1 Add an `OverlayPreferencesStore` wrapping an injectable `UserDefaults`, covering `overlay.frame`, `fontSize`, `scrollSpeed`, `backgroundOpacity`, `textColor` and `lastOpenedScriptID`
- [x] 3.2 Encode the text color as sRGB components rather than an archived `NSColor`, with a default-color fallback when the stored value is missing or unreadable
- [x] 3.3 Implement frame validation: intersect the saved frame against `NSScreen.screens`, enforce a minimum size, and fall back to a centered default frame on the main display
- [x] 3.4 Write Swift Testing unit tests against a throwaway `UserDefaults` suite: round-tripping every key, defaults on empty storage, off-screen frame rejection, degenerate frame rejection, unreadable color fallback
- [x] 3.5 Confirm click-through mode is deliberately excluded from persistence and always starts off

## 4. Overlay Window

- [x] 4.1 Add the `OverlayPanel` `NSPanel` subclass with style mask `[.borderless, .nonactivatingPanel]` and `canBecomeKey` overridden to `true`
- [x] 4.2 Configure the panel: `level = .floating`, `isOpaque = false`, `backgroundColor = .clear`, `hasShadow = false`, `becomesKeyOnlyIfNeeded = true`, `hidesOnDeactivate = false`, `isReleasedWhenClosed = false`
- [x] 4.3 Set `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]`
- [x] 4.4 Enable dragging with `isMovableByWindowBackground = true` and enforce the minimum size via `contentMinSize`
- [x] 4.5 Add the `OverlayWindowController` (`NSWindowController`, `@MainActor`) owning construction, show, hide and teardown
- [x] 4.6 Restore the validated frame from the preferences store *before* the first `orderFront` so the panel never appears and jumps
- [x] 4.7 Save the frame on `windowDidMove` and `windowDidEndLiveResize`, debounced so a drag produces one write
- [x] 4.8 Host the SwiftUI `OverlayView` in an `NSHostingView` set as `contentView`, with `autoresizingMask = [.width, .height]` and the SwiftUI root pinned to `maxWidth`/`maxHeight` `.infinity`
- [x] 4.9 Inject the shared `@Observable` `OverlayViewModel` into the hosted view via `.environment(...)`
- [x] 4.10 Add the show/hide toggle in the main window, stopping playback when the overlay is hidden
- [x] 4.11 Add the click-through toggle in the main window driving `ignoresMouseEvents` and `acceptsMouseMovedEvents`, with the control living outside the overlay
- [ ] 4.12 Manually verify on device: floats over other apps, survives app deactivation, present on all Spaces, visible over another app's fullscreen window, click does not steal focus
- [x] 4.13 Add XCTest UI coverage for show/hide and for frame restoration across relaunch

## 5. Scroll Playback

- [x] 5.1 Add the `@Observable ScrollPlaybackEngine` holding `state` (`.stopped | .playing | .paused`), `offset`, `contentHeight`, `viewportHeight` and `speed` in points per second
- [x] 5.2 Implement the pure `advance(by deltaTime:)` step and the `start` / `pause` / `resume` / `stop` transitions, with start-from-stopped resetting the offset to zero
- [x] 5.3 Implement auto-stop when the end of the content reaches the bottom of the viewport, clamping the offset so it never scrolls past the content
- [x] 5.4 Reject `start` when no script is active
- [x] 5.5 Write Swift Testing unit tests for the full state machine with synthetic deltas: reset on start, offset preserved across pause/resume, reset on stop from both playing and paused, auto-stop at the end, speed change producing no positional discontinuity, frame-rate independence for equal elapsed time across differing tick counts
- [x] 5.6 Drive the engine with a `CADisplayLink`, deriving delta time from its timestamps and invalidating it on pause and stop
- [x] 5.7 Render the overlay text in a `ScrollView` with `.scrollDisabled(true)` and a `.offset(y:)` bound to the engine
- [x] 5.8 Add the speed control, clamped to the supported range, applied live and persisted through the preferences store
- [x] 5.9 Add the font-size control, clamped to the supported range, applied live and persisted, keeping the reading position on the same passage when the size changes mid-scroll
- [x] 5.10 Wire the start / pause / stop controls in the main window to the engine

## 6. Overlay Appearance

- [x] 6.1 Draw the overlay background in SwiftUI at the configured opacity and leave `panel.alphaValue` at `1.0`
- [x] 6.2 Verify text renders at full opacity independently of the background setting, including at minimum background opacity
- [x] 6.3 Add the background-opacity control, applied live and persisted
- [x] 6.4 Add the text-color picker, applied live and persisted, with the default-color fallback exercised
- [ ] 6.5 Manually verify appearance edits preview live over a real video call or recording app without stealing its focus

## 7. Integration and Wrap-up

- [ ] 7.1 End-to-end pass: create a script, make it active, show the overlay, scroll it over a fullscreen app, adjust speed, font size, opacity and color, then quit and relaunch and confirm every persisted value returns
- [x] 7.2 Run SwiftLint and SwiftFormat clean across the whole target
- [x] 4.14 Add numeric width and height fields for the overlay, clamped and synced back after a drag-resize
- [x] 4.15 Use a fixed 800x600 first-launch default size, shrunk to fit displays smaller than that
- [x] 7.3 Run the full Swift Testing and XCTest UI suites green
- [x] 7.4 Update `README.md` with the MVP feature list and the known limitations from `design.md` (fullscreen edge cases, screen sharing captures the overlay)
- [x] 7.5 Resolve the two open questions in `design.md` — hover control strip and default first-launch overlay placement — and record the decisions
