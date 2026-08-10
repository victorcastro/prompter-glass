import Foundation
import Testing
@testable import PrompterGlass

@Suite("Script aligner")
struct ScriptAlignerTests {
    private func makeAligner(_ script: String) -> ScriptAligner {
        ScriptAligner(tokens: ScriptTokenizer.tokenize(script))
    }

    @Test("Reading the script exactly confirms every word in order")
    func exactReadingConfirmsAll() {
        var aligner = makeAligner("Hello and welcome to the show")

        aligner.ingest(["Hello", "and", "welcome", "to", "the", "show"])

        #expect(aligner.confirmedCount == 6)
        #expect(aligner.progress == 1)
    }

    @Test("Punctuation, case and accents do not block matching")
    func normalizationTolerance() {
        var aligner = makeAligner("¡Hola, cámara! Acción.")

        aligner.ingest(["hola", "camara", "accion"])

        #expect(aligner.confirmedCount == 3)
    }

    @Test("Unmatched words leave the confirmed position untouched")
    func noiseDoesNotAdvance() {
        var aligner = makeAligner("the quick brown fox jumps")
        aligner.ingest(["the", "quick"])

        aligner.ingest(["banana", "keyboard", "aardvark"])

        #expect(aligner.confirmedCount == 2)
    }

    @Test("A skipped phrase requires two consecutive matches before jumping")
    func skipNeedsConfirmation() {
        var aligner = makeAligner("one two three four five six seven")

        aligner.ingest(["five"])
        #expect(aligner.confirmedCount == 0)

        aligner.ingest(["six"])
        #expect(aligner.confirmedCount == 6)
    }

    @Test("A single stray match deep in the window does not jump")
    func singleStrayMatchStaysPut() {
        var aligner = makeAligner("one two three four five six seven")

        aligner.ingest(["five", "banana"])

        #expect(aligner.confirmedCount == 0)
    }

    @Test("Repeated words advance one position per occurrence")
    func repeatedWordsAdvanceInOrder() {
        var aligner = makeAligner("really really long pause")

        aligner.ingest(["really", "really", "long"])

        #expect(aligner.confirmedCount == 3)
    }

    @Test("Filler words between script words are ignored")
    func fillerNoiseBetweenMatches() {
        var aligner = makeAligner("welcome to my channel")

        aligner.ingest(["welcome", "uh", "to", "um", "my", "channel"])

        #expect(aligner.confirmedCount == 4)
    }

    @Test("Small recognition errors still match")
    func fuzzyMatchingToleratesOneEdit() {
        var aligner = makeAligner("teleprompter software")

        aligner.ingest(["telepromter", "software"])

        #expect(aligner.confirmedCount == 2)
    }

    @Test("Words beyond the look-ahead window are ignored")
    func matchesOutsideWindowAreIgnored() {
        let words = (1 ... 40).map { "w\($0)" }.joined(separator: " ")
        var aligner = makeAligner(words)

        aligner.ingest(["w30", "w31"])

        #expect(aligner.confirmedCount == 0)
    }

    @Test("Confirmed end index maps back into the original text")
    func confirmedEndIndexTracksOriginalRange() throws {
        let script = "Hello, world! Goodbye."
        var aligner = makeAligner(script)

        aligner.ingest(["hello", "world"])

        let end = try #require(aligner.confirmedEndIndex)
        #expect(script[..<end].hasSuffix("world"))
    }

    @Test("Reset returns to the top of the script")
    func resetClearsProgress() {
        var aligner = makeAligner("alpha beta gamma")
        aligner.ingest(["alpha", "beta"])

        aligner.reset()

        #expect(aligner.confirmedCount == 0)
        #expect(aligner.confirmedEndIndex == nil)
    }

    @Test("An empty script reports zero progress and never advances")
    func emptyScriptIsInert() {
        var aligner = makeAligner("")

        aligner.ingest(["anything"])

        #expect(aligner.confirmedCount == 0)
        #expect(aligner.progress == 0)
    }
}
