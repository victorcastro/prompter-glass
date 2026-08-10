import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let preferences: OverlayPreferencesStore
    let activeScript: ActiveScriptStore
    let playback: ScrollPlaybackController
    let overlay: OverlayPresenter

    @ObservationIgnored
    private nonisolated(unsafe) var terminationObserver: NSObjectProtocol?

    @ObservationIgnored
    private let notificationCenter: NotificationCenter

    init(preferences: OverlayPreferencesStore, notificationCenter: NotificationCenter = .default) {
        let activeScript = ActiveScriptStore(preferences: preferences)
        let playback = ScrollPlaybackController(preferences: preferences)

        self.preferences = preferences
        self.notificationCenter = notificationCenter
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
        terminationObserver = notificationCenter.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.prepareForTermination()
            }
        }
    }

    deinit {
        if let terminationObserver {
            notificationCenter.removeObserver(terminationObserver)
        }
    }

    func prepareForTermination() {
        overlay.tearDown()
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
