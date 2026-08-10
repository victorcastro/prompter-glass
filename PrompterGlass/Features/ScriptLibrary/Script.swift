import Foundation
import SwiftData

@Model
final class Script {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = Script.defaultTitle,
        body: String = "",
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = Script.normalizedTitle(title)
        self.body = body
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}

extension Script {
    static let defaultTitle = "Untitled Script"

    var canReceiveEdits: Bool {
        modelContext != nil && !isDeleted
    }

    static func normalizedTitle(_ title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTitle : trimmed
    }

    func apply(title newTitle: String, body newBody: String, now: Date = Date()) {
        let normalized = Script.normalizedTitle(newTitle)
        guard normalized != title || newBody != body else { return }
        title = normalized
        body = newBody
        updatedAt = now
    }
}
