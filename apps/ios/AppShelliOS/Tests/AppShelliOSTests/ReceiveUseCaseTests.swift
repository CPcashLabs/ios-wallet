import XCTest
@testable import AppShelliOS

@MainActor
final class ReceiveUseCaseTests: XCTestCase {
    func testLoadReceiveAddressLimitUsesBackendValue() async {
        let appState = makeAppState()

        await appState.loadReceiveAddressLimit()

        XCTAssertEqual(appState.receiveDomainState.receiveAddressLimit, 5)
        XCTAssertNil(appState.errorMessage(.receiveAddressLimit))
    }

    func testLoadReceiveAddressLimitFallsBackToDefaultOnError() async {
        let appState = makeAppState(.error)

        await appState.loadReceiveAddressLimit()

        XCTAssertEqual(appState.receiveDomainState.receiveAddressLimit, 20)
        XCTAssertNotNil(appState.errorMessage(.receiveAddressLimit))
    }

    func testLoadReceiveSelectNetworkBuildsNormalAndProxyNetworks() async {
        let appState = makeAppState()

        await appState.loadReceiveSelectNetwork()

        XCTAssertFalse(appState.receiveNormalNetworks.isEmpty)
        XCTAssertFalse(appState.receiveProxyNetworks.isEmpty)
        XCTAssertFalse(appState.receiveSelectNetworks.isEmpty)
    }

    func testSelectReceiveNetworkNormalUpdatesDomainState() async {
        let appState = makeAppState()
        await appState.loadReceiveSelectNetwork()
        guard let normal = appState.receiveNormalNetworks.first else {
            return XCTFail("missing normal network")
        }

        await appState.selectReceiveNetwork(item: normal)

        XCTAssertTrue(appState.receiveDomainState.selectedIsNormalChannel)
        XCTAssertEqual(appState.receiveDomainState.selectedPairLabel, "USDT/USDT")
    }

    func testLoadReceiveAddressesInvalidLoadsInvalidList() async {
        let appState = makeAppState()
        await appState.loadReceiveSelectNetwork()
        guard let proxy = appState.receiveProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectReceiveNetwork(item: proxy)

        await appState.loadReceiveAddresses(validity: .invalid)

        XCTAssertEqual(appState.receiveDomainState.validityStatus, .invalid)
        XCTAssertFalse(appState.receiveRecentInvalid.isEmpty)
        XCTAssertNil(appState.errorMessage(.receiveInvalid))
    }

    func testMarkTraceOrderShowsSuccessToast() async {
        let appState = makeAppState()
        await appState.loadReceiveSelectNetwork()
        guard let proxy = appState.receiveProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectReceiveNetwork(item: proxy)
        guard let orderSN = appState.receiveRecentValid.first?.orderSn else {
            return XCTFail("missing valid order")
        }

        await appState.markTraceOrder(orderSN: orderSN)

        XCTAssertEqual(appState.toast?.message, "Default receive address updated")
        XCTAssertNil(appState.errorMessage(.receiveMark))
    }

    func testLoadReceiveTraceChildrenPopulatesChildren() async {
        let appState = makeAppState()

        await appState.loadReceiveTraceChildren(orderSN: "TRACE-IND-1")

        XCTAssertFalse(appState.receiveTraceChildren.isEmpty)
        XCTAssertNil(appState.errorMessage(.receiveChildren))
    }

    func testLoadReceiveSharePopulatesShareDetail() async {
        let appState = makeAppState()

        await appState.loadReceiveShare(orderSN: "TRACE-IND-1")

        XCTAssertEqual(appState.receiveShareDetail?.orderSn, "TRACE-IND-1")
        XCTAssertNil(appState.errorMessage(.receiveShare))
    }

    func testLoadAndUpdateReceiveExpiryConfig() async {
        let appState = makeAppState()

        await appState.loadReceiveExpiryConfig()
        await appState.updateReceiveExpiry(duration: 24)

        XCTAssertEqual(appState.receiveExpiryConfig.selectedDuration, 24)
        XCTAssertNil(appState.errorMessage(.receiveExpiryUpdate))
    }

    func testEditAddressInfoReturnsTrueOnSuccess() async {
        let appState = makeAppState()
        await appState.loadReceiveSelectNetwork()
        guard let proxy = appState.receiveProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectReceiveNetwork(item: proxy)
        guard let order = appState.receiveRecentValid.first,
              let orderSN = order.orderSn,
              let address = order.address ?? order.receiveAddress
        else {
            return XCTFail("missing editable order")
        }

        let ok = await appState.editAddressInfo(orderSN: orderSN, remarkName: "new-name", address: address)

        XCTAssertTrue(ok)
        XCTAssertEqual(appState.toast?.message, "Address note updated")
    }

    func testCreateShortTraceOrderHandlesLimitExceeded() async {
        let appState = makeAppState(.limitExceeded)
        await appState.loadReceiveSelectNetwork()
        guard let proxy = appState.receiveProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectReceiveNetwork(item: proxy)

        await appState.createShortTraceOrder()

        XCTAssertEqual(appState.toast?.message, "Current receive address count has reached the limit")
    }
}
