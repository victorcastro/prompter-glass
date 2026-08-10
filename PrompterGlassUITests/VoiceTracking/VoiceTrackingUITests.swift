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

    func testVoiceToggleIsVisibleAndDisabledWithoutAScript() {
        let toggle = app.control(AccessibilityIdentifier.Controls.voiceToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "The voice toggle should be in the control panel")
        XCTAssertFalse(toggle.isEnabled, "Voice tracking needs a script with content")
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
        XCTAssertTrue(
            toggle.waitForEnabled(timeout: 5),
            "Voice tracking should become available once the script has text"
        )
    }
}

private extension XCUIElement {
    func waitForEnabled(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "isEnabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
