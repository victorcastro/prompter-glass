# Design: p01-ui-glass-redesign

## Context

The app today is stock SwiftUI/AppKit chrome: `MainWindowView` wraps a `NavigationSplitView` with a native `List` sidebar (`ScriptLibraryView`), a plain `ScriptEditorView` detail, and a `ControlPanelView` grid of sliders/toggles pinned under the editor. The overlay (`OverlayView`) is a black rectangle whose opacity the user controls, with two text states (voice-spoken = plain yellow, rest = user color).

Reference designs (docs/ mockups provided 2026-08-10) define a dark-glass identity: ambient mood gradients per section, glass cards, iris (violet) primary accent, amber voice accent, a spherical "Roll" playback orb, and an overlay with a status bar, reading-guide line and three-state text. This phase is visual only; countdown/mirror (p02) and activity tracking (p03) come later.

Constraints: macOS 26.5+, SwiftUI-first with AppKit only for window glue, SwiftLint/SwiftFormat limits (file 500 warn, type nesting ≤2), UI-test accessibility identifiers currently in use must keep working, zero code comments (intent in names, rationale here).

## Goals / Non-Goals

**Goals:**
- Single source of truth for color/gradient/typography tokens matching the references.
- Custom shell (sidebar + section switching) replacing NavigationSplitView.
- Library card grid, Prompter home, restyled editor, redesigned overlay.
- Preserve all existing behavior: selection restore, deletion flow, playback, voice tracking, preferences persistence, click-through.

**Non-Goals:**
- Countdown, mirror text, activity tracking, "My activity" section (p02/p03).
- Light mode. References are dark-only; app declares dark appearance.
- Onboarding/illustration asset for the Prompter hero beyond a simple SwiftUI-drawn glass panel graphic.
- Changing persistence models or preference storage keys.

## Decisions

### D1 — Token library as Swift namespace, not Asset Catalog
`DesignSystem/Theme.swift` exposes `Theme` enum with nested `Palette` (static `Color` values built from hex), `Mood` (per-section background gradient pairs), `Glass` (fill/stroke opacities), and `TextStyle` helpers. Rationale: tokens are consumed programmatically (gradients, opacity math, glow radii); Asset Catalog adds indirection without benefit for a dark-only app, and hex literals stay greppable next to their names. Alternative considered: `.xcassets` color sets — rejected because gradients and opacity-derived variants can't live there anyway, which would split the source of truth.

Token values (sRGB, extracted from references):

| Token | Value | Use |
|---|---|---|
| `accentIris` | `#7C6CF0` | primary accent: active chips, toggles, stats, orb glow |
| `accentIrisSoft` | `#9D8FF5` | secondary accent text, deltas |
| `accentAmber` | `#F5C842` | voice: spoken highlight, voice pill, voice chip |
| `orbTop` / `orbBottom` | `#C8D4EE` / `#8B7FD6` | Roll orb gradient |
| `moodPurple` | `#221A4D` → `#2C1F63` @36% → `#181341` @74% → `#0B0920`, glow `#9678FF` | Library aurora background |
| `moodForest` | `#0B2F2A` → `#0A3B34` @34% → `#07231F` @72% → `#050F0E`, glow `#5BE3B3` | Prompter aurora background |
| `moodSlate` | `#1E2735` → `#253243` @35% → `#141B26` @73% → `#0A0E14`, glow `#7FA6D9` | reserved for p03 activity |

Aurora structure (D1b): base linear gradient at 165° (4 stops per mood), plus elliptical
radial glow halos in the mood's accent — a large one top center-left (25–30% opacity,
~70%×55% of the container, fading to transparent at 68% of its radius) and a small
counterweight halo bottom-right (12–14%). Halos never reach the edges and never exceed
30% opacity; glass cards (white 7% fill, white 10% stroke) sit on top so the glow reads
through them. Mood switches animate over 400 ms.
| `sidebarScrim` | black @ 28% | sidebar darkening over the section mood gradient |
| `glassFill` / `glassStroke` | white 7% / white 12% | cards, containers |
| `textPrimary` | `#F2F0FA` | titles |
| `textSecondary` / `textTertiary` | white 62% / 40% | body, meta |
| `overlaySpoken` | `#F0C93F` | spoken text (with glow) |
| `overlayCurrent` | `#E9F2EC` | current line |
| `overlayUpcoming` | white 38% | upcoming text |
| `overlayBackdrop` | `#6B6B6B` | overlay background base (opacity user-controlled) |

### D2 — Component kit in `DesignSystem/Components/`
Reusable views: `GlassCard` (fill+stroke+radius 16), `IconChip` (rounded-square icon with tint or iris gradient), `PillBadge` (status pills: dot/icon + label variants), `RollOrb` (gradient sphere + iris glow + press/disabled states), `MoodBackground` (radial gradient + vignette per `Mood`). Rationale: three sections plus overlay share these; duplicating styles per view would drift. Kept as plain views + `ViewModifier`s, no custom `ButtonStyle` protocol hierarchy beyond `RollOrb`'s.

### D3 — Shell: custom HSplit-less HStack, section enum, no NavigationSplitView
`MainWindowView` becomes `HStack(spacing: 0) { SidebarView; sectionContent }` over a full-window `MoodBackground`. `AppSection` enum (`prompter`, `library`) drives both sidebar selection and mood. Rationale: NavigationSplitView imposes native sidebar material, toolbar, and collapse behavior that fight the mockups; the app has exactly two (later three) fixed sections, so navigation machinery buys nothing. Window uses `.windowStyle(.hiddenTitleBar)` with `fullSizeContentView` so the gradient reaches the traffic lights. Alternative: restyling NavigationSplitView via `.toolbarBackground`/introspection — rejected as fragile against OS updates.

Sidebar bottom hosts the "Overlay visible" glass card: title, "Floats over every app · ⌥⌘P" hint, iris toggle bound to `environment.setOverlayVisible`.

### D4 — Library: LazyVGrid of script cards; card activation opens editor in-section
`LibrarySectionView` shows title row ("Library" + "+ New script" pill) and `LazyVGrid`(adaptive min 260) of `ScriptCardView`s (icon chip, relative timestamp, title, 2-line preview, "N words · N min read"). Clicking a card sets the section-local `editingScript`; the section swaps to the restyled `ScriptEditorView` with a back affordance. Rationale: user decision (card click → editor) with editor kept inside Library section to avoid a modal editing surface. Word count = whitespace/newline-split token count; read time = `max(1, words/200)` minutes displayed as "min read"; both derived on the fly from `Script` — no schema change. Deletion keeps the existing confirmation dialog and context menu, now on cards.

### D5 — Prompter home consumes existing controllers, adds derived on-air estimate
`PrompterSectionView`: hero (SwiftUI-drawn tilted glass panel graphic, active script title, "N words · about M:SS on air" using words-per-minute 130 speaking rate), feature rows (Voice tracking, Click-through — each an `IconChip` + name + state text, wired to existing toggles), slider bar (`GlassCard` containing Speed / Text size / Backdrop with bold trailing values — same bindings as today's `ControlPanelView`), and `RollOrb` centered at bottom (play when idle, pause when rolling; stop via secondary control). Microphone picker and overlay size fields move into a compact "settings" popover from the slider bar to keep the mockup's clean layout. Rationale: `ControlPanelView` dissolves into this section; its bindings (`playback.speed`, `preferences.fontSize`, `preferences.backgroundOpacity`, mic selection, overlay size) are already exposed on `AppEnvironment` and move over unchanged.

### D6 — Overlay: status bar + three-state attributed text

(2026-08-11) The reading guide line originally specified here was removed at the user's request; the depth-fade alone marks the reading zone.
`OverlayView` layers: `overlayBackdrop` color at `preferences.backgroundOpacity` (replacing black) with corner radius handled by the panel; top `HStack`: playback pill ("Paused"/"Rolling" + dot), amber voice pill shown when voice tracking active ("Voice ready"/"Listening" + waveform icon), meta text ("X pt/s · M:SS left · click-through" — remaining time from content height, offset and speed), drag-handle glyph right. Reading guide: 1pt horizontal line at 38% viewport height, `glassStroke` opacity, drawn over the backdrop under the text. Text states: spoken range = `overlaySpoken` + `.shadow` glow; the line intersecting the guide = `overlayCurrent`; below = `overlayUpcoming`. Current/upcoming split computed from scroll offset and layout — approximated per-paragraph (attributed ranges by character offset from `ScriptAligner`'s spoken boundary; "current" extends from spoken boundary to the next sentence end). Rationale: exact per-line geometry from SwiftUI `Text` is not accessible without `NSTextLayoutManager`; sentence-granularity approximation matches the mockup's visual effect at far lower complexity. `preferences.textColor` keeps working: it recolors `overlayCurrent`/`overlayUpcoming` tints via hue shift — simplest faithful behavior: user color replaces `overlayCurrent`, upcoming = same color at 38% opacity.

### D7 — Accessibility identifiers preserved
All existing `Identifier` constants (`controls.*`, `library.*`, `overlay.root`) are reattached to their new homes (Roll orb gets `controls.play`/`controls.pause` semantics via a single button whose identifier switches, or keeps `controls.play` plus separate pause — decide in implementation to keep UI tests green; stop control keeps `controls.stop`). UI tests are run and adjusted only where interaction semantics genuinely changed (e.g., list → grid card tap).

### D8 — Dark appearance enforced
Root views apply `.preferredColorScheme(.dark)` and the window `appearance` set to dark aqua. Rationale: token library is dark-only; letting system light mode leak in would produce unreadable glass surfaces.

## Risks / Trade-offs

- [Custom shell loses free NavigationSplitView behaviors (sidebar collapse, state restoration)] → Sections are fixed and few; selection persisted via existing `ActiveScriptStore` + a `@AppStorage` section key.
- [UI tests break from list→grid and control panel dissolution] → Identifiers preserved deliberately (D7); run UITests after shell lands, adjust queries where the element type changed.
- [Three-state overlay text approximation may look off for long paragraphs] → Sentence-boundary heuristic; if visibly wrong, fall back to two zones (spoken/unspoken) plus guide line — still matches mockup at a glance.
- [Remaining-time meta in overlay needs content height ↔ speed math] → Engine already tracks `offset`, content height and speed; derived property, no engine change.
- [`.hiddenTitleBar` + custom drag regions can break window moving] → Keep standard traffic lights; make sidebar/background draggable via `WindowDragGesture` where safe.
- [File count grows; SwiftLint 500-line limit] → One component per file under `DesignSystem/`, sections as separate views.

## Migration Plan

Pure UI refactor on branch `feat/ui-redesign`; no data migration. Rollback = revert merge. `ControlPanelView.swift` deleted once Prompter section reaches parity (mic picker, overlay size, text color included in popover).

## Open Questions

- Roll orb pause affordance: orb toggles play/pause with label swap vs. orb=play + small pause/stop pills beside it. Default: orb toggles, stop as small pill; revisit against mockup during implementation.
- Editor back affordance style (breadcrumb vs. chevron pill) — pick during implementation to match card visual language.
