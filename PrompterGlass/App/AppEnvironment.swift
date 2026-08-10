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
    let sessionRecorder: SessionRecorder

    @ObservationIgnored
    var onSessionRecorded: ((SessionDraft) -> Void)?

    @ObservationIgnored
    private nonisolated(unsafe) var terminationObserver: NSObjectProtocol?

    @ObservationIgnored
    private let notificationCenter: NotificationCenter

    init(
        preferences: OverlayPreferencesStore,
        notificationCenter: NotificationCenter = .default,
        sessionClock: @escaping () -> Date = Date.init
    ) {
        let activeScript = ActiveScriptStore(preferences: preferences)
        let playback = ScrollPlaybackController(preferences: preferences)
        sessionRecorder = SessionRecorder(clock: sessionClock)
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
            makeContent: { presenter in
                AnyView(
                    OverlayView(
                        activeScript: activeScript,
                        playback: playback,
                        voiceTracking: voiceTracking,
                        preferences: preferences,
                        overlay: presenter
                    )
                )
            }
        )
        voiceTracking.setMicrophone(uid: preferences.microphoneUID)
        wireSessionRecording()
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
        finishSessionIfNeeded()
        overlay.tearDown()
    }

    private func wireSessionRecording() {
        playback.engine.onStateChange = { [weak self] oldState, newState in
            self?.handlePlaybackTransition(from: oldState, to: newState)
        }
        voiceTracking.onWordCountChanged = { [weak self] count in
            self?.sessionRecorder.noteSpokenWords(count)
        }
    }

    private func handlePlaybackTransition(
        from oldState: ScrollPlaybackEngine.State,
        to newState: ScrollPlaybackEngine.State
    ) {
        switch (oldState, newState) {
        case (.stopped, .playing):
            sessionRecorder.playbackStarted(
                scriptID: activeScript.script?.id,
                scriptTitle: activeScript.script?.title ?? Script.defaultTitle,
                usingVoice: voiceTracking.isActive
            )
        case (.paused, .playing):
            sessionRecorder.resume()
            sessionRecorder.noteVoiceUsed(voiceTracking.isActive)
        case (_, .paused):
            sessionRecorder.pause()
        case (_, .stopped):
            finishSessionIfNeeded()
        default:
            break
        }
    }

    private func finishSessionIfNeeded() {
        guard let draft = sessionRecorder.finish(reachedEnd: playback.engine.didReachEnd) else { return }
        onSessionRecorded?(draft)
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

    func selectMicrophone(uid: String?) {
        preferences.microphoneUID = uid
        voiceTracking.setMicrophone(uid: uid)
    }

    func stopPlayback() {
        voiceTracking.stopAndReset()
        playback.stop()
    }

    func toggleRolling() {
        if !playback.isPlaying, !overlay.isVisible {
            setOverlayVisible(true)
        }
        playback.toggle()
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
