import Combine
import Foundation

@MainActor
final class AppStore: ObservableObject {
    let appState: AppState
    let sessionStore: SessionStore
    let homeStore: HomeStore
    let meStore: MeStore
    let receiveStore: ReceiveStore
    let transferStore: TransferStore
    let uiStore: UIStore

    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        sessionStore = SessionStore(appState: appState)
        homeStore = HomeStore(appState: appState)
        meStore = MeStore(appState: appState)
        receiveStore = ReceiveStore(appState: appState)
        transferStore = TransferStore(appState: appState)
        uiStore = UIStore(appState: appState)
        bind()
    }

    convenience init() {
        self.init(appState: AppState())
    }

    convenience init(dependencies: AppDependencies) {
        self.init(appState: AppState(dependencies: dependencies))
    }

    var rootScreen: RootScreen {
        sessionStore.rootScreen
    }

    var toast: ToastState? {
        uiStore.toast
    }

    func boot() {
        appState.boot()
    }

    private func bind() {
        sessionStore.$isAuthenticated
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        uiStore.$toast
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
