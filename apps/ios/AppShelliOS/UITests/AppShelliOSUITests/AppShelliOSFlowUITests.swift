import XCTest

final class AppShelliOSFlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @discardableResult
    private func launchApp(scenario: String = "happy", skipLogin: Bool = true) -> AppShellPage {
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--uitest-scenario=\(scenario)"]
        if skipLogin {
            app.launchArguments.append("--uitest-skip-login")
        }
        app.launch()

        let page = AppShellPage(app: app)
        XCTAssertTrue(page.wait(app.otherElements[TestID.App.contentRoot], timeout: 12))
        return page
    }

    private func openAddReceiveAddress(page: AppShellPage, business: Bool = false) {
        page.openReceiveSelectFromHome()
        XCTAssertTrue(page.wait(page.firstButton(withPrefix: TestID.Receive.networkProxyPrefix), timeout: 10))
        page.selectProxyReceiveNetwork()
        if business {
            XCTAssertTrue(page.wait(app.buttons[TestID.Receive.drawerBusiness], timeout: 10))
            app.buttons[TestID.Receive.drawerBusiness].tap()
        }
        let addressEntryID = business ? TestID.Receive.addressTapBusiness : TestID.Receive.addressTapIndividuals
        XCTAssertTrue(page.tapIdentifier(addressEntryID, timeout: 12))
        let addPageShown = page.waitForIdentifier(TestID.Receive.addButton, timeout: 12) != nil
            || page.waitForIdentifier(TestID.Receive.invalidButton, timeout: 2) != nil
            || page.waitForIdentifier(TestID.Receive.addHeader, timeout: 2) != nil
            || page.waitForIdentifier(TestID.Receive.addTitle, timeout: 2) != nil
        XCTAssertTrue(addPageShown)
    }

    private func openTransferAddress(page: AppShellPage) {
        page.openTransferSelectFromHome()
        XCTAssertTrue(page.wait(page.firstButton(withPrefix: TestID.Transfer.networkNormalPrefix), timeout: 10))
        page.selectNormalTransferNetwork()
        XCTAssertTrue(page.wait(app.textFields[TestID.Transfer.addressInput], timeout: 10))
    }

    private func openReceiveHome(page: AppShellPage) {
        page.openReceiveSelectFromHome()
        XCTAssertTrue(page.wait(page.firstButton(withPrefix: TestID.Receive.networkProxyPrefix), timeout: 10))
        page.selectProxyReceiveNetwork()
        XCTAssertTrue(app.navigationBars["Receive"].waitForExistence(timeout: 8))
    }

    private func openMeBillList(page: AppShellPage) {
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.bill].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.bill].tap()
        XCTAssertTrue(app.navigationBars["账单"].waitForExistence(timeout: 8))
    }

    private func inputText(_ value: String, identifier: String, page: AppShellPage) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 8))
        field.tap()
        if let oldValue = field.value as? String,
           !oldValue.isEmpty
        {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: oldValue.count))
        }
        field.typeText(value)
        page.dismissKeyboard()
    }

    private func openOrderDetailFromBill(page: AppShellPage) {
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.bill].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.bill].tap()
        XCTAssertTrue(app.navigationBars["账单"].waitForExistence(timeout: 8))
        let firstBillRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", TestID.Me.billRowPrefix)).firstMatch
        XCTAssertTrue(firstBillRow.waitForExistence(timeout: 10))
        firstBillRow.tap()
        let detailShown = page.waitForIdentifier(TestID.OrderDetail.summary, timeout: 10) != nil
            || app.navigationBars["订单详情"].waitForExistence(timeout: 6)
        XCTAssertTrue(detailShown)
    }

    private func moveToTransferAmount(page: AppShellPage) {
        if page.tapIdentifier(TestID.Transfer.addressRecentPrimary, timeout: 2) {
            let byRecent = app.textFields[TestID.Transfer.amountInput].waitForExistence(timeout: 8)
                || app.buttons[TestID.Transfer.amountNext].waitForExistence(timeout: 8)
            if byRecent {
                return
            }
        }

        let nextButton = app.buttons[TestID.Transfer.addressNext]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 8))
        XCTAssertTrue(nextButton.isEnabled)
        if app.keyboards.element.exists {
            if app.keyboards.buttons["Done"].exists {
                app.keyboards.buttons["Done"].tap()
            } else if app.keyboards.buttons["Return"].exists {
                app.keyboards.buttons["Return"].tap()
            }
        }
        XCTAssertTrue(page.tapIdentifier(TestID.Transfer.addressNext, timeout: 8))
        let amountInput = app.textFields[TestID.Transfer.amountInput]
        if !amountInput.waitForExistence(timeout: 6) {
            XCTAssertTrue(page.tapIdentifier(TestID.Transfer.addressNext, timeout: 3))
        }
        XCTAssertTrue(
            amountInput.waitForExistence(timeout: 10) ||
                app.buttons[TestID.Transfer.amountNext].waitForExistence(timeout: 10)
        )
    }

    private func moveToTransferConfirm(page: AppShellPage, amount: String = "1") {
        moveToTransferAmount(page: page)
        page.inputTransferAmount(amount)
        page.dismissKeyboard()
        let amountNext = app.buttons[TestID.Transfer.amountNext]
        XCTAssertTrue(amountNext.waitForExistence(timeout: 8))
        XCTAssertTrue(amountNext.isEnabled)
        let confirmButton = app.buttons[TestID.Transfer.confirm]
        for _ in 0 ..< 3 {
            XCTAssertTrue(page.tapIdentifier(TestID.Transfer.amountNext, timeout: 8))
            if confirmButton.waitForExistence(timeout: 4) {
                break
            }
            page.dismissKeyboard()
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 6))
    }

    func testHomeShortcutReceiveVisible() {
        _ = launchApp()
        XCTAssertTrue(app.buttons[TestID.Home.shortcutReceive].waitForExistence(timeout: 8))
    }

    func testHomeShortcutTransferVisible() {
        _ = launchApp()
        XCTAssertTrue(app.buttons[TestID.Home.shortcutTransfer].waitForExistence(timeout: 8))
    }

    func testHomeShortcutStatisticsVisible() {
        _ = launchApp()
        XCTAssertTrue(app.buttons[TestID.Home.shortcutStatistics].waitForExistence(timeout: 8))
    }

    func testHomeRecentMessageCanOpenMessageCenter() {
        let page = launchApp()
        XCTAssertTrue(page.tapIdentifier(TestID.Home.recentMessageButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["消息"].waitForExistence(timeout: 8))
    }

    func testMessageCenterShowsAllReadButton() {
        let page = launchApp()
        XCTAssertTrue(page.tapIdentifier(TestID.Home.recentMessageButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["消息"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons[TestID.Me.messageAllReadButton].waitForExistence(timeout: 8))
    }

    func testCanSwitchMeTabAndBack() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.settings].waitForExistence(timeout: 8))
        page.tapTab("首页")
        XCTAssertTrue(app.buttons[TestID.Home.shortcutReceive].waitForExistence(timeout: 8))
    }

    func testReceiveSelectNetworkShowsInAppChannel() {
        let page = launchApp()
        page.openReceiveSelectFromHome()
        XCTAssertTrue(app.buttons[TestID.Receive.networkInApp].waitForExistence(timeout: 10))
    }

    func testOpenAddReceiveAddressFromProxyNetwork() {
        let page = launchApp()
        openAddReceiveAddress(page: page)
        XCTAssertNotNil(page.waitForIdentifier(TestID.Receive.addHeader, timeout: 8))
    }

    func testAddReceiveBottomBarShowsAddAndInvalidButtons() {
        let page = launchApp()
        openAddReceiveAddress(page: page)
        let bottomBarVisible = app.otherElements[TestID.Receive.addBottomBar].waitForExistence(timeout: 5)
            || app.buttons[TestID.Receive.addButton].waitForExistence(timeout: 5)
        XCTAssertTrue(bottomBarVisible)
        XCTAssertTrue(app.buttons[TestID.Receive.addButton].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons[TestID.Receive.invalidButton].waitForExistence(timeout: 8))
    }

    func testAddReceiveBottomBarButtonsAreHittable() {
        let page = launchApp()
        openAddReceiveAddress(page: page)

        let addButton = app.buttons[TestID.Receive.addButton]
        let invalidButton = app.buttons[TestID.Receive.invalidButton]
        XCTAssertTrue(addButton.waitForExistence(timeout: 8))
        XCTAssertTrue(invalidButton.waitForExistence(timeout: 8))

        let window = app.windows.firstMatch.frame
        XCTAssertTrue(
            addButton.isHittable,
            "Add button exists but is not hittable, frame=\(addButton.frame), window=\(window), enabled=\(addButton.isEnabled)"
        )
        XCTAssertTrue(
            invalidButton.isHittable,
            "Invalid-address button exists but is not hittable, frame=\(invalidButton.frame), window=\(window), enabled=\(invalidButton.isEnabled)"
        )
        XCTAssertLessThanOrEqual(addButton.frame.maxY, window.maxY + 1, "Add button is outside viewport")
        XCTAssertLessThanOrEqual(invalidButton.frame.maxY, window.maxY + 1, "Invalid-address button is outside viewport")
    }

    func testBusinessAddAddressShowsRandomAndRareOptions() {
        let page = launchApp()
        openAddReceiveAddress(page: page, business: true)
        app.buttons[TestID.Receive.addButton].tap()
        XCTAssertTrue(app.buttons[TestID.Receive.businessRandom].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons[TestID.Receive.businessRare].exists)
    }

    func testAddReceiveHeaderContainsLimitCounter() {
        let page = launchApp()
        openAddReceiveAddress(page: page)
        XCTAssertTrue(app.staticTexts["已添加地址"].waitForExistence(timeout: 8))
        let counter = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^[0-9]+/[0-9]+$")).firstMatch
        XCTAssertTrue(counter.waitForExistence(timeout: 8))
    }

    func testReceiveEmptyScenarioShowsEmptyStateInAddAddress() {
        let page = launchApp(scenario: "empty")
        page.openReceiveSelectFromHome()
        XCTAssertTrue(app.buttons[TestID.Receive.networkInApp].waitForExistence(timeout: 10))
        app.buttons[TestID.Receive.networkInApp].tap()
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.addressTap, timeout: 10))
        XCTAssertNotNil(page.waitForIdentifier(TestID.Receive.addEmpty, timeout: 15))
    }

    func testReceiveHomeMenuCanOpenValidAddressList() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["有效地址"].waitForExistence(timeout: 8))
        app.buttons["有效地址"].tap()
        XCTAssertTrue(app.navigationBars["有效地址"].waitForExistence(timeout: 8))
    }

    func testReceiveAddressListLogsActionCanOpenTxLogs() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["有效地址"].waitForExistence(timeout: 8))
        app.buttons["有效地址"].tap()
        XCTAssertTrue(app.navigationBars["有效地址"].waitForExistence(timeout: 8))
        let logsButton = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@",
                TestID.Receive.addressListActionPrefix,
                ".logs"
            )
        ).firstMatch
        XCTAssertTrue(logsButton.waitForExistence(timeout: 8))
        logsButton.tap()
        XCTAssertTrue(app.navigationBars["收款记录"].waitForExistence(timeout: 8))
    }

    func testReceiveAddressListShareActionCanOpenSharePage() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["有效地址"].waitForExistence(timeout: 8))
        app.buttons["有效地址"].tap()
        XCTAssertTrue(app.navigationBars["有效地址"].waitForExistence(timeout: 8))
        let shareButton = app.buttons.matching(
            NSPredicate(
                format: "identifier BEGINSWITH %@ AND identifier ENDSWITH %@",
                TestID.Receive.addressListActionPrefix,
                ".share"
            )
        ).firstMatch
        XCTAssertTrue(shareButton.waitForExistence(timeout: 8))
        shareButton.tap()
        XCTAssertTrue(app.navigationBars["分享"].waitForExistence(timeout: 8))
    }

    func testReceiveHomeMenuCanOpenInvalidAddressPage() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["无效地址"].waitForExistence(timeout: 8))
        app.buttons["无效地址"].tap()
        let invalidShown = app.navigationBars["无效地址"].waitForExistence(timeout: 8)
            || app.navigationBars["失效地址"].waitForExistence(timeout: 2)
        XCTAssertTrue(invalidShown)
    }

    func testReceiveHomeMenuCanOpenExpiryPage() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["地址有效期设置"].waitForExistence(timeout: 8))
        app.buttons["地址有效期设置"].tap()
        XCTAssertTrue(app.navigationBars["Expiry Date"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons[TestID.Receive.expiryConfirmButton].waitForExistence(timeout: 8))
    }

    func testReceiveHomeMenuCanOpenDeleteAddressPage() {
        let page = launchApp()
        openReceiveHome(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Receive.homeMenuButton, timeout: 8))
        XCTAssertTrue(app.buttons["删除地址"].waitForExistence(timeout: 8))
        app.buttons["删除地址"].tap()
        XCTAssertTrue(app.navigationBars["删除地址"].waitForExistence(timeout: 8))
    }

    func testTransferSelectNetworkShowsNormalRow() {
        let page = launchApp()
        page.openTransferSelectFromHome()
        XCTAssertTrue(page.firstButton(withPrefix: TestID.Transfer.networkNormalPrefix).waitForExistence(timeout: 10))
    }

    func testTransferAddressNextDisabledForInvalidAddress() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("invalid-address")
        XCTAssertFalse(app.buttons[TestID.Transfer.addressNext].isEnabled)
    }

    func testTransferAddressNextEnabledForValidAddress() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        XCTAssertTrue(app.buttons[TestID.Transfer.addressNext].isEnabled)
    }

    func testTransferAddressNextButtonIsHittable() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")

        let nextButton = app.buttons[TestID.Transfer.addressNext]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 8))
        XCTAssertTrue(nextButton.isEnabled)

        let window = app.windows.firstMatch.frame
        XCTAssertTrue(
            nextButton.isHittable,
            "Next button exists but is not hittable, frame=\(nextButton.frame), window=\(window), enabled=\(nextButton.isEnabled)"
        )
        XCTAssertLessThanOrEqual(nextButton.frame.maxY, window.maxY + 1, "Next button is outside viewport")
    }

    func testTransferAmountNextNavigatesToConfirm() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        moveToTransferConfirm(page: page, amount: "1")
    }

    func testTransferConfirmCanSubmitAndShowReceipt() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        moveToTransferConfirm(page: page, amount: "1")
        app.buttons[TestID.Transfer.confirm].tap()
        XCTAssertTrue(app.buttons[TestID.Transfer.receiptDone].waitForExistence(timeout: 12))
    }

    func testTransferReceiptDoneReturnsHome() {
        let page = launchApp()
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        moveToTransferConfirm(page: page, amount: "1")
        app.buttons[TestID.Transfer.confirm].tap()
        XCTAssertTrue(app.buttons[TestID.Transfer.receiptDone].waitForExistence(timeout: 12))
        app.buttons[TestID.Transfer.receiptDone].tap()
        XCTAssertTrue(app.buttons[TestID.Home.shortcutReceive].waitForExistence(timeout: 8))
    }

    func testTransferReceiptAppearsOnlyAfterSlowConfirmation() {
        let page = launchApp(scenario: "slowConfirm")
        openTransferAddress(page: page)
        page.inputTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        moveToTransferConfirm(page: page, amount: "1")

        app.buttons[TestID.Transfer.confirm].tap()

        XCTAssertFalse(app.buttons[TestID.Transfer.receiptDone].waitForExistence(timeout: 1))
        XCTAssertTrue(app.buttons[TestID.Transfer.receiptDone].waitForExistence(timeout: 12))
    }

    func testMeTabShowsSettingsButton() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.settings].waitForExistence(timeout: 8))
    }

    func testMeTabShowsBillEntry() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.bill].waitForExistence(timeout: 8))
    }

    func testMeTabShowsAddressBookEntry() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.addressBook].waitForExistence(timeout: 8))
    }

    func testMeTabShowsPersonalAndTotalAssetsEntries() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertNotNil(page.waitForIdentifier(TestID.Me.personal, timeout: 8))
        XCTAssertTrue(app.buttons[TestID.Me.totalAssets].waitForExistence(timeout: 8))
    }

    func testMeCanOpenSettingsPage() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.settings].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.settings].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 8))
    }

    func testMeCanOpenPersonalPage() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertNotNil(page.waitForIdentifier(TestID.Me.personal, timeout: 8))
        XCTAssertTrue(page.tapIdentifier(TestID.Me.personal, timeout: 8))
        let personalShown = page.waitForIdentifier(TestID.Me.personalPage, timeout: 8) != nil
            || app.navigationBars["个人信息"].waitForExistence(timeout: 4)
        XCTAssertTrue(personalShown)
        XCTAssertNotNil(page.waitForIdentifier(TestID.Me.personalNicknameLabel, timeout: 6))
    }

    func testMeCanOpenTotalAssetsPage() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.totalAssets].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.totalAssets].tap()
        XCTAssertTrue(app.navigationBars["全部资产"].waitForExistence(timeout: 8))
    }

    func testSettingsCurrencyRowCanOpenSettingUnitPage() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.settings].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.settings].tap()
        XCTAssertTrue(app.navigationBars["设置"].waitForExistence(timeout: 8))
        XCTAssertTrue(page.tapIdentifier(TestID.Me.settingsCurrencyRow, timeout: 8))
        XCTAssertTrue(app.navigationBars["货币单位"].waitForExistence(timeout: 8))
    }

    func testAddressBookCanAddAndDeleteItem() {
        let page = launchApp()
        page.tapTab("我的")
        XCTAssertTrue(app.buttons[TestID.Me.addressBook].waitForExistence(timeout: 8))
        app.buttons[TestID.Me.addressBook].tap()
        XCTAssertTrue(app.navigationBars["地址簿"].waitForExistence(timeout: 8))

        XCTAssertTrue(page.tapIdentifier(TestID.Me.addressBookAddButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["添加地址"].waitForExistence(timeout: 8))
        inputText("UI Test Contact", identifier: TestID.Me.addressBookNameInput, page: page)
        inputText("0xcccccccccccccccccccccccccccccccccccccccc", identifier: TestID.Me.addressBookWalletInput, page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Me.addressBookSaveButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["地址簿"].waitForExistence(timeout: 8))

        let firstRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", TestID.Me.addressBookRowPrefix)).firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 8))
        firstRow.tap()
        let editShown = app.navigationBars["编辑地址"].waitForExistence(timeout: 8)
            || app.navigationBars["添加地址"].waitForExistence(timeout: 2)
        XCTAssertTrue(editShown)
        XCTAssertTrue(page.tapIdentifier(TestID.Me.addressBookDeleteButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["地址簿"].waitForExistence(timeout: 8))
    }

    func testBillFilterSheetCanOpenAndApply() {
        let page = launchApp()
        openMeBillList(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Me.billFilterButton, timeout: 8))
        XCTAssertTrue(app.navigationBars["筛选"].waitForExistence(timeout: 8))
        let completedToggle = app.switches["仅显示已完成"]
        if completedToggle.waitForExistence(timeout: 2) {
            completedToggle.tap()
        }
        XCTAssertTrue(app.buttons["应用"].waitForExistence(timeout: 8))
        app.buttons["应用"].tap()
        XCTAssertTrue(app.buttons[TestID.Me.billFilterButton].waitForExistence(timeout: 8))
    }

    func testBillMoreButtonCanOpenStatisticsPage() {
        let page = launchApp()
        openMeBillList(page: page)
        XCTAssertTrue(page.tapIdentifier(TestID.Me.billMoreButton, timeout: 8))
        XCTAssertTrue(app.buttons["统计"].waitForExistence(timeout: 8))
        app.buttons["统计"].tap()
        XCTAssertTrue(app.navigationBars["统计"].waitForExistence(timeout: 8))
    }

    func testOrderDetailShowsSummaryAndGroupedSections() {
        let page = launchApp()
        openOrderDetailFromBill(page: page)

        XCTAssertNotNil(page.waitForIdentifier(TestID.OrderDetail.summary, timeout: 8))
        XCTAssertNotNil(page.waitForIdentifier(TestID.OrderDetail.transaction, timeout: 8))
        XCTAssertNotNil(page.waitForIdentifier(TestID.OrderDetail.address, timeout: 8))
        XCTAssertNotNil(page.waitForIdentifier(TestID.OrderDetail.chain, timeout: 8))
        XCTAssertNotNil(page.waitForIdentifier(TestID.OrderDetail.time, timeout: 8))
    }
}
