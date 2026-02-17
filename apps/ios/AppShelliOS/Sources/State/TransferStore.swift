import BackendAPI
import Combine
import Foundation

@MainActor
final class TransferStore: ObservableObject {
    private let appState: AppState
    private var appStateChanges: AnyCancellable?

    init(appState: AppState) {
        self.appState = appState
        appStateChanges = appState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var transferDomainState: TransferDomainState {
        appState.transferDomainState
    }

    var transferSelectNetworks: [TransferNetworkItem] {
        appState.transferSelectNetworks
    }

    var transferNormalNetworks: [TransferNetworkItem] {
        appState.transferNormalNetworks
    }

    var transferProxyNetworks: [TransferNetworkItem] {
        appState.transferProxyNetworks
    }

    var transferSelectedNetworkId: String? {
        appState.transferSelectedNetworkId
    }

    var transferDraft: TransferDraft {
        appState.transferDraft
    }

    var transferRecentContacts: [TransferReceiveContact] {
        appState.transferRecentContacts
    }

    var addressBooks: [AddressBookItem] {
        appState.addressBooks
    }

    func loadTransferSelectNetwork() async {
        await appState.loadTransferSelectNetwork()
    }

    func selectTransferNetwork(item: TransferNetworkItem) async {
        await appState.selectTransferNetwork(item: item)
    }

    func selectTransferPair(sendCoinCode: String, recvCoinCode: String) {
        appState.selectTransferPair(sendCoinCode: sendCoinCode, recvCoinCode: recvCoinCode)
    }

    func selectTransferNormalCoin(coinCode: String) async {
        await appState.selectTransferNormalCoin(coinCode: coinCode)
    }

    func updateTransferRecipientAddress(_ address: String) {
        appState.updateTransferRecipientAddress(address)
    }

    func resetTransferFlow() {
        appState.resetTransferFlow()
    }

    func transferAddressValidationMessage(_ address: String) -> String? {
        appState.transferAddressValidationMessage(address)
    }

    func isValidTransferAddress(_ address: String) -> Bool {
        appState.isValidTransferAddress(address)
    }

    func transferAddressBookCandidates() -> [AddressBookItem] {
        appState.transferAddressBookCandidates()
    }

    func detectAddressChainType(_ address: String) -> String? {
        appState.detectAddressChainType(address)
    }

    func loadTransferAddressCandidates() async {
        await appState.loadTransferAddressCandidates()
    }

    func prepareTransferPayment(amountText: String, note: String) async -> Bool {
        await appState.prepareTransferPayment(amountText: amountText, note: note)
    }

    func executeTransferPayment() async -> Bool {
        await appState.executeTransferPayment()
    }
}
