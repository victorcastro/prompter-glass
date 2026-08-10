# Tasks: p01-ui-glass-redesign

## 1. Design system foundation

- [x] 1.1 Create `DesignSystem/Theme.swift` with `Theme.Palette` (all color tokens from design.md D1), `Theme.Mood` (purple/forest/slate gradient pairs) and `Theme.Glass` (fill/stroke styles)
- [x] 1.2 Create `DesignSystem/Components/MoodBackground.swift` (radial gradient + vignette per mood) and `GlassCard.swift` (fill, stroke, radius 16 container)
- [x] 1.3 Create `DesignSystem/Components/IconChip.swift` (rounded-square icon, flat tint and iris-gradient variants) and `PillBadge.swift` (dot/icon + label pill)
- [x] 1.4 Create `DesignSystem/Components/RollOrb.swift` (gradient sphere, iris glow, pressed/disabled states, label)
- [x] 1.5 Enforce dark appearance at the app root and add unit tests for derived script metadata helpers (word count, read time, on-air estimate) in `PrompterGlassTests`

## 2. Shell and sidebar

- [x] 2.1 Add `AppSection` enum with `@AppStorage` persistence and rebuild `MainWindowView` as custom HStack shell (sidebar + section content over `MoodBackground`), removing `NavigationSplitView`
- [x] 2.2 Create `MainWindow/SidebarView.swift`: Prompter/Library items with icon chips and active pill, "Overlay visible" glass card with ⌥⌘P hint and overlay toggle (keep `controls.overlayToggle` identifier)
- [x] 2.3 Configure window style (hidden title bar, full-size content view, dark appearance) keeping traffic lights and window dragging functional

## 3. Library section

- [x] 3.1 Create `ScriptCardView` (icon chip, relative timestamp, title, 2-line preview, "N words · N min read") and rebuild `ScriptLibraryView` as title row + "+ New script" pill + adaptive `LazyVGrid`, preserving `library.*` identifiers
- [x] 3.2 Wire card activation to open restyled editor in-section with back affordance; keep deletion confirmation dialog and context menu on cards; preserve selection restore and active-script reconciliation from `MainWindowView`
- [x] 3.3 Restyle `ScriptEditorView` (glass surfaces, token typography) keeping autosave/commit behavior intact

## 4. Prompter section

- [x] 4.1 Create `PrompterSectionView` hero: tilted glass-panel graphic, active script title, "N words · about M:SS on air", empty state directing to Library
- [x] 4.2 Add feature status rows (Voice tracking amber chip with state text and toggle, Click-through iris chip with toggle), preserving `controls.voiceToggle` / `controls.clickThroughToggle` identifiers and voice status states (preparing/denied/unavailable)
- [x] 4.3 Build slider bar in `GlassCard`: Speed / Text size / Backdrop with bold trailing values, same bindings and identifiers as old `ControlPanelView`; move microphone picker, overlay size fields and text color picker into settings popover keeping their identifiers
- [x] 4.4 Integrate `RollOrb` (play when idle, pause when rolling, stop pill alongside) with `controls.play`/`controls.pause`/`controls.stop` identifiers preserved; delete `ControlPanelView.swift` once at parity

## 5. Overlay redesign

- [x] 5.1 Replace black backdrop with `overlayBackdrop` gray at user opacity and draw the reading guide line at 38% viewport height beneath the text
- [x] 5.2 Build overlay status bar: playback pill (Paused/Rolling), amber voice pill when voice tracking active, meta line (speed · time left · click-through), drag-handle glyph; derive time-left from engine offset/content/speed
- [x] 5.3 Implement three-state attributed text (spoken amber + glow, current zone full-opacity user color, upcoming dimmed) per design.md D6, with no amber state when voice tracking is off
- [x] 5.4 Keep `overlay.root` identifier and verify click-through and viewport/content height reporting still drive playback correctly

## 6. Verification

- [x] 6.1 Run swiftformat + swiftlint and fix violations
- [x] 6.2 Run unit tests (`PrompterGlassTests`) and fix failures
- [x] 6.3 Run UI tests (`PrompterGlassUITests`), migrate queries where element types changed (list → grid cards), and fix failures
- [x] 6.4 Manual pass against reference images: Library grid, Prompter section, overlay with voice tracking; adjust tokens where visibly off
