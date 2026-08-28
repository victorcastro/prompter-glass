import XCTest

final class VoiceTrackingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testVoiceToggleRespondsWithoutAScriptAndSaysWhy() {
        let toggle = app.control(AccessibilityIdentifier.Controls.voiceToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "The voice toggle should be in the control panel")
        XCTAssertTrue(toggle.isEnabled, "The voice toggle must never look dead; it explains itself instead")

        toggle.click()

        let explanation = app.control(AccessibilityIdentifier.Controls.voiceNoScript)
        XCTAssertTrue(
            explanation.waitForExistence(timeout: 5),
            "Turning voice tracking on without a script should say a script is needed"
        )
        XCTAssertTrue(app.control(AccessibilityIdentifier.Controls.voiceNoScriptOpen).exists)
    }

    func testVoiceToggleEnablesOnceAScriptHasContent() {
        app.openSection(AccessibilityIdentifier.Sidebar.library)
        let create = app.buttons[AccessibilityIdentifier.Library.createFirst]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.click()

        let body = app.textViews[AccessibilityIdentifier.Editor.body]
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        body.click()
        body.typeText("Hello from the teleprompter.")

        app.openSection(AccessibilityIdentifier.Sidebar.prompter)
        let toggle = app.control(AccessibilityIdentifier.Controls.voiceToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertTrue(toggle.isEnabled)
        XCTAssertFalse(
            app.control(AccessibilityIdentifier.Controls.voiceNoScript).exists,
            "With a script in hand the no-script explanation should be gone"
        )
    }
}

final class VoiceTrackingFailureUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting(extraArguments: ["-ui-testing-voice-failure"])
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testFailedActivationExplainsItselfAndOffersRetry() {
        app.openSection(AccessibilityIdentifier.Sidebar.library)
        let create = app.buttons[AccessibilityIdentifier.Library.createFirst]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.click()

        let body = app.textViews[AccessibilityIdentifier.Editor.body]
        XCTAssertTrue(body.waitForExistence(timeout: 5))
        body.click()
        body.typeText("Hello from the teleprompter.")

        app.openSection(AccessibilityIdentifier.Sidebar.prompter)
        let toggle = app.control(AccessibilityIdentifier.Controls.voiceToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.click()

        let failure = app.control(AccessibilityIdentifier.Controls.voiceUnavailable)
        XCTAssertTrue(failure.waitForExistence(timeout: 5), "A failed activation should state what went wrong")
        XCTAssertTrue(
            app.control(AccessibilityIdentifier.Controls.voiceRetry).waitForExistence(timeout: 2),
            "A failed activation should offer Retry"
        )
    }
}
