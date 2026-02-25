import BackendAPI
import XCTest
@testable import AppShelliOS

final class AppErrorMapperTests: XCTestCase {
    private struct TextError: Error, CustomStringConvertible {
        let description: String
    }

    func testMapsUnauthorizedBackendError() {
        let message = AppErrorMapper.message(for: BackendAPIError.unauthorized)

        XCTAssertEqual(message, "Login session expired, please sign in again")
    }

    func testMapsUserCancelledErrorText() {
        let message = AppErrorMapper.message(for: TextError(description: "rpc request cancelled by user"))

        XCTAssertEqual(message, "Payment cancelled by user")
    }
}
