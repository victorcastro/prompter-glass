import CoreGraphics
import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Overlay preferences store")
struct OverlayPreferencesStoreTests {
    private func makeStore(
        suite: String = UUID().uuidString
    ) -> (store: OverlayPreferencesStore, defaults: UserDefaults) {
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return (OverlayPreferencesStore(defaults: defaults), defaults)
    }

    @Test("Empty storage yields the documented defaults")
    func defaultsOnEmptyStorage() {
        let (store, _) = makeStore()

        #expect(store.overlayFrame == nil)
        #expect(store.fontSize == OverlayPreferencesStore.Defaults.fontSize)
        #expect(store.scrollSpeed == OverlayPreferencesStore.Defaults.scrollSpeed)
        #expect(store.backgroundOpacity == OverlayPreferencesStore.Defaults.backgroundOpacity)
        #expect(store.textColor == OverlayPreferencesStore.Defaults.textColor)
        #expect(store.lastOpenedScriptID == nil)
    }

    @Test("The microphone choice round-trips and clears back to the system default")
    func microphoneUIDRoundTrips() {
        let (store, defaults) = makeStore()
        #expect(store.microphoneUID == nil)

        store.microphoneUID = "usb-mic-42"
        #expect(OverlayPreferencesStore(defaults: defaults).microphoneUID == "usb-mic-42")

        store.microphoneUID = nil
        #expect(OverlayPreferencesStore(defaults: defaults).microphoneUID == nil)
    }

    @Test("The documented defaults are white text on an 80% opaque background")
    func documentedDefaultValues() {
        #expect(OverlayPreferencesStore.Defaults.backgroundOpacity == 0.80)
        #expect(OverlayPreferencesStore.Defaults.textColor == RGBAColor.white)
    }

    @Test("Every key round-trips through a fresh store reading the same defaults")
    func everyKeyRoundTrips() {
        let suite = UUID().uuidString
        let (store, defaults) = makeStore(suite: suite)
        let scriptID = UUID()
        let frame = CGRect(x: 120, y: 340, width: 800, height: 300)

        store.overlayFrame = frame
        store.fontSize = 44
        store.scrollSpeed = 120
        store.backgroundOpacity = 0.3
        store.textColor = RGBAColor(red: 0.2, green: 0.4, blue: 0.6)
        store.lastOpenedScriptID = scriptID

        let reloaded = OverlayPreferencesStore(defaults: defaults)

        #expect(reloaded.overlayFrame == frame)
        #expect(reloaded.fontSize == 44)
        #expect(reloaded.scrollSpeed == 120)
        #expect(reloaded.backgroundOpacity == 0.3)
        #expect(reloaded.textColor == RGBAColor(red: 0.2, green: 0.4, blue: 0.6))
        #expect(reloaded.lastOpenedScriptID == scriptID)
    }

    @Test("Clearing the frame and the active script removes them")
    func nilWritesClearStoredValues() {
        let (store, _) = makeStore()
        store.overlayFrame = CGRect(x: 0, y: 0, width: 500, height: 200)
        store.lastOpenedScriptID = UUID()

        store.overlayFrame = nil
        store.lastOpenedScriptID = nil

        #expect(store.overlayFrame == nil)
        #expect(store.lastOpenedScriptID == nil)
    }

    @Test("Out-of-range values are clamped on write", arguments: [
        (input: 1000.0, expected: OverlayPreferencesStore.Limits.fontSize.upperBound),
        (input: -5.0, expected: OverlayPreferencesStore.Limits.fontSize.lowerBound),
    ])
    func fontSizeIsClamped(input: Double, expected: Double) {
        let (store, _) = makeStore()
        store.fontSize = input
        #expect(store.fontSize == expected)
    }

    @Test("Scroll speed is clamped to the supported range")
    func scrollSpeedIsClamped() {
        let (store, _) = makeStore()

        store.scrollSpeed = 10000
        #expect(store.scrollSpeed == OverlayPreferencesStore.Limits.scrollSpeed.upperBound)

        store.scrollSpeed = 0
        #expect(store.scrollSpeed == OverlayPreferencesStore.Limits.scrollSpeed.lowerBound)
    }

    @Test("Background opacity is clamped to 0...1")
    func backgroundOpacityIsClamped() {
        let (store, _) = makeStore()

        store.backgroundOpacity = 4
        #expect(store.backgroundOpacity == 1)

        store.backgroundOpacity = -4
        #expect(store.backgroundOpacity == 0)
    }

    @Test("A stored value outside the range is clamped on read")
    func storedOutOfRangeValueIsClampedOnRead() {
        let suite = UUID().uuidString
        let (_, defaults) = makeStore(suite: suite)
        defaults.set(9999.0, forKey: "overlay.fontSize")

        let store = OverlayPreferencesStore(defaults: defaults)

        #expect(store.fontSize == OverlayPreferencesStore.Limits.fontSize.upperBound)
    }

    @Test("An unreadable stored color falls back to the default instead of failing")
    func unreadableColorFallsBackToDefault() {
        let suite = UUID().uuidString
        let (_, defaults) = makeStore(suite: suite)
        defaults.set(Data([0x00, 0x01, 0x02]), forKey: "overlay.textColor")

        let store = OverlayPreferencesStore(defaults: defaults)

        #expect(store.textColor == OverlayPreferencesStore.Defaults.textColor)
    }

    @Test("A malformed stored frame reads back as no saved frame")
    func malformedFrameReadsAsNil() {
        let suite = UUID().uuidString
        let (_, defaults) = makeStore(suite: suite)
        defaults.set("not a rect", forKey: "overlay.frame")

        let store = OverlayPreferencesStore(defaults: defaults)

        #expect(store.overlayFrame == nil)
    }

    @Test("A malformed stored script id reads back as no active script")
    func malformedScriptIDReadsAsNil() {
        let suite = UUID().uuidString
        let (_, defaults) = makeStore(suite: suite)
        defaults.set("nonsense", forKey: "overlay.lastOpenedScriptID")

        let store = OverlayPreferencesStore(defaults: defaults)

        #expect(store.lastOpenedScriptID == nil)
    }
}
