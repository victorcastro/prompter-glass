import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Voice tracking controller")
struct VoiceTrackingControllerTests {
    @MainActor
    private final class FakeSession: VoiceTranscribing {
        var startError: Error?
        private(set) var stopped = false
        private var onUpdate: (@MainActor (VoiceTranscriptionSession.Update) -> Void)?

        func start(onUpdate: @escaping @MainActor (VoiceTranscriptionSession.Update) -> Void) async throws {
            if let startError {
                throw startError
            }
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
        script: String = "hello world how are you"
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
            makeSession: { session }
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

        #expect(harness.controller.state == .unavailable)
        #expect(harness.session.stopped)
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

        #expect(harness.controller.highlightedUTF16Length == "one two three".utf16.count)
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

        #expect(harness.controller.highlightedUTF16Length == "I'm applying".utf16.count)
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
}
