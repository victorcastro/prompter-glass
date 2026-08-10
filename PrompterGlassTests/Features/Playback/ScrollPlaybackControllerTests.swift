import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Scroll playback controller")
struct ScrollPlaybackControllerTests {
    private func makeController(
        configure: (OverlayPreferencesStore) -> Void = { _ in }
    ) -> ScrollPlaybackController {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let preferences = OverlayPreferencesStore(defaults: defaults)
        configure(preferences)
        return ScrollPlaybackController(preferences: preferences)
    }

    private func makeScrollableController() -> ScrollPlaybackController {
        let controller = makeController()
        controller.hasContent = true
        controller.engine.updateContentHeight(1000)
        controller.engine.updateViewportHeight(500)
        return controller
    }

    @Test("The engine starts at the persisted speed")
    func engineAdoptsThePersistedSpeed() {
        let controller = makeController { $0.scrollSpeed = 137 }

        #expect(controller.speed == 137)
        #expect(controller.engine.speed == 137)
    }

    @Test("Setting the speed clamps it and hands the clamped value to the engine")
    func speedIsClampedAndForwarded() {
        let controller = makeController()

        controller.speed = 10000

        let expected = OverlayPreferencesStore.Limits.scrollSpeed.upperBound
        #expect(controller.speed == expected)
        #expect(controller.engine.speed == expected)
    }

    @Test("The speed survives into a controller built from the same preferences")
    func speedPersists() {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let preferences = OverlayPreferencesStore(defaults: defaults)

        ScrollPlaybackController(preferences: preferences).speed = 90

        #expect(ScrollPlaybackController(preferences: preferences).engine.speed == 90)
    }

    @Test("Transport commands drive the engine")
    func transportDrivesTheEngine() {
        let controller = makeScrollableController()

        controller.start()
        #expect(controller.isPlaying)

        controller.pause()
        #expect(controller.engine.state == .paused)

        controller.start()
        #expect(controller.isPlaying)

        controller.stop()
        #expect(controller.engine.state == .stopped)
        #expect(controller.engine.offset == 0)
    }

    @Test("Toggling alternates between playing and paused")
    func toggleAlternates() {
        let controller = makeScrollableController()

        controller.toggle()
        #expect(controller.isPlaying)

        controller.toggle()
        #expect(controller.engine.state == .paused)
    }

    @Test("Losing the content stops playback")
    func losingContentStopsPlayback() {
        let controller = makeScrollableController()
        controller.start()

        controller.hasContent = false

        #expect(controller.engine.state == .stopped)
        #expect(controller.engine.offset == 0)
    }

    @Test("Playback cannot start without content")
    func startRequiresContent() {
        let controller = makeController()

        controller.start()

        #expect(controller.isPlaying == false)
    }

    @Test("Stopping is only offered once there is something to reset")
    func canStopReflectsProgress() {
        let controller = makeScrollableController()
        #expect(controller.canStop == false)

        controller.start()
        #expect(controller.canStop)

        controller.stop()
        #expect(controller.canStop == false)
    }
}
