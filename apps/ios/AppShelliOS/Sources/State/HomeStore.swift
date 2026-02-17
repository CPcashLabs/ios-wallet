import BackendAPI
import Combine
import Foundation

@MainActor
final class HomeStore: ObservableObject {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var coins: [CoinItem]
    @Published private(set) var recentTransfers: [TransferItem]
    @Published private(set) var homeRecentMessages: [MessageItem]
    @Published private(set) var receives: [ReceiveRecord]
    @Published private(set) var orders: [OrderSummary]

    init(appState: AppState) {
        self.appState = appState
        userProfile = appState.userProfile
        coins = appState.coins
        recentTransfers = appState.recentTransfers
        homeRecentMessages = appState.homeRecentMessages
        receives = appState.receives
        orders = appState.orders
        bind()
    }

    func refreshHomeData() async {
        await appState.refreshHomeData()
    }

    private func bind() {
        appState.$userProfile
            .sink { [weak self] in self?.userProfile = $0 }
            .store(in: &cancellables)

        appState.$coins
            .sink { [weak self] in self?.coins = $0 }
            .store(in: &cancellables)

        appState.$recentTransfers
            .sink { [weak self] in self?.recentTransfers = $0 }
            .store(in: &cancellables)

        appState.$homeRecentMessages
            .sink { [weak self] in self?.homeRecentMessages = $0 }
            .store(in: &cancellables)

        appState.$receives
            .sink { [weak self] in self?.receives = $0 }
            .store(in: &cancellables)

        appState.$orders
            .sink { [weak self] in self?.orders = $0 }
            .store(in: &cancellables)
    }
}
