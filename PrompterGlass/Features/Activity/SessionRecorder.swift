import Foundation

struct SessionDraft: Equatable {
    let scriptID: UUID?
    let scriptTitle: String
    let startedAt: Date
    let onAirSeconds: Double
    let spokenWordCount: Int
    let usedVoiceTracking: Bool
    let reachedEnd: Bool
}

@MainActor
final class SessionRecorder {
    static let minimumSessionSeconds: Double = 5

    private struct ActiveSession {
        let scriptID: UUID?
        let scriptTitle: String
        let startedAt: Date
        var accumulatedSeconds: Double
        var playingSince: Date?
        var maxSpokenWords: Int
        var usedVoiceTracking: Bool
    }

    private let clock: () -> Date
    private var active: ActiveSession?

    init(clock: @escaping () -> Date = Date.init) {
        self.clock = clock
    }

    var isRecording: Bool {
        active != nil
    }

    func playbackStarted(scriptID: UUID?, scriptTitle: String, usingVoice: Bool) {
        let now = clock()
        if active != nil {
            resume()
            noteVoiceUsed(usingVoice)
            return
        }
        active = ActiveSession(
            scriptID: scriptID,
            scriptTitle: scriptTitle,
            startedAt: now,
            accumulatedSeconds: 0,
            playingSince: now,
            maxSpokenWords: 0,
            usedVoiceTracking: usingVoice
        )
    }

    func pause() {
        guard var session = active, let since = session.playingSince else { return }
        session.accumulatedSeconds += clock().timeIntervalSince(since)
        session.playingSince = nil
        active = session
    }

    func resume() {
        guard var session = active, session.playingSince == nil else { return }
        session.playingSince = clock()
        active = session
    }

    func noteSpokenWords(_ count: Int) {
        guard var session = active else { return }
        session.maxSpokenWords = max(session.maxSpokenWords, count)
        if count > 0 {
            session.usedVoiceTracking = true
        }
        active = session
    }

    func noteVoiceUsed(_ used: Bool) {
        guard used, var session = active else { return }
        session.usedVoiceTracking = true
        active = session
    }

    func finish(reachedEnd: Bool) -> SessionDraft? {
        guard var session = active else { return nil }
        if let since = session.playingSince {
            session.accumulatedSeconds += clock().timeIntervalSince(since)
        }
        active = nil
        guard session.accumulatedSeconds >= SessionRecorder.minimumSessionSeconds else { return nil }
        return SessionDraft(
            scriptID: session.scriptID,
            scriptTitle: session.scriptTitle,
            startedAt: session.startedAt,
            onAirSeconds: session.accumulatedSeconds,
            spokenWordCount: session.maxSpokenWords,
            usedVoiceTracking: session.usedVoiceTracking,
            reachedEnd: reachedEnd
        )
    }
}
