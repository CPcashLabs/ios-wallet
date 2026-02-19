import Foundation
import BackendAPI
import XCTest
@testable import AppShelliOS

@MainActor
final class TransferUseCaseTests: XCTestCase {
    func testLoadTransferSelectNetworkBuildsNormalAndProxyNetworks() async {
        let appState = makeAppState()

        await appState.loadTransferSelectNetwork()

        XCTAssertFalse(appState.transferNormalNetworks.isEmpty)
        XCTAssertFalse(appState.transferProxyNetworks.isEmpty)
        XCTAssertFalse(appState.transferSelectNetworks.isEmpty)
    }

    func testSelectTransferNetworkRejectsUnavailableItem() async {
        let appState = makeAppState()
        let unavailable = TransferNetworkItem(
            id: "proxy:zero",
            name: "Zero",
            logoURL: nil,
            chainColor: "#1677FF",
            category: .proxySettlement,
            allowChain: nil,
            normalChain: nil,
            isNormalChannel: false,
            balance: 0
        )

        await appState.selectTransferNetwork(item: unavailable)

        XCTAssertEqual(appState.toast?.message, "余额不足，请切换其他网络")
    }

    func testTransferAddressValidationMessageForInvalidInput() {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true

        let message = appState.transferAddressValidationMessage("abc")

        XCTAssertEqual(message, "请输入正确地址")
    }

    func testIsValidTransferAddressForNormalChannel() {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true

        XCTAssertTrue(appState.isValidTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
        XCTAssertFalse(appState.isValidTransferAddress("TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE"))
    }

    func testIsValidTransferAddressForProxyRegex() {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = false
        appState.transferDomainState.selectedAddressRegex = ["^T[a-zA-Z0-9]{33}$"]

        XCTAssertTrue(appState.isValidTransferAddress("TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE"))
        XCTAssertFalse(appState.isValidTransferAddress("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"))
    }

    func testDetectAddressChainType() {
        let appState = makeAppState()

        XCTAssertEqual(appState.detectAddressChainType("0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"), "EVM")
        XCTAssertEqual(appState.detectAddressChainType("TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE"), "TRON")
        XCTAssertNil(appState.detectAddressChainType("invalid"))
    }

    func testTransferAddressBookCandidatesFilterByChain() {
        let appState = makeAppState()
        appState.addressBooks = [
            decodeFixture(
                [
                    "id": 1,
                    "name": "evm",
                    "wallet_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "chain_type": "EVM",
                ],
                as: AddressBookItem.self
            ),
            decodeFixture(
                [
                    "id": 2,
                    "name": "tron",
                    "wallet_address": "TQn9Y2khEsLJW1ChVWFMSMeRDow5KcbLSE",
                    "chain_type": "TRON",
                ],
                as: AddressBookItem.self
            ),
        ]
        appState.transferDomainState.selectedPayChain = "TRON"

        let tronOnly = appState.transferAddressBookCandidates()

        XCTAssertEqual(tronOnly.count, 1)
        XCTAssertEqual(tronOnly.first?.chainType, "TRON")
    }

    func testLoadTransferAddressCandidatesSuccess() async {
        let appState = makeAppState()

        await appState.loadTransferAddressCandidates()

        XCTAssertFalse(appState.transferRecentContacts.isEmpty)
        XCTAssertNil(appState.errorMessage(.transferAddressCandidates))
    }

    func testPrepareTransferPaymentRejectsInvalidAddress() async {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true
        appState.transferDraft.recipientAddress = "invalid"

        let ok = await appState.prepareTransferPayment(amountText: "1", note: "")

        XCTAssertFalse(ok)
        XCTAssertEqual(appState.toast?.message, "地址格式错误")
    }

    func testPrepareTransferPaymentRejectsInvalidAmount() async {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

        let ok = await appState.prepareTransferPayment(amountText: "0", note: "")

        XCTAssertFalse(ok)
        XCTAssertEqual(appState.toast?.message, "请输入正确金额")
    }

    func testPrepareTransferPaymentNormalSuccess() async {
        let appState = makeAppState()
        await appState.loadTransferSelectNetwork()
        guard let normal = appState.transferNormalNetworks.first else {
            return XCTFail("missing normal network")
        }
        await appState.selectTransferNetwork(item: normal)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

        let ok = await appState.prepareTransferPayment(amountText: "1", note: "note")

        XCTAssertTrue(ok)
        XCTAssertEqual(appState.transferDraft.mode, .normal)
        XCTAssertEqual(appState.transferDraft.amountText, "1")
    }

    func testPrepareTransferPaymentProxySuccess() async {
        let appState = makeAppState()
        await appState.loadTransferSelectNetwork()
        guard let proxy = appState.transferProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectTransferNetwork(item: proxy)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

        let ok = await appState.prepareTransferPayment(amountText: "1", note: "proxy")

        XCTAssertTrue(ok)
        XCTAssertEqual(appState.transferDraft.mode, .proxy)
        XCTAssertNotNil(appState.transferDraft.orderSN)
        XCTAssertNotNil(appState.transferDraft.orderDetail)
    }

    func testExecuteTransferPaymentRequiresUnlockedSession() async {
        let appState = makeAppState()
        appState.approvalSessionState = .locked

        let ok = await appState.executeTransferPayment()

        XCTAssertFalse(ok)
        XCTAssertEqual(appState.toast?.message, "登录会话失效，请重新登录")
    }

    func testExecuteTransferPaymentNormalSuccess() async {
        let appState = makeAppState()
        await appState.loadTransferSelectNetwork()
        guard let normal = appState.transferNormalNetworks.first else {
            return XCTFail("missing normal network")
        }
        await appState.selectTransferNetwork(item: normal)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        _ = await appState.prepareTransferPayment(amountText: "1", note: "n")
        appState.approvalSessionState = .unlocked(lastVerifiedAt: Date())

        let ok = await appState.executeTransferPayment()

        XCTAssertTrue(ok)
        XCTAssertTrue(appState.lastTxHash.hasPrefix("0x"))
        XCTAssertEqual(appState.toast?.message, "支付成功")
    }

    func testExecuteTransferPaymentProxySuccess() async {
        let appState = makeAppState()
        await appState.loadTransferSelectNetwork()
        guard let proxy = appState.transferProxyNetworks.first else {
            return XCTFail("missing proxy network")
        }
        await appState.selectTransferNetwork(item: proxy)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        _ = await appState.prepareTransferPayment(amountText: "1", note: "proxy")
        appState.approvalSessionState = .unlocked(lastVerifiedAt: Date())

        let ok = await appState.executeTransferPayment()

        XCTAssertTrue(ok)
        XCTAssertTrue(appState.lastTxHash.hasPrefix("0x"))
        XCTAssertEqual(appState.toast?.message, "支付成功")
    }
}
