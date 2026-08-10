import AppKit
import Foundation
import Testing
@testable import PrompterGlass

@MainActor
@Suite("App environment coordination")
struct AppEnvironmentTests {
    private func makeEnvironment(notificationCenter: NotificationCenter = .default) -> AppEnvironment {
        let suite = UUID().uuidString
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        return AppEnvironment(
            preferences: OverlayPreferencesStore(defaults: defaults),
            notificationCenter: notificationCenter
        )
    }

    private func makeScrollableEnvironment() -> AppEnvironment {
        let environment = makeEnvironment()
        environment.selectScript(Script(title: "Intro", body: "line one\nline two"))
        environment.playback.engine.updateContentHeight(1000)
        environment.playback.engine.updateViewportHeight(500)
        return environment
    }

    @Test("Selecting a script makes playback available")
    func selectingEnablesPlayback() {
        let environment = makeEnvironment()

        environment.selectScript(Script(title: "Intro", body: "hello"))

        #expect(environment.activeScript.text == "hello")
        #expect(environment.playback.hasContent)
    }

    @Test("Selecting a blank script leaves playback unavailable")
    func blankScriptLeavesPlaybackUnavailable() {
        let environment = makeEnvironment()

        environment.selectScript(Script(title: "Blank", body: "   "))
        environment.playback.start()

        #expect(environment.playback.hasContent == false)
        #expect(environment.playback.isPlaying == false)
    }

    @Test("Switching scripts stops playback so the new one starts from the top")
    func switchingScriptsStopsPlayback() {
        let environment = makeScrollableEnvironment()
        environment.playback.start()
        environment.playback.engine.advance(by: 1)

        environment.selectScript(Script(title: "Other", body: "different"))

        #expect(environment.playback.engine.state == .stopped)
        #expect(environment.playback.engine.offset == 0)
    }

    @Test("Re-selecting the same script does not interrupt playback")
    func reselectingTheSameScriptKeepsPlaying() {
        let environment = makeScrollableEnvironment()
        let same = environment.activeScript.script
        environment.playback.start()

        environment.selectScript(same)

        #expect(environment.playback.isPlaying)
    }

    @Test("Clearing the active script empties the overlay and stops playback")
    func clearingResetsEverything() {
        let environment = makeScrollableEnvironment()
        environment.playback.start()

        environment.clearActiveScript()

        #expect(environment.activeScript.script == nil)
        #expect(environment.preferences.lastOpenedScriptID == nil)
        #expect(environment.playback.engine.state == .stopped)
        #expect(environment.playback.hasContent == false)
    }

    @Test("App termination tears down the overlay and flushes the pending frame save")
    func terminationTearsDownOverlayAndFlushesFrame() {
        let center = NotificationCenter()
        let environment = makeEnvironment(notificationCenter: center)
        environment.setOverlayVisible(true)
        #expect(environment.playback.displaySourceView != nil)

        environment.overlay.setSize(CGSize(width: 640, height: 480))
        center.post(name: NSApplication.willTerminateNotification, object: nil)

        #expect(environment.playback.displaySourceView == nil)
        #expect(environment.preferences.overlayFrame?.size == CGSize(width: 640, height: 480))
    }

    @Test("Rolling with the overlay hidden shows it before starting playback")
    func rollingShowsTheOverlay() {
        let environment = makeScrollableEnvironment()
        #expect(environment.overlay.isVisible == false)

        environment.toggleRolling()

        #expect(environment.overlay.isVisible)
        #expect(environment.playback.isPlaying)
    }

    @Test("Rolling while playing pauses without hiding the overlay")
    func rollingAgainPausesAndKeepsOverlay() {
        let environment = makeScrollableEnvironment()
        environment.toggleRolling()

        environment.toggleRolling()

        #expect(environment.overlay.isVisible)
        #expect(environment.playback.isPlaying == false)
    }

    @Test("Emptying the script body through the editor withdraws playback")
    func emptyingTheBodyWithdrawsPlayback() {
        let environment = makeScrollableEnvironment()
        environment.playback.start()

        environment.activeScript.script?.apply(title: "Intro", body: "")
        environment.refreshPlaybackAvailability()

        #expect(environment.playback.hasContent == false)
        #expect(environment.playback.engine.state == .stopped)
    }
}
