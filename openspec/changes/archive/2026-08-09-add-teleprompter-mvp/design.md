## Context

PrompterGlass is a macOS-only app whose entire value depends on one window behavior SwiftUI does not expose: a chromeless, semi-transparent surface that sits above every other application — including other apps in fullscreen — without stealing focus from whatever the user is actually doing (Zoom, QuickTime, Final Cut, a browser).

SwiftUI's `Window` / `WindowGroup` scenes give no control over window level, collection behavior, panel style masks, or activation policy. `.windowStyle(.hiddenTitleBar)` removes the title bar but leaves an ordinary `NSWindow` that key-activates on click and disappears when the user switches Space or enters fullscreen. So the overlay must be an AppKit window created and owned by the app, with SwiftUI hosted inside it.

The rest of the app — the script library, the editor, the controls — is a conventional document-ish SwiftUI app and needs no AppKit at all. The design's job is to keep that boundary clean: AppKit owns the window, SwiftUI owns everything drawn inside it, and a shared observable state object bridges them.

Current state: the Xcode target is fresh template scaffolding. There is no existing architecture to migrate from.

## Goals / Non-Goals

**Goals:**

- A single overlay surface that is borderless, transparent, always on top, present on all Spaces, visible over fullscreen apps, draggable by its body, and frame-restoring across launches.
- Overlay never steals keyboard focus from the frontmost app during playback.
- Scripts persisted durably with SwiftData; overlay chrome preferences persisted cheaply and read synchronously at window-construction time.
- Playback logic (position, speed, state machine) testable without instantiating a window or a view.
- AppKit surface area confined to a small number of files so the SwiftUI side stays unit-testable and the app stays easy to reason about.

**Non-Goals:**

- Multi-overlay / multi-monitor mirroring. One overlay window in the MVP.
- Global hotkeys, remote control, or any control surface outside the app's own windows.
- Screen recording, camera capture, or compositing the overlay into a recording.
- Rich text, Markdown rendering, or imported document formats. Plain text bodies only.
- Cloud sync, export, iOS/iPadOS.

## Decisions

### Decision 1: `NSPanel` instead of `NSWindow`

The overlay is an `NSPanel` subclass, not an `NSWindow` subclass.

**Rationale.** `NSPanel` is AppKit's type for auxiliary windows that assist the frontmost work rather than being the work, and it carries behaviors an `NSWindow` cannot get without fighting the framework:

- **`.nonactivatingPanel` style mask.** Only a panel supports it. Clicking the overlay (to drag it, to hit pause) does not activate PrompterGlass, so the user's recording app or call app stays frontmost and keeps keyboard focus. With a plain `NSWindow`, every click on the overlay pulls the app forward — unacceptable when the user is mid-take.
- **`becomesKeyOnlyIfNeeded = true`.** A panel can accept mouse events while refusing key status unless a control genuinely needs text input. `NSWindow` has no equivalent; overriding `canBecomeKey` on an `NSWindow` is coarse — it is all-or-nothing and does not restore focus behavior correctly.
- **`hidesOnDeactivate = false` on a panel** keeps the overlay up while the app is in the background, which is the normal state for this app.
- Panels are excluded from the Window menu and from standard window cycling by default, which is the desired behavior for an overlay.

**Alternatives considered.**

- *Plain `NSWindow` with `level = .floating` and overridden `canBecomeKey`.* Reproduces roughly half the behavior and needs manual work to avoid activation on click; the non-activating path is exactly what `NSPanel` exists to provide.
- *SwiftUI `Window` scene with `.windowLevel(.floating)`.* Covers level only. No non-activating behavior, no collection behavior control, no borderless transparent background without dropping to AppKit anyway.
- *`NSStatusItem` popover.* Auto-dismisses on outside click and cannot be dragged freely — wrong interaction model for something the user reads for minutes at a time.

**Configuration used.**

```
styleMask:            [.borderless, .nonactivatingPanel]
level:                .floating          // above normal windows, below system UI
collectionBehavior:   [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
isOpaque:             false
backgroundColor:      .clear             // opacity is drawn by SwiftUI, not the window
hasShadow:            false
isMovableByWindowBackground: true
becomesKeyOnlyIfNeeded: true
hidesOnDeactivate:    false
isReleasedWhenClosed: false
```

`.canJoinAllSpaces` puts the overlay on every Space. `.fullScreenAuxiliary` is the piece that makes it survive over *another app's* fullscreen window — without it the overlay is hidden the moment the user fullscreens their call app. `.stationary` keeps it from sliding during Spaces transitions. `isReleasedWhenClosed = false` is required because the panel is retained by a controller and reshown.

Because `.borderless` panels return `false` from `canBecomeKey` by default, the subclass overrides `canBecomeKey` to `true` — otherwise text fields and buttons inside the hosted SwiftUI never respond. Focus stealing is prevented by `.nonactivatingPanel` + `becomesKeyOnlyIfNeeded`, not by refusing key status.

### Decision 2: SwiftUI hosted via `NSHostingView` inside an `OverlayWindowController`

An `OverlayWindowController` (an `NSWindowController` subclass, `@MainActor`) owns the panel's whole lifecycle: construct, configure, show, hide, and save frame. The panel's `contentView` is set to an `NSHostingView` wrapping the SwiftUI `OverlayView`.

**Rationale.**

- `NSHostingView` is the direct AppKit-view bridge — it drops straight into `contentView` with no intermediate view controller and no extra responder-chain hop, which matters because the panel is borderless and the hosting view must fill the entire frame edge to edge.
- Shared state is injected once at construction, as an `@Observable` `OverlayViewModel` passed via `.environment(...)`. The main window's controls and the overlay's content read and write the same instance, so a speed change in the control panel is reflected in the overlay with no notification plumbing.
- Sizing: `NSHostingView` reports a SwiftUI-derived `intrinsicContentSize`. For a resizable overlay that is unwanted, so the hosting view is pinned with `autoresizingMask = [.width, .height]` and the SwiftUI root uses `.frame(maxWidth: .infinity, maxHeight: .infinity)`; the window frame is the authority on size, not the content.
- `sizingOptions` is left at its default. `.preferredContentSize` would let SwiftUI resize the panel and fight the restored frame.

**Alternatives considered.**

- *`NSHostingController` set as `contentViewController`.* Works, but assigning a `contentViewController` makes AppKit manage the window's content sizing and can override the frame restored from preferences. The extra controller buys nothing here.
- *`NSWindow(contentViewController:)` convenience initializer.* Cannot express the panel style mask.

### Decision 3: Click-through is opt-in, off by default, and implemented with `ignoresMouseEvents`

The overlay has two interaction modes, toggled from the control panel:

- **Interactive (default).** `panel.ignoresMouseEvents = false`. The user can drag the overlay, hit playback controls in its hover chrome, and resize it.
- **Click-through.** `panel.ignoresMouseEvents = true`. Every mouse event — clicks, scrolls, hovers — passes to whatever is underneath. The overlay becomes pure glass; the user interacts with their call or editor as if the overlay were not there.

**Rationale.** These are the only two states worth having in an MVP, and `ignoresMouseEvents` is a single window-level property with no event-tap, no Accessibility permission, and no per-region hit-testing cost. Rejecting the more elaborate options is deliberate:

- *Per-region click-through via `NSView.hitTest` returning `nil` for the text area and `self` for the control strip.* Nicer in theory. In practice it interacts badly with `isMovableByWindowBackground` (a `nil` hit-test kills window dragging in that region) and produces an interaction model the user cannot see the boundaries of. Deferred.
- *`CGEventTap` to forward events.* Requires Accessibility permission and a trust prompt. Disproportionate.

Because click-through mode makes the panel unclickable, exiting it must be possible from elsewhere: the toggle lives in the main control window, and the mode is **not** persisted across launches — the app always starts interactive, so a user cannot lock themselves out by quitting while click-through is on. This is the one preference deliberately excluded from restoration.

When `ignoresMouseEvents` is true the panel also sets `acceptsMouseMovedEvents = false` to avoid tracking-area work for events it will never receive.

### Decision 4: Window state persisted manually in `UserDefaults`, not via `setFrameAutosaveName`

The overlay frame is saved to `UserDefaults` under one key (`overlay.frame`) as an `NSStringFromRect` string, written on `windowDidMove` and `windowDidEndLiveResize` (both debounced to coalesce a drag into a single write), and read back synchronously before the panel is first shown.

**Rationale.**

- `setFrameAutosaveName` is the built-in path, but it is unreliable for borderless panels: AppKit ties autosave restoration to window ordering and to `NSWindowRestoration`, and it applies the saved frame *after* the window is first ordered in — producing a visible jump. It also silently no-ops when the name collides with another window's autosave name, which is exactly the kind of failure that is invisible in development and reported as a bug later.
- Reading the frame before `orderFront` means the panel appears at its final position with no flash.
- Validation is required and easy to own manually: on restore, the saved frame is intersected against `NSScreen.screens`. If no screen contains a usable portion of it (monitor unplugged, resolution changed), the frame is discarded and the panel is centered on `NSScreen.main` at the default size. A minimum size floor is enforced so a saved degenerate frame cannot produce an invisible window.
- A single `UserDefaults` key keeps the persistence layer trivially testable: the store takes a `UserDefaults` instance by injection, so tests pass a throwaway suite instead of polluting the app domain.

**Why not SwiftData for this.** SwiftData is right for scripts — user-authored content that grows, needs querying, and must be durable. It is wrong for window chrome: reading a `ModelContainer` at launch is asynchronous relative to window construction, the data is a handful of scalars with no relationships, and a corrupt or migrating store must never be able to prevent the overlay from opening. Appearance and playback preferences (`fontSize`, `scrollSpeed`, `backgroundOpacity`, `textColor`, `lastOpenedScriptID`) follow the same reasoning and live in `UserDefaults` alongside the frame, exposed through the same injectable store.

`textColor` is stored as sRGB components rather than an archived `NSColor`, so the value is inspectable, diffable, and free of unarchiving failure modes.

### Decision 5: Playback is a testable engine driven by a display-linked tick

Scroll state lives in an `@Observable ScrollPlaybackEngine` holding `state` (`.stopped | .playing | .paused`), `offset`, `contentHeight`, `viewportHeight` and `speed`. The engine exposes a pure `advance(by deltaTime:)` that computes the next offset; the view layer only feeds it elapsed time and reads `offset`.

**Rationale.** Keeping time-stepping out of the view means the whole state machine — start from stopped resets to zero, pause preserves offset, resume continues from it, stop resets, reaching the end auto-stops, speed changes take effect without a discontinuity — is verified by Swift Testing unit tests with synthetic deltas and no window, no timer, and no waiting.

The driver is a `CADisplayLink` (available on macOS 14+, and the deployment target is far above that) rather than a `Timer`, so ticks align to the display refresh and the scroll does not judder. `Timer.publish` at 60 Hz drifts and is throttled by run-loop mode during window drags. Delta time comes from the display link's timestamps, so the scroll speed is frame-rate independent — a dropped frame produces a larger step, not a slower scroll.

Speed is specified in points per second so it is resolution- and font-size-independent; changing font size therefore changes how many lines per second pass, which is the behavior a reader expects.

Rendering uses a `ScrollView` with `.scrollDisabled(true)` during playback and a `.offset(y:)` applied to the text, rather than programmatic `scrollTo` — offset animation is continuous and sub-pixel, whereas `scrollTo` snaps to anchor positions.

### Decision 6: Opacity is drawn by SwiftUI, not by the window

`panel.alphaValue` stays at `1.0`. Background opacity is a SwiftUI `Color.black.opacity(backgroundOpacity)` behind the text.

**Rationale.** `alphaValue` fades the entire window uniformly — text included. The user wants a translucent *background* with fully legible text on top; those must be independent. Drawing the background in SwiftUI also lets the text keep full opacity at any background setting, and lets the background be a material or gradient later without touching window code.

A minimum text/background contrast is not enforced programmatically in the MVP — the user chooses the text color and can see the result live over their actual content, which is more reliable than a computed contrast ratio against an unknown video behind the glass.

## Risks / Trade-offs

- **Click-through mode makes the overlay unreachable.** → The toggle lives in the main control window, not the overlay, and the mode is never persisted; the app always launches interactive.
- **A saved frame can point at a screen that no longer exists.** → Restored frames are validated against `NSScreen.screens` on every launch and fall back to a centered default.
- **`.fullScreenAuxiliary` behavior is not uniform across every macOS configuration** (notably some fullscreen games and Stage Manager arrangements). → Accepted for the MVP; documented as a known limitation rather than worked around with private API.
- **Screen sharing captures the overlay.** In a call, sharing the whole screen shares the teleprompter with it. → Out of scope for the MVP; `NSWindow.sharingType = .none` is a possible follow-up but interacts with the user's own recording setup and needs its own decision.
- **`NSHostingView` inside a borderless panel has occasional first-responder quirks** with text fields. → Mitigated by keeping the overlay read-only: all editing happens in the main window, so the overlay hosts no text input.
- **Display-link driven scrolling costs a redraw per frame while playing.** → Only while `state == .playing`; the display link is invalidated on pause and stop.
- **AppKit interop makes the overlay hard to cover with unit tests.** → Deliberately mitigated by pushing all logic (playback math, frame validation, preference encoding) out of the window layer into plain testable types; the window layer itself is covered by UI tests only.

## Migration Plan

Not applicable — greenfield. The only removal is the Xcode template `Item.swift` model and template `ContentView` body, deleted in the same change that introduces the `Script` model. No user data exists, so no SwiftData migration is required; the initial schema is version 1.

## Open Questions

- Should the overlay expose a minimal hover-revealed control strip (play/pause, speed) or stay entirely chrome-free with all control in the main window? The specs assume the overlay renders text only and all controls live in the main window; a hover strip can be added without changing any requirement here.
- Default overlay size and position on first launch: centered on the main screen at a fraction of screen height, or docked to the top edge under the webcam? Top-docked matches the eyeline use case; leaning that way, to be confirmed during implementation with a real camera setup.
