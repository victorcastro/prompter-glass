import Foundation
import Observation

@MainActor
@Observable
final class ActiveScriptStore {
    private(set) var script: Script?

    @ObservationIgnored
    private let preferences: OverlayPreferencesStore

    init(preferences: OverlayPreferencesStore) {
        self.preferences = preferences
    }

    var text: String {
        script?.body ?? ""
    }

    var hasRenderableText: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func select(_ script: Script?) {
        self.script = script
        preferences.lastOpenedScriptID = script?.id
    }

    func clear() {
        select(nil)
    }

    func restorableIdentifier(among scripts: [Script]) -> Script.ID? {
        guard let saved = preferences.lastOpenedScriptID else { return nil }
        return scripts.contains { $0.id == saved } ? saved : nil
    }
}
