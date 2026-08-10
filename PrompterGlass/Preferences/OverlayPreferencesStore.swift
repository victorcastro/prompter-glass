import AppKit
import Foundation
import Observation

@Observable
final class OverlayPreferencesStore {
    enum Limits {
        static let fontSize: ClosedRange<Double> = 12 ... 96
        static let scrollSpeed: ClosedRange<Double> = 10 ... 300
        static let backgroundOpacity: ClosedRange<Double> = 0 ... 1
    }

    enum Defaults {
        static let fontSize: Double = 32
        static let scrollSpeed: Double = 60
        static let backgroundOpacity: Double = 0.55
        static let textColor = RGBAColor.white
    }

    private enum Key {
        static let overlayFrame = "overlay.frame"
        static let fontSize = "overlay.fontSize"
        static let scrollSpeed = "overlay.scrollSpeed"
        static let backgroundOpacity = "overlay.backgroundOpacity"
        static let textColor = "overlay.textColor"
        static let lastOpenedScriptID = "overlay.lastOpenedScriptID"
    }

    @ObservationIgnored
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var overlayFrame: CGRect? {
        get {
            access(keyPath: \.overlayFrame)
            guard let raw = defaults.string(forKey: Key.overlayFrame) else { return nil }
            let rect = NSRectFromString(raw)
            return rect == .zero ? nil : rect
        }
        set {
            withMutation(keyPath: \.overlayFrame) {
                if let newValue {
                    defaults.set(NSStringFromRect(newValue), forKey: Key.overlayFrame)
                } else {
                    defaults.removeObject(forKey: Key.overlayFrame)
                }
            }
        }
    }

    var fontSize: Double {
        get {
            access(keyPath: \.fontSize)
            return clamped(Key.fontSize, default: Defaults.fontSize, to: Limits.fontSize)
        }
        set {
            withMutation(keyPath: \.fontSize) {
                defaults.set(newValue.clamped(to: Limits.fontSize), forKey: Key.fontSize)
            }
        }
    }

    var scrollSpeed: Double {
        get {
            access(keyPath: \.scrollSpeed)
            return clamped(Key.scrollSpeed, default: Defaults.scrollSpeed, to: Limits.scrollSpeed)
        }
        set {
            withMutation(keyPath: \.scrollSpeed) {
                defaults.set(newValue.clamped(to: Limits.scrollSpeed), forKey: Key.scrollSpeed)
            }
        }
    }

    var backgroundOpacity: Double {
        get {
            access(keyPath: \.backgroundOpacity)
            return clamped(
                Key.backgroundOpacity,
                default: Defaults.backgroundOpacity,
                to: Limits.backgroundOpacity
            )
        }
        set {
            withMutation(keyPath: \.backgroundOpacity) {
                defaults.set(newValue.clamped(to: Limits.backgroundOpacity), forKey: Key.backgroundOpacity)
            }
        }
    }

    var textColor: RGBAColor {
        get {
            access(keyPath: \.textColor)
            guard
                let data = defaults.data(forKey: Key.textColor),
                let decoded = try? JSONDecoder().decode(RGBAColor.self, from: data)
            else {
                return Defaults.textColor
            }
            return decoded
        }
        set {
            withMutation(keyPath: \.textColor) {
                guard let data = try? JSONEncoder().encode(newValue) else { return }
                defaults.set(data, forKey: Key.textColor)
            }
        }
    }

    var lastOpenedScriptID: UUID? {
        get {
            access(keyPath: \.lastOpenedScriptID)
            guard let raw = defaults.string(forKey: Key.lastOpenedScriptID) else { return nil }
            return UUID(uuidString: raw)
        }
        set {
            withMutation(keyPath: \.lastOpenedScriptID) {
                if let newValue {
                    defaults.set(newValue.uuidString, forKey: Key.lastOpenedScriptID)
                } else {
                    defaults.removeObject(forKey: Key.lastOpenedScriptID)
                }
            }
        }
    }

    private func clamped(_ key: String, default fallback: Double, to range: ClosedRange<Double>) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        let stored = defaults.double(forKey: key)
        guard stored.isFinite else { return fallback }
        return stored.clamped(to: range)
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        guard isFinite else { return range.lowerBound }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
