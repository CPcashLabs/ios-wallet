import Combine
import Foundation

@MainActor
final class UIStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var toast: ToastState?
    @Published private(set) var logs: [String]
    @Published private(set) var loginBusy: Bool
    @Published private(set) var loginErrorKind: LoginErrorKind?

    init(appState: AppState) {
        self.appState = appState
        toast = appState.toast
        logs = appState.logs
        loginBusy = appState.loginBusy
        loginErrorKind = appState.loginErrorKind
        bind()
    }

    func isLoading(_ key: String) -> Bool {
        appState.isLoading(key)
    }

    func errorMessage(_ key: String) -> String? {
        appState.errorMessage(key)
    }

    func showInfoToast(_ message: String) {
        appState.showInfoToast(message)
    }

    private func bind() {
        appState.$toast
            .sink { [weak self] in self?.toast = $0 }
            .store(in: &cancellables)

        appState.$logs
            .sink { [weak self] in self?.logs = $0 }
            .store(in: &cancellables)

        appState.$loginBusy
            .sink { [weak self] in self?.loginBusy = $0 }
            .store(in: &cancellables)

        appState.$loginErrorKind
            .sink { [weak self] in self?.loginErrorKind = $0 }
            .store(in: &cancellables)
    }
}
