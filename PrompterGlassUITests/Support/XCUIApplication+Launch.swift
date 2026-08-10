import XCTest

extension XCUIApplication {
    @discardableResult
    static func launchForTesting(resettingPreferences: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
        if resettingPreferences {
            app.launchArguments += ["-ui-testing-reset"]
        }
        app.launch()
        return app
    }

    func openSection(_ identifier: String) {
        let item = buttons[identifier]
        guard item.waitForExistence(timeout: 10) else { return }
        item.click()
    }

    func control(_ identifier: String) -> XCUIElement {
        descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
