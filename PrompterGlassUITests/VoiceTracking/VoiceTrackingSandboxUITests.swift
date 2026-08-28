import XCTest

/// Guideline 2.4.5 verification: with the temporary mach-lookup exception removed, the Speech
/// stack must still start under the plain App Sandbox. Reaching the listening state exercises the
/// analyzer and the audio engine, which is where a missing entitlement would fail.
///
/// Opt in with `PROMPTERGLASS_SANDBOX_AUDIO_CHECK=1`, since it needs a real microphone and
/// microphone permission already granted for dev.victorcastro.prompter-glass.
final class VoiceTrackingSandboxUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["PROMPTERGLASS_SANDBOX_AUDIO_CHECK"] == "1",
            "Set PROMPTERGLASS_SANDBOX_AUDIO_CHECK=1 to run the sandboxed audio check"
        )
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testVoiceTrackingStartsUnderTheSandbox() {
        app.openSection(AccessibilityIdentifier.Sidebar.library)
        let create = app.buttons[AccessibilityIdentifier.Library.createFirst]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.click()

        let body = app.textViews[AccessibilityIdentifier.Editor.body]
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        body.click()
        body.typeText("Reading this line proves the analyzer started.")

        app.openSection(AccessibilityIdentifier.Sidebar.prompter)
        let toggle = app.control(AccessibilityIdentifier.Controls.voiceToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.click()

        // The speech model may have to be installed on first use, which is bounded by the
        // controller's own activation timeout.
        let unavailable = app.control(AccessibilityIdentifier.Controls.voiceUnavailable)
        let deadline = Date().addingTimeInterval(150)
        while Date() < deadline {
            if unavailable.exists {
                XCTFail("Voice tracking failed to start under the sandbox: \(unavailable.label)")
                return
            }
            let preparing = app.control(AccessibilityIdentifier.Controls.voicePreparing).exists
            let downloading = app.control(AccessibilityIdentifier.Controls.voiceDownloadingModel).exists
            let isOn = String(describing: toggle.value ?? "") == "1"
            if !preparing, !downloading, isOn {
                return
            }
            usleep(200_000)
        }
        let preparing = app.control(AccessibilityIdentifier.Controls.voicePreparing).exists
        let downloading = app.control(AccessibilityIdentifier.Controls.voiceDownloadingModel).exists
        let noScript = app.control(AccessibilityIdentifier.Controls.voiceNoScript).exists
        let denied = app.control(AccessibilityIdentifier.Controls.voiceDenied).exists
        XCTFail(
            "Never reached listening. preparing=\(preparing) downloading=\(downloading) "
                + "noScript=\(noScript) denied=\(denied) toggle=\(String(describing: toggle.value))"
        )
    }
}
