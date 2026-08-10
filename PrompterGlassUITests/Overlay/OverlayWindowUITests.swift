import XCTest

final class OverlayWindowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testOverlayCanBeShownAndHidden() {
        app = XCUIApplication.launchForTesting()

        let root = showOverlay()
        XCTAssertTrue(root.waitForExistence(timeout: 5), "Toggling on should show the overlay")

        app.typeKey("o", modifierFlags: [.command, .shift])

        XCTAssertTrue(
            waitForDisappearance(of: root),
            "Toggling off should remove the overlay from the screen"
        )
    }

    func testOverlayHasNoWindowChrome() {
        app = XCUIApplication.launchForTesting()

        let root = showOverlay()
        XCTAssertTrue(root.waitForExistence(timeout: 5), "The overlay should be on screen")

        XCTAssertEqual(app.windows.count, 1, "The overlay should not appear as a titled window")
        XCTAssertEqual(root.buttons.count, 0, "The overlay should have no buttons of its own")
        XCTAssertEqual(root.toolbars.count, 0, "The overlay should have no toolbar")
    }

    func testOverlayRendersTheSelectedScript() {
        app = XCUIApplication.launchForTesting()
        app.openSection(AccessibilityIdentifier.Sidebar.library)

        let createFirst = app.buttons[AccessibilityIdentifier.Library.createFirst]
        XCTAssertTrue(createFirst.waitForExistence(timeout: 15))
        createFirst.click()

        let editor = app.textViews[AccessibilityIdentifier.Editor.body]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.click()
        editor.typeText("Look at the lens, not the screen.")

        let root = showOverlay()
        XCTAssertTrue(root.waitForExistence(timeout: 5))

        let scriptText = app.staticTexts.matching(
            NSPredicate(format: "value CONTAINS %@ OR label CONTAINS %@", "Look at the lens", "Look at the lens")
        ).firstMatch
        XCTAssertTrue(
            scriptText.waitForExistence(timeout: 5),
            "The overlay should show the selected script's text"
        )
    }

    func testOverlayOpensDockedToTheTopOfTheScreen() {
        app = XCUIApplication.launchForTesting()

        let root = showOverlay()
        XCTAssertTrue(root.waitForExistence(timeout: 5))

        let mainWindow = app.windows.firstMatch.frame
        XCTAssertGreaterThan(root.frame.width, 0)
        XCTAssertLessThan(
            root.frame.minY,
            mainWindow.minY,
            "The overlay should sit above the main window's top edge"
        )
    }

    func testOverlayFrameIsRestoredAfterRelaunch() {
        app = XCUIApplication.launchForTesting()

        let root = showOverlay()
        XCTAssertTrue(root.waitForExistence(timeout: 5))
        let originalFrame = root.frame

        let start = root.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.4, thenDragTo: start.withOffset(CGVector(dx: -140, dy: 90)))

        let movedFrame = root.frame
        XCTAssertNotEqual(movedFrame.origin, originalFrame.origin, "Dragging the body should move the overlay")

        Thread.sleep(forTimeInterval: 1.0)
        app.terminate()

        app = XCUIApplication.launchForTesting(resettingPreferences: false)
        let restored = showOverlay()
        XCTAssertTrue(restored.waitForExistence(timeout: 5))

        XCTAssertEqual(restored.frame.origin.x, movedFrame.origin.x, accuracy: 2)
        XCTAssertEqual(restored.frame.origin.y, movedFrame.origin.y, accuracy: 2)
        XCTAssertEqual(restored.frame.width, movedFrame.width, accuracy: 2)
        XCTAssertEqual(restored.frame.height, movedFrame.height, accuracy: 2)
    }
}

private extension OverlayWindowUITests {
    var overlayRoot: XCUIElement {
        app.descendants(matching: .any).matching(identifier: AccessibilityIdentifier.Overlay.root).firstMatch
    }

    @discardableResult
    func showOverlay() -> XCUIElement {
        let toggle = app.control(AccessibilityIdentifier.Controls.overlayToggle)
        XCTAssertTrue(toggle.waitForExistence(timeout: 15), "The overlay toggle should be in the main window")
        toggle.click()
        return overlayRoot
    }
}
