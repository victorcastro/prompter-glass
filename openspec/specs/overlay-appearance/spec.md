# overlay-appearance Specification

## Purpose
TBD - created by archiving change add-teleprompter-mvp. Update Purpose after archive.
## Requirements
### Requirement: Adjustable background opacity

The app SHALL let the user adjust the opacity of the overlay's background from fully transparent to fully opaque, SHALL apply the change immediately, and SHALL persist the chosen value across launches. The default background opacity SHALL be 0.80; a previously stored value SHALL always take precedence over the default.

#### Scenario: Lowering the background opacity

- **WHEN** the user lowers the background opacity
- **THEN** the content behind the overlay becomes more visible through its background immediately

#### Scenario: Fully transparent background

- **WHEN** the user sets the background opacity to its minimum
- **THEN** only the script text is drawn and the content behind the overlay is fully visible

#### Scenario: Opacity persists across launches

- **WHEN** the user sets a background opacity, quits the app and relaunches it
- **THEN** the overlay is drawn with the same background opacity

#### Scenario: First launch default

- **WHEN** the app runs with no stored background opacity
- **THEN** the overlay background is drawn at 0.80 opacity

### Requirement: Text remains fully opaque

Changing the background opacity SHALL NOT change the opacity of the script text, so the text stays fully legible at any background setting.

#### Scenario: Background set to fully transparent

- **WHEN** the background opacity is set to its minimum
- **THEN** the script text is still rendered at full opacity

### Requirement: Adjustable text color

The app SHALL let the user choose the color of the overlay's unspoken script text, SHALL apply the change immediately, and SHALL persist the chosen color across launches. The chosen color SHALL render the current reading zone at full opacity and the upcoming text dimmed, and SHALL NOT affect the spoken-text highlight color.

#### Scenario: Choosing a text color

- **WHEN** the user picks a text color
- **THEN** the overlay renders the current reading zone in that color immediately and the upcoming text in a dimmed variant of it

#### Scenario: Text color persists across launches

- **WHEN** the user picks a text color, quits the app and relaunches it
- **THEN** the overlay renders the script in the same color

#### Scenario: Stored color cannot be read

- **WHEN** the app launches and the stored text color is missing or unreadable
- **THEN** the overlay falls back to the default text color instead of failing to render

### Requirement: Appearance changes preview live over real content

Appearance changes SHALL be reflected in the overlay as the user adjusts them, while the overlay stays on top of whatever the user is viewing behind it.

#### Scenario: Adjusting appearance while another app is frontmost

- **WHEN** the user adjusts background opacity or text color while a video call or recording app is frontmost behind the overlay
- **THEN** the overlay updates live over that content and that application stays frontmost

### Requirement: Neutral gray backdrop

The overlay background SHALL be a neutral gray surface whose opacity the user controls, replacing the pure black backdrop, with rounded corners.

#### Scenario: Backdrop at mid opacity

- **WHEN** the background opacity is set to a mid value
- **THEN** the overlay draws a translucent gray backdrop through which the content behind remains recognizable

### Requirement: Overlay status bar

The overlay SHALL show a top status bar containing: a playback state pill reading "Paused" or "Rolling", an amber voice pill visible only while voice tracking is active, a meta line with the current scroll speed, estimated time left and "click-through" when click-through is enabled, and a drag-handle affordance.

#### Scenario: Paused with voice ready

- **WHEN** playback is paused and voice tracking is active
- **THEN** the status bar shows the "Paused" pill and the amber voice pill

#### Scenario: Voice tracking off

- **WHEN** voice tracking is not active
- **THEN** no voice pill is shown in the status bar

#### Scenario: Time left updates while rolling

- **WHEN** playback is rolling
- **THEN** the meta line's time-left value decreases as the script scrolls

### Requirement: Three-state script text hierarchy

The overlay SHALL render script text in three visual states driven by voice recognition: already-said text in the solid recognition color with no effects, the current word in the same recognition color with a soft centered glow (22 pt radius at 60% opacity) as the only self-lit element in the panel, and upcoming text in the normal reading color with no opacity or weight changes. State transitions SHALL change only color and glow — never size, weight, background or position — and SHALL animate over 160 ms with a linear curve. Only one word at a time SHALL carry the glow: when the recognition index jumps several words at once, intermediate words become already-said without glowing. The recognition index SHALL never move backwards; when recognition loses track, the highlight freezes in place until a new match. The glow SHALL be drawn beneath the general legibility shadow of the text, not replace it.

#### Scenario: Voice tracking highlights spoken text

- **WHEN** voice tracking confirms words have been spoken
- **THEN** already-said words render in the solid recognition color, the latest word carries the centered glow, and upcoming text renders in the reading color unchanged

#### Scenario: Recognition index jumps several words

- **WHEN** the recognition index advances several words at once
- **THEN** all intermediate words become already-said without glowing, and only the newest word carries the glow

#### Scenario: Recognition loses track

- **WHEN** the recognition stops matching the script
- **THEN** the highlight stays frozen at its position and never moves backwards

#### Scenario: No voice tracking

- **WHEN** voice tracking is inactive during playback
- **THEN** all text renders in the reading color with no recognition highlight and no glow

### Requirement: Configurable recognition color

The recognition color SHALL be user-configurable and SHALL maintain at least a 4.5:1 contrast ratio against the overlay panel reference; a stored color below that ratio SHALL fall back to the default recognition amber.

#### Scenario: Picking an accessible recognition color

- **WHEN** the user picks a recognition color with at least 4.5:1 contrast against the panel reference
- **THEN** the overlay uses that color for already-said text and the current word's glow

#### Scenario: Picking a low-contrast recognition color

- **WHEN** the stored recognition color falls below 4.5:1 contrast against the panel reference
- **THEN** the overlay falls back to the default recognition amber
