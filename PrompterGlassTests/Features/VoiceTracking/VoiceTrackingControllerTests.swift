import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Voice tracking controller")
struct VoiceTrackingControllerTests {
    @MainActor
    private final class FakeSession: VoiceTranscribing {
        var startError: Error?
        /// Reported before the session finishes starting, the way a real model install would be.
        var installingModelLanguage: String?
        /// Never returns until cancelled, standing in for an install that does not complete.
        var hangsOnStart = false
        private(set) var stopped = false
        private(set) var startCount = 0
        private(set) var lastDeviceUID: String?
        private var onUpdate: (@MainActor (VoiceTranscriptionSession.Update) -> Void)?

        func start(
            deviceUID: String?,
            onPhase: @escaping @MainActor (VoiceTranscriptionSession.Phase) -> Void,
            onUpdate: @escaping @MainActor (VoiceTranscriptionSession.Update) -> Void
        ) async throws {
            if let installingModelLanguage {
                onPhase(.installingModel(language: installingModelLanguage))
            }
            if hangsOnStart {
                try await Task.sleep(for: .seconds(30))
            }
            if let startError {
                throw startError
            }
            onPhase(.starting)
            startCount += 1
            lastDeviceUID = deviceUID
            self.onUpdate = onUpdate
        }

        func stop() {
            stopped = true
        }

        func emit(_ text: String, isFinal: Bool = false) {
            onUpdate?(VoiceTranscriptionSession.Update(text: text, isFinal: isFinal))
        }
    }

    private struct Harness {
        let controller: VoiceTrackingController
        let playback: ScrollPlaybackController
        let session: FakeSession
    }

    private func makeHarness(
        permission: MicrophonePermission.Status = .granted,
        requestOutcome: Bool = true,
        startError: Error? = nil,
        script: String = "hello world how are you",
        activationTimeout: Duration = .seconds(30)
    ) -> Harness {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let playback = ScrollPlaybackController(preferences: OverlayPreferencesStore(defaults: defaults))
        playback.hasContent = true
        playback.engine.updateContentHeight(1000)
        playback.engine.updateViewportHeight(500)

        let session = FakeSession()
        session.startError = startError
        let controller = VoiceTrackingController(
            playback: playback,
            permission: MicrophonePermissionClient(
                status: { permission },
                request: { requestOutcome }
            ),
            makeSession: { session },
            activationTimeout: activationTimeout
        )
        controller.setScript(script)
        return Harness(controller: controller, playback: playback, session: session)
    }

    @Test("Enabling with permission granted starts listening and drives playback")
    func grantedFlowListens() async {
        let harness = makeHarness()

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .listening)
        #expect(harness.playback.engine.isVoiceDriven)
    }

    @Test("Denied permission surfaces the denied state and never listens")
    func deniedPermissionStopsFlow() async {
        let harness = makeHarness(permission: .denied)

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .denied)
        #expect(harness.playback.engine.isVoiceDriven == false)
    }

    @Test("A rejected permission request ends in the denied state")
    func rejectedRequestEndsDenied() async {
        let harness = makeHarness(permission: .undetermined, requestOutcome: false)

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .denied)
    }

    @Test("A session that fails to start reports unavailable")
    func failedSessionIsUnavailable() async {
        struct Boom: Error {}
        let harness = makeHarness(startError: Boom())

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .unavailable(.unknown))
        #expect(harness.session.stopped)
    }

    @Test("Enabling without a script reports that a script is needed and never opens the microphone")
    func withoutScriptReportsNoScript() async {
        let harness = makeHarness(script: "   \n  ")

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .noScript)
        #expect(harness.session.startCount == 0)
        #expect(harness.controller.isActive == false)
    }

    @Test("Picking a script clears the no-script state")
    func scriptClearsNoScriptState() async {
        let harness = makeHarness(script: "")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()
        #expect(harness.controller.state == .noScript)

        harness.controller.setScript("now there is something to read")

        #expect(harness.controller.state == .idle)
    }

    @Test("A model installation is reported as its own state before listening starts")
    func modelInstallationIsReported() async {
        let harness = makeHarness()
        harness.session.installingModelLanguage = "English"
        harness.session.hangsOnStart = true

        harness.controller.setEnabled(true)
        #expect(await waitFor { harness.controller.state == .downloadingModel(language: "English") })
        #expect(harness.controller.isActive)
    }

    @Test("An activation that never completes ends in a stated failure")
    func stalledActivationTimesOut() async {
        let harness = makeHarness(activationTimeout: .milliseconds(30))
        harness.session.hangsOnStart = true

        harness.controller.setEnabled(true)
        #expect(await waitFor { harness.controller.state == .unavailable(.modelUnavailable) })
        #expect(harness.controller.isActive == false)
        #expect(harness.playback.engine.isVoiceDriven == false)
    }

    @Test("Each session error keeps its own reason instead of blaming the language")
    func errorsKeepTheirReason() async {
        let cases: [(VoiceTranscriptionSession.SessionError, VoiceTrackingController.Reason)] = [
            (.localeNotSupported, .languageNotSupported),
            (.modelUnavailable, .modelUnavailable),
            (.audioFormatUnavailable, .audioInputFailed),
            (.audioEngineFailed, .audioInputFailed)
        ]
        for (error, reason) in cases {
            let harness = makeHarness(startError: error)

            harness.controller.setEnabled(true)
            await harness.controller.waitUntilSettled()

            #expect(harness.controller.state == .unavailable(reason))
            #expect(harness.controller.canRetry)
        }
    }

    @Test("Retry reaches the listening state once the cause is gone")
    func retryStartsListening() async {
        struct Boom: Error {}
        let harness = makeHarness(startError: Boom())
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()
        #expect(harness.controller.canRetry)

        harness.session.startError = nil
        harness.controller.retry()
        await harness.controller.waitUntilSettled()

        #expect(harness.controller.state == .listening)
    }

    @Test("Recognized words extend the highlight and move the scroll target")
    func updatesAdvanceHighlightAndScroll() async {
        let harness = makeHarness(script: "hello world how are you")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("hello world", isFinal: true)

        #expect(harness.controller.highlightedUTF16Length == "hello world".utf16.count)
        #expect((harness.playback.engine.voiceTargetOffset ?? 0) > 0)
    }

    @Test("Volatile re-emissions do not double-count and the in-progress word is held back")
    func volatileDeltasAreIncremental() async {
        let harness = makeHarness(script: "one two three four five")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("one")
        harness.session.emit("one two")
        harness.session.emit("one two", isFinal: true)
        harness.session.emit("three four")

        #expect(harness.controller.highlightedUTF16Length == "one two three four".utf16.count)
    }

    @Test("The word being spoken is highlighted speculatively as soon as it matches")
    func speculativeHighlightAppearsImmediately() async {
        let harness = makeHarness(script: "hello world how are you")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("hello")

        #expect(harness.controller.highlightedUTF16Length == "hello".utf16.count)
    }

    @Test("A wrong in-progress word is not highlighted")
    func wrongSpeculationDoesNotHighlight() async {
        let harness = makeHarness(script: "hello world how are you")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("goodbye")

        #expect(harness.controller.highlightedUTF16Length == 0)
    }

    @Test("A partial prefix of the next word lights it up early")
    func partialPrefixSpeculates() async {
        let harness = makeHarness(script: "teleprompter overlay")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("telep")

        #expect(harness.controller.highlightedUTF16Length == "teleprompter".utf16.count)
    }

    @Test("A word that finishes forming is ingested complete, not as its early prefix")
    func inProgressWordIsIngestedComplete() async {
        let harness = makeHarness(script: "I'm applying for the position")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.session.emit("I")
        harness.session.emit("I'm")
        harness.session.emit("I'm applying")
        harness.session.emit("I'm applying for")

        #expect(harness.controller.highlightedUTF16Length == "I'm applying for".utf16.count)
    }

    @Test("Disabling stops the session and pauses playback")
    func disablingStopsEverything() async {
        let harness = makeHarness()
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.controller.setEnabled(false)

        #expect(harness.controller.state == .idle)
        #expect(harness.session.stopped)
        #expect(harness.playback.engine.isVoiceDriven == false)
    }

    @Test("The chosen microphone is handed to the transcription session")
    func selectedMicrophoneReachesSession() async {
        let harness = makeHarness()
        harness.controller.setMicrophone(uid: "usb-mic-42")

        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        #expect(harness.session.lastDeviceUID == "usb-mic-42")
    }

    @Test("Switching microphones while listening restarts the session")
    func switchingMicrophoneRestartsSession() async {
        let harness = makeHarness()
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()
        #expect(harness.session.startCount == 1)

        harness.controller.setMicrophone(uid: "usb-mic-42")
        await harness.controller.waitUntilSettled()

        #expect(harness.session.stopped)
        #expect(harness.session.startCount == 2)
        #expect(harness.session.lastDeviceUID == "usb-mic-42")
        #expect(harness.controller.state == .listening)
    }

    @Test("Re-selecting the same microphone does not restart the session")
    func sameMicrophoneIsNoOp() async {
        let harness = makeHarness()
        harness.controller.setMicrophone(uid: "usb-mic-42")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()

        harness.controller.setMicrophone(uid: "usb-mic-42")
        await harness.controller.waitUntilSettled()

        #expect(harness.session.startCount == 1)
    }

    @Test("Stop clears the highlight and turns voice tracking off")
    func stopClearsHighlightAndDisables() async {
        let harness = makeHarness(script: "hello world how are you")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()
        harness.session.emit("hello world", isFinal: true)
        #expect(harness.controller.highlightedUTF16Length > 0)

        harness.controller.stopAndReset()

        #expect(harness.controller.state == .idle)
        #expect(harness.controller.highlightedUTF16Length == 0)
        #expect(harness.session.stopped)
        #expect(harness.playback.engine.isVoiceDriven == false)
    }

    @Test("Changing the script resets the highlight")
    func scriptChangeResetsHighlight() async {
        let harness = makeHarness(script: "alpha beta gamma")
        harness.controller.setEnabled(true)
        await harness.controller.waitUntilSettled()
        harness.session.emit("alpha beta")

        harness.controller.setScript("totally different text")

        #expect(harness.controller.highlightedUTF16Length == 0)
        #expect(harness.controller.state == .idle)
    }

    private func waitFor(
        timeout: Duration = .seconds(2),
        _ predicate: @escaping @MainActor () -> Bool
    ) async -> Bool {
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            if predicate() { return true }
            try? await Task.sleep(for: .milliseconds(5))
        }
        return predicate()
    }
}
