import Foundation

enum ActivityCSV {
    static let header = "started_at,script_title,on_air_seconds,spoken_words,"
        + "words_per_minute,used_voice_tracking,reached_end"

    static func render(sessions: [ActivityMetrics.Session]) -> String {
        let formatter = ISO8601DateFormatter()
        let rows = sessions
            .sorted { $0.startedAt < $1.startedAt }
            .map { session in
                [
                    formatter.string(from: session.startedAt),
                    escaped(session.scriptTitle),
                    String(format: "%.0f", session.onAirSeconds),
                    String(session.spokenWordCount),
                    session.wordsPerMinute.map { String(format: "%.0f", $0) } ?? "",
                    String(session.usedVoiceTracking),
                    String(session.reachedEnd)
                ].joined(separator: ",")
            }
        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escaped(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
