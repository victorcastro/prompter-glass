import Foundation
import Testing
@testable import PrompterGlass

@Suite("Recognition color")
struct RecognitionColorTests {
    private func makeStore() -> OverlayPreferencesStore {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return OverlayPreferencesStore(defaults: defaults)
    }

    @Test("Contrast ratio matches WCAG reference values")
    func contrastRatio() {
        let black = RGBAColor(red: 0, green: 0, blue: 0)
        let white = RGBAColor.white

        #expect(abs(white.contrastRatio(against: black) - 21) < 0.1)
        #expect(abs(black.contrastRatio(against: black) - 1) < 0.01)
    }

    @Test("Default recognition amber clears the minimum contrast against the panel")
    func defaultAmberHasContrast() {
        let ratio = RGBAColor.recognitionAmber
            .contrastRatio(against: OverlayPreferencesStore.Contrast.panelReference)

        #expect(ratio >= OverlayPreferencesStore.Contrast.minimumRatio)
    }

    @Test("A stored color round-trips when it has enough contrast")
    func storesAccessibleColor() {
        let store = makeStore()
        let accessible = RGBAColor(red: 1, green: 1, blue: 0.8)

        store.recognitionColor = accessible

        #expect(store.recognitionColor == accessible)
    }

    @Test("A low-contrast stored color falls back to the default")
    func lowContrastFallsBack() {
        let store = makeStore()
        let lowContrast = RGBAColor(red: 0.35, green: 0.35, blue: 0.35)

        store.recognitionColor = lowContrast

        #expect(store.recognitionColor == OverlayPreferencesStore.Defaults.recognitionColor)
    }

    @Test("Unset recognition color returns the default")
    func unsetReturnsDefault() {
        #expect(makeStore().recognitionColor == OverlayPreferencesStore.Defaults.recognitionColor)
    }
}
