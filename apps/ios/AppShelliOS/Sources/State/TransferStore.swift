import BackendAPI
import Combine
import Foundation

@MainActor
final class TransferStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var transferDomainState: TransferDomainState
    @Published private(set) var transferSelectNetworks: [TransferNetworkItem]
    @Published private(set) var transferNormalNetworks: [TransferNetworkItem]
    @Published private(set) var transferProxyNetworks: [TransferNetworkItem]
    @Published private(set) var transferSelectedNetworkId: String?
    @Published private(set) var transferDraft: TransferDraft
    @Published private(set) var transferRecentContacts: [TransferReceiveContact]
    @Published private(set) var addressBooks: [AddressBookItem]

    init(appState: AppState) {
        self.appState = appState
        transferDomainState = appState.transferDomainState
        transferSelectNetworks = appState.transferSelectNetworks
        transferNormalNetworks = appState.transferNormalNetworks
        transferProxyNetworks = appState.transferProxyNetworks
        transferSelectedNetworkId = appState.transferSelectedNetworkId
        transferDraft = appState.transferDraft
        transferRecentContacts = appState.transferRecentContacts
        addressBooks = appState.addressBooks

        bind()
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

    private func bind() {
        appState.$transferDomainState
            .sink { [weak self] in self?.transferDomainState = $0 }
            .store(in: &cancellables)

        appState.$transferSelectNetworks
            .sink { [weak self] in self?.transferSelectNetworks = $0 }
            .store(in: &cancellables)

        appState.$transferNormalNetworks
            .sink { [weak self] in self?.transferNormalNetworks = $0 }
            .store(in: &cancellables)

        appState.$transferProxyNetworks
            .sink { [weak self] in self?.transferProxyNetworks = $0 }
            .store(in: &cancellables)

        appState.$transferSelectedNetworkId
            .sink { [weak self] in self?.transferSelectedNetworkId = $0 }
            .store(in: &cancellables)

        appState.$transferDraft
            .sink { [weak self] in self?.transferDraft = $0 }
            .store(in: &cancellables)

        appState.$transferRecentContacts
            .sink { [weak self] in self?.transferRecentContacts = $0 }
            .store(in: &cancellables)

        appState.$addressBooks
            .sink { [weak self] in self?.addressBooks = $0 }
            .store(in: &cancellables)
    }
}
