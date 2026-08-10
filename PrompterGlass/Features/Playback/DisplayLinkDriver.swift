import AppKit
import QuartzCore

@MainActor
final class DisplayLinkDriver {
    private static let maximumDelta: CFTimeInterval = 0.25

    private final class WeakTickTarget: NSObject {
        weak var driver: DisplayLinkDriver?

        @objc
        func tick(_ link: CADisplayLink) {
            guard let driver else {
                link.invalidate()
                return
            }
            MainActor.assumeIsolated {
                driver.handleTick(link)
            }
        }
    }

    private nonisolated(unsafe) var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var isViewBacked = false
    private let onTick: (TimeInterval) -> Void

    private let source: () -> NSView?

    init(source: @escaping () -> NSView?, onTick: @escaping (TimeInterval) -> Void) {
        self.source = source
        self.onTick = onTick
    }

    deinit {
        displayLink?.invalidate()
    }

    var isRunning: Bool {
        displayLink != nil
    }

    func start() {
        guard displayLink == nil else { return }
        lastTimestamp = nil
        arm()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    private func arm() {
        let target = WeakTickTarget()
        target.driver = self
        let selector = #selector(WeakTickTarget.tick(_:))
        let view = source()
        let link: CADisplayLink? = if let view {
            view.displayLink(target: target, selector: selector)
        } else {
            NSScreen.main?.displayLink(target: target, selector: selector)
        }
        guard let link else { return }
        isViewBacked = view != nil
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func handleTick(_ link: CADisplayLink) {
        if isViewBacked, source() == nil {
            rearmFromScreen()
            return
        }
        processTick(timestamp: link.timestamp)
    }

    func processTick(timestamp: CFTimeInterval) {
        let now = timestamp
        defer { lastTimestamp = now }
        guard let last = lastTimestamp else { return }
        let delta = min(now - last, DisplayLinkDriver.maximumDelta)
        guard delta > 0 else { return }
        onTick(delta)
    }

    private func rearmFromScreen() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
        isViewBacked = false
        arm()
    }
}
