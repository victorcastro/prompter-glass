import SwiftUI
import Testing
@testable import PrompterGlass

@Suite("RGBA color storage")
struct RGBAColorTests {
    @Test("Components round-trip through JSON")
    func encodesAndDecodes() throws {
        let color = RGBAColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 0.4)

        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(RGBAColor.self, from: data)

        #expect(decoded == color)
    }

    @Test("Out-of-range components are clamped")
    func componentsAreClamped() {
        let color = RGBAColor(red: 5, green: -2, blue: 0.5, alpha: 100)

        #expect(color.red == 1)
        #expect(color.green == 0)
        #expect(color.blue == 0.5)
        #expect(color.alpha == 1)
    }

    @Test("Non-finite components do not produce an unrenderable color")
    func nonFiniteComponentsAreRejected() {
        let color = RGBAColor(red: .nan, green: .infinity, blue: -.infinity, alpha: .nan)

        #expect(color.red == 0)
        #expect(color.green == 1)
        #expect(color.blue == 0)
        #expect(color.alpha == 0)
    }

    @Test("The default text color is opaque white")
    func defaultIsOpaqueWhite() {
        #expect(RGBAColor.white == RGBAColor(red: 1, green: 1, blue: 1, alpha: 1))
    }

    @MainActor
    @Test("A SwiftUI color converts to sRGB components and back")
    func convertsFromSwiftUIColor() {
        let original = RGBAColor(red: 0.25, green: 0.5, blue: 0.75)

        let round = RGBAColor(original.color)

        #expect(abs(round.red - original.red) < 0.01)
        #expect(abs(round.green - original.green) < 0.01)
        #expect(abs(round.blue - original.blue) < 0.01)
    }
}
