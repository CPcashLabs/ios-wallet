import Foundation

@MainActor
final class MeUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func loadMeRootData() async {
        await appState.loadMeRootDataImpl()
    }

    func loadMessages(page: Int, append: Bool) async {
        await appState.loadMessagesImpl(page: page, append: append)
    }

    func loadAddressBooks() async {
        await appState.loadAddressBooksImpl()
    }

    func updateNickname(_ nickname: String) async {
        await appState.updateNicknameImpl(nickname)
    }

    func updateAvatar(fileData: Data, fileName: String, mimeType: String) async {
        await appState.updateAvatarImpl(fileData: fileData, fileName: fileName, mimeType: mimeType)
    }

    func loadExchangeRates() async {
        await appState.loadExchangeRatesImpl()
    }
}
