import XCTest

final class AppShellPage {
    let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    @discardableResult
    func wait(_ element: XCUIElement, timeout: TimeInterval = 10) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    func firstButton(withPrefix prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    @discardableResult
    func waitForIdentifier(_ identifier: String, timeout: TimeInterval = 10) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.buttons[identifier].exists {
                return app.buttons[identifier]
            }
            if app.otherElements[identifier].exists {
                return app.otherElements[identifier]
            }
            if app.cells[identifier].exists {
                return app.cells[identifier]
            }
            if app.staticTexts[identifier].exists {
                return app.staticTexts[identifier]
            }
            let any = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if any.exists {
                return any
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return nil
    }

    @discardableResult
    func tapIdentifier(_ identifier: String, timeout: TimeInterval = 10) -> Bool {
        guard let target = waitForIdentifier(identifier, timeout: timeout) else {
            return false
        }
        if target.isHittable {
            target.tap()
            return true
        }

        // Try to reveal off-screen controls before falling back to coordinate tap.
        for _ in 0 ..< 3 {
            app.swipeUp()
            if target.isHittable {
                target.tap()
                return true
            }
        }
        for _ in 0 ..< 3 {
            app.swipeDown()
            if target.isHittable {
                target.tap()
                return true
            }
        }

        target.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return true
    }

    func tapTab(_ title: String) {
        app.tabBars.buttons[title].tap()
    }

    func openReceiveSelectFromHome() {
        app.buttons[TestID.Home.shortcutReceive].tap()
    }

    func openTransferSelectFromHome() {
        app.buttons[TestID.Home.shortcutTransfer].tap()
    }

    func selectProxyReceiveNetwork() {
        firstButton(withPrefix: TestID.Receive.networkProxyPrefix).tap()
    }

    func selectNormalTransferNetwork() {
        firstButton(withPrefix: TestID.Transfer.networkNormalPrefix).tap()
    }

    func inputTransferAddress(_ value: String) {
        guard let input = inputElement(identifier: TestID.Transfer.addressInput, timeout: 10) else {
            XCTFail("transfer address input not found")
            return
        }
        input.tap()
        if let oldValue = input.value as? String,
           !oldValue.isEmpty,
           oldValue != "Enter wallet address"
        {
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count)
            input.typeText(delete)
        }
        input.typeText(value)
        dismissKeyboardIfPossible()
    }

    func inputTransferAmount(_ value: String) {
        guard let input = inputElement(identifier: TestID.Transfer.amountInput, timeout: 10) else {
            XCTFail("transfer amount input not found")
            return
        }
        input.tap()
        if let oldValue = input.value as? String,
           !oldValue.isEmpty,
           oldValue != "0.00"
        {
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count)
            input.typeText(delete)
        }
        input.typeText(value)
        dismissKeyboardIfPossible()
    }

    private func inputElement(identifier: String, timeout: TimeInterval) -> XCUIElement? {
        let textField = app.textFields[identifier]
        if textField.waitForExistence(timeout: timeout) {
            return textField
        }
        return waitForIdentifier(identifier, timeout: timeout)
    }

    private func dismissKeyboardIfPossible() {
        if !app.keyboards.element.exists {
            return
        }
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
            return
        }
        if app.keyboards.buttons["Done"].exists {
            app.keyboards.buttons["Done"].tap()
            return
        }
        if app.keyboards.buttons["Return"].exists {
            app.keyboards.buttons["Return"].tap()
            return
        }
        if app.keyboards.buttons["Collapse"].exists {
            app.keyboards.buttons["Collapse"].tap()
            return
        }
        if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
            return
        }
        if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
            return
        }

        // Numeric keyboards may not have an explicit done button; tap outside as fallback.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)).tap()
        if app.keyboards.element.exists {
            app.keyboards.element.swipeDown()
        }
        if app.keyboards.element.exists {
            app.tap()
        }
    }

    func dismissKeyboard() {
        dismissKeyboardIfPossible()
    }
}
