## ADDED Requirements

### Requirement: Adjustable background opacity

The app SHALL let the user adjust the opacity of the overlay's background from fully transparent to fully opaque, SHALL apply the change immediately, and SHALL persist the chosen value across launches.

#### Scenario: Lowering the background opacity

- **WHEN** the user lowers the background opacity
- **THEN** the content behind the overlay becomes more visible through its background immediately

#### Scenario: Fully transparent background

- **WHEN** the user sets the background opacity to its minimum
- **THEN** only the script text is drawn and the content behind the overlay is fully visible

#### Scenario: Opacity persists across launches

- **WHEN** the user sets a background opacity, quits the app and relaunches it
- **THEN** the overlay is drawn with the same background opacity

### Requirement: Text remains fully opaque

Changing the background opacity SHALL NOT change the opacity of the script text, so the text stays fully legible at any background setting.

#### Scenario: Background set to fully transparent

- **WHEN** the background opacity is set to its minimum
- **THEN** the script text is still rendered at full opacity

### Requirement: Adjustable text color

The app SHALL let the user choose the color of the script text in the overlay, SHALL apply the change immediately, and SHALL persist the chosen color across launches.

#### Scenario: Choosing a text color

- **WHEN** the user picks a text color
- **THEN** the overlay renders the script in that color immediately

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
