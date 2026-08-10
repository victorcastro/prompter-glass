import Foundation
import Testing
@testable import PrompterGlass

@Suite("Activity metrics")
struct ActivityMetricsTests {
    private let now = Date(timeIntervalSince1970: 100_000_000)

    private func session(
        daysAgo: Double,
        seconds: Double,
        words: Int = 0,
        voice: Bool = false,
        reachedEnd: Bool = false,
        title: String = "Script"
    ) -> ActivityMetrics.Session {
        ActivityMetrics.Session(
            scriptTitle: title,
            startedAt: now.addingTimeInterval(-daysAgo * 24 * 3600),
            onAirSeconds: seconds,
            spokenWordCount: words,
            usedVoiceTracking: voice,
            reachedEnd: reachedEnd
        )
    }

    @Test("Average pace weighs only voice sessions while time on air counts all")
    func averagePaceOnlyVoice() {
        let metrics = ActivityMetrics(
            sessions: [
                session(daysAgo: 1, seconds: 60, words: 120, voice: true),
                session(daysAgo: 2, seconds: 120, words: 300, voice: true),
                session(daysAgo: 3, seconds: 600)
            ],
            now: now
        )

        #expect(metrics.averageWordsPerMinute == 140)
        #expect(metrics.timeOnAirSeconds == 780)
        #expect(metrics.paceBars.count == 2)
    }

    @Test("Sessions outside the 30-day window are ignored")
    func windowFilter() {
        let metrics = ActivityMetrics(
            sessions: [
                session(daysAgo: 5, seconds: 100),
                session(daysAgo: 45, seconds: 900)
            ],
            now: now
        )

        #expect(metrics.timeOnAirSeconds == 100)
    }

    @Test("Delta compares against the previous 30-day window")
    func deltaAgainstPreviousPeriod() {
        let metrics = ActivityMetrics(
            sessions: [
                session(daysAgo: 5, seconds: 500),
                session(daysAgo: 40, seconds: 200)
            ],
            now: now
        )

        #expect(metrics.deltaSeconds == 300)
    }

    @Test("No delta when the previous window is empty")
    func noDeltaWithoutPreviousData() {
        let metrics = ActivityMetrics(
            sessions: [session(daysAgo: 5, seconds: 500)],
            now: now
        )

        #expect(metrics.deltaSeconds == nil)
    }

    @Test("Retakes avoided counts sessions that reached the end")
    func retakesAvoided() {
        let metrics = ActivityMetrics(
            sessions: [
                session(daysAgo: 1, seconds: 60, reachedEnd: true),
                session(daysAgo: 2, seconds: 60, reachedEnd: true),
                session(daysAgo: 3, seconds: 60)
            ],
            now: now
        )

        #expect(metrics.retakesAvoided == 2)
    }

    @Test("Top scripts aggregate by title and keep the top three")
    func topScripts() {
        let metrics = ActivityMetrics(
            sessions: [
                session(daysAgo: 1, seconds: 100, title: "A"),
                session(daysAgo: 2, seconds: 400, title: "B"),
                session(daysAgo: 3, seconds: 200, title: "A"),
                session(daysAgo: 4, seconds: 50, title: "C"),
                session(daysAgo: 5, seconds: 10, title: "D")
            ],
            now: now
        )

        #expect(metrics.topScripts.map(\.title) == ["B", "A", "C"])
        #expect(metrics.topScripts.first?.seconds == 400)
    }

    @Test("Empty history reports empty state")
    func emptyState() {
        let metrics = ActivityMetrics(sessions: [], now: now)

        #expect(metrics.isEmpty)
        #expect(metrics.averageWordsPerMinute == nil)
        #expect(metrics.paceBars.isEmpty)
    }

    @Test("Recent flag marks the newest three pace bars")
    func recentBars() {
        let sessions = (1 ... 6).map {
            session(daysAgo: Double($0), seconds: 60, words: 100, voice: true)
        }
        let metrics = ActivityMetrics(sessions: sessions, now: now)

        #expect(metrics.paceBars.map(\.isRecent) == [false, false, false, true, true, true])
    }

    @Test("Time labels format hours, minutes and seconds")
    func timeLabels() {
        #expect(ActivityMetrics.timeLabel(seconds: 15120) == "4h 12m")
        #expect(ActivityMetrics.timeLabel(seconds: 2880) == "48m")
        #expect(ActivityMetrics.timeLabel(seconds: 42) == "42s")
    }
}
