import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Session recorder")
struct SessionRecorderTests {
    private final class FakeClock {
        var now = Date(timeIntervalSince1970: 1000)
        func advance(_ seconds: Double) {
            now = now.addingTimeInterval(seconds)
        }
    }

    private func makeRecorder() -> (SessionRecorder, FakeClock) {
        let clock = FakeClock()
        return (SessionRecorder(clock: { clock.now }), clock)
    }

    @Test("A full run records script identity, duration and end flag")
    func recordsFullRun() {
        let (recorder, clock) = makeRecorder()
        let scriptID = UUID()

        recorder.playbackStarted(scriptID: scriptID, scriptTitle: "Intro", usingVoice: false)
        clock.advance(42)
        let draft = recorder.finish(reachedEnd: true)

        #expect(draft?.scriptID == scriptID)
        #expect(draft?.scriptTitle == "Intro")
        #expect(draft?.onAirSeconds == 42)
        #expect(draft?.reachedEnd == true)
        #expect(draft?.usedVoiceTracking == false)
    }

    @Test("Pauses do not count as on-air time")
    func pausesExcluded() {
        let (recorder, clock) = makeRecorder()

        recorder.playbackStarted(scriptID: nil, scriptTitle: "A", usingVoice: false)
        clock.advance(10)
        recorder.pause()
        clock.advance(60)
        recorder.resume()
        clock.advance(5)
        let draft = recorder.finish(reachedEnd: false)

        #expect(draft?.onAirSeconds == 15)
    }

    @Test("Sessions shorter than the minimum are discarded")
    func shortSessionDiscarded() {
        let (recorder, clock) = makeRecorder()

        recorder.playbackStarted(scriptID: nil, scriptTitle: "A", usingVoice: false)
        clock.advance(3)

        #expect(recorder.finish(reachedEnd: false) == nil)
        #expect(recorder.isRecording == false)
    }

    @Test("Spoken words keep a running maximum across voice resets")
    func spokenWordsRunningMax() {
        let (recorder, clock) = makeRecorder()

        recorder.playbackStarted(scriptID: nil, scriptTitle: "A", usingVoice: true)
        recorder.noteSpokenWords(40)
        recorder.noteSpokenWords(0)
        clock.advance(20)
        let draft = recorder.finish(reachedEnd: false)

        #expect(draft?.spokenWordCount == 40)
        #expect(draft?.usedVoiceTracking == true)
    }

    @Test("Finishing without a session yields nothing")
    func finishWithoutSession() {
        let (recorder, _) = makeRecorder()

        #expect(recorder.finish(reachedEnd: false) == nil)
    }
}
