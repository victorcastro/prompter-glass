import AppKit
import Observation

@MainActor
@Observable
final class ScrollPlaybackController {
    let engine: ScrollPlaybackEngine

    @ObservationIgnored
    private let preferences: OverlayPreferencesStore

    @ObservationIgnored
    weak var displaySourceView: NSView?

    @ObservationIgnored
    private var driver: DisplayLinkDriver?

    init(preferences: OverlayPreferencesStore, engine: ScrollPlaybackEngine? = nil) {
        self.preferences = preferences
        let resolved = engine ?? ScrollPlaybackEngine()
        self.engine = resolved
        resolved.speed = preferences.scrollSpeed
    }

    var speed: Double {
        get { preferences.scrollSpeed }
        set {
            preferences.scrollSpeed = newValue
            engine.speed = preferences.scrollSpeed
        }
    }

    var isPlaying: Bool {
        engine.isPlaying
    }

    var canStop: Bool {
        engine.state != .stopped || engine.offset > 0
    }

    var hasContent: Bool {
        get { engine.hasContent }
        set {
            engine.hasContent = newValue
            if !newValue, engine.state != .stopped {
                stop()
            }
        }
    }

    func start() {
        engine.start()
        syncDriver()
    }

    func pause() {
        engine.pause()
        syncDriver()
    }

    func stop() {
        engine.stop()
        syncDriver()
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            start()
        }
    }

    private func syncDriver() {
        if isPlaying {
            resolvedDriver.start()
        } else {
            driver?.stop()
        }
    }

    private var resolvedDriver: DisplayLinkDriver {
        if let driver { return driver }
        let created = DisplayLinkDriver(
            source: { [weak self] in self?.displaySourceView },
            onTick: { [weak self] delta in self?.tick(delta) }
        )
        driver = created
        return created
    }

    private func tick(_ delta: TimeInterval) {
        engine.advance(by: delta)
        if !isPlaying {
            driver?.stop()
        }
    }
}
