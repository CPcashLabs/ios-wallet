import BackendAPI
import Foundation

@MainActor
final class ReceiveUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadReceiveSelectNetwork() async {
        await appState.loadReceiveSelectNetworkImpl()
    }

    func loadReceiveHome(autoCreateIfMissing: Bool) async {
        await appState.loadReceiveHomeImpl(autoCreateIfMissing: autoCreateIfMissing)
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        await appState.loadReceiveAddressesImpl(validity: validity)
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int, perPage: Int) async {
        await appState.loadReceiveTraceChildrenImpl(orderSN: orderSN, page: page, perPage: perPage)
    }

    func loadReceiveShare(orderSN: String) async {
        await appState.loadReceiveShareImpl(orderSN: orderSN)
    }

    func loadReceiveExpiryConfig() async {
        await appState.loadReceiveExpiryConfigImpl()
    }

    func updateReceiveExpiry(duration: Int) async {
        await appState.updateReceiveExpiryImpl(duration: duration)
    }
}
