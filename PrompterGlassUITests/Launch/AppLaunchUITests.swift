import XCTest

final class AppLaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsThePrompterSectionsAndControls() {
        let app = XCUIApplication.launchForTesting()

        XCTAssertTrue(
            app.buttons[AccessibilityIdentifier.Sidebar.prompter].waitForExistence(timeout: 15),
            "The sidebar should be visible after launch"
        )
        XCTAssertTrue(
            app.control(AccessibilityIdentifier.Controls.overlayToggle).waitForExistence(timeout: 10),
            "The overlay toggle should be reachable from the sidebar"
        )
        XCTAssertTrue(
            app.control(AccessibilityIdentifier.Controls.clickThroughToggle).waitForExistence(timeout: 10),
            "The click-through toggle should be visible in the Prompter section"
        )

        app.openSection(AccessibilityIdentifier.Sidebar.library)
        XCTAssertTrue(
            app.buttons[AccessibilityIdentifier.Library.createFirst].waitForExistence(timeout: 10),
            "The empty library should offer to create the first script"
        )

        app.terminate()
    }
}
