import LocalAuthentication
import BackendAPI
import XCTest
@testable import AppShelliOS

@MainActor
final class SessionUseCaseTests: XCTestCase {
    func testBootSetsActiveAddressAndPasskeyAccounts() {
        let appState = makeAppState()

        appState.boot()

        XCTAssertTrue(appState.activeAddress.hasPrefix("0x"))
        XCTAssertFalse(appState.passkeyAccounts.isEmpty)
    }

    func testLoginWithPasskeySuccessUpdatesSession() async {
        let appState = makeAppState()

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertTrue(appState.isAuthenticated)
        if case .unlocked = appState.approvalSessionState {
            XCTAssertNil(appState.loginErrorKind)
        } else {
            XCTFail("approval session should be unlocked")
        }
    }

    func testRegisterPasskeySuccessUpdatesSession() async {
        let appState = makeAppState()

        await appState.registerPasskey(displayName: "tester")

        XCTAssertTrue(appState.isAuthenticated)
        XCTAssertFalse(appState.selectedPasskeyRawId.isEmpty)
    }

    func testLoginFlowRespectsBusyFlag() async {
        let appState = makeAppState()
        appState.loginBusy = true

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertTrue(appState.loginBusy)
    }

    func testLoginFlowRespectsCooldown() async {
        let appState = makeAppState()
        appState.loginCooldownUntil = Date().addingTimeInterval(30)

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertFalse(appState.loginBusy)
    }

    func testLoginFailureClassifiesRejectSign() async {
        let base = AppDependencies.uiTest(scenario: .happy)
        let deps = AppDependencies(
            securityService: StaticSecurityService(),
            backendFactory: base.backendFactory,
            passkeyService: FailingPasskeyService(error: LAError(.userCancel)),
            clock: base.clock,
            idGenerator: base.idGenerator,
            logger: base.logger
        )
        let appState = AppState(dependencies: deps)

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertEqual(appState.loginErrorKind, .rejectSign)
        XCTAssertEqual(appState.toast?.message, "用户拒绝该请求")
    }

    func testLoginFailureClassifiesNetworkError() async {
        let base = AppDependencies.uiTest(scenario: .happy)
        let deps = AppDependencies(
            securityService: StaticSecurityService(),
            backendFactory: base.backendFactory,
            passkeyService: FailingPasskeyService(error: URLError(.timedOut)),
            clock: base.clock,
            idGenerator: base.idGenerator,
            logger: base.logger
        )
        let appState = AppState(dependencies: deps)

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertEqual(appState.loginErrorKind, .networkFailed)
        XCTAssertEqual(appState.toast?.message, "网络连接失败")
    }

    func testLoginFailureClassifiesAuthError() async {
        let base = AppDependencies.uiTest(scenario: .happy)
        let deps = AppDependencies(
            securityService: StaticSecurityService(),
            backendFactory: base.backendFactory,
            passkeyService: FailingPasskeyService(error: LocalPasskeyError.accountNotFound),
            clock: base.clock,
            idGenerator: base.idGenerator,
            logger: base.logger
        )
        let appState = AppState(dependencies: deps)

        await appState.loginWithPasskey(rawId: nil)

        XCTAssertEqual(appState.loginErrorKind, .authFailed)
        XCTAssertEqual(appState.toast?.message, "身份验证失败")
    }

    func testSignOutClearsSensitiveState() async {
        let appState = makeAppState()
        await appState.loginWithPasskey(rawId: nil)
        appState.messageList = [decodeFixture(["id": 1, "title": "x"], as: MessageItem.self)]
        appState.addressBooks = [decodeFixture(["id": 1, "name": "a"], as: AddressBookItem.self)]
        appState.billList = [decodeFixture(["order_sn": "1"], as: OrderSummary.self)]

        appState.signOutToLogin()

        XCTAssertFalse(appState.isAuthenticated)
        XCTAssertTrue(appState.messageList.isEmpty)
        XCTAssertTrue(appState.addressBooks.isEmpty)
        XCTAssertTrue(appState.billList.isEmpty)
        XCTAssertEqual(appState.approvalSessionState, .locked)
    }
}
