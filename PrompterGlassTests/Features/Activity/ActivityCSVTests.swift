import Foundation
import Testing
@testable import PrompterGlass

@Suite("Activity CSV")
struct ActivityCSVTests {
    private func session(
        title: String,
        words: Int = 0,
        voice: Bool = false
    ) -> ActivityMetrics.Session {
        ActivityMetrics.Session(
            scriptTitle: title,
            startedAt: Date(timeIntervalSince1970: 0),
            onAirSeconds: 60,
            spokenWordCount: words,
            usedVoiceTracking: voice,
            reachedEnd: true
        )
    }

    @Test("Renders a header and one row per session")
    func rendersRows() {
        let csv = ActivityCSV.render(sessions: [session(title: "Intro", words: 120, voice: true)])
        let lines = csv.split(separator: "\n")

        #expect(lines.count == 2)
        #expect(lines[0] == Substring(ActivityCSV.header))
        #expect(lines[1] == "1970-01-01T00:00:00Z,Intro,60,120,120,true,true")
    }

    @Test("Sessions without voice leave the wpm column empty")
    func emptyWPMWithoutVoice() {
        let csv = ActivityCSV.render(sessions: [session(title: "Plain")])

        #expect(csv.contains("Plain,60,0,,false,true"))
    }

    @Test("Titles with commas and quotes are escaped")
    func escapesTitles() {
        let csv = ActivityCSV.render(sessions: [session(title: "Hello, \"World\"")])

        #expect(csv.contains("\"Hello, \"\"World\"\"\""))
    }
}
