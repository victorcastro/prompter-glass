import Foundation
import SwiftData
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Sample script seeding")
struct SampleScriptSeederTests {
    private struct Harness {
        /// Held on to: the context does not keep its container alive.
        let container: ModelContainer
        let context: ModelContext
        let preferences: OverlayPreferencesStore
    }

    private func makeHarness() -> Harness {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let container = ModelContainerFactory.make(inMemory: true)
        return Harness(
            container: container,
            context: ModelContext(container),
            preferences: OverlayPreferencesStore(defaults: defaults)
        )
    }

    private func scripts(in context: ModelContext) -> [Script] {
        (try? context.fetch(FetchDescriptor<Script>())) ?? []
    }

    @Test("A fresh install gets one sample script, selected for the next launch")
    func seedsOnFirstLaunch() {
        let harness = makeHarness()

        let seeded = SampleScriptSeeder.seedIfNeeded(context: harness.context, preferences: harness.preferences)

        #expect(seeded != nil)
        #expect(scripts(in: harness.context).count == 1)
        #expect(harness.preferences.lastOpenedScriptID == seeded?.id)
        #expect(seeded?.body.isEmpty == false)
    }

    @Test("An existing library is left alone")
    func doesNotSeedOverExistingScripts() {
        let harness = makeHarness()
        harness.context.insert(Script(title: "Mine", body: "already here"))

        let seeded = SampleScriptSeeder.seedIfNeeded(context: harness.context, preferences: harness.preferences)

        #expect(seeded == nil)
        #expect(scripts(in: harness.context).count == 1)
    }

    @Test("Deleting the sample is permanent across launches")
    func doesNotReseedAfterDeletion() {
        let harness = makeHarness()
        guard let seeded = SampleScriptSeeder.seedIfNeeded(
            context: harness.context,
            preferences: harness.preferences
        ) else {
            Issue.record("The first launch should have seeded a sample script")
            return
        }
        harness.context.delete(seeded)
        try? harness.context.save()

        let again = SampleScriptSeeder.seedIfNeeded(context: harness.context, preferences: harness.preferences)

        #expect(again == nil)
        #expect(scripts(in: harness.context).isEmpty)
    }

    @Test("Seeding runs at most once even while the library is still empty")
    func runsOnlyOnce() {
        let harness = makeHarness()
        _ = SampleScriptSeeder.seedIfNeeded(context: harness.context, preferences: harness.preferences)

        #expect(harness.preferences.didSeedSampleScript)
        #expect(SampleScriptSeeder.seedIfNeeded(context: harness.context, preferences: harness.preferences) == nil)
    }
}
