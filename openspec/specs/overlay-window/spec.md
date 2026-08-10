# overlay-window Specification

## Purpose
TBD - created by archiving change add-teleprompter-mvp. Update Purpose after archive.
## Requirements
### Requirement: Borderless overlay panel

The app SHALL present the teleprompter text in a borderless window with no title bar, no traffic-light buttons and no visible frame, so only the script text and its background are drawn.

#### Scenario: Showing the overlay

- **WHEN** the user shows the overlay
- **THEN** a window appears containing only the script content, with no title bar, no window buttons and no border

#### Scenario: Overlay is excluded from standard window cycling

- **WHEN** the overlay is visible and the user cycles windows with the standard system shortcut
- **THEN** the overlay is not offered as a cycling target and remains in place

### Requirement: Overlay floats above other applications

The overlay SHALL be displayed above the windows of all other applications while it is visible, regardless of which application is frontmost.

#### Scenario: Another app is activated

- **WHEN** the overlay is visible and the user clicks another application to bring it to the front
- **THEN** the overlay remains visible on top of that application's windows

#### Scenario: App is in the background

- **WHEN** PrompterGlass is not the active application
- **THEN** the overlay stays on screen instead of hiding with the rest of the app

### Requirement: Overlay does not steal focus

Interacting with the overlay SHALL NOT activate PrompterGlass or move keyboard focus away from the application the user is working in.

#### Scenario: Clicking the overlay while another app is frontmost

- **WHEN** the user clicks or drags the overlay while another application is frontmost
- **THEN** that application stays frontmost and keeps keyboard focus, and PrompterGlass is not brought forward

### Requirement: Overlay is visible on all Spaces and over fullscreen apps

The overlay SHALL appear on every Space and SHALL remain visible when another application is in fullscreen mode.

#### Scenario: Switching Spaces

- **WHEN** the user switches to a different Space
- **THEN** the overlay is visible on the new Space at the same position

#### Scenario: Another app enters fullscreen

- **WHEN** the user puts another application into fullscreen mode
- **THEN** the overlay remains visible on top of that fullscreen window

### Requirement: Overlay is draggable

The user SHALL be able to reposition the overlay by dragging anywhere on its body, since it has no title bar to drag.

#### Scenario: Dragging the overlay

- **WHEN** the user presses on the overlay background and drags
- **THEN** the overlay follows the pointer and stays at the position where the drag ended

### Requirement: Overlay is resizable

The user SHALL be able to resize the overlay, and the app SHALL enforce a minimum size that keeps the overlay visible and usable.

#### Scenario: Resizing the overlay

- **WHEN** the user drags the overlay's resize affordance
- **THEN** the overlay changes size and the script text reflows to the new width

#### Scenario: Resizing below the minimum

- **WHEN** the user attempts to resize the overlay smaller than the minimum size
- **THEN** the overlay stops shrinking at the minimum size

### Requirement: Overlay size is configurable numerically

The app SHALL let the user set the overlay's width and height in points from the main window, SHALL clamp the entered values so the overlay stays visible and usable, and SHALL keep the entered values in sync when the overlay is resized by dragging.

#### Scenario: Typing a size

- **WHEN** the user enters a width and height for the overlay
- **THEN** the overlay resizes to those dimensions and its top edge stays where it was

#### Scenario: Entering a size outside the usable range

- **WHEN** the user enters a size smaller than the minimum or larger than the screen
- **THEN** the value is clamped to the nearest usable size rather than applied as entered

#### Scenario: Resizing by dragging updates the fields

- **WHEN** the user resizes the overlay by dragging
- **THEN** the width and height fields show the new size

### Requirement: Overlay visibility is toggleable

The app SHALL allow the user to show and hide the overlay from the main window.

#### Scenario: Hiding the overlay

- **WHEN** the overlay is visible and the user toggles it off
- **THEN** the overlay is removed from the screen and scrolling stops

#### Scenario: Showing the overlay again

- **WHEN** the overlay is hidden and the user toggles it on
- **THEN** the overlay reappears at its last position and size

### Requirement: Click-through mode

The app SHALL provide a click-through mode in which the overlay ignores all mouse events and passes them to the application underneath, and this mode SHALL be toggleable from the main window.

#### Scenario: Enabling click-through

- **WHEN** click-through mode is enabled and the user clicks over the overlay
- **THEN** the click is received by the application underneath and the overlay does not move or react

#### Scenario: Disabling click-through

- **WHEN** click-through mode is disabled from the main window
- **THEN** the overlay again responds to dragging and to its own controls

#### Scenario: Click-through is never restored on launch

- **WHEN** the user quits the app with click-through enabled and relaunches it
- **THEN** the overlay starts in interactive mode, so the user cannot be locked out of the overlay

### Requirement: Overlay position and size persist across launches

The app SHALL save the overlay's frame when it is moved or resized and SHALL restore that frame the next time the overlay is shown, including after a relaunch. Any pending debounced frame save SHALL be flushed when the app terminates, so a move or resize immediately before quitting is never lost.

#### Scenario: Frame restored after relaunch

- **WHEN** the user moves and resizes the overlay, quits the app, and relaunches it
- **THEN** the overlay is shown at the same position and size

#### Scenario: Overlay appears directly at its restored frame

- **WHEN** the overlay is shown at launch with a saved frame
- **THEN** it appears at that frame without first appearing elsewhere and jumping

#### Scenario: Saved frame is off-screen

- **WHEN** the app launches and the saved frame does not intersect any connected display
- **THEN** the app discards the saved frame and shows the overlay centered on the main display at the default size

#### Scenario: First launch with no saved frame

- **WHEN** the overlay is shown for the first time and no frame has been saved
- **THEN** the app shows the overlay at its default size of 800 by 600 points, docked to the top of the main display and centred horizontally

#### Scenario: First launch on a very wide display

- **WHEN** the overlay is shown for the first time on an ultrawide display
- **THEN** the default size stays 800 by 600 rather than scaling with the screen, so the overlay does not open far wider than a readable column

#### Scenario: First launch on a display smaller than the default size

- **WHEN** the overlay is shown for the first time on a display smaller than 800 by 600
- **THEN** the overlay is sized to fit that display instead of extending past its edges

#### Scenario: Quit within the save debounce window

- **WHEN** the user moves or resizes the overlay and quits the app before the debounced save fires
- **THEN** the final frame is persisted during termination and restored on the next launch

### Requirement: Overlay tears down on app termination

The app SHALL run the overlay teardown path when the application terminates, releasing the overlay window and emitting the display-view-cleared callback exactly once.

#### Scenario: App quits with overlay visible

- **WHEN** the app terminates while the overlay is visible
- **THEN** overlay teardown runs, the pending frame save is flushed, and the display-view-cleared callback fires exactly once

