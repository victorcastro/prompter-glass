# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

### Known limitations

- Sharing your whole screen in a call shares the overlay with it. Share a single window instead.
- Some fullscreen games and certain Stage Manager arrangements can still cover the overlay.
- One overlay on one display; no multi-monitor mirroring.
- Plain text only — no rich text, Markdown or imported documents.

[1.0.0]: https://github.com/VictorCastroDev/PrompterGlass/releases/tag/v1.0.0
