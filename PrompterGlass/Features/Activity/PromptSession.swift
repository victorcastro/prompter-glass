import Foundation
import SwiftData

@Model
final class PromptSession {
    @Attribute(.unique)
    var id: UUID
    var scriptID: UUID?
    var scriptTitle: String
    var startedAt: Date
    var onAirSeconds: Double
    var spokenWordCount: Int
    var usedVoiceTracking: Bool
    var reachedEnd: Bool

    init(
        id: UUID = UUID(),
        scriptID: UUID?,
        scriptTitle: String,
        startedAt: Date,
        onAirSeconds: Double,
        spokenWordCount: Int,
        usedVoiceTracking: Bool,
        reachedEnd: Bool
    ) {
        self.id = id
        self.scriptID = scriptID
        self.scriptTitle = scriptTitle
        self.startedAt = startedAt
        self.onAirSeconds = onAirSeconds
        self.spokenWordCount = spokenWordCount
        self.usedVoiceTracking = usedVoiceTracking
        self.reachedEnd = reachedEnd
    }
}

extension PromptSession {
    convenience init(draft: SessionDraft) {
        self.init(
            scriptID: draft.scriptID,
            scriptTitle: draft.scriptTitle,
            startedAt: draft.startedAt,
            onAirSeconds: draft.onAirSeconds,
            spokenWordCount: draft.spokenWordCount,
            usedVoiceTracking: draft.usedVoiceTracking,
            reachedEnd: draft.reachedEnd
        )
    }

    var metricsSession: ActivityMetrics.Session {
        ActivityMetrics.Session(
            scriptTitle: scriptTitle,
            startedAt: startedAt,
            onAirSeconds: onAirSeconds,
            spokenWordCount: spokenWordCount,
            usedVoiceTracking: usedVoiceTracking,
            reachedEnd: reachedEnd
        )
    }
}
