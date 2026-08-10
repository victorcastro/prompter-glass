# overlay-appearance Delta

## MODIFIED Requirements

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

### Requirement: Adjustable text color

The app SHALL let the user choose the color of the script text in the overlay, SHALL apply the change immediately, and SHALL persist the chosen color across launches. The default text color SHALL be white.

#### Scenario: Choosing a text color

- **WHEN** the user picks a text color
- **THEN** the overlay renders the script in that color immediately

#### Scenario: Text color persists across launches

- **WHEN** the user picks a text color, quits the app and relaunches it
- **THEN** the overlay renders the script in the same color

#### Scenario: Stored color cannot be read

- **WHEN** the app launches and the stored text color is missing or unreadable
- **THEN** the overlay falls back to white instead of failing to render
