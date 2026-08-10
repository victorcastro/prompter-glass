# design-system Delta

## ADDED Requirements

### Requirement: Centralized color token library

The app SHALL define all UI colors, gradients and glass-surface styles in a single design-system token library, and all main-window sections and the overlay SHALL consume colors exclusively from it. The library SHALL include: an iris primary accent, an amber voice accent, per-section mood gradients (purple, forest, slate), glass fill and stroke styles, a three-level text hierarchy, and overlay text-state colors.

#### Scenario: Sections render from tokens

- **WHEN** any main-window section or the overlay renders
- **THEN** every color it draws resolves from the design-system token library rather than ad-hoc color literals in the view

#### Scenario: Changing a token value

- **WHEN** a token value is changed in the library
- **THEN** every surface consuming that token reflects the new value without further edits

### Requirement: Per-section mood backgrounds

The main window SHALL render an ambient gradient background whose mood matches the visible section: purple for Library and forest green for Prompter. Switching sections SHALL update the background.

#### Scenario: Switching sections changes the mood

- **WHEN** the user switches from Library to Prompter
- **THEN** the window background changes from the purple mood gradient to the forest mood gradient

### Requirement: Reusable glass components

The design system SHALL provide reusable components — glass card, icon chip, pill badge, Roll orb and mood background — and sections SHALL compose from them rather than restyling per view.

#### Scenario: Cards share one glass style

- **WHEN** the Library grid and the Prompter slider bar render
- **THEN** both use the same glass card component with identical fill, stroke and corner radius

### Requirement: Dark appearance enforced

The app SHALL render in dark appearance regardless of the system appearance setting, so glass surfaces and token contrast remain as designed.

#### Scenario: System is in light mode

- **WHEN** macOS is set to light appearance and the app launches
- **THEN** the main window and overlay still render with the dark design-system styling
