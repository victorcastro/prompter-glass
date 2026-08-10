import Foundation
import SwiftData

enum ModelContainerFactory {
    static func make(inMemory: Bool) -> ModelContainer {
        let schema = Schema([Script.self, PromptSession.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        return make(schema: schema, configuration: configuration)
    }

    static func make(schema: Schema, configuration: ModelConfiguration) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            return recover(schema: schema, configuration: configuration, underlying: error)
        }
    }

    private static func recover(
        schema: Schema,
        configuration: ModelConfiguration,
        underlying: Error
    ) -> ModelContainer {
        NSLog("PrompterGlass: recreating unreadable store (%@)", String(describing: underlying))
        destroyStore(at: configuration.url)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer after store recovery: \(error)")
        }
    }

    private static func destroyStore(at url: URL) {
        let manager = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let target = URL(fileURLWithPath: url.path + suffix)
            try? manager.removeItem(at: target)
        }
    }
}
