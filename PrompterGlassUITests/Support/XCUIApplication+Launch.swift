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
}
