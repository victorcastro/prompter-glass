## Why

Recording a video or joining a call while reading a script forces a choice: look at the script and break eye contact with the camera, or memorize the script. PrompterGlass exists to remove that tradeoff, and today the Xcode project is empty scaffolding — nothing ships until the core teleprompter loop (write a script, float it over any app, scroll it hands-free) works end to end.

This change defines that first usable version.

## What Changes

- Add script management: create, edit, rename, list and delete teleprompter scripts, persisted locally with SwiftData so they survive app relaunches.
- Add the overlay window: a borderless, transparent `NSPanel` that floats above every other app, joins all Spaces, stays visible over fullscreen apps, can be dragged by its body, and restores its last position and size on launch.
- Add scroll playback: start, pause, resume and stop automatic scrolling of the active script inside the overlay, with an adjustable scroll speed and an adjustable font size.
- Add appearance controls: adjustable overlay background opacity and adjustable text color, so the script stays readable over any video content behind it.
- Remove the Xcode template scaffolding (`Item.swift`, the template `ContentView`) and replace the SwiftData model with the real `Script` model.

No breaking changes — there is no released behavior to break.

## Capabilities

### New Capabilities

- `script-management`: Creating, editing, listing and deleting teleprompter scripts, and their persistence with SwiftData.
- `overlay-window`: The borderless transparent always-on-top panel — floating level, Spaces and fullscreen behavior, dragging, and persistence of its frame across launches.
- `scroll-playback`: Start / pause / resume / stop scrolling of the active script in the overlay, plus scroll speed and font size control.
- `overlay-appearance`: Background opacity and text color controls that keep the script legible over arbitrary content.

### Modified Capabilities

None. This is the first change in the project; `openspec/specs/` is empty.

## Impact

- **New app sources** under `PrompterGlass/`: the `Script` SwiftData model, a scripts library view, the `NSPanel` subclass plus its SwiftUI hosting glue, a scroll playback engine, and an overlay settings store.
- **Modified**: `PrompterGlassApp.swift` gains the `ModelContainer` setup and the overlay window lifecycle; `ContentView.swift` becomes the script library instead of the template list.
- **Deleted**: `Item.swift` (Xcode template model).
- **AppKit dependency**: the app stops being pure SwiftUI. `NSPanel`, `NSHostingView`, `NSWindow.CollectionBehavior` and `NSScreen` are used directly for window behavior SwiftUI cannot express. Design rationale lives in `design.md`.
- **Persistence split**: script content goes to SwiftData; overlay frame and appearance/playback preferences go to `UserDefaults` (see `design.md` for why).
- **Tests**: new Swift Testing suites in `PrompterGlassTests` for the model, the playback engine and the settings store; XCTest UI coverage in `PrompterGlassUITests` for the script CRUD flow.
- **No new third-party dependencies.** No entitlements beyond the default app sandbox; the overlay needs no Screen Recording or Accessibility permission.
- **Out of scope**: export, cloud sync, iOS/iPadOS, remote control, camera capture, recording.
