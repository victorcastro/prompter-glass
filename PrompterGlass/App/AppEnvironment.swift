import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class AppEnvironment {
    let preferences: OverlayPreferencesStore
    let activeScript: ActiveScriptStore
    let playback: ScrollPlaybackController
    let voiceTracking: VoiceTrackingController
    let overlay: OverlayPresenter

    @ObservationIgnored
    private nonisolated(unsafe) var terminationObserver: NSObjectProtocol?

    @ObservationIgnored
    private let notificationCenter: NotificationCenter

    init(preferences: OverlayPreferencesStore, notificationCenter: NotificationCenter = .default) {
        let activeScript = ActiveScriptStore(preferences: preferences)
        let playback = ScrollPlaybackController(preferences: preferences)
        let voiceTracking = VoiceTrackingController(
            playback: playback,
            permission: .live,
            makeSession: { VoiceTranscriptionSession() }
        )

        self.preferences = preferences
        self.notificationCenter = notificationCenter
        self.activeScript = activeScript
        self.playback = playback
        self.voiceTracking = voiceTracking
        overlay = OverlayPresenter(
            preferences: preferences,
            onDisplayViewChange: { [weak playback] view in playback?.displaySourceView = view },
            makeContent: {
                AnyView(
                    OverlayView(
                        activeScript: activeScript,
                        playback: playback,
                        voiceTracking: voiceTracking,
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
        voiceTracking.setScript(activeScript.text)
    }

    func stopPlayback() {
        voiceTracking.stopAndReset()
        playback.stop()
    }

    func setOverlayVisible(_ visible: Bool) {
        guard visible != overlay.isVisible else { return }
        overlay.setVisible(visible)
        if !visible {
            voiceTracking.setEnabled(false)
            playback.stop()
        }
    }

    func toggleOverlayVisibility() {
        setOverlayVisible(!overlay.isVisible)
    }
}
