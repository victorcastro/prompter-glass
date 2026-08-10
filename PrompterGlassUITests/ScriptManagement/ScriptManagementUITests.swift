import XCTest

final class ScriptManagementUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication.launchForTesting()
        app.openSection(AccessibilityIdentifier.Sidebar.library)
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testEmptyLibraryOffersToCreateTheFirstScript() {
        let createFirst = app.buttons[AccessibilityIdentifier.Library.createFirst]
        XCTAssertTrue(createFirst.waitForExistence(timeout: 5), "Empty state should offer a create action")

        createFirst.click()

        XCTAssertTrue(titleField.waitForExistence(timeout: 5), "Creating should open the editor")
    }

    func testCreatingAScriptFocusesTheTitleField() {
        createScript()

        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        XCTAssertEqual(titleField.value as? String, "Untitled Script")
        XCTAssertTrue(titleField.hasKeyboardFocus, "The title field should be focused for a new script")
    }

    func testEditingTheTitleUpdatesTheLibraryRow() {
        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))

        setTitle("Launch Video")
        returnToGrid()

        let row = libraryRow(titled: "Launch Video")
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The library card should show the edited title")
    }

    func testEditingTheBodyPersistsWhileSwitchingScripts() {
        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        setTitle("First")
        setBody("Hello from the teleprompter.")

        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        setTitle("Second")
        returnToGrid()

        libraryRow(titled: "First").click()

        let reopened = bodyEditor
        XCTAssertTrue(reopened.waitForExistence(timeout: 5))
        XCTAssertEqual(reopened.value as? String, "Hello from the teleprompter.")
    }

    func testScriptsAreListedNewestFirst() {
        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        setTitle("Older")

        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        setTitle("Newer")
        returnToGrid()

        let newer = libraryRow(titled: "Newer")
        let older = libraryRow(titled: "Older")
        XCTAssertTrue(newer.waitForExistence(timeout: 5))
        XCTAssertTrue(older.waitForExistence(timeout: 5))

        let newerComesFirst = newer.frame.minY < older.frame.minY - 1
            || (abs(newer.frame.minY - older.frame.minY) <= 1 && newer.frame.minX < older.frame.minX)
        XCTAssertTrue(
            newerComesFirst,
            "The most recently edited script should come before the older one in the grid"
        )
    }

    func testDeletingAScriptAsksForConfirmationAndRemovesIt() {
        let row = createScript(titled: "Doomed")
        row.click()
        beginDeletion()

        let confirm = app.buttons[AccessibilityIdentifier.Library.confirmDelete]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "Deleting should ask for confirmation")
        confirm.click()

        XCTAssertTrue(
            waitForDisappearance(of: row),
            "The script should be gone from the library after confirming"
        )
    }

    func testCancellingDeletionKeepsTheScript() {
        let row = createScript(titled: "Survivor")
        row.click()
        beginDeletion()

        let cancel = app.buttons[AccessibilityIdentifier.Library.cancelDelete]
        XCTAssertTrue(cancel.waitForExistence(timeout: 5))
        cancel.click()
        returnToGrid()

        XCTAssertTrue(row.waitForExistence(timeout: 5), "Cancelling must leave the script in place")
    }
}

private extension ScriptManagementUITests {
    var titleField: XCUIElement {
        app.textFields[AccessibilityIdentifier.Editor.title]
    }

    var bodyEditor: XCUIElement {
        app.textViews[AccessibilityIdentifier.Editor.body]
    }

    func createScript() {
        returnToGrid()
        let createButton = app.buttons[AccessibilityIdentifier.Library.create]
        if createButton.waitForExistence(timeout: 3) {
            createButton.click()
        } else {
            app.buttons[AccessibilityIdentifier.Library.createFirst].click()
        }
    }

    @discardableResult
    func createScript(titled title: String) -> XCUIElement {
        createScript()
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        setTitle(title)
        returnToGrid()

        let row = libraryRow(titled: title)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        return row
    }

    func returnToGrid() {
        let back = app.buttons[AccessibilityIdentifier.Library.back]
        if back.waitForExistence(timeout: 2) {
            back.click()
        }
    }

    func libraryRow(titled title: String) -> XCUIElement {
        app.staticTexts
            .matching(identifier: AccessibilityIdentifier.Library.rowTitle)
            .matching(NSPredicate(format: "label == %@ OR value == %@", title, title))
            .firstMatch
    }

    func setTitle(_ title: String) {
        titleField.click()
        titleField.typeKey("a", modifierFlags: .command)
        titleField.typeText(title)
        titleField.typeKey(.tab, modifierFlags: [])
    }

    func setBody(_ body: String) {
        let editor = bodyEditor
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.click()
        editor.typeText(body)
    }

    func beginDeletion() {
        let deleteButton = app.buttons[AccessibilityIdentifier.Library.delete]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.click()
    }
}
