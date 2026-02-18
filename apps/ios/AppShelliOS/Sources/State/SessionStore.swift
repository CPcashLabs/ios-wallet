import BackendAPI
import Combine
import Foundation

@MainActor
final class SessionStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var activeAddress: String
    @Published private(set) var environment: EnvironmentConfig
    @Published private(set) var selectedChainId: Int
    @Published private(set) var selectedChainName: String
    @Published private(set) var networkOptions: [NetworkOption]
    @Published private(set) var isAuthenticated: Bool
    @Published private(set) var approvalSessionState: ApprovalSessionState
    @Published private(set) var passkeyAccounts: [LocalPasskeyAccount]

    init(appState: AppState) {
        self.appState = appState
        activeAddress = appState.activeAddress
        environment = appState.environment
        selectedChainId = appState.selectedChainId
        selectedChainName = appState.selectedChainName
        networkOptions = appState.networkOptions
        isAuthenticated = appState.isAuthenticated
        approvalSessionState = appState.approvalSessionState
        passkeyAccounts = appState.passkeyAccounts

        bind()
    }

    var rootScreen: RootScreen {
        isAuthenticated ? .home : .login
    }

    func boot() {
        appState.boot()
    }

    func signOutToLogin() {
        appState.signOutToLogin()
    }

    func refreshNetworkOptions() async {
        await appState.refreshNetworkOptions()
    }

    func selectNetwork(chainId: Int) {
        appState.selectNetwork(chainId: chainId)
    }

    func refreshPasskeyAccounts() {
        appState.refreshPasskeyAccounts()
    }

    func registerPasskey(displayName: String) async {
        await appState.registerPasskey(displayName: displayName)
    }

    func loginWithPasskey(rawId: String?) async {
        await appState.loginWithPasskey(rawId: rawId)
    }

    func cycleEnvironmentForDebug() {
        appState.cycleEnvironmentForDebug()
    }

    private func bind() {
        appState.$activeAddress
            .sink { [weak self] in self?.activeAddress = $0 }
            .store(in: &cancellables)

        appState.$environment
            .sink { [weak self] in self?.environment = $0 }
            .store(in: &cancellables)

        appState.$selectedChainId
            .sink { [weak self] in self?.selectedChainId = $0 }
            .store(in: &cancellables)

        appState.$selectedChainName
            .sink { [weak self] in self?.selectedChainName = $0 }
            .store(in: &cancellables)

        appState.$networkOptions
            .sink { [weak self] in self?.networkOptions = $0 }
            .store(in: &cancellables)

        appState.$isAuthenticated
            .sink { [weak self] in self?.isAuthenticated = $0 }
            .store(in: &cancellables)

        appState.$approvalSessionState
            .sink { [weak self] in self?.approvalSessionState = $0 }
            .store(in: &cancellables)

        appState.$passkeyAccounts
            .sink { [weak self] in self?.passkeyAccounts = $0 }
            .store(in: &cancellables)
    }
}
