import Foundation
import SwiftData
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Script model")
struct ScriptTests {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Script.self, configurations: configuration)
        return ModelContext(container)
    }

    @Test("A new script starts with the default title, an empty body and matching timestamps")
    func creationDefaults() throws {
        let context = try makeContext()
        let script = Script()
        context.insert(script)

        #expect(script.title == Script.defaultTitle)
        #expect(script.body.isEmpty)
        #expect(script.createdAt == script.updatedAt)
    }

    @Test("A blank title is stored as the default title rather than as an empty string")
    func blankTitleFallsBackToDefault() throws {
        let context = try makeContext()
        let script = Script(title: "   \n ")
        context.insert(script)

        #expect(script.title == Script.defaultTitle)
    }

    @Test("Editing bumps updatedAt but leaves the identifier untouched")
    func editingBumpsTimestampAndKeepsIdentity() throws {
        let context = try makeContext()
        let created = Date(timeIntervalSince1970: 1000)
        let script = Script(title: "Intro", body: "one", createdAt: created)
        context.insert(script)
        let originalID = script.id

        let edited = Date(timeIntervalSince1970: 2000)
        script.apply(title: "Intro v2", body: "two", now: edited)

        #expect(script.id == originalID)
        #expect(script.title == "Intro v2")
        #expect(script.body == "two")
        #expect(script.updatedAt == edited)
        #expect(script.createdAt == created)
    }

    @Test("Applying identical content does not bump updatedAt")
    func noOpEditDoesNotBumpTimestamp() throws {
        let context = try makeContext()
        let created = Date(timeIntervalSince1970: 1000)
        let script = Script(title: "Intro", body: "one", createdAt: created)
        context.insert(script)

        script.apply(title: "Intro", body: "one", now: Date(timeIntervalSince1970: 5000))

        #expect(script.updatedAt == created)
    }

    @Test("Scripts round-trip through the store and can be fetched newest-first")
    func scriptsPersistAndSortByUpdatedAt() throws {
        let context = try makeContext()
        let older = Script(title: "Older", body: "a", createdAt: Date(timeIntervalSince1970: 100))
        let newer = Script(title: "Newer", body: "b", createdAt: Date(timeIntervalSince1970: 200))
        context.insert(older)
        context.insert(newer)
        try context.save()

        let descriptor = FetchDescriptor<Script>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        let fetched = try context.fetch(descriptor)

        #expect(fetched.count == 2)
        #expect(fetched.first?.title == "Newer")
        #expect(fetched.last?.title == "Older")
    }

    @Test("A deleted script is gone from the store")
    func deletionRemovesTheScript() throws {
        let context = try makeContext()
        let script = Script(title: "Doomed")
        context.insert(script)
        try context.save()

        context.delete(script)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Script>())
        #expect(fetched.isEmpty)
    }
}
