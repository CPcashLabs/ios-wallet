import XCTest
@testable import AppShelliOS

@MainActor
final class BillRangeTests: XCTestCase {
    func testMonthlyPresetBuildsMonthBoundaryRange() {
        let appState = AppState()
        let calendar = Calendar(identifier: .gregorian)
        let selectedMonth = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15, hour: 12))!

        let range = appState.billRangeForPreset(.monthly, selectedMonth: selectedMonth)

        XCTAssertEqual(range.startedAt, "2025-01-01 00:00:00")
        XCTAssertEqual(range.endedAt, "2025-01-31 23:59:59")
        XCTAssertEqual(range.preset, .monthly)
    }
}
