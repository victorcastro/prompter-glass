import Observation
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let preferences: OverlayPreferencesStore
    let activeScript: ActiveScriptStore
    let playback: ScrollPlaybackController
    let overlay: OverlayPresenter

    init(preferences: OverlayPreferencesStore) {
        let activeScript = ActiveScriptStore(preferences: preferences)
        let playback = ScrollPlaybackController(preferences: preferences)

        self.preferences = preferences
        self.activeScript = activeScript
        self.playback = playback
        overlay = OverlayPresenter(
            preferences: preferences,
            onDisplayViewChange: { [weak playback] view in playback?.displaySourceView = view },
            makeContent: {
                AnyView(
                    OverlayView(
                        activeScript: activeScript,
                        playback: playback,
                        preferences: preferences
                    )
                )
            }
        )
    }

    func selectScript(_ script: Script?) {
        guard script?.id != activeScript.script?.id else {
            refreshPlaybackAvailability()
            return
        }
        activeScript.select(script)
        playback.stop()
        refreshPlaybackAvailability()
    }

    func clearActiveScript() {
        activeScript.clear()
        playback.stop()
        refreshPlaybackAvailability()
    }

    func refreshPlaybackAvailability() {
        playback.hasContent = activeScript.hasRenderableText
    }

    func setOverlayVisible(_ visible: Bool) {
        guard visible != overlay.isVisible else { return }
        overlay.setVisible(visible)
        if !visible {
            playback.stop()
        }
    }

    func toggleOverlayVisibility() {
        setOverlayVisible(!overlay.isVisible)
    }
}
