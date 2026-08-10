import AppKit
import Foundation

enum OverlayFrameResolver {
    static let minimumSize = CGSize(width: 320, height: 120)

    static let minimumVisibleExtent = CGSize(width: 120, height: 60)

    static let defaultSize = CGSize(width: 800, height: 600)

    private static let topInset: CGFloat = 24

    static func clampSize(_ size: CGSize, in visibleFrame: CGRect) -> CGSize {
        CGSize(
            width: min(max(size.width, minimumSize.width), max(minimumSize.width, visibleFrame.width)),
            height: min(max(size.height, minimumSize.height), max(minimumSize.height, visibleFrame.height))
        )
    }

    static func defaultFrame(in visibleFrame: CGRect) -> CGRect {
        let size = clampSize(defaultSize, in: visibleFrame)
        let originX = visibleFrame.midX - size.width / 2
        let originY = visibleFrame.maxY - size.height - topInset
        return CGRect(
            x: originX,
            y: max(visibleFrame.minY, originY),
            width: size.width,
            height: size.height
        )
    }

    static func resolve(
        saved: CGRect?,
        screens: [CGRect],
        primaryVisibleFrame: CGRect
    ) -> CGRect {
        guard let saved, isUsable(saved, on: screens) else {
            return defaultFrame(in: primaryVisibleFrame)
        }
        return saved
    }

    static func isUsable(_ frame: CGRect, on screens: [CGRect]) -> Bool {
        guard frame.width >= minimumSize.width, frame.height >= minimumSize.height else { return false }
        return screens.contains { screen in
            let visible = screen.intersection(frame)
            guard !visible.isNull else { return false }
            return visible.width >= minimumVisibleExtent.width
                && visible.height >= minimumVisibleExtent.height
        }
    }

    @MainActor
    static func currentVisibleFrame() -> CGRect {
        NSScreen.main?.visibleFrame
            ?? NSScreen.screens.first?.visibleFrame
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    @MainActor
    static func resolveOnCurrentScreens(saved: CGRect?) -> CGRect {
        let screens = NSScreen.screens.map(\.visibleFrame)
        let primary = NSScreen.main?.visibleFrame
            ?? screens.first
            ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        return resolve(saved: saved, screens: screens, primaryVisibleFrame: primary)
    }
}
