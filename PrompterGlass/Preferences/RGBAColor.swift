import SwiftUI

struct RGBAColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
        self.red = RGBAColor.clampComponent(red)
        self.green = RGBAColor.clampComponent(green)
        self.blue = RGBAColor.clampComponent(blue)
        self.alpha = RGBAColor.clampComponent(alpha)
    }

    private static func clampComponent(_ value: Double) -> Double {
        guard !value.isNaN else { return 0 }
        return min(max(value, 0), 1)
    }
}

extension RGBAColor {
    static let white = RGBAColor(red: 1, green: 1, blue: 1)
    static let warmWhite = RGBAColor(red: 234 / 255, green: 246 / 255, blue: 239 / 255)
    static let recognitionAmber = RGBAColor(red: 1, green: 216 / 255, blue: 77 / 255)

    var relativeLuminance: Double {
        func linearized(_ component: Double) -> Double {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearized(red) + 0.7152 * linearized(green) + 0.0722 * linearized(blue)
    }

    func contrastRatio(against other: RGBAColor) -> Double {
        let lighter = max(relativeLuminance, other.relativeLuminance)
        let darker = min(relativeLuminance, other.relativeLuminance)
        return (lighter + 0.05) / (darker + 0.05)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }

    init(_ color: Color) {
        let resolved = NSColor(color).usingColorSpace(.sRGB) ?? .white
        self.init(
            red: Double(resolved.redComponent),
            green: Double(resolved.greenComponent),
            blue: Double(resolved.blueComponent),
            alpha: Double(resolved.alphaComponent)
        )
    }
}
