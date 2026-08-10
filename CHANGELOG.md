# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-08-11

### Added

- **Voice tracking.** Turn on the new Voice toggle and PrompterGlass follows your voice through the script: speech is transcribed entirely on your Mac (no network involved), the words you have already read are highlighted in yellow, and the overlay scrolls automatically to keep your reading position in view. Manual playback is untouched when the toggle is off.
- Clear permission states: the first activation asks for microphone access; if it is denied, the control panel says so and links to System Settings.

### Changed

- The default overlay background opacity is now 80% (was 55%); a value you had already chosen is kept. The default text color remains white.

## [1.0.0] - 2026-08-10

First usable version. Build it from source in Xcode; there is no signed binary or installer yet.

### Added

- **Script management.** Create, edit, list and delete teleprompter scripts. Scripts are stored locally with SwiftData, autosaved as you type, and listed newest-first. Deleting asks for confirmation.
- **Floating overlay.** A borderless, transparent panel that stays above every other app, shows up on all Spaces, and survives another app going fullscreen. Drag it anywhere by its body; it reopens at the position and size you left it.
- **Focus is never stolen.** Clicking or dragging the overlay leaves your recording or call app frontmost and in control of the keyboard.
- **Click-through mode.** Make the overlay ignore the mouse entirely so you can work underneath it. Never restored on launch, so it cannot lock you out of the overlay.
- **Scroll playback.** Play, pause, resume and stop, with an adjustable speed in points per second. Scrolling is display-linked and frame-rate independent, and stops on its own at the end of the script.
- **Readable over anything.** Adjustable font size, background opacity and text color. The text stays fully opaque no matter how transparent the background gets.
- **Overlay size.** Set the width and height in points, or drag to resize. Opens at 800 × 600 by default, docked to the top of the screen so the reading position sits near the webcam.
- **Show Overlay** menu command, bound to <kbd>⌘</kbd><kbd>⇧</kbd><kbd>O</kbd>.

### Fixed

- **Memory leak in scroll playback.** The display link retained its driver through a reference cycle, so playback resources could outlive their owner. The link now holds its target weakly and is invalidated deterministically.
- **Playback froze if the overlay closed mid-scroll.** The display link now re-arms from the screen when the overlay's view goes away, instead of silently reporting itself as running while delivering no frames.
- **Overlay position could be lost on quit.** Moves and resizes are saved with a short debounce; quitting inside that window dropped the last frame. The pending save is now flushed when the app terminates.
- **Deleting a script while editing it could write to the deleted record.** Pending autosaves are now skipped once a script has been removed from storage.
- **A corrupt script store no longer crashes the app at launch.** The store is recreated empty and the app opens normally; recovery only runs when the store is genuinely unreadable.

### Changed

- Continuous integration runs on Linux only: SwiftLint plus repository sanity checks. The test suites run locally via Xcode.
- Library rows use stable accessibility identifiers instead of identifiers derived from the script title.

### Known limitations

- Sharing your whole screen in a call shares the overlay with it. Share a single window instead.
- Some fullscreen games and certain Stage Manager arrangements can still cover the overlay.
- One overlay on one display; no multi-monitor mirroring.
- Plain text only — no rich text, Markdown or imported documents.

[1.1.0]: https://github.com/VictorCastroDev/PrompterGlass/releases/tag/v1.1.0
[1.0.0]: https://github.com/VictorCastroDev/PrompterGlass/releases/tag/v1.0.0
