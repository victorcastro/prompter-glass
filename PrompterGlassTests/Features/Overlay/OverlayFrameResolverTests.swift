import CoreGraphics
import Foundation
import Testing
@testable import PrompterGlass

@Suite("Overlay frame resolution")
struct OverlayFrameResolverTests {
    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let secondScreen = CGRect(x: 1920, y: 0, width: 1920, height: 1080)

    private func resolve(saved: CGRect?, screens: [CGRect]? = nil) -> CGRect {
        OverlayFrameResolver.resolve(
            saved: saved,
            screens: screens ?? [screen],
            primaryVisibleFrame: screen
        )
    }

    @Test("With no saved frame the overlay docks to the top of the screen, centred")
    func defaultFrameIsTopDocked() {
        let frame = resolve(saved: nil)

        #expect(frame.midX == screen.midX)
        #expect(frame.maxY < screen.maxY)
        #expect(frame.maxY > screen.maxY - 100)
        #expect(frame.width > 0)
        #expect(frame.height > 0)
    }

    @Test("The default size is 800 by 600")
    func defaultSizeIsFixed() {
        #expect(OverlayFrameResolver.defaultSize == CGSize(width: 800, height: 600))

        let frame = OverlayFrameResolver.defaultFrame(in: screen)
        #expect(frame.size == CGSize(width: 800, height: 600))
    }

    @Test("The default size does not scale with the display")
    func defaultSizeIsIndependentOfScreenSize() {
        let ultrawide = CGRect(x: 0, y: 0, width: 5120, height: 2160)
        let laptop = CGRect(x: 0, y: 0, width: 1440, height: 900)

        #expect(OverlayFrameResolver.defaultFrame(in: ultrawide).size == OverlayFrameResolver.defaultSize)
        #expect(OverlayFrameResolver.defaultFrame(in: laptop).size == OverlayFrameResolver.defaultSize)
        #expect(OverlayFrameResolver.defaultFrame(in: ultrawide).midX == ultrawide.midX)
    }

    @Test("The default size shrinks to fit a screen smaller than it")
    func defaultSizeFitsSmallScreens() {
        let small = CGRect(x: 0, y: 0, width: 640, height: 480)
        let frame = OverlayFrameResolver.defaultFrame(in: small)

        #expect(frame.width == 640)
        #expect(frame.height == 480)
    }

    @Test("A requested size is clamped between the minimum and the screen")
    func requestedSizeIsClamped() {
        let tooSmall = OverlayFrameResolver.clampSize(CGSize(width: 10, height: 10), in: screen)
        #expect(tooSmall == OverlayFrameResolver.minimumSize)

        let tooBig = OverlayFrameResolver.clampSize(CGSize(width: 99999, height: 99999), in: screen)
        #expect(tooBig == CGSize(width: screen.width, height: screen.height))

        let fine = CGSize(width: 800, height: 300)
        #expect(OverlayFrameResolver.clampSize(fine, in: screen) == fine)
    }

    @Test("The default frame is never smaller than the minimum size")
    func defaultFrameRespectsMinimumSize() {
        let tinyScreen = CGRect(x: 0, y: 0, width: 400, height: 200)
        let frame = OverlayFrameResolver.defaultFrame(in: tinyScreen)

        #expect(frame.width >= OverlayFrameResolver.minimumSize.width)
        #expect(frame.height >= OverlayFrameResolver.minimumSize.height)
    }

    @Test("The default frame stays within the screen it is placed on")
    func defaultFrameStaysOnScreen() {
        let frame = OverlayFrameResolver.defaultFrame(in: screen)

        #expect(frame.minY >= screen.minY)
        #expect(frame.width <= screen.width)
        #expect(frame.height <= screen.height)
    }

    @Test("A saved frame that is still on screen is used as-is")
    func usableSavedFrameIsRestored() {
        let saved = CGRect(x: 300, y: 500, width: 900, height: 320)

        #expect(resolve(saved: saved) == saved)
    }

    @Test("A saved frame on a second display is restored while that display is connected")
    func savedFrameOnSecondaryDisplayIsRestored() {
        let saved = CGRect(x: 2100, y: 400, width: 900, height: 320)

        #expect(resolve(saved: saved, screens: [screen, secondScreen]) == saved)
    }

    @Test("A saved frame is discarded once its display is gone")
    func savedFrameOffScreenIsDiscarded() {
        let saved = CGRect(x: 2100, y: 400, width: 900, height: 320)

        let frame = resolve(saved: saved, screens: [screen])

        #expect(frame != saved)
        #expect(frame == OverlayFrameResolver.defaultFrame(in: screen))
    }

    @Test("A saved frame that only overlaps by a sliver counts as off-screen")
    func slightlyOverlappingFrameIsDiscarded() {
        let saved = CGRect(x: 1910, y: 400, width: 900, height: 320)

        #expect(resolve(saved: saved, screens: [screen]) == OverlayFrameResolver.defaultFrame(in: screen))
    }

    @Test("A degenerate saved frame is discarded", arguments: [
        CGRect(x: 100, y: 100, width: 0, height: 0),
        CGRect(x: 100, y: 100, width: 10, height: 800),
        CGRect(x: 100, y: 100, width: 800, height: 10),
    ])
    func degenerateSavedFrameIsDiscarded(saved: CGRect) {
        #expect(resolve(saved: saved) == OverlayFrameResolver.defaultFrame(in: screen))
    }

    @Test("A frame exactly at the minimum size is still usable")
    func minimumSizedFrameIsUsable() {
        let saved = CGRect(
            origin: CGPoint(x: 200, y: 200),
            size: OverlayFrameResolver.minimumSize
        )

        #expect(OverlayFrameResolver.isUsable(saved, on: [screen]))
    }
}
