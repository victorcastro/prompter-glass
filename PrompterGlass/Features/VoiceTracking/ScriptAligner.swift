import Foundation

struct ScriptAligner {
    private static let lookAhead = 20
    private static let skipConfirmationMatches = 2

    private let tokens: [ScriptTokenizer.Token]
    private(set) var confirmedCount = 0
    private var pendingSkip: (start: Int, matched: Int)?

    init(tokens: [ScriptTokenizer.Token]) {
        self.tokens = tokens
    }

    var totalCount: Int {
        tokens.count
    }

    var progress: Double {
        guard !tokens.isEmpty else { return 0 }
        return Double(confirmedCount) / Double(tokens.count)
    }

    var confirmedEndIndex: String.Index? {
        guard confirmedCount > 0 else { return nil }
        return tokens[confirmedCount - 1].range.upperBound
    }

    mutating func ingest(_ spokenWords: [String]) {
        for word in spokenWords {
            let normalized = ScriptTokenizer.normalize(word)
            guard !normalized.isEmpty else { continue }
            ingestNormalized(normalized)
        }
    }

    mutating func reset() {
        confirmedCount = 0
        pendingSkip = nil
    }

    func speculativeEndIndex(ifNextWordIs word: String) -> String.Index? {
        let normalized = ScriptTokenizer.normalize(word)
        guard !normalized.isEmpty, confirmedCount < tokens.count else { return nil }
        let next = tokens[confirmedCount]
        let isPartialPrefix = normalized.count >= 3 && next.normalized.hasPrefix(normalized)
        guard isPartialPrefix || matches(normalized, next.normalized) else { return nil }
        return next.range.upperBound
    }

    private mutating func ingestNormalized(_ word: String) {
        guard confirmedCount < tokens.count else { return }

        if var pending = pendingSkip {
            let expected = pending.start + pending.matched
            if expected < tokens.count, matches(word, tokens[expected].normalized) {
                pending.matched += 1
                if pending.matched >= ScriptAligner.skipConfirmationMatches {
                    confirmedCount = pending.start + pending.matched
                    pendingSkip = nil
                } else {
                    pendingSkip = pending
                }
                return
            }
            pendingSkip = nil
        }

        if matches(word, tokens[confirmedCount].normalized) {
            confirmedCount += 1
            return
        }

        let windowEnd = min(tokens.count, confirmedCount + ScriptAligner.lookAhead)
        let window = (confirmedCount + 1) ..< windowEnd
        if let candidate = window.first(where: { matches(word, tokens[$0].normalized) }) {
            pendingSkip = (start: candidate, matched: 1)
        }
    }

    private func matches(_ spoken: String, _ scripted: String) -> Bool {
        if spoken == scripted { return true }
        let sharesPrefix = spoken.hasPrefix(scripted) || scripted.hasPrefix(spoken)
        if spoken.count >= 4, scripted.count >= 4, sharesPrefix {
            return true
        }
        if spoken.count >= 5, scripted.count >= 5, abs(spoken.count - scripted.count) <= 1 {
            return editDistanceIsAtMostOne(spoken, scripted)
        }
        return false
    }

    private func editDistanceIsAtMostOne(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs)
        let right = Array(rhs)
        if left.count == right.count {
            return zip(left, right).count(where: { $0 != $1 }) <= 1
        }
        let (shorter, longer) = left.count < right.count ? (left, right) : (right, left)
        var shortIndex = 0
        var longIndex = 0
        var skipped = false
        while shortIndex < shorter.count, longIndex < longer.count {
            if shorter[shortIndex] == longer[longIndex] {
                shortIndex += 1
                longIndex += 1
            } else if skipped {
                return false
            } else {
                skipped = true
                longIndex += 1
            }
        }
        return true
    }
}
