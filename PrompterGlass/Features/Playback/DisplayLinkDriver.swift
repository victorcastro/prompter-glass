import AppKit
import QuartzCore

@MainActor
final class DisplayLinkDriver {
    private static let maximumDelta: CFTimeInterval = 0.25

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
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
        let link: CADisplayLink? = if let view = source() {
            view.displayLink(target: self, selector: #selector(tick))
        } else {
            NSScreen.main?.displayLink(target: self, selector: #selector(tick))
        }
        guard let link else { return }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        lastTimestamp = nil
    }

    @objc
    private func tick(_ link: CADisplayLink) {
        let now = link.timestamp
        defer { lastTimestamp = now }
        guard let last = lastTimestamp else { return }
        let delta = min(now - last, DisplayLinkDriver.maximumDelta)
        guard delta > 0 else { return }
        onTick(delta)
    }
}
