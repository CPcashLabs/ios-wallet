import XCTest
@testable import AppShelliOS

final class DateTextFormatterTests: XCTestCase {
    func testMillisecondsTimestampConvertsToSecondsDate() {
        let date = DateTextFormatter.date(fromTimestamp: 1_735_689_600_000)

        XCTAssertNotNil(date)
        XCTAssertEqual(date?.timeIntervalSince1970 ?? 0, 1_735_689_600, accuracy: 0.001)
    }

    func testFallbackForMissingTimestamp() {
        XCTAssertEqual(DateTextFormatter.yearMonthDay(fromTimestamp: nil), "-")
    }
}
