import Foundation

struct ActivityMetrics {
    struct Session: Equatable {
        let scriptTitle: String
        let startedAt: Date
        let onAirSeconds: Double
        let spokenWordCount: Int
        let usedVoiceTracking: Bool
        let reachedEnd: Bool

        var wordsPerMinute: Double? {
            guard usedVoiceTracking, onAirSeconds > 0, spokenWordCount > 0 else { return nil }
            return Double(spokenWordCount) / (onAirSeconds / 60)
        }
    }

    struct PaceBar: Identifiable, Equatable {
        let id: Int
        let wordsPerMinute: Double
        let isRecent: Bool
    }

    struct ScriptTotal: Identifiable, Equatable {
        var id: String {
            title
        }

        let title: String
        let seconds: Double
    }

    static let windowDays = 30
    static let paceBarCount = 12
    static let recentBarCount = 3
    static let topScriptCount = 3

    let averageWordsPerMinute: Int?
    let paceBars: [PaceBar]
    let timeOnAirSeconds: Double
    let deltaSeconds: Double?
    let topScripts: [ScriptTotal]
    let retakesAvoided: Int
    let isEmpty: Bool

    init(sessions: [Session], now: Date) {
        let windowLength = TimeInterval(ActivityMetrics.windowDays * 24 * 3600)
        let windowStart = now.addingTimeInterval(-windowLength)
        let previousStart = windowStart.addingTimeInterval(-windowLength)

        let current = sessions
            .filter { $0.startedAt >= windowStart && $0.startedAt <= now }
            .sorted { $0.startedAt < $1.startedAt }
        let previous = sessions.filter { $0.startedAt >= previousStart && $0.startedAt < windowStart }

        isEmpty = current.isEmpty
        timeOnAirSeconds = current.reduce(0) { $0 + $1.onAirSeconds }
        retakesAvoided = current.count(where: \.reachedEnd)

        let voiced = current.filter { $0.wordsPerMinute != nil }
        let voicedSeconds = voiced.reduce(0) { $0 + $1.onAirSeconds }
        let voicedWords = voiced.reduce(0) { $0 + $1.spokenWordCount }
        averageWordsPerMinute = voicedSeconds > 0
            ? Int((Double(voicedWords) / (voicedSeconds / 60)).rounded())
            : nil

        let latestVoiced = voiced.suffix(ActivityMetrics.paceBarCount)
        let recentThreshold = latestVoiced.count - ActivityMetrics.recentBarCount
        paceBars = latestVoiced.enumerated().map { index, session in
            PaceBar(
                id: index,
                wordsPerMinute: session.wordsPerMinute ?? 0,
                isRecent: index >= recentThreshold
            )
        }

        deltaSeconds = previous.isEmpty
            ? nil
            : timeOnAirSeconds - previous.reduce(0) { $0 + $1.onAirSeconds }

        let totalsByTitle = current.reduce(into: [String: Double]()) { totals, session in
            totals[session.scriptTitle, default: 0] += session.onAirSeconds
        }
        topScripts = totalsByTitle
            .map { ScriptTotal(title: $0.key, seconds: $0.value) }
            .sorted { $0.seconds > $1.seconds }
            .prefix(ActivityMetrics.topScriptCount)
            .map { $0 }
    }
}

extension ActivityMetrics {
    static func timeLabel(seconds: Double) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        }
        if minutes > 0 {
            return "\(minutes)m"
        }
        return "\(total)s"
    }
}
