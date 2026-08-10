import AppKit
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Overlay panel configuration")
struct OverlayPanelTests {
    private func makePanel() -> OverlayPanel {
        OverlayPanel(contentRect: CGRect(x: 0, y: 0, width: 800, height: 300))
    }

    @Test("The panel is borderless and non-activating")
    func styleMaskIsBorderlessAndNonActivating() {
        let panel = makePanel()

        #expect(panel.styleMask.contains(.borderless))
        #expect(panel.styleMask.contains(.nonactivatingPanel))
        #expect(!panel.styleMask.contains(.titled))
    }

    @Test("The panel floats above ordinary windows")
    func panelFloats() {
        #expect(makePanel().level == .floating)
    }

    @Test("The panel joins all Spaces and survives another app's fullscreen window")
    func collectionBehaviorCoversSpacesAndFullscreen() {
        let behavior = makePanel().collectionBehavior

        #expect(behavior.contains(.canJoinAllSpaces))
        #expect(behavior.contains(.fullScreenAuxiliary))
        #expect(behavior.contains(.stationary))
    }

    @Test("The panel is transparent, shadowless and stays on screen while the app is in the background")
    func panelIsTransparentAndPersistent() {
        let panel = makePanel()

        #expect(panel.isOpaque == false)
        #expect(panel.backgroundColor == .clear)
        #expect(panel.hasShadow == false)
        #expect(panel.hidesOnDeactivate == false)
        #expect(panel.isReleasedWhenClosed == false)
        #expect(panel.becomesKeyOnlyIfNeeded)
    }

    @Test("Opacity is drawn by SwiftUI, so the window's own alpha stays fully opaque")
    func windowAlphaIsNeverUsedForOpacity() {
        #expect(makePanel().alphaValue == 1)
    }

    @Test("The panel can take key status but never becomes the app's main window")
    func keyAndMainBehavior() {
        let panel = makePanel()

        #expect(panel.canBecomeKey)
        #expect(panel.canBecomeMain == false)
    }

    @Test("The whole body is a drag handle and the panel cannot shrink below the minimum size")
    func draggingAndMinimumSize() {
        let panel = makePanel()

        #expect(panel.isMovableByWindowBackground)
        #expect(panel.contentMinSize == OverlayFrameResolver.minimumSize)
        #expect(panel.minSize == OverlayFrameResolver.minimumSize)
    }

    @Test("The panel is kept out of the Window menu and standard window cycling")
    func panelIsExcludedFromWindowCycling() {
        #expect(makePanel().isExcludedFromWindowsMenu)
    }

    @Test("Click-through toggles mouse handling in both directions")
    func clickThroughTogglesMouseHandling() {
        let panel = makePanel()

        panel.setClickThrough(true)
        #expect(panel.ignoresMouseEvents)
        #expect(panel.acceptsMouseMovedEvents == false)

        panel.setClickThrough(false)
        #expect(panel.ignoresMouseEvents == false)
        #expect(panel.acceptsMouseMovedEvents)
    }

    @Test("The panel opens at the frame it was constructed with")
    func panelUsesTheGivenFrame() {
        let requested = CGRect(x: 120, y: 240, width: 900, height: 360)
        let panel = OverlayPanel(contentRect: requested)

        #expect(panel.frame.size == requested.size)
    }
}
