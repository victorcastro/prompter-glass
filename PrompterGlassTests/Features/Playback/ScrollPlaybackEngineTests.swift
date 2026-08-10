import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Scroll playback engine")
struct ScrollPlaybackEngineTests {
    private func makeEngine(speed: Double = 100) -> ScrollPlaybackEngine {
        let engine = ScrollPlaybackEngine()
        engine.hasContent = true
        engine.updateContentHeight(1000)
        engine.updateViewportHeight(500)
        engine.speed = speed
        return engine
    }

    @Test("maxOffset is the content that does not fit in the viewport")
    func maxOffsetIsOverflow() {
        let engine = makeEngine()
        #expect(engine.maxOffset == 500)
    }

    @Test("Starting from stopped plays from the first line")
    func startResetsOffset() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 1)
        #expect(engine.offset == 100)

        engine.stop()
        engine.start()

        #expect(engine.state == .playing)
        #expect(engine.offset == 0)
    }

    @Test("Starting is refused when there is no active script")
    func startRequiresContent() {
        let engine = makeEngine()
        engine.hasContent = false

        engine.start()

        #expect(engine.state == .stopped)
        #expect(engine.offset == 0)
    }

    @Test("Pausing freezes the offset and resuming continues from it")
    func pausePreservesOffsetAndResumeContinues() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 1.5)
        let atPause = engine.offset

        engine.pause()
        engine.advance(by: 10)

        #expect(engine.state == .paused)
        #expect(engine.offset == atPause)

        engine.resume()
        engine.advance(by: 1)

        #expect(engine.state == .playing)
        #expect(engine.offset == atPause + 100)
    }

    @Test("Stopping from playing returns to the first line")
    func stopFromPlayingResets() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 2)

        engine.stop()

        #expect(engine.state == .stopped)
        #expect(engine.offset == 0)
    }

    @Test("Stopping from paused returns to the first line")
    func stopFromPausedResets() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 2)
        engine.pause()

        engine.stop()

        #expect(engine.state == .stopped)
        #expect(engine.offset == 0)
    }

    @Test("Reaching the end stops automatically without scrolling past the content")
    func autoStopsAtTheEnd() {
        let engine = makeEngine()
        engine.start()

        engine.advance(by: 100)

        #expect(engine.state == .stopped)
        #expect(engine.didReachEnd)
        #expect(engine.offset == 500)
    }

    @Test("A script that already fits stops immediately with nothing to scroll")
    func contentShorterThanViewportStopsImmediately() {
        let engine = ScrollPlaybackEngine()
        engine.hasContent = true
        engine.updateContentHeight(200)
        engine.updateViewportHeight(500)

        engine.start()
        engine.advance(by: 1)

        #expect(engine.maxOffset == 0)
        #expect(engine.state == .stopped)
        #expect(engine.offset == 0)
    }

    @Test("Changing speed mid-scroll does not move the text")
    func speedChangeIsContinuous() {
        let engine = makeEngine(speed: 50)
        engine.start()
        engine.advance(by: 2)
        let beforeChange = engine.offset

        engine.speed = 200

        #expect(engine.offset == beforeChange)

        engine.advance(by: 1)

        #expect(engine.offset == beforeChange + 200)
    }

    @Test("Equal elapsed time produces equal distance regardless of tick count")
    func scrollIsFrameRateIndependent() {
        let smoothRun = makeEngine()
        smoothRun.start()
        for _ in 0 ..< 60 {
            smoothRun.advance(by: 1.0 / 60.0)
        }

        let droppedFrames = makeEngine()
        droppedFrames.start()
        for _ in 0 ..< 6 {
            droppedFrames.advance(by: 1.0 / 6.0)
        }

        #expect(abs(smoothRun.offset - droppedFrames.offset) < 0.000_001)
    }

    @Test("Non-positive deltas are ignored")
    func nonPositiveDeltaDoesNothing() {
        let engine = makeEngine()
        engine.start()

        engine.advance(by: 0)
        engine.advance(by: -1)

        #expect(engine.offset == 0)
    }

    @Test("A font-size change keeps the reader on the same passage")
    func contentHeightChangePreservesProgress() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 2.5)
        #expect(engine.offset == 250)

        engine.updateContentHeight(2000)

        #expect(engine.maxOffset == 1500)
        #expect(engine.offset == 750)
    }

    @Test("Resizing the overlay keeps the reader on the same passage")
    func viewportHeightChangePreservesProgress() {
        let engine = makeEngine()
        engine.start()
        engine.advance(by: 2.5)

        engine.updateViewportHeight(750)

        #expect(engine.maxOffset == 250)
        #expect(engine.offset == 125)
    }

    @Test("Seeking moves the offset to the requested progress")
    func seekMovesOffset() {
        let engine = makeEngine()

        engine.seek(toProgress: 0.5)

        #expect(engine.offset == engine.maxOffset / 2)
    }

    @Test("Seeking clamps out-of-range and non-finite progress")
    func seekClampsInput() {
        let engine = makeEngine()

        engine.seek(toProgress: 2)
        #expect(engine.offset == engine.maxOffset)

        engine.seek(toProgress: -1)
        #expect(engine.offset == 0)

        engine.seek(toProgress: .nan)
        #expect(engine.offset == 0)
    }

    @Test("Seeking without content is ignored")
    func seekWithoutContentIsIgnored() {
        let engine = ScrollPlaybackEngine()

        engine.seek(toProgress: 0.5)

        #expect(engine.offset == 0)
    }
}
