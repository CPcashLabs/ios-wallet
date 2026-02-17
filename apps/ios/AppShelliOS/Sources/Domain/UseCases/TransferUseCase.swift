import Foundation

@MainActor
final class TransferUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadTransferSelectNetwork() async {
        await appState.loadTransferSelectNetworkImpl()
    }

    func loadTransferAddressCandidates() async {
        await appState.loadTransferAddressCandidatesImpl()
    }

    func prepareTransferPayment(amountText: String, note: String) async -> Bool {
        await appState.prepareTransferPaymentImpl(amountText: amountText, note: note)
    }

    func executeTransferPayment() async -> Bool {
        await appState.executeTransferPaymentImpl()
    }
}
