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
