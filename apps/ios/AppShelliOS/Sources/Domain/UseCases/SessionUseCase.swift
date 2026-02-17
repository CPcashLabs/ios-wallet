import Foundation

@MainActor
final class SessionUseCase {
    private unowned let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func boot() {
        appState.bootImpl()
    }

    func refreshPasskeyAccounts() {
        appState.refreshPasskeyAccountsImpl()
    }

    func registerPasskey(displayName: String) async {
        await appState.registerPasskeyImpl(displayName: displayName)
    }

    func loginWithPasskey(rawId: String?) async {
        await appState.loginWithPasskeyImpl(rawId: rawId)
    }

    func signOutToLogin() {
        appState.signOutToLoginImpl()
    }

    #if DEBUG
    func cycleEnvironmentForDebug() {
        appState.cycleEnvironmentForDebugImpl()
    }
    #endif
}
