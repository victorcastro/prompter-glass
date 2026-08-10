# scroll-playback Delta

## ADDED Requirements

### Requirement: Playback resources are released deterministically

The playback display link SHALL NOT keep its driver alive through a retain cycle: releasing the last owning reference to the playback driver SHALL invalidate and release the display link, even if playback was running at that moment.

#### Scenario: Driver released while playing

- **WHEN** the playback driver is running and its last owning reference is released
- **THEN** the display link is invalidated and no further ticks are delivered

#### Scenario: Driver released while stopped

- **WHEN** the playback driver is stopped and its last owning reference is released
- **THEN** the driver deallocates without leaving a display link behind

### Requirement: Driver running state stays consistent when the source view disappears

If the display link was created from the overlay's content view and that view is destroyed while playback is running, the driver SHALL either continue ticking from a screen-based display link or transition to a stopped state; its reported running state SHALL always match whether ticks are being delivered.

#### Scenario: Overlay closed mid-playback

- **WHEN** the overlay window is torn down while the script is scrolling
- **THEN** playback continues driven by a screen-based display link, or the driver reports itself stopped — it never reports running while delivering no ticks
