import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
final class OverlayPresenter {
    private(set) var isVisible = false
    private(set) var size: CGSize

    var isClickThroughEnabled = false {
        didSet {
            guard isClickThroughEnabled != oldValue else { return }
            controller?.setClickThrough(isClickThroughEnabled)
        }
    }

    @ObservationIgnored
    private let preferences: OverlayPreferencesStore

    @ObservationIgnored
    private let makeContent: () -> AnyView

    @ObservationIgnored
    private var controller: OverlayWindowController?

    @ObservationIgnored
    private var onDisplayViewChange: ((NSView?) -> Void)?

    init(
        preferences: OverlayPreferencesStore,
        onDisplayViewChange: ((NSView?) -> Void)? = nil,
        makeContent: @escaping () -> AnyView
    ) {
        self.preferences = preferences
        self.onDisplayViewChange = onDisplayViewChange
        self.makeContent = makeContent
        size = OverlayFrameResolver.resolveOnCurrentScreens(saved: preferences.overlayFrame).size
    }

    var width: Double {
        get { Double(size.width) }
        set { setSize(CGSize(width: newValue, height: size.height)) }
    }

    var height: Double {
        get { Double(size.height) }
        set { setSize(CGSize(width: size.width, height: newValue)) }
    }

    func setVisible(_ visible: Bool) {
        guard visible != isVisible else { return }
        isVisible = visible
        resolvedController.setVisible(visible)
    }

    func setSize(_ requested: CGSize) {
        let clamped = OverlayFrameResolver.clampSize(requested, in: OverlayFrameResolver.currentVisibleFrame())
        guard clamped != size else { return }
        size = clamped
        controller?.setSize(clamped)
    }

    func syncSizeFromWindow(_ windowSize: CGSize) {
        guard windowSize != size else { return }
        size = windowSize
    }

    func tearDown() {
        controller?.tearDown()
        controller = nil
        onDisplayViewChange?(nil)
    }

    private var resolvedController: OverlayWindowController {
        if let controller {
            return controller
        }
        let created = OverlayWindowController(
            preferences: preferences,
            presenter: self,
            isClickThroughEnabled: isClickThroughEnabled,
            preferredSize: size,
            content: makeContent(),
            onDisplayViewChange: onDisplayViewChange
        )
        controller = created
        return created
    }
}
