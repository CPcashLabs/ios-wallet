import BackendAPI
import Foundation
import XCTest
@testable import AppShelliOS

@MainActor
final class AppStateLogicTests: XCTestCase {
    func testMergeMessagesDeduplicatesByID() {
        let appState = makeAppState()
        let current: [MessageItem] = [
            decodeFixture(["id": 1, "title": "a"], as: MessageItem.self),
        ]
        let incoming: [MessageItem] = [
            decodeFixture(["id": 1, "title": "a-dup"], as: MessageItem.self),
            decodeFixture(["id": 2, "title": "b"], as: MessageItem.self),
        ]

        let merged = appState.mergeMessages(current: current, incoming: incoming)

        XCTAssertEqual(merged.count, 2)
    }

    func testMergeMessagesDeduplicatesByFallbackKey() {
        let appState = makeAppState()
        let current: [MessageItem] = [
            decodeFixture(["title": "title", "content": "c", "type": "SYSTEM", "created_at": 1], as: MessageItem.self),
        ]
        let incoming: [MessageItem] = [
            decodeFixture(["title": "title", "content": "c", "type": "SYSTEM", "created_at": 1], as: MessageItem.self),
            decodeFixture(["title": "new", "content": "c2", "type": "SYSTEM", "created_at": 2], as: MessageItem.self),
        ]

        let merged = appState.mergeMessages(current: current, incoming: incoming)

        XCTAssertEqual(merged.count, 2)
    }

    func testMergeOrdersDeduplicatesByOrderSN() {
        let appState = makeAppState()
        let current: [OrderSummary] = [
            decodeFixture(["order_sn": "A"], as: OrderSummary.self),
        ]
        let incoming: [OrderSummary] = [
            decodeFixture(["order_sn": "A"], as: OrderSummary.self),
            decodeFixture(["order_sn": "B"], as: OrderSummary.self),
        ]

        let merged = appState.mergeOrders(current: current, incoming: incoming)

        XCTAssertEqual(merged.count, 2)
    }

    func testMergeOrdersDeduplicatesByFallbackKey() {
        let appState = makeAppState()
        let current: [OrderSummary] = [
            decodeFixture(["created_at": 1, "order_type": "PAYMENT", "payment_address": "0x1", "receive_address": "0x2"], as: OrderSummary.self),
        ]
        let incoming: [OrderSummary] = [
            decodeFixture(["created_at": 1, "order_type": "PAYMENT", "payment_address": "0x1", "receive_address": "0x2"], as: OrderSummary.self),
            decodeFixture(["created_at": 2, "order_type": "PAYMENT", "payment_address": "0x3", "receive_address": "0x4"], as: OrderSummary.self),
        ]

        let merged = appState.mergeOrders(current: current, incoming: incoming)

        XCTAssertEqual(merged.count, 2)
    }

    func testComputeLastPageTrueWhenReachTotal() {
        let appState = makeAppState()

        XCTAssertTrue(appState.computeLastPage(page: 2, perPage: 10, total: 20))
    }

    func testComputeLastPageFalseWhenNotReachTotalOrInvalid() {
        let appState = makeAppState()

        XCTAssertFalse(appState.computeLastPage(page: 1, perPage: 10, total: 21))
        XCTAssertFalse(appState.computeLastPage(page: nil, perPage: 10, total: 20))
        XCTAssertFalse(appState.computeLastPage(page: 1, perPage: 0, total: 20))
    }

    func testBillRangeTodayUsesFixedClock() {
        let fixed = Date(timeIntervalSince1970: 1_736_294_400) // 2025-01-08 00:00:00 UTC
        let base = AppDependencies.uiTest(scenario: .happy)
        let deps = AppDependencies(
            securityService: base.securityService,
            backendFactory: base.backendFactory,
            passkeyService: base.passkeyService,
            clock: FixedClock(now: fixed),
            idGenerator: base.idGenerator,
            logger: base.logger
        )
        let appState = AppState(dependencies: deps)

        let range = appState.billRangeForPreset(.today)

        XCTAssertTrue(range.startedAt.hasSuffix("00:00:00"))
        XCTAssertTrue(range.endedAt.hasSuffix("23:59:59"))
    }

    func testBillRangeYesterdayPreset() {
        let fixed = Date(timeIntervalSince1970: 1_736_380_800) // 2025-01-09 00:00:00 UTC
        let base = AppDependencies.uiTest(scenario: .happy)
        let deps = AppDependencies(
            securityService: base.securityService,
            backendFactory: base.backendFactory,
            passkeyService: base.passkeyService,
            clock: FixedClock(now: fixed),
            idGenerator: base.idGenerator,
            logger: base.logger
        )
        let appState = AppState(dependencies: deps)

        let range = appState.billRangeForPreset(.yesterday)

        XCTAssertEqual(range.preset, .yesterday)
        guard let started = range.startedTimestamp, let ended = range.endedTimestamp else {
            return XCTFail("timestamp missing")
        }
        XCTAssertLessThan(started, ended)
    }

    func testBillRangeLast7DaysPreset() {
        let appState = makeAppState()

        let range = appState.billRangeForPreset(.last7Days)

        XCTAssertEqual(range.preset, .last7Days)
        guard let started = range.startedTimestamp, let ended = range.endedTimestamp else {
            return XCTFail("timestamp missing")
        }
        XCTAssertLessThan(started, ended)
    }

    func testSetBillAddressFilterImplTrimsSpaces() {
        let appState = makeAppState()

        appState.setBillAddressFilterImpl("  0xabc  ")
        XCTAssertEqual(appState.billAddressFilter, "0xabc")
        appState.setBillAddressFilterImpl("  ")
        XCTAssertNil(appState.billAddressFilter)
    }

    func testRestoreSelectedChainFallsBackToDefault() {
        let appState = makeAppState()
        UserDefaults.standard.set(999, forKey: appState.selectedChainStorageKey)

        appState.restoreSelectedChain()

        XCTAssertEqual(appState.selectedChainId, 1029)
        XCTAssertEqual(appState.selectedChainName, "BTT_TEST")
    }

    func testStableRowIDUtilities() {
        XCTAssertEqual(StableRowID.make(nil, " ", "row-1", fallback: "x"), "row-1")
        XCTAssertEqual(StableRowID.uniqued(["a", "a", "b"]), ["a", "a#2", "b"])
    }

    func testPaginationGateBeginEndReset() {
        let gate = PaginationGate()
        XCTAssertTrue(gate.begin(token: "p1"))
        XCTAssertFalse(gate.begin(token: "p1"))
        gate.end(token: "p1")
        XCTAssertTrue(gate.begin(token: "p1"))
        gate.reset()
        XCTAssertTrue(gate.begin(token: "p2"))
    }

    func testLogRedactsAddressAndTxHash() {
        let appState = makeAppState()
        let address = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        let txHash = "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

        appState.log("address=\(address), tx=\(txHash)")

        guard let last = appState.logs.last else {
            return XCTFail("missing log entry")
        }
        XCTAssertFalse(last.contains(address))
        XCTAssertFalse(last.contains(txHash))
        XCTAssertTrue(last.contains("..."))
    }
}
