import AppKit
import SwiftUI

@MainActor
final class OverlayWindowController: NSWindowController {
    private static let saveDebounce = Duration.milliseconds(300)

    private let preferences: OverlayPreferencesStore
    private weak var presenter: OverlayPresenter?
    private let isClickThroughEnabled: Bool
    private let preferredSize: CGSize
    private let content: AnyView
    private let onDisplayViewChange: ((NSView?) -> Void)?
    private var saveTask: Task<Void, Never>?

    init(
        preferences: OverlayPreferencesStore,
        presenter: OverlayPresenter,
        isClickThroughEnabled: Bool,
        preferredSize: CGSize,
        content: AnyView,
        onDisplayViewChange: ((NSView?) -> Void)?
    ) {
        self.preferences = preferences
        self.presenter = presenter
        self.isClickThroughEnabled = isClickThroughEnabled
        self.preferredSize = preferredSize
        self.content = content
        self.onDisplayViewChange = onDisplayViewChange
        super.init(window: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private var panel: OverlayPanel? {
        window as? OverlayPanel
    }

    func setVisible(_ visible: Bool) {
        if visible {
            show()
        } else {
            panel?.orderOut(nil)
        }
    }

    func setClickThrough(_ enabled: Bool) {
        panel?.setClickThrough(enabled)
    }

    func setSize(_ size: CGSize) {
        guard let panel else { return }
        applySize(size, to: panel, persist: true)
    }

    func tearDown() {
        saveTask?.cancel()
        saveTask = nil
        persistFrame()
        panel?.delegate = nil
        panel?.orderOut(nil)
        onDisplayViewChange?(nil)
    }

    private func show() {
        let panel: OverlayPanel
        if let existing = self.panel {
            panel = existing
        } else {
            panel = makePanel()
            window = panel
            applySize(preferredSize, to: panel, persist: false)
        }
        panel.orderFrontRegardless()
    }

    private func makePanel() -> OverlayPanel {
        let frame = OverlayFrameResolver.resolveOnCurrentScreens(saved: preferences.overlayFrame)
        let panel = OverlayPanel(contentRect: frame)

        let hostingView = NSHostingView(rootView: content)
        hostingView.autoresizingMask = [.width, .height]
        hostingView.frame = panel.contentLayoutRect
        panel.contentView = hostingView

        onDisplayViewChange?(hostingView)

        panel.setClickThrough(isClickThroughEnabled)
        panel.delegate = self
        return panel
    }

    private func applySize(_ size: CGSize, to panel: OverlayPanel, persist: Bool) {
        let clamped = OverlayFrameResolver.clampSize(size, in: OverlayFrameResolver.currentVisibleFrame())
        guard clamped != panel.frame.size else { return }
        var frame = panel.frame
        frame.origin.y += frame.height - clamped.height
        frame.size = clamped
        panel.setFrame(frame, display: true, animate: false)
        if persist {
            scheduleFrameSave()
        }
    }

    private func scheduleFrameSave() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: OverlayWindowController.saveDebounce)
            guard !Task.isCancelled else { return }
            self?.persistFrame()
        }
    }

    private func persistFrame() {
        guard let panel, panel.isVisible || preferences.overlayFrame != nil else { return }
        preferences.overlayFrame = panel.frame
    }
}

extension OverlayWindowController: NSWindowDelegate {
    func windowDidMove(_: Notification) {
        scheduleFrameSave()
    }

    func windowDidEndLiveResize(_: Notification) {
        if let panel {
            presenter?.syncSizeFromWindow(panel.frame.size)
        }
        scheduleFrameSave()
    }
}
