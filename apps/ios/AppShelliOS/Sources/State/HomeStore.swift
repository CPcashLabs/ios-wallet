import BackendAPI
import Combine
import Foundation

@MainActor
final class HomeStore: ObservableObject {
    private let appState: AppState
    private var heartbeatTask: Task<Void, Never>?
    private let heartbeatInterval: UInt64 = 30_000_000_000 // 30 seconds
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var coins: [CoinItem] = []
    @Published private(set) var allCoins: [CoinItem] = []
    @Published private(set) var recentTransfers: [TransferItem] = []
    @Published private(set) var homeRecentMessages: [MessageItem] = []
    @Published private(set) var receives: [ReceiveRecord] = []
    @Published private(set) var orders: [OrderSummary] = []

    init(appState: AppState) {
        self.appState = appState
        userProfile = appState.meProfile
        coins = appState.coins
        allCoins = appState.allCoins
        recentTransfers = appState.recentTransfers
        homeRecentMessages = appState.homeRecentMessages
        receives = appState.receives
        orders = appState.orders
        bind()
    }

    func startHeartbeat() {
        guard heartbeatTask == nil else { return }
        heartbeatTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: heartbeatInterval)
                guard !Task.isCancelled else { break }
                await refreshHomeData()
            }
        }
    }

    func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }

    func refreshHomeData() async {
        await appState.refreshHomeData()
    }

    private func bind() {
        appState.$meProfile
            .sink { [weak self] in self?.userProfile = $0 }
            .store(in: &cancellables)

        appState.$coins
            .sink { [weak self] in self?.coins = $0 }
            .store(in: &cancellables)

        appState.$allCoins
            .sink { [weak self] in self?.allCoins = $0 }
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
