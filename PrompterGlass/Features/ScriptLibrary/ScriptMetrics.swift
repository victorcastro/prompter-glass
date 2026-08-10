import Foundation

enum ScriptMetrics {
    static let readingWordsPerMinute = 200.0
    static let speakingWordsPerMinute = 130.0

    static func wordCount(of text: String) -> Int {
        text.split(whereSeparator: \.isWhitespace).count
    }

    static func readMinutes(wordCount: Int) -> Int {
        guard wordCount > 0 else { return 1 }
        return max(1, Int((Double(wordCount) / readingWordsPerMinute).rounded(.up)))
    }

    static func onAirSeconds(wordCount: Int) -> Int {
        guard wordCount > 0 else { return 0 }
        return max(1, Int((Double(wordCount) / speakingWordsPerMinute * 60).rounded()))
    }

    static func onAirLabel(wordCount: Int) -> String {
        formatted(seconds: onAirSeconds(wordCount: wordCount))
    }

    static func formatted(seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%d:%02d", clamped / 60, clamped % 60)
    }

    static func cardSummary(wordCount: Int) -> String {
        "\(wordCount) words · \(readMinutes(wordCount: wordCount)) min read"
    }
}
