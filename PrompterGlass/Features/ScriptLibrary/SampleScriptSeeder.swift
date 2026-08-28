import Foundation
import SwiftData

/// Creates one script on the first launch of a fresh installation. An empty library leaves
/// playback, the overlay and voice tracking with nothing to act on, which reads as a broken app.
@MainActor
enum SampleScriptSeeder {
    static let title = "Welcome to PrompterGlass"

    static let body = """
    Welcome to PrompterGlass.

    This is a sample script, so you have something to read while you get your bearings. \
    Edit it, or delete it and write your own — it will not come back.

    Press Roll to start scrolling, and drag the glass panel until it sits right under your \
    webcam. Your eyes stay in frame while you read.

    Turn on Voice tracking and the panel follows you instead of the clock: the words you have \
    already said turn yellow, and the script scrolls to keep your place in view. Your voice is \
    transcribed on this Mac and never leaves it.

    When you are done, press Stop. That is the whole app.
    """

    @discardableResult
    static func seedIfNeeded(context: ModelContext, preferences: OverlayPreferencesStore) -> Script? {
        guard !preferences.didSeedSampleScript else { return nil }
        preferences.didSeedSampleScript = true
        var probe = FetchDescriptor<Script>()
        probe.fetchLimit = 1
        guard let existing = try? context.fetch(probe), existing.isEmpty else { return nil }
        let script = Script(title: title, body: body)
        context.insert(script)
        try? context.save()
        preferences.lastOpenedScriptID = script.id
        return script
    }
}
