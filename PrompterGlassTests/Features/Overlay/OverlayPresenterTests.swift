import CoreGraphics
import Foundation
import SwiftUI
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Overlay presenter")
struct OverlayPresenterTests {
    private func makePresenter(preferences: OverlayPreferencesStore? = nil) -> OverlayPresenter {
        let store = preferences ?? OverlayPreferencesStore(defaults: makeDefaults().defaults)
        return OverlayPresenter(preferences: store) { _ in
            AnyView(EmptyView())
        }
    }

    private func makeDefaults() -> (suite: String, defaults: UserDefaults) {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return (suite, defaults)
    }

    @Test("The overlay starts hidden and interactive")
    func startsHiddenAndInteractive() {
        let presenter = makePresenter()

        #expect(presenter.isVisible == false)
        #expect(presenter.isClickThroughEnabled == false)
    }

    @Test("The initial size comes from the resolved frame")
    func initialSizeIsResolved() {
        let presenter = makePresenter()

        #expect(presenter.size.width >= OverlayFrameResolver.minimumSize.width)
        #expect(presenter.size.height >= OverlayFrameResolver.minimumSize.height)
    }

    @Test("A requested size is clamped to the minimum")
    func sizeIsClamped() {
        let presenter = makePresenter()

        presenter.setSize(CGSize(width: 10, height: 10))

        #expect(presenter.size == OverlayFrameResolver.minimumSize)
    }

    @Test("Width and height can be set independently")
    func widthAndHeightAreIndependent() {
        let presenter = makePresenter()
        presenter.setSize(CGSize(width: 800, height: 300))

        presenter.width = 640
        #expect(presenter.size == CGSize(width: 640, height: 300))

        presenter.height = 200
        #expect(presenter.size == CGSize(width: 640, height: 200))
    }

    @Test("Click-through is never written to storage, so it cannot be restored on launch")
    func clickThroughIsNotPersisted() {
        let (suite, defaults) = makeDefaults()
        let presenter = makePresenter(preferences: OverlayPreferencesStore(defaults: defaults))

        presenter.isClickThroughEnabled = true

        let keys = Array(defaults.persistentDomain(forName: suite)?.keys ?? [:].keys)
        #expect(!keys.contains { $0.localizedCaseInsensitiveContains("click") })

        let relaunched = makePresenter(preferences: OverlayPreferencesStore(defaults: defaults))
        #expect(relaunched.isClickThroughEnabled == false)
    }

    @Test("A drag-resize is mirrored back into the numeric size")
    func dragResizeSyncsBack() {
        let presenter = makePresenter()

        presenter.syncSizeFromWindow(CGSize(width: 712, height: 244))

        #expect(presenter.size == CGSize(width: 712, height: 244))
    }

    @Test("Tearing down a visible overlay clears the display view exactly once")
    func tearDownClearsDisplayViewOnce() {
        var received: [NSView?] = []
        let store = OverlayPreferencesStore(defaults: makeDefaults().defaults)
        let presenter = OverlayPresenter(
            preferences: store,
            onDisplayViewChange: { received.append($0) },
            makeContent: { _ in AnyView(EmptyView()) }
        )

        presenter.setVisible(true)
        #expect(received.count == 1)
        #expect(received[0] != nil)

        presenter.tearDown()

        #expect(received.count == 2)
        #expect(received[1] == nil)
    }

    @Test("Tearing down a never-shown overlay emits no display view callback")
    func tearDownWithoutPanelEmitsNothing() {
        var received: [NSView?] = []
        let store = OverlayPreferencesStore(defaults: makeDefaults().defaults)
        let presenter = OverlayPresenter(
            preferences: store,
            onDisplayViewChange: { received.append($0) },
            makeContent: { _ in AnyView(EmptyView()) }
        )

        presenter.tearDown()

        #expect(received.isEmpty)
    }
}
