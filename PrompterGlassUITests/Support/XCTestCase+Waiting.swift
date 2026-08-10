import XCTest

extension XCTestCase {
    func waitForDisappearance(of element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        wait(for: element, toSatisfy: NSPredicate(format: "exists == false"), timeout: timeout)
    }

    func waitForValue(of element: XCUIElement, containing text: String, timeout: TimeInterval = 5) -> Bool {
        wait(for: element, toSatisfy: NSPredicate(format: "value CONTAINS %@", text), timeout: timeout)
    }

    private func wait(for element: XCUIElement, toSatisfy predicate: NSPredicate, timeout: TimeInterval) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
