import Foundation
import Observation

@MainActor
@Observable
final class ScrollPlaybackEngine {
    enum State: Equatable {
        case stopped
        case playing
        case paused
    }

    private(set) var state: State = .stopped {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(oldValue, state)
        }
    }

    @ObservationIgnored
    var onStateChange: ((State, State) -> Void)?

    private(set) var offset: Double = 0

    private(set) var didReachEnd = false

    var speed: Double = OverlayPreferencesStore.Defaults.scrollSpeed

    var hasContent = false

    private(set) var contentHeight: Double = 0
    private(set) var viewportHeight: Double = 0

    private(set) var voiceTargetOffset: Double?

    private static let voiceEasingRate: Double = 4
    private static let voiceReadingZoneFraction: Double = 1.0 / 3.0

    var maxOffset: Double {
        max(0, contentHeight - viewportHeight)
    }

    var isPlaying: Bool {
        state == .playing
    }

    func start() {
        guard hasContent else { return }
        switch state {
        case .playing:
            return
        case .paused:
            resume()
        case .stopped:
            offset = 0
            didReachEnd = false
            state = .playing
        }
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
    }

    func resume() {
        guard state == .paused, hasContent else { return }
        didReachEnd = false
        state = .playing
    }

    func stop() {
        state = .stopped
        offset = 0
        didReachEnd = false
        voiceTargetOffset = nil
    }

    var isVoiceDriven: Bool {
        voiceTargetOffset != nil
    }

    func startVoiceTracking() {
        guard hasContent else { return }
        didReachEnd = false
        voiceTargetOffset = offset
        state = .playing
    }

    func endVoiceTracking() {
        guard isVoiceDriven else { return }
        voiceTargetOffset = nil
        state = offset > 0 ? .paused : .stopped
    }

    func setVoiceTarget(progress: Double) {
        guard isVoiceDriven, progress.isFinite else { return }
        let clamped = progress.clamped(to: 0 ... 1)
        let anchor = clamped * contentHeight - viewportHeight * ScrollPlaybackEngine.voiceReadingZoneFraction
        voiceTargetOffset = anchor.clamped(to: 0 ... max(0, maxOffset))
    }

    func seek(toProgress progress: Double) {
        guard hasContent, progress.isFinite else { return }
        offset = progress.clamped(to: 0 ... 1) * maxOffset
        didReachEnd = false
    }

    func advance(by deltaTime: TimeInterval) {
        guard state == .playing, deltaTime > 0 else { return }
        if let target = voiceTargetOffset {
            let step = min(1, deltaTime * ScrollPlaybackEngine.voiceEasingRate)
            offset += (target - offset) * step
            return
        }
        let limit = maxOffset
        guard limit > 0 else {
            finishAtEnd(limit: 0)
            return
        }
        let next = offset + speed * deltaTime
        if next >= limit {
            finishAtEnd(limit: limit)
        } else {
            offset = next
        }
    }

    private func finishAtEnd(limit: Double) {
        offset = limit
        didReachEnd = true
        state = .stopped
    }

    func updateContentHeight(_ newValue: Double) {
        guard newValue.isFinite, newValue >= 0, newValue != contentHeight else { return }
        let progress = progressThroughScript
        contentHeight = newValue
        offset = min(progress * maxOffset, maxOffset)
    }

    func updateViewportHeight(_ newValue: Double) {
        guard newValue.isFinite, newValue >= 0, newValue != viewportHeight else { return }
        let progress = progressThroughScript
        viewportHeight = newValue
        offset = min(progress * maxOffset, maxOffset)
    }

    private var progressThroughScript: Double {
        let limit = maxOffset
        guard limit > 0 else { return 0 }
        return offset / limit
    }
}
