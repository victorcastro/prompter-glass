import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTheLibraryAndControls() {
        let app = XCUIApplication.launchForTesting()

        XCTAssertTrue(app.buttons[AccessibilityIdentifier.Library.createFirst].waitForExistence(timeout: 10))
        XCTAssertTrue(app.switches[AccessibilityIdentifier.Controls.overlayToggle].exists)
        XCTAssertTrue(app.switches[AccessibilityIdentifier.Controls.clickThroughToggle].exists)

        app.terminate()
    }
}
