import Testing
@testable import PrompterGlass

@Suite("Script metrics")
struct ScriptMetricsTests {
    @Test("Counts words separated by any whitespace")
    func countsWords() {
        #expect(ScriptMetrics.wordCount(of: "one two\nthree\tfour") == 4)
        #expect(ScriptMetrics.wordCount(of: "  spaced   out  ") == 2)
        #expect(ScriptMetrics.wordCount(of: "") == 0)
    }

    @Test("Read time rounds up and never drops below one minute")
    func readMinutes() {
        #expect(ScriptMetrics.readMinutes(wordCount: 0) == 1)
        #expect(ScriptMetrics.readMinutes(wordCount: 104) == 1)
        #expect(ScriptMetrics.readMinutes(wordCount: 201) == 2)
    }

    @Test("On-air estimate uses the speaking rate")
    func onAirSeconds() {
        #expect(ScriptMetrics.onAirSeconds(wordCount: 0) == 0)
        #expect(ScriptMetrics.onAirSeconds(wordCount: 130) == 60)
        #expect(ScriptMetrics.onAirSeconds(wordCount: 65) == 30)
    }

    @Test("Seconds format as minutes and zero-padded seconds")
    func formatting() {
        #expect(ScriptMetrics.formatted(seconds: 0) == "0:00")
        #expect(ScriptMetrics.formatted(seconds: 48) == "0:48")
        #expect(ScriptMetrics.formatted(seconds: 132) == "2:12")
        #expect(ScriptMetrics.formatted(seconds: -5) == "0:00")
    }

    @Test("Card summary combines words and read time")
    func cardSummary() {
        #expect(ScriptMetrics.cardSummary(wordCount: 104) == "104 words · 1 min read")
    }
}
