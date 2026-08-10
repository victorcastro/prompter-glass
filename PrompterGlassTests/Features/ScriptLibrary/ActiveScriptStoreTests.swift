import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Active script store")
struct ActiveScriptStoreTests {
    private func makeStore() -> (store: ActiveScriptStore, preferences: OverlayPreferencesStore) {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let preferences = OverlayPreferencesStore(defaults: defaults)
        return (ActiveScriptStore(preferences: preferences), preferences)
    }

    @Test("Nothing is active to begin with")
    func startsEmpty() {
        let (store, _) = makeStore()

        #expect(store.script == nil)
        #expect(store.text.isEmpty)
        #expect(store.hasRenderableText == false)
    }

    @Test("Selecting a script exposes its text and records it for the next launch")
    func selectingRecordsTheScript() {
        let (store, preferences) = makeStore()
        let script = Script(title: "Intro", body: "hello")

        store.select(script)

        #expect(store.script?.id == script.id)
        #expect(store.text == "hello")
        #expect(store.hasRenderableText)
        #expect(preferences.lastOpenedScriptID == script.id)
    }

    @Test("Clearing forgets the script and the stored identifier")
    func clearingForgetsEverything() {
        let (store, preferences) = makeStore()
        store.select(Script(title: "Intro", body: "hello"))

        store.clear()

        #expect(store.script == nil)
        #expect(store.text.isEmpty)
        #expect(preferences.lastOpenedScriptID == nil)
    }

    @Test("A whitespace-only script has nothing to render")
    func blankScriptIsNotRenderable() {
        let (store, _) = makeStore()

        store.select(Script(title: "Blank", body: "   \n\t  "))

        #expect(store.hasRenderableText == false)
    }

    @Test("The stored identifier is restored only while that script still exists")
    func restorableIdentifierResolvesAgainstTheLibrary() {
        let (store, _) = makeStore()
        let kept = Script(title: "Kept", body: "a")
        let removed = Script(title: "Removed", body: "b")

        store.select(kept)
        #expect(store.restorableIdentifier(among: [kept, removed]) == kept.id)

        store.select(removed)
        #expect(store.restorableIdentifier(among: [kept]) == nil)
    }

    @Test("No stored identifier means nothing to restore")
    func nothingToRestoreOnAFreshInstall() {
        let (store, _) = makeStore()

        #expect(store.restorableIdentifier(among: [Script(title: "Any", body: "a")]) == nil)
    }
}
