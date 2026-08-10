import AppKit

final class OverlayPanel: NSPanel {
    convenience init(contentRect: NSRect) {
        self.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    private func configure() {
        level = .floating

        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        isOpaque = false
        backgroundColor = .clear
        alphaValue = 1
        hasShadow = false

        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false

        isMovableByWindowBackground = true
        isMovable = true

        isExcludedFromWindowsMenu = true

        contentMinSize = OverlayFrameResolver.minimumSize
        minSize = OverlayFrameResolver.minimumSize
    }

    func setClickThrough(_ enabled: Bool) {
        ignoresMouseEvents = enabled
        acceptsMouseMovedEvents = !enabled
    }
}
