import XCTest
@testable import AppShelliOS

final class AddressFormatterTests: XCTestCase {
    func testShortenedLongAddress() {
        let value = "0xdb435783c118F4573B3aD48022F45E08d8fB6134"

        let shortened = AddressFormatter.shortened(value)

        XCTAssertEqual(shortened, "0xdb43...6134")
    }

    func testKeepsShortAddressUnchanged() {
        let value = "0x1234"

        XCTAssertEqual(AddressFormatter.shortened(value), value)
    }
}
