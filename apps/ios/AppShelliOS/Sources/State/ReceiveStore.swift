import BackendAPI
import Combine
import Foundation

@MainActor
final class ReceiveStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var receiveDomainState: ReceiveDomainState
    @Published private(set) var receiveSelectNetworks: [ReceiveNetworkItem]
    @Published private(set) var receiveNormalNetworks: [ReceiveNetworkItem]
    @Published private(set) var receiveProxyNetworks: [ReceiveNetworkItem]
    @Published private(set) var receiveSelectedNetworkId: String?
    @Published private(set) var individualTraceOrder: TraceOrderItem?
    @Published private(set) var businessTraceOrder: TraceOrderItem?
    @Published private(set) var receiveRecentValid: [TraceOrderItem]
    @Published private(set) var receiveRecentInvalid: [TraceOrderItem]
    @Published private(set) var receiveTraceChildren: [TraceChildItem]
    @Published private(set) var individualTraceDetail: TraceShowDetail?
    @Published private(set) var businessTraceDetail: TraceShowDetail?
    @Published private(set) var receiveShareDetail: ReceiveOrderDetail?
    @Published private(set) var receiveExpiryConfig: ReceiveExpiryConfig
    @Published private(set) var activeAddress: String
    @Published private(set) var environment: EnvironmentConfig

    init(appState: AppState) {
        self.appState = appState
        receiveDomainState = appState.receiveDomainState
        receiveSelectNetworks = appState.receiveSelectNetworks
        receiveNormalNetworks = appState.receiveNormalNetworks
        receiveProxyNetworks = appState.receiveProxyNetworks
        receiveSelectedNetworkId = appState.receiveSelectedNetworkId
        individualTraceOrder = appState.individualTraceOrder
        businessTraceOrder = appState.businessTraceOrder
        receiveRecentValid = appState.receiveRecentValid
        receiveRecentInvalid = appState.receiveRecentInvalid
        receiveTraceChildren = appState.receiveTraceChildren
        individualTraceDetail = appState.individualTraceDetail
        businessTraceDetail = appState.businessTraceDetail
        receiveShareDetail = appState.receiveShareDetail
        receiveExpiryConfig = appState.receiveExpiryConfig
        activeAddress = appState.activeAddress
        environment = appState.environment

        bind()
    }

    func loadReceiveSelectNetwork() async {
        await appState.loadReceiveSelectNetwork()
    }

    func selectReceiveNetwork(item: ReceiveNetworkItem, preloadHome: Bool = true) async {
        await appState.selectReceiveNetwork(item: item, preloadHome: preloadHome)
    }

    func selectReceivePair(sendCoinCode: String, recvCoinCode: String) async {
        await appState.selectReceivePair(sendCoinCode: sendCoinCode, recvCoinCode: recvCoinCode)
    }

    func setReceiveActiveTab(_ tab: ReceiveTabMode) {
        appState.setReceiveActiveTab(tab)
    }

    func loadReceiveHome(autoCreateIfMissing: Bool = true) async {
        await appState.loadReceiveHome(autoCreateIfMissing: autoCreateIfMissing)
    }

    func createShortTraceOrder(note: String = "") async {
        await appState.createShortTraceOrder(note: note)
    }

    func createLongTraceOrder(note: String = "") async {
        await appState.createLongTraceOrder(note: note)
    }

    func refreshTraceShow(orderSN: String) async {
        await appState.refreshTraceShow(orderSN: orderSN)
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        await appState.loadReceiveAddresses(validity: validity)
    }

    func markTraceOrder(orderSN: String, sendCoinCode: String? = nil, recvCoinCode: String? = nil, orderType: String? = nil) async {
        await appState.markTraceOrder(orderSN: orderSN, sendCoinCode: sendCoinCode, recvCoinCode: recvCoinCode, orderType: orderType)
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        await appState.loadReceiveTraceChildren(orderSN: orderSN, page: page, perPage: perPage)
    }

    func loadReceiveShare(orderSN: String) async {
        await appState.loadReceiveShare(orderSN: orderSN)
    }

    func loadReceiveExpiryConfig() async {
        await appState.loadReceiveExpiryConfig()
    }

    func updateReceiveExpiry(duration: Int) async {
        await appState.updateReceiveExpiry(duration: duration)
    }

    func loadReceiveAddressLimit() async {
        await appState.loadReceiveAddressLimit()
    }

    func editAddressInfo(orderSN: String, remarkName: String, address: String) async -> Bool {
        await appState.editAddressInfo(orderSN: orderSN, remarkName: remarkName, address: address)
    }

    func isLoading(_ key: LoadKey) -> Bool {
        appState.isLoading(key)
    }

    func errorMessage(_ key: LoadKey) -> String? {
        appState.errorMessage(key)
    }

    func showInfoToast(_ message: String) {
        appState.showInfoToast(message)
    }

    private func bind() {
        appState.$receiveDomainState
            .sink { [weak self] in self?.receiveDomainState = $0 }
            .store(in: &cancellables)

        appState.$receiveSelectNetworks
            .sink { [weak self] in self?.receiveSelectNetworks = $0 }
            .store(in: &cancellables)

        appState.$receiveNormalNetworks
            .sink { [weak self] in self?.receiveNormalNetworks = $0 }
            .store(in: &cancellables)

        appState.$receiveProxyNetworks
            .sink { [weak self] in self?.receiveProxyNetworks = $0 }
            .store(in: &cancellables)

        appState.$receiveSelectedNetworkId
            .sink { [weak self] in self?.receiveSelectedNetworkId = $0 }
            .store(in: &cancellables)

        appState.$individualTraceOrder
            .sink { [weak self] in self?.individualTraceOrder = $0 }
            .store(in: &cancellables)

        appState.$businessTraceOrder
            .sink { [weak self] in self?.businessTraceOrder = $0 }
            .store(in: &cancellables)

        appState.$receiveRecentValid
            .sink { [weak self] in self?.receiveRecentValid = $0 }
            .store(in: &cancellables)

        appState.$receiveRecentInvalid
            .sink { [weak self] in self?.receiveRecentInvalid = $0 }
            .store(in: &cancellables)

        appState.$receiveTraceChildren
            .sink { [weak self] in self?.receiveTraceChildren = $0 }
            .store(in: &cancellables)

        appState.$individualTraceDetail
            .sink { [weak self] in self?.individualTraceDetail = $0 }
            .store(in: &cancellables)

        appState.$businessTraceDetail
            .sink { [weak self] in self?.businessTraceDetail = $0 }
            .store(in: &cancellables)

        appState.$receiveShareDetail
            .sink { [weak self] in self?.receiveShareDetail = $0 }
            .store(in: &cancellables)

        appState.$receiveExpiryConfig
            .sink { [weak self] in self?.receiveExpiryConfig = $0 }
            .store(in: &cancellables)

        appState.$activeAddress
            .sink { [weak self] in self?.activeAddress = $0 }
            .store(in: &cancellables)

        appState.$environment
            .sink { [weak self] in self?.environment = $0 }
            .store(in: &cancellables)
    }
}
