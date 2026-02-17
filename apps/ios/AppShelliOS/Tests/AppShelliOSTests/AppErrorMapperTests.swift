import BackendAPI
import XCTest
@testable import AppShelliOS

final class AppErrorMapperTests: XCTestCase {
    private struct TextError: Error, CustomStringConvertible {
        let description: String
    }

    func testMapsUnauthorizedBackendError() {
        let message = AppErrorMapper.message(for: BackendAPIError.unauthorized)

        XCTAssertEqual(message, "登录状态失效，请重新登录")
    }

    func testMapsUserCancelledErrorText() {
        let message = AppErrorMapper.message(for: TextError(description: "rpc request cancelled by user"))

        XCTAssertEqual(message, "用户取消支付")
    }
}
