import Foundation

enum ScriptTokenizer {
    struct Token: Equatable {
        let normalized: String
        let range: Range<String.Index>
    }

    static func tokenize(_ text: String) -> [Token] {
        var tokens: [Token] = []
        text.enumerateSubstrings(in: text.startIndex..., options: [.byWords, .localized]) { substring, range, _, _ in
            guard let substring else { return }
            let normalized = normalize(substring)
            guard !normalized.isEmpty else { return }
            tokens.append(Token(normalized: normalized, range: range))
        }
        return tokens
    }

    static func normalize(_ word: String) -> String {
        word.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
            .filter { $0.isLetter || $0.isNumber }
    }
}
