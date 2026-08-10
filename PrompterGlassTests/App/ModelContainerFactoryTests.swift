import Foundation
import SwiftData
import Testing
@testable import PrompterGlass

@MainActor
@Suite("Model container factory")
struct ModelContainerFactoryTests {
    private func makeStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("PrompterGlassTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("store.sqlite")
    }

    private func prepareDirectory(for url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
    }

    @Test("A corrupt store file is recreated as an empty working store")
    func recoversFromCorruptStore() throws {
        let url = makeStoreURL()
        try prepareDirectory(for: url)
        try Data("this is not a database".utf8).write(to: url)
        let schema = Schema([Script.self])
        let configuration = ModelConfiguration(schema: schema, url: url)

        let container = ModelContainerFactory.make(schema: schema, configuration: configuration)

        let context = ModelContext(container)
        let fetched = try context.fetch(FetchDescriptor<Script>())
        #expect(fetched.isEmpty)

        context.insert(Script(title: "After recovery"))
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Script>()).count == 1)
    }

    @Test("A healthy store keeps its scripts and never triggers recovery")
    func healthyStoreIsUntouched() throws {
        let url = makeStoreURL()
        try prepareDirectory(for: url)
        let schema = Schema([Script.self])
        let configuration = ModelConfiguration(schema: schema, url: url)

        let first = ModelContainerFactory.make(schema: schema, configuration: configuration)
        let firstContext = ModelContext(first)
        firstContext.insert(Script(title: "Persisted"))
        try firstContext.save()

        let second = ModelContainerFactory.make(schema: schema, configuration: configuration)
        let fetched = try ModelContext(second).fetch(FetchDescriptor<Script>())

        #expect(fetched.count == 1)
        #expect(fetched.first?.title == "Persisted")
    }
}
