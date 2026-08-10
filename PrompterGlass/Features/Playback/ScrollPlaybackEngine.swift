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

    private(set) var state: State = .stopped

    private(set) var offset: Double = 0

    private(set) var didReachEnd = false

    var speed: Double = OverlayPreferencesStore.Defaults.scrollSpeed

    var hasContent = false

    private(set) var contentHeight: Double = 0
    private(set) var viewportHeight: Double = 0

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
    }

    func advance(by deltaTime: TimeInterval) {
        guard state == .playing, deltaTime > 0 else { return }
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
        state = .stopped
        didReachEnd = true
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
