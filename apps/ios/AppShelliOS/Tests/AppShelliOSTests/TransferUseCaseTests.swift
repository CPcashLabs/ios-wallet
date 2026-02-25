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

        XCTAssertEqual(appState.toast?.message, "Insufficient balance, please switch to another network")
    }

    func testTransferAddressValidationMessageForInvalidInput() {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true

        let message = appState.transferAddressValidationMessage("abc")

        XCTAssertEqual(message, "Please enter a valid address")
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
        XCTAssertEqual(appState.toast?.message, "Invalid address format")
    }

    func testPrepareTransferPaymentRejectsInvalidAmount() async {
        let appState = makeAppState()
        appState.transferDomainState.selectedIsNormalChannel = true
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"

        let ok = await appState.prepareTransferPayment(amountText: "0", note: "")

        XCTAssertFalse(ok)
        XCTAssertEqual(appState.toast?.message, "Please enter a valid amount")
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
        XCTAssertEqual(appState.toast?.message, "Login session expired, please sign in again")
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
        XCTAssertEqual(appState.toast?.message, "Payment successful")
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
        XCTAssertEqual(appState.toast?.message, "Payment successful")
    }

    func testExecuteTransferPaymentNormalFailsWhenConfirmationTimeout() async {
        let security = ControlledConfirmationSecurityService()
        security.mode = .timeout
        let appState = makeAppState(securityService: security)
        await appState.loadTransferSelectNetwork()
        guard let normal = appState.transferNormalNetworks.first else {
            return XCTFail("missing normal network")
        }
        await appState.selectTransferNetwork(item: normal)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        _ = await appState.prepareTransferPayment(amountText: "1", note: "n")
        appState.approvalSessionState = .unlocked(lastVerifiedAt: Date())
        appState.transferConfirmationTimeoutSeconds = 0.1
        appState.transferConfirmationPollIntervalSeconds = 0.01

        let ok = await appState.executeTransferPayment()

        XCTAssertFalse(ok)
        XCTAssertEqual(security.waitCallCount, 1)
        XCTAssertEqual(appState.toast?.message, "On-chain confirmation timed out, please check the result in bills later")
    }

    func testExecuteTransferPaymentNormalFailsWhenConfirmationStatusIsFailed() async {
        let security = ControlledConfirmationSecurityService()
        security.mode = .executionFailed
        let appState = makeAppState(securityService: security)
        await appState.loadTransferSelectNetwork()
        guard let normal = appState.transferNormalNetworks.first else {
            return XCTFail("missing normal network")
        }
        await appState.selectTransferNetwork(item: normal)
        appState.transferDraft.recipientAddress = "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
        _ = await appState.prepareTransferPayment(amountText: "1", note: "n")
        appState.approvalSessionState = .unlocked(lastVerifiedAt: Date())

        let ok = await appState.executeTransferPayment()

        XCTAssertFalse(ok)
        XCTAssertEqual(security.waitCallCount, 1)
        XCTAssertEqual(appState.toast?.message, "On-chain confirmation failed")
    }

    func testExecuteTransferPaymentNormalSuccessRequiresConfirmationCall() async {
        let security = ControlledConfirmationSecurityService()
        security.mode = .success(status: 1, blockNumber: 12)
        let appState = makeAppState(securityService: security)
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
        XCTAssertEqual(security.waitCallCount, 1)
        XCTAssertEqual(appState.toast?.message, "Payment successful")
    }

    func testExecuteTransferPaymentProxySuccessRequiresConfirmationCall() async {
        let security = ControlledConfirmationSecurityService()
        security.mode = .success(status: 1, blockNumber: 7)
        let appState = makeAppState(securityService: security)
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
        XCTAssertEqual(security.waitCallCount, 1)
        XCTAssertEqual(appState.toast?.message, "Payment successful")
    }
}
