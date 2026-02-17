import BackendAPI
import Combine
import Foundation

@MainActor
final class ReceiveStore: ObservableObject {
    private let appState: AppState
    private var appStateChanges: AnyCancellable?

    init(appState: AppState) {
        self.appState = appState
        appStateChanges = appState.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    var receiveDomainState: ReceiveDomainState {
        appState.receiveDomainState
    }

    var receiveSelectNetworks: [ReceiveNetworkItem] {
        appState.receiveSelectNetworks
    }

    var receiveNormalNetworks: [ReceiveNetworkItem] {
        appState.receiveNormalNetworks
    }

    var receiveProxyNetworks: [ReceiveNetworkItem] {
        appState.receiveProxyNetworks
    }

    var receiveSelectedNetworkId: String? {
        appState.receiveSelectedNetworkId
    }

    var individualTraceOrder: TraceOrderItem? {
        appState.individualTraceOrder
    }

    var businessTraceOrder: TraceOrderItem? {
        appState.businessTraceOrder
    }

    var receiveRecentValid: [TraceOrderItem] {
        appState.receiveRecentValid
    }

    var receiveRecentInvalid: [TraceOrderItem] {
        appState.receiveRecentInvalid
    }

    var receiveTraceChildren: [TraceChildItem] {
        appState.receiveTraceChildren
    }

    var individualTraceDetail: TraceShowDetail? {
        appState.individualTraceDetail
    }

    var businessTraceDetail: TraceShowDetail? {
        appState.businessTraceDetail
    }

    var receiveShareDetail: ReceiveOrderDetail? {
        appState.receiveShareDetail
    }

    var receiveExpiryConfig: ReceiveExpiryConfig {
        appState.receiveExpiryConfig
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
}
