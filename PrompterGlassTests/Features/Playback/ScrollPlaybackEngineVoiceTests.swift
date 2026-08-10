import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Scroll playback engine voice mode")
struct ScrollPlaybackEngineVoiceTests {
    private func makeEngine() -> ScrollPlaybackEngine {
        let engine = ScrollPlaybackEngine()
        engine.hasContent = true
        engine.updateContentHeight(1000)
        engine.updateViewportHeight(500)
        return engine
    }

    @Test("Voice tracking cannot start without content")
    func voiceNeedsContent() {
        let engine = ScrollPlaybackEngine()

        engine.startVoiceTracking()

        #expect(engine.isVoiceDriven == false)
        #expect(engine.state == .stopped)
    }

    @Test("Starting voice tracking plays and anchors the target at the current offset")
    func startAnchorsAtCurrentOffset() {
        let engine = makeEngine()

        engine.startVoiceTracking()

        #expect(engine.state == .playing)
        #expect(engine.isVoiceDriven)
        #expect(engine.voiceTargetOffset == 0)
    }

    @Test("The voice target keeps the reading position in the upper third")
    func targetUsesReadingZone() {
        let engine = makeEngine()
        engine.startVoiceTracking()

        engine.setVoiceTarget(progress: 0.5)

        let expected = 0.5 * 1000 - 500.0 / 3.0
        #expect(abs((engine.voiceTargetOffset ?? -1) - expected) < 0.001)
    }

    @Test("The voice target is clamped to the scrollable range")
    func targetIsClamped() {
        let engine = makeEngine()
        engine.startVoiceTracking()

        engine.setVoiceTarget(progress: 1)
        #expect(engine.voiceTargetOffset == engine.maxOffset)

        engine.setVoiceTarget(progress: 0)
        #expect(engine.voiceTargetOffset == 0)
    }

    @Test("Advancing eases toward the target without overshooting")
    func advanceEasesTowardTarget() {
        let engine = makeEngine()
        engine.startVoiceTracking()
        engine.setVoiceTarget(progress: 1)

        var previous = engine.offset
        for _ in 0 ..< 50 {
            engine.advance(by: 0.1)
            #expect(engine.offset >= previous)
            #expect(engine.offset <= engine.maxOffset)
            previous = engine.offset
        }
        #expect(abs(engine.offset - engine.maxOffset) < 1)
    }

    @Test("Ending voice tracking pauses at the current position")
    func endPausesInPlace() {
        let engine = makeEngine()
        engine.startVoiceTracking()
        engine.setVoiceTarget(progress: 1)
        engine.advance(by: 1)

        engine.endVoiceTracking()

        #expect(engine.isVoiceDriven == false)
        #expect(engine.state == .paused)
        #expect(engine.offset > 0)
    }

    @Test("Stop clears the voice target")
    func stopClearsVoiceTarget() {
        let engine = makeEngine()
        engine.startVoiceTracking()

        engine.stop()

        #expect(engine.isVoiceDriven == false)
        #expect(engine.offset == 0)
    }

    @Test("Fixed-speed playback is unaffected when voice tracking is off")
    func fixedSpeedUnchanged() {
        let engine = makeEngine()
        engine.speed = 100

        engine.start()
        engine.advance(by: 1)

        #expect(engine.offset == 100)
    }
}
