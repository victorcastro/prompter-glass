# Proposal: p01-ui-glass-redesign

## Why

The app currently uses stock macOS chrome (NavigationSplitView, native list, plain control grid) that reads as a utility, not a product. New reference designs define a cohesive "dark glass" identity — ambient mood gradients per section, glass surfaces, an iris/amber accent system, and a redesigned overlay with a reading guide — that makes the app feel intentional and improves overlay readability during recordings.

This is phase 1 of 3 (p01 visual redesign → p02 countdown + mirror → p03 activity tracking).

## What Changes

- Introduce a design-system layer: color token library extracted from the reference designs (iris/amber accents, mood gradients, glass fills/strokes, text hierarchy), plus reusable glass components (glass card, icon chip, pill badge, Roll orb).
- Replace the NavigationSplitView shell with a custom sidebar (Prompter and Library sections, icon chips, active-item pill, "Overlay visible" toggle card with shortcut hint at the bottom).
- Replace the native script list with a Library section: card grid with icon chip, relative timestamp, title, body preview, and word count / estimated read time metadata; clicking a card opens the (restyled) editor.
- Add a Prompter section: hero view of the active script (title, word count, on-air estimate), feature status rows (voice tracking, click-through), redesigned slider bar (speed, text size, backdrop) and the Roll orb as the primary playback control.
- Redesign the overlay: gray translucent backdrop (replacing pure black), top status bar with playback state pill, amber "Voice ready" pill, meta line (speed · time left · click-through), drag handle affordance, a horizontal reading-guide line, and a three-state text hierarchy (spoken = amber with glow, current = near-white, upcoming = dimmed).
- Section backgrounds use distinct mood gradients: purple (Library), forest green (Prompter). Slate mood token is defined now for p03's activity section.

Out of scope (later phases): countdown, mirror text, activity tracking/stats, "My activity" sidebar entry.

## Capabilities

### New Capabilities

- `design-system`: color token library, mood gradients, and reusable glass UI components that all main-window sections and the overlay consume.
- `prompter-home`: the Prompter section — active-script hero with derived metadata (word count, on-air estimate), feature status rows, playback controls (sliders + Roll orb).

### Modified Capabilities

- `script-management`: library presentation becomes a card grid with body preview and word count / read-time metadata; editing opens by activating a card.
- `overlay-appearance`: backdrop becomes gray translucent; overlay gains a status bar (playback pill, voice pill, meta line, drag handle), a central reading-guide line, and three-state script text coloring driven by voice tracking.

## Impact

- `MainWindow/MainWindowView.swift`, `MainWindow/ControlPanelView.swift`: replaced by new shell + section views.
- `Features/ScriptLibrary/ScriptLibraryView.swift`, `ScriptEditorView.swift`: rewritten as card grid + restyled editor.
- `Features/Overlay/OverlayView.swift`: redesigned (backdrop, status bar, guide, text states).
- New `DesignSystem/` group: theme tokens, mood gradients, glass components.
- `Preferences/OverlayPreferencesStore.swift`: default text color semantics move to theme tokens; background opacity now modulates the gray backdrop.
- Existing UI test accessibility identifiers must keep working or be migrated deliberately (`PrompterGlassUITests`).
- No persistence schema changes; no new dependencies.
