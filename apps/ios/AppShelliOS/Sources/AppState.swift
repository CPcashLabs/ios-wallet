import BackendAPI
import CoreRuntime
import Foundation
import LocalAuthentication
import SecurityCore

enum LoginErrorKind: String {
    case rejectSign = "reject_sign"
    case authFailed = "auth_failed"
    case networkFailed = "network_failed"
}

enum ToastTheme {
    case success
    case error
    case info
}

struct ToastState: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let theme: ToastTheme
    let duration: TimeInterval

    init(message: String, theme: ToastTheme, duration: TimeInterval = 2) {
        self.message = message
        self.theme = theme
        self.duration = duration
    }
}

enum RootScreen {
    case login
    case home
}

enum ApprovalSessionState: Equatable {
    case locked
    case unlocked(lastVerifiedAt: Date)
}

enum ReceiveTabMode: String {
    case individuals = "individuals"
    case business = "business"
}

private enum ReceiveFlowError: Error {
    case traceOrderCreationFailed
}

enum ReceiveNetworkCategory: String, Equatable {
    case appChannel
    case proxySettlement
}

struct ReceiveNetworkItem: Identifiable, Equatable {
    let id: String
    let name: String
    let logoURL: String?
    let chainColor: String
    let category: ReceiveNetworkCategory
    let allowChain: ReceiveAllowChainItem?
    let isNormalChannel: Bool

    init(
        id: String,
        name: String,
        logoURL: String?,
        chainColor: String,
        category: ReceiveNetworkCategory,
        allowChain: ReceiveAllowChainItem?,
        isNormalChannel: Bool
    ) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.chainColor = chainColor
        self.category = category
        self.allowChain = allowChain
        self.isNormalChannel = isNormalChannel
    }
}

struct ReceiveDomainState: Equatable {
    var activeTab: ReceiveTabMode = .individuals
    var individualOrderSN: String?
    var businessOrderSN: String?
    var receiveMinAmount: Double = 10
    var receiveMaxAmount: Double = 0
    var validityStatus: ReceiveAddressValidityState = .valid
    var isPolling = false
    var selectedPayChain: String = "BTT_TEST"
    var selectedChainColor: String = "#1677FF"
    var selectedSendCoinCode: String = "USDT_BTT"
    var selectedRecvCoinCode: String = "USDT_BTT"
    var selectedSendCoinName: String = "USDT"
    var selectedRecvCoinName: String = "USDT"
    var selectedPairLabel: String = "USDT/USDT"
    var availablePairs: [AllowExchangePair] = []
    var selectedSellerId: Int?
    var selectedNetworkName: String = "CPcash"
    var selectedIsNormalChannel = false
}

enum TransferNetworkCategory: String, Equatable {
    case appChannel
    case proxySettlement
}

struct TransferNetworkItem: Identifiable, Equatable {
    let id: String
    let name: String
    let logoURL: String?
    let chainColor: String
    let category: TransferNetworkCategory
    let allowChain: ReceiveAllowChainItem?
    let normalChain: NormalAllowChainItem?
    let isNormalChannel: Bool
    let balance: Double?

    var isAvailable: Bool {
        guard let balance else { return true }
        return balance > 0
    }

    init(
        id: String,
        name: String,
        logoURL: String?,
        chainColor: String,
        category: TransferNetworkCategory,
        allowChain: ReceiveAllowChainItem?,
        normalChain: NormalAllowChainItem?,
        isNormalChannel: Bool,
        balance: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.logoURL = logoURL
        self.chainColor = chainColor
        self.category = category
        self.allowChain = allowChain
        self.normalChain = normalChain
        self.isNormalChannel = isNormalChannel
        self.balance = balance
    }
}

enum TransferPayMode: Equatable {
    case normal
    case proxy
}

struct TransferDraft: Equatable {
    var mode: TransferPayMode = .normal
    var recipientAddress: String = ""
    var amountText: String = ""
    var note: String = ""
    var orderSN: String?
    var orderDetail: OrderDetail?
}

struct TransferDomainState: Equatable {
    var selectedNetworkName: String = "CPcash"
    var selectedPayChain: String = "BTT_TEST"
    var selectedChainColor: String = "#1677FF"
    var selectedIsNormalChannel = false
    var selectedSendCoinCode: String = "USDT_BTT_TEST"
    var selectedRecvCoinCode: String = "USDT_BTT_TEST"
    var selectedSendCoinName: String = "USDT"
    var selectedRecvCoinName: String = "USDT"
    var selectedPairLabel: String = "USDT/USDT"
    var selectedCoinContract: String?
    var selectedCoinPrecision: Int = 6
    var selectedCoinSymbol: String = "USDT"
    var selectedAddressRegex: [String] = []
    var availablePairs: [AllowExchangePair] = []
    var availableNormalCoins: [NormalAllowCoin] = []
    var selectedSellerId: Int?
}

@MainActor
final class AppState: ObservableObject {
    @Published var environment: EnvironmentConfig
    @Published var activeAddress: String = "-"
    @Published var userProfile: UserProfile?
    @Published var coins: [CoinItem] = []
    @Published var recentTransfers: [TransferItem] = []
    @Published var transferRecentContacts: [TransferReceiveContact] = []
    @Published var homeRecentMessages: [MessageItem] = []
    @Published var receives: [ReceiveRecord] = []
    @Published var orders: [OrderSummary] = []
    @Published var selectedOrderDetail: OrderDetail?
    @Published var lastCreatedReceiveOrderSN: String = "-"
    @Published var lastCreatedPaymentOrderSN: String = "-"
    @Published var lastTxHash: String = "-"
    @Published var meProfile: UserProfile?
    @Published var messageList: [MessageItem] = []
    @Published var messagePage: Int = 1
    @Published var messageLastPage = false
    @Published var addressBooks: [AddressBookItem] = []
    @Published var billList: [OrderSummary] = []
    @Published var billFilter = BillFilter()
    @Published var billAddressFilter: String?
    @Published var billStats: BillStatisticsSummary?
    @Published var billAddressAggList: [BillAddressAggregateItem] = []
    @Published var billCurrentPage: Int = 1
    @Published var billTotal: Int = 0
    @Published var billLastPage = false
    @Published var exchangeRates: [ExchangeRateItem] = []
    @Published var selectedCurrency = "USD"
    @Published var uiLoadingMap: [String: Bool] = [:]
    @Published var uiErrorMap: [String: String] = [:]
    @Published var transferEmailNotify = false
    @Published var rewardEmailNotify = false
    @Published var receiptEmailNotify = false
    @Published var backupWalletNotify = false
    @Published var logs: [String] = []
    @Published var passkeyAccounts: [LocalPasskeyAccount] = []
    @Published var selectedPasskeyRawId: String = ""

    @Published var isAuthenticated = false
    @Published var loginBusy = false
    @Published var loginCooldownUntil: Date?
    @Published var loginErrorKind: LoginErrorKind?
    @Published var toast: ToastState?

    @Published var selectedChainId: Int = 1029
    @Published var selectedChainName: String = "BTT_TEST"
    @Published var networkOptions: [NetworkOption] = []
    @Published var approvalSessionState: ApprovalSessionState = .locked

    @Published var receiveDomainState = ReceiveDomainState()
    @Published var receiveSelectNetworks: [ReceiveNetworkItem] = []
    @Published var receiveNormalNetworks: [ReceiveNetworkItem] = []
    @Published var receiveProxyNetworks: [ReceiveNetworkItem] = []
    @Published var receiveSelectedNetworkId: String?
    @Published var individualTraceOrder: TraceOrderItem?
    @Published var businessTraceOrder: TraceOrderItem?
    @Published var receiveRecentValid: [TraceOrderItem] = []
    @Published var receiveRecentInvalid: [TraceOrderItem] = []
    @Published var receiveTraceChildren: [TraceChildItem] = []
    @Published var individualTraceDetail: TraceShowDetail?
    @Published var businessTraceDetail: TraceShowDetail?
    @Published var receiveShareDetail: ReceiveOrderDetail?
    @Published var receiveExpiryConfig = ReceiveExpiryConfig(durations: [24, 72, 168], selectedDuration: 72)
    @Published var transferDomainState = TransferDomainState()
    @Published var transferSelectNetworks: [TransferNetworkItem] = []
    @Published var transferNormalNetworks: [TransferNetworkItem] = []
    @Published var transferProxyNetworks: [TransferNetworkItem] = []
    @Published var transferSelectedNetworkId: String?
    @Published var transferDraft = TransferDraft()

    var rootScreen: RootScreen {
        isAuthenticated ? .home : .login
    }

    private var toastDismissTask: Task<Void, Never>?
    let securityService: SecurityServing
    let backendFactory: (EnvironmentConfig) -> BackendServing
    var backend: BackendServing
    private static let logTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    private static let evmAddressRegex = try! NSRegularExpression(pattern: "0x[a-fA-F0-9]{40}")
    private static let txHashRegex = try! NSRegularExpression(pattern: "0x[a-fA-F0-9]{64}")
    let passkeyService: PasskeyServing
    let clock: AppClock
    let idGenerator: AppIDGenerator
    let appLogger: AppLogger
    let selectedChainStorageKey = "cpcash.selected.chain.id"
    private lazy var sessionUseCase = SessionUseCase(appState: self)
    private lazy var meUseCase = MeUseCase(appState: self)
    private lazy var billUseCase = BillUseCase(appState: self)
    private lazy var transferUseCase = TransferUseCase(appState: self)
    private lazy var receiveUseCase = ReceiveUseCase(appState: self)
    var messageRequestGeneration = 0
    var billRequestGeneration = 0
    var networkSelectionGeneration = 0
    var activeOrderDetailRequestSN: String?
    let messagePaginationGate = PaginationGate()
    let billPaginationGate = PaginationGate()

    init(dependencies: AppDependencies) {
        let env = EnvironmentConfig.default
        environment = env
        securityService = dependencies.securityService
        backendFactory = dependencies.backendFactory
        backend = dependencies.backendFactory(env)
        passkeyService = dependencies.passkeyService
        clock = dependencies.clock
        idGenerator = dependencies.idGenerator
        appLogger = dependencies.logger
    }

    convenience init() {
        self.init(dependencies: .live())
    }

    deinit {
        toastDismissTask?.cancel()
    }

    func boot() {
        sessionUseCase.boot()
    }

    func refreshPasskeyAccounts() {
        sessionUseCase.refreshPasskeyAccounts()
    }

    func registerPasskey(displayName: String) async {
        await sessionUseCase.registerPasskey(displayName: displayName)
    }

    func loginWithPasskey(rawId: String?) async {
        await sessionUseCase.loginWithPasskey(rawId: rawId)
    }

    func refreshHomeData() async {
        do {
            async let profileTask = backend.auth.currentUser()
            async let coinTask = backend.wallet.coinList(chainName: selectedChainName)
            async let transferTask = backend.wallet.recentTransferList()
            async let homeMessagesTask = backend.message.list(page: 1, perPage: 10)
            async let receiveTask = backend.receive.recentValidReceives(page: 1, perPage: 20)
            async let orderTask = backend.order.list(page: 1, perPage: 20, address: nil)

            userProfile = try await profileTask
            coins = try await coinTask
            recentTransfers = try await transferTask
            let homeMessageResponse = try await homeMessagesTask
            homeRecentMessages = Array(homeMessageResponse.data.prefix(3))
            receives = try await receiveTask
            orders = try await orderTask.data
            log("基础数据刷新完成: coin=\(coins.count), transfer=\(recentTransfers.count), message=\(homeRecentMessages.count), receive=\(receives.count), order=\(orders.count)")
        } catch {
            log("刷新数据失败: \(error)")
        }
    }

    func loadMeRootData() async {
        await meUseCase.loadMeRootData()
    }

    func loadMessages(page: Int, append: Bool) async {
        await meUseCase.loadMessages(page: page, append: append)
    }

    func markMessageRead(id: String) async {
        await meUseCase.markMessageRead(id: id)
    }

    func markAllMessagesRead() async {
        await meUseCase.markAllMessagesRead()
    }

    func loadAddressBooks() async {
        await meUseCase.loadAddressBooks()
    }

    func createAddressBook(name: String, walletAddress: String, chainType: String = "EVM") async -> Bool {
        await meUseCase.createAddressBook(name: name, walletAddress: walletAddress, chainType: chainType)
    }

    func updateAddressBook(id: String, name: String, walletAddress: String, chainType: String = "EVM") async -> Bool {
        await meUseCase.updateAddressBook(id: id, name: name, walletAddress: walletAddress, chainType: chainType)
    }

    func deleteAddressBook(id: String) async {
        await meUseCase.deleteAddressBook(id: id)
    }

    func loadBillList(filter: BillFilter, append: Bool = false) async {
        await billUseCase.loadBillList(filter: filter, append: append)
    }

    func loadBillListImpl(filter: BillFilter, append: Bool = false) async {
        let requestedPage = max(filter.page, 1)
        let pageToken = "bill.page.\(requestedPage)"
        if append {
            guard billPaginationGate.begin(token: pageToken) else { return }
        } else {
            billPaginationGate.reset()
            billRequestGeneration += 1
        }
        let generation = billRequestGeneration
        guard !isLoading(LoadKey.meBillList) else {
            if append {
                billPaginationGate.end(token: pageToken)
            }
            return
        }
        setLoading(LoadKey.meBillList, true)
        defer {
            setLoading(LoadKey.meBillList, false)
            if append {
                billPaginationGate.end(token: pageToken)
            }
        }
        do {
            let response = try await backend.bill.list(filter: filter)
            guard generation == billRequestGeneration else { return }
            billFilter = filter
            billAddressFilter = filter.otherAddress
            if append {
                billList = mergeOrders(current: billList, incoming: response.data)
            } else {
                billList = response.data
            }
            billCurrentPage = response.page ?? requestedPage
            billTotal = response.total ?? billList.count
            billLastPage = computeLastPage(page: response.page, perPage: response.perPage, total: response.total)
            clearError(LoadKey.meBillList)
            log("账单列表加载成功: \(billList.count)")
        } catch {
            guard generation == billRequestGeneration else { return }
            setError(LoadKey.meBillList, error)
            log("账单列表加载失败: \(error)")
        }
    }

    func setBillAddressFilter(_ address: String?) {
        billUseCase.setBillAddressFilter(address)
    }

    func setBillAddressFilterImpl(_ address: String?) {
        let normalized = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalized, !normalized.isEmpty {
            billAddressFilter = normalized
        } else {
            billAddressFilter = nil
        }
    }

    func loadBillStatistics(range: BillTimeRange) async {
        await billUseCase.loadBillStatistics(range: range)
    }

    func loadBillStatisticsImpl(range: BillTimeRange) async {
        setLoading(LoadKey.meBillStat, true)
        defer { setLoading(LoadKey.meBillStat, false) }
        do {
            billStats = try await backend.bill.statAllAddressStat(range: range)
            clearError(LoadKey.meBillStat)
        } catch {
            setError(LoadKey.meBillStat, error)
            log("账单统计加载失败: \(error)")
        }
    }

    func loadBillAddressAggregate(range: BillTimeRange, page: Int = 1, perPage: Int = 50) async {
        await billUseCase.loadBillAddressAggregate(range: range, page: page, perPage: perPage)
    }

    func loadBillAddressAggregateImpl(range: BillTimeRange, page: Int = 1, perPage: Int = 50) async {
        setLoading(LoadKey.meBillAggregate, true)
        defer { setLoading(LoadKey.meBillAggregate, false) }
        do {
            let response = try await backend.bill.statAllAddressPage(range: range, page: page, perPage: perPage)
            billAddressAggList = response.data
            clearError(LoadKey.meBillAggregate)
            log("账单地址聚合加载成功: \(billAddressAggList.count)")
        } catch {
            setError(LoadKey.meBillAggregate, error)
            log("账单地址聚合加载失败: \(error)")
        }
    }

    func updateNickname(_ nickname: String) async {
        await meUseCase.updateNickname(nickname)
    }

    func updateAvatar(fileData: Data, fileName: String = "avatar.jpg", mimeType: String = "image/jpeg") async {
        await meUseCase.updateAvatar(fileData: fileData, fileName: fileName, mimeType: mimeType)
    }

    func loadExchangeRates() async {
        await meUseCase.loadExchangeRates()
    }

    func saveCurrencyUnit(currency: String) {
        meUseCase.saveCurrencyUnit(currency: currency)
    }

    func setTransferEmailNotify(_ enable: Bool) async {
        await meUseCase.setTransferEmailNotify(enable)
    }

    func setRewardEmailNotify(_ enable: Bool) async {
        await meUseCase.setRewardEmailNotify(enable)
    }

    func setReceiptEmailNotify(_ enable: Bool) async {
        await meUseCase.setReceiptEmailNotify(enable)
    }

    func setBackupWalletNotify(_ enable: Bool) async {
        await meUseCase.setBackupWalletNotify(enable)
    }

    func refreshNetworkOptions() async {
        do {
            let options = try await backend.wallet.networkOptions()
            networkOptions = options.sorted(by: { $0.chainId < $1.chainId })
            if let selected = networkOptions.first(where: { $0.chainId == selectedChainId }) {
                selectedChainName = selected.chainName
            } else if let fallback = networkOptions.first {
                applyNetworkOption(fallback)
            }
        } catch {
            networkOptions = fallbackNetworkOptions()
            if let selected = networkOptions.first(where: { $0.chainId == selectedChainId }) {
                selectedChainName = selected.chainName
            }
            log("网络列表加载失败，使用默认配置: \(error)")
        }
    }

    func selectNetwork(chainId: Int) {
        if let option = networkOptions.first(where: { $0.chainId == chainId }) {
            networkSelectionGeneration += 1
            let generation = networkSelectionGeneration
            applyNetworkOption(option)
            Task { [weak self] in
                guard let self else { return }
                await self.loadReceiveSelectNetwork()
                guard generation == self.networkSelectionGeneration else { return }
                await self.loadTransferSelectNetwork()
            }
        }
    }

    func loadTransferSelectNetwork() async {
        await transferUseCase.loadTransferSelectNetwork()
    }

    func selectTransferNetwork(item: TransferNetworkItem) async {
        await transferUseCase.selectTransferNetwork(item: item)
    }

    func selectTransferPair(sendCoinCode: String, recvCoinCode: String) {
        transferUseCase.selectTransferPair(sendCoinCode: sendCoinCode, recvCoinCode: recvCoinCode)
    }

    func selectTransferNormalCoin(coinCode: String) async {
        await transferUseCase.selectTransferNormalCoin(coinCode: coinCode)
    }

    func updateTransferRecipientAddress(_ address: String) {
        transferUseCase.updateTransferRecipientAddress(address)
    }

    func resetTransferFlow() {
        transferUseCase.resetTransferFlow()
    }

    func transferAddressValidationMessage(_ address: String) -> String? {
        transferUseCase.transferAddressValidationMessage(address)
    }

    func isValidTransferAddress(_ address: String) -> Bool {
        transferUseCase.isValidTransferAddress(address)
    }

    func transferAddressBookCandidates() -> [AddressBookItem] {
        transferUseCase.transferAddressBookCandidates()
    }

    func detectAddressChainType(_ address: String) -> String? {
        transferUseCase.detectAddressChainType(address)
    }

    func loadTransferAddressCandidates() async {
        await transferUseCase.loadTransferAddressCandidates()
    }

    func prepareTransferPayment(amountText: String, note: String) async -> Bool {
        await transferUseCase.prepareTransferPayment(amountText: amountText, note: note)
    }

    func executeTransferPayment() async -> Bool {
        await transferUseCase.executeTransferPayment()
    }

    func loadReceiveSelectNetwork() async {
        await receiveUseCase.loadReceiveSelectNetwork()
    }

    func loadReceiveSelectNetworkImpl() async {
        let requestedChainId = selectedChainId
        let requestedGeneration = networkSelectionGeneration
        setLoading(LoadKey.receiveSelectNetwork, true)
        defer { setLoading(LoadKey.receiveSelectNetwork, false) }

        do {
            let query = AllowListQuery(
                groupByType: 0,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                recvChainName: selectedChainName,
                env: backendEnvValue()
            )

            async let cpListTask = backend.receive.cpCashAllowList(query: query)
            async let normalListTask = backend.receive.normalAllowList(
                chainName: nil,
                coinCode: nil,
                isSendAllowed: true,
                isRecvAllowed: true,
                coinSymbol: nil
            )

            let cpList = try await cpListTask
            let normalList = try await normalListTask

            let preferredNormalChainName = selectedChainId == 199 ? "BTT" : "BTT_TEST"
            let normalEntry = normalList.first {
                ($0.chainName ?? "").uppercased() == preferredNormalChainName
            } ?? normalList.first

            var normalNetworks: [ReceiveNetworkItem] = []
            if let normalEntry {
                normalNetworks = [
                    ReceiveNetworkItem(
                        id: "normal:\(normalEntry.chainName ?? "CPcash")",
                        name: "CPcash",
                        logoURL: normalEntry.chainLogo,
                        chainColor: normalEntry.chainColor ?? "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        isNormalChannel: true
                    ),
                ]
            } else {
                normalNetworks = [
                    ReceiveNetworkItem(
                        id: "normal:CPcash",
                        name: "CPcash",
                        logoURL: nil,
                        chainColor: "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        isNormalChannel: true
                    ),
                ]
            }

            let proxyNetworks = cpList.map { item in
                ReceiveNetworkItem(
                    id: "proxy:\(item.chainName ?? idGenerator.makeID())",
                    name: item.chainName ?? "-",
                    logoURL: item.chainLogo,
                    chainColor: item.chainColor ?? "#1677FF",
                    category: .proxySettlement,
                    allowChain: item,
                    isNormalChannel: false
                )
            }

            guard requestedGeneration == networkSelectionGeneration, requestedChainId == selectedChainId else {
                return
            }
            receiveNormalNetworks = normalNetworks
            receiveProxyNetworks = proxyNetworks
            receiveSelectNetworks = normalNetworks + proxyNetworks

            if let selectedId = receiveSelectedNetworkId,
               !receiveSelectNetworks.contains(where: { $0.id == selectedId })
            {
                receiveSelectedNetworkId = nil
            }
            if receiveSelectedNetworkId == nil, let first = receiveSelectNetworks.first {
                configureReceiveNetwork(first)
            }
            clearError(LoadKey.receiveSelectNetwork)
        } catch {
            guard requestedGeneration == networkSelectionGeneration, requestedChainId == selectedChainId else {
                return
            }
            setError(LoadKey.receiveSelectNetwork, error)
            receiveNormalNetworks = [
                ReceiveNetworkItem(
                    id: "normal:CPcash",
                    name: "CPcash",
                    logoURL: nil,
                    chainColor: "#1677FF",
                    category: .appChannel,
                    allowChain: nil,
                    isNormalChannel: true
                ),
            ]
            receiveProxyNetworks = []
            receiveSelectNetworks = receiveNormalNetworks
            if let first = receiveSelectNetworks.first {
                configureReceiveNetwork(first)
            }
            log("收款网络加载失败: \(error)")
        }
    }

    func selectReceiveNetwork(item: ReceiveNetworkItem, preloadHome: Bool = true) async {
        configureReceiveNetwork(item)
        if !item.isNormalChannel {
            if preloadHome {
                await refreshReceivePairOptions(for: item)
            } else {
                Task { [weak self] in
                    guard let self else { return }
                    await self.refreshReceivePairOptions(for: item)
                }
            }
        }
        if preloadHome {
            await loadReceiveHome(autoCreateIfMissing: true)
        }
    }

    func selectReceivePair(sendCoinCode: String, recvCoinCode: String) async {
        guard let pair = receiveDomainState.availablePairs.first(where: {
            $0.sendCoinCode == sendCoinCode && $0.recvCoinCode == recvCoinCode
        }) else {
            return
        }
        applyReceivePair(pair)
        receiveDomainState.individualOrderSN = nil
        receiveDomainState.businessOrderSN = nil
        individualTraceOrder = nil
        businessTraceOrder = nil
        individualTraceDetail = nil
        businessTraceDetail = nil
        await loadReceiveHome(autoCreateIfMissing: true)
    }

    func setReceiveActiveTab(_ tab: ReceiveTabMode) {
        receiveDomainState.activeTab = tab
    }

    func loadReceiveHome(autoCreateIfMissing: Bool = true) async {
        await receiveUseCase.loadReceiveHome(autoCreateIfMissing: autoCreateIfMissing)
    }

    func loadReceiveHomeImpl(autoCreateIfMissing: Bool = true) async {
        setLoading(LoadKey.receiveHome, true)
        defer { setLoading(LoadKey.receiveHome, false) }

        if receiveDomainState.selectedIsNormalChannel {
            individualTraceOrder = nil
            businessTraceOrder = nil
            individualTraceDetail = nil
            businessTraceDetail = nil
            receiveDomainState.individualOrderSN = nil
            receiveDomainState.businessOrderSN = nil
            receiveDomainState.receiveMinAmount = 0
            receiveDomainState.receiveMaxAmount = 0
            clearError(LoadKey.receiveHome)
            return
        }

        do {
            let exchange = try await backend.receive.exchangeShow(
                sendCoinCode: receiveDomainState.selectedSendCoinCode,
                recvCoinCode: receiveDomainState.selectedRecvCoinCode,
                rateType: 1,
                env: backendEnvValue()
            )

            receiveDomainState.receiveMinAmount = exchange.recvMinAmount ?? exchange.sendMinAmount ?? 10
            receiveDomainState.receiveMaxAmount = exchange.recvMaxAmount ?? 0
            receiveDomainState.selectedSellerId = exchange.sellerId
            receiveDomainState.selectedSendCoinName = exchange.sendCoinName ?? receiveDomainState.selectedSendCoinName
            receiveDomainState.selectedRecvCoinName = exchange.recvCoinName ?? receiveDomainState.selectedRecvCoinName

            async let individualTask = backend.receive.recentValidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE",
                sendCoinCode: receiveDomainState.selectedSendCoinCode,
                recvCoinCode: receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )
            async let businessTask = backend.receive.recentValidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE_LONG_TERM",
                sendCoinCode: receiveDomainState.selectedSendCoinCode,
                recvCoinCode: receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )
            async let invalidTask = backend.receive.recentInvalidTraces(
                page: 1,
                perPage: 20,
                orderType: "TRACE",
                sendCoinCode: receiveDomainState.selectedSendCoinCode,
                recvCoinCode: receiveDomainState.selectedRecvCoinCode,
                multisigWalletId: nil
            )

            let individualList = try await individualTask
            let businessList = try await businessTask
            let invalidList = try await invalidTask

            receiveRecentValid = individualList + businessList
            receiveRecentInvalid = invalidList

            individualTraceOrder = resolvePreferredOrder(from: individualList)
            businessTraceOrder = resolvePreferredOrder(from: businessList)
            receiveDomainState.individualOrderSN = individualTraceOrder?.orderSn
            receiveDomainState.businessOrderSN = businessTraceOrder?.orderSn
            if receiveDomainState.individualOrderSN == nil {
                individualTraceDetail = nil
            }
            if receiveDomainState.businessOrderSN == nil {
                businessTraceDetail = nil
            }

            if receiveDomainState.individualOrderSN == nil, autoCreateIfMissing {
                await createTraceOrder(isLongTerm: false, note: "", silent: true)
            } else if let orderSN = receiveDomainState.activeTab == .individuals ? receiveDomainState.individualOrderSN : receiveDomainState.businessOrderSN {
                await refreshTraceShow(orderSN: orderSN)
            }
            clearError(LoadKey.receiveHome)
        } catch {
            setError(LoadKey.receiveHome, error)
            log("收款主页加载失败: \(error)")
        }
    }

    func createShortTraceOrder(note: String = "") async {
        await createTraceOrder(isLongTerm: false, note: note)
    }

    func createLongTraceOrder(note: String = "") async {
        await createTraceOrder(isLongTerm: true, note: note)
    }

    func refreshTraceShow(orderSN: String) async {
        do {
            let detail = try await backend.receive.traceShow(orderSN: orderSN)
            let minAmount = detail.recvMinAmount?.doubleValue ?? detail.recvAmount?.doubleValue ?? 10
            let maxAmount = detail.recvMaxAmount?.doubleValue ?? 0
            receiveDomainState.receiveMinAmount = minAmount
            receiveDomainState.receiveMaxAmount = maxAmount
            if receiveDomainState.individualOrderSN == orderSN {
                individualTraceDetail = detail
            }
            if receiveDomainState.businessOrderSN == orderSN {
                businessTraceDetail = detail
            }
            if receiveDomainState.activeTab == .individuals,
               receiveDomainState.individualOrderSN == nil
            {
                individualTraceDetail = detail
            }
            if receiveDomainState.activeTab == .business,
               receiveDomainState.businessOrderSN == nil
            {
                businessTraceDetail = detail
            }
            clearError(LoadKey.receiveDetail)
        } catch {
            setError(LoadKey.receiveDetail, error)
            log("收款详情刷新失败: \(error)")
        }
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        await receiveUseCase.loadReceiveAddresses(validity: validity)
    }

    func loadReceiveAddressesImpl(validity: ReceiveAddressValidityState) async {
        receiveDomainState.validityStatus = validity
        switch validity {
        case .valid:
            await loadReceiveHome()
        case .invalid:
            setLoading(LoadKey.receiveInvalid, true)
            defer { setLoading(LoadKey.receiveInvalid, false) }
            do {
                let invalidOrderType = receiveDomainState.activeTab == .business ? "TRACE_LONG_TERM" : "TRACE"
                receiveRecentInvalid = try await backend.receive.recentInvalidTraces(
                    page: 1,
                    perPage: 50,
                    orderType: invalidOrderType,
                    sendCoinCode: receiveDomainState.selectedSendCoinCode,
                    recvCoinCode: receiveDomainState.selectedRecvCoinCode,
                    multisigWalletId: nil
                )
                clearError(LoadKey.receiveInvalid)
            } catch {
                setError(LoadKey.receiveInvalid, error)
                log("失效地址加载失败: \(error)")
            }
        }
    }

    func markTraceOrder(
        orderSN: String,
        sendCoinCode: String? = nil,
        recvCoinCode: String? = nil,
        orderType: String? = nil
    ) async {
        do {
            let resolvedSendCoinCode = sendCoinCode ?? receiveDomainState.selectedSendCoinCode
            let resolvedRecvCoinCode = recvCoinCode ?? receiveDomainState.selectedRecvCoinCode
            let resolvedOrderType: String
            if let orderType, !orderType.isEmpty {
                resolvedOrderType = orderType
            } else {
                resolvedOrderType = receiveDomainState.activeTab == .business ? "TRACE_LONG_TERM" : "TRACE"
            }
            try await backend.receive.markTraceOrder(
                orderSN: orderSN,
                sendCoinCode: resolvedSendCoinCode,
                recvCoinCode: resolvedRecvCoinCode,
                orderType: resolvedOrderType
            )
            showToast("已更新默认收款地址", theme: .success)
            await loadReceiveHome()
            clearError(LoadKey.receiveMark)
        } catch {
            setError(LoadKey.receiveMark, error)
            showToast("更新默认地址失败", theme: .error)
            log("更新默认收款地址失败: \(error)")
        }
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        await receiveUseCase.loadReceiveTraceChildren(orderSN: orderSN, page: page, perPage: perPage)
    }

    func loadReceiveTraceChildrenImpl(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        setLoading(LoadKey.receiveChildren, true)
        defer { setLoading(LoadKey.receiveChildren, false) }
        do {
            let pageData = try await backend.receive.traceChildren(orderSN: orderSN, page: page, perPage: perPage)
            receiveTraceChildren = pageData.data
            clearError(LoadKey.receiveChildren)
        } catch {
            setError(LoadKey.receiveChildren, error)
            log("收款记录加载失败: \(error)")
        }
    }

    func loadReceiveShare(orderSN: String) async {
        await receiveUseCase.loadReceiveShare(orderSN: orderSN)
    }

    func loadReceiveShareImpl(orderSN: String) async {
        setLoading(LoadKey.receiveShare, true)
        defer { setLoading(LoadKey.receiveShare, false) }
        do {
            receiveShareDetail = try await backend.receive.receiveShare(orderSN: orderSN)
            clearError(LoadKey.receiveShare)
        } catch {
            setError(LoadKey.receiveShare, error)
            log("收款分享数据加载失败: \(error)")
        }
    }

    func loadReceiveExpiryConfig() async {
        await receiveUseCase.loadReceiveExpiryConfig()
    }

    func loadReceiveExpiryConfigImpl() async {
        do {
            let config = try await backend.settings.traceExpiryCollection()
            if !config.durations.isEmpty {
                receiveExpiryConfig = config
            }
            clearError(LoadKey.receiveExpiry)
        } catch {
            setError(LoadKey.receiveExpiry, error)
            log("收款地址有效期配置加载失败: \(error)")
        }
    }

    func updateReceiveExpiry(duration: Int) async {
        await receiveUseCase.updateReceiveExpiry(duration: duration)
    }

    func updateReceiveExpiryImpl(duration: Int) async {
        do {
            try await backend.settings.updateTraceExpiryMark(duration: duration)
            receiveExpiryConfig = ReceiveExpiryConfig(
                durations: receiveExpiryConfig.durations,
                selectedDuration: duration
            )
            showToast("有效期已更新", theme: .success)
            clearError(LoadKey.receiveExpiryUpdate)
        } catch {
            setError(LoadKey.receiveExpiryUpdate, error)
            showToast("有效期更新失败", theme: .error)
            log("收款地址有效期更新失败: \(error)")
        }
    }

    func refreshOrdersOnly() async {
        do {
            let response = try await backend.order.list(page: 1, perPage: 20, address: nil)
            orders = response.data
            log("订单列表刷新成功: \(response.data.count)")
        } catch {
            log("订单列表刷新失败: \(error)")
        }
    }

    func loadOrderDetail(orderSN: String) async {
        activeOrderDetailRequestSN = orderSN
        selectedOrderDetail = nil
        do {
            let detail = try await backend.order.detail(orderSN: orderSN)
            guard activeOrderDetailRequestSN == orderSN else { return }
            selectedOrderDetail = detail
            log("订单详情加载成功: \(detail.orderSn ?? orderSN)")
        } catch {
            guard activeOrderDetailRequestSN == orderSN else { return }
            selectedOrderDetail = nil
            log("订单详情加载失败: \(error)")
        }
    }

    func signOutToLogin() {
        sessionUseCase.signOutToLogin()
    }

    func showInfoToast(_ message: String) {
        showToast(message, theme: .info)
    }

    #if DEBUG
    func cycleEnvironmentForDebug() {
        sessionUseCase.cycleEnvironmentForDebug()
    }
    #endif

    func showToast(_ message: String, theme: ToastTheme, duration: TimeInterval = 2) {
        let current = ToastState(message: message, theme: theme, duration: duration)
        toast = current

        toastDismissTask?.cancel()
        toastDismissTask = Task { [weak self] in
            let nanoseconds = UInt64(duration * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else { return }
            guard let self else { return }
            if self.toast?.id == current.id {
                self.toast = nil
            }
        }
    }

    func billRangeForPreset(_ preset: BillPresetRange, selectedMonth: Date = Date()) -> BillTimeRange {
        billUseCase.billRangeForPreset(preset, selectedMonth: selectedMonth)
    }

    func billRangeForPresetImpl(_ preset: BillPresetRange, selectedMonth: Date = Date()) -> BillTimeRange {
        let calendar = Calendar(identifier: .gregorian)
        let now = clock.now
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let start: Date
        let end: Date
        switch preset {
        case .today:
            start = calendar.startOfDay(for: now)
            end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? now
        case .yesterday:
            let todayStart = calendar.startOfDay(for: now)
            start = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? now
            end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: start) ?? now
        case .last7Days:
            let todayStart = calendar.startOfDay(for: now)
            start = calendar.date(byAdding: .day, value: -7, to: todayStart) ?? now
            end = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: todayStart) ?? now
        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: selectedMonth)
            start = calendar.date(from: components).map { calendar.startOfDay(for: $0) } ?? now
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: start) ?? now
            end = monthEnd
        }

        return BillTimeRange(
            startedAt: formatter.string(from: start),
            endedAt: formatter.string(from: end),
            startedTimestamp: Int64(start.timeIntervalSince1970 * 1000),
            endedTimestamp: Int64(end.timeIntervalSince1970 * 1000),
            preset: preset
        )
    }

    func isLoading(_ key: String) -> Bool {
        uiLoadingMap[key] ?? false
    }

    func isLoading(_ key: LoadKey) -> Bool {
        isLoading(key.rawValue)
    }

    func errorMessage(_ key: String) -> String? {
        uiErrorMap[key]
    }

    func errorMessage(_ key: LoadKey) -> String? {
        errorMessage(key.rawValue)
    }

    func mergeMessages(current: [MessageItem], incoming: [MessageItem]) -> [MessageItem] {
        var merged = current
        var seen = Set(current.map(messageUniqueKey))
        for item in incoming {
            let key = messageUniqueKey(item)
            if seen.insert(key).inserted {
                merged.append(item)
            }
        }
        return merged
    }

    func mergeOrders(current: [OrderSummary], incoming: [OrderSummary]) -> [OrderSummary] {
        var merged = current
        var seen = Set(current.map(orderUniqueKey))
        for item in incoming {
            let key = orderUniqueKey(item)
            if seen.insert(key).inserted {
                merged.append(item)
            }
        }
        return merged
    }

    private func messageUniqueKey(_ item: MessageItem) -> String {
        if let id = item.id {
            return "id:\(id)"
        }
        return [
            item.createdAt.map(String.init) ?? "-",
            item.type ?? "-",
            item.orderSn ?? "-",
            item.title ?? "-",
            item.content ?? "-",
        ].joined(separator: "|")
    }

    private func orderUniqueKey(_ item: OrderSummary) -> String {
        if let orderSN = item.orderSn, !orderSN.isEmpty {
            return "order:\(orderSN)"
        }
        return [
            item.createdAt.map(String.init) ?? "-",
            item.orderType ?? "-",
            item.paymentAddress ?? "-",
            item.receiveAddress ?? "-",
            item.sendAmount?.description ?? "-",
            item.recvAmount?.description ?? "-",
        ].joined(separator: "|")
    }

    func computeLastPage(page: Int?, perPage: Int?, total: Int?) -> Bool {
        guard let page, let perPage, let total, perPage > 0 else {
            return false
        }
        return page * perPage >= total
    }

    func setLoading(_ key: String, _ loading: Bool) {
        uiLoadingMap[key] = loading
    }

    func setLoading(_ key: LoadKey, _ loading: Bool) {
        setLoading(key.rawValue, loading)
    }

    func setError(_ key: String, _ error: Error) {
        uiErrorMap[key] = simplifyError(error)
    }

    func setError(_ key: LoadKey, _ error: Error) {
        setError(key.rawValue, error)
    }

    func clearError(_ key: String) {
        uiErrorMap[key] = nil
    }

    func clearError(_ key: LoadKey) {
        clearError(key.rawValue)
    }

    func simplifyError(_ error: Error) -> String {
        AppErrorMapper.message(for: error)
    }

    private func fallbackNetworkOptions() -> [NetworkOption] {
        [
            NetworkOption(chainId: 199, chainName: "BTT", chainFullName: "BitTorrent Chain Mainnet", rpcURL: "https://rpc.bt.io/"),
            NetworkOption(chainId: 1029, chainName: "BTT_TEST", chainFullName: "BitTorrent Chain Testnet", rpcURL: "https://pre-rpc.bt.io/"),
        ]
    }

    func restoreSelectedChain() {
        let storedChainId = UserDefaults.standard.integer(forKey: selectedChainStorageKey)
        if storedChainId == 199 || storedChainId == 1029 {
            selectedChainId = storedChainId
        } else {
            selectedChainId = 1029
        }
        let selected = fallbackNetworkOptions().first(where: { $0.chainId == selectedChainId })
        selectedChainName = selected?.chainName ?? "BTT_TEST"
        receiveDomainState.selectedPayChain = selectedChainName
        receiveDomainState.selectedSendCoinCode = "USDT_\(selectedChainName)"
        receiveDomainState.selectedRecvCoinCode = "USDT_\(selectedChainName)"
    }

    private func applyNetworkOption(_ option: NetworkOption) {
        selectedChainId = option.chainId
        selectedChainName = option.chainName
        UserDefaults.standard.set(option.chainId, forKey: selectedChainStorageKey)
        if receiveDomainState.selectedIsNormalChannel || receiveSelectedNetworkId == nil {
            receiveDomainState.selectedPayChain = option.chainName
            receiveDomainState.selectedSendCoinCode = "USDT_\(option.chainName)"
            receiveDomainState.selectedRecvCoinCode = "USDT_\(option.chainName)"
        }
        log("网络已切换: \(option.chainName) (\(option.chainId))")
    }

    private func configureReceiveNetwork(_ item: ReceiveNetworkItem) {
        receiveSelectedNetworkId = item.id
        receiveDomainState.selectedNetworkName = item.name
        receiveDomainState.selectedChainColor = item.chainColor
        receiveDomainState.selectedIsNormalChannel = item.isNormalChannel
        receiveDomainState.activeTab = .individuals
        receiveDomainState.individualOrderSN = nil
        receiveDomainState.businessOrderSN = nil
        individualTraceOrder = nil
        businessTraceOrder = nil

        if item.isNormalChannel {
            let activeChain = selectedChainId == 199 ? "BTT" : "BTT_TEST"
            receiveDomainState.selectedPayChain = activeChain
            receiveDomainState.selectedSendCoinCode = "USDT_\(activeChain)"
            receiveDomainState.selectedRecvCoinCode = "USDT_\(activeChain)"
            receiveDomainState.selectedSendCoinName = "USDT"
            receiveDomainState.selectedRecvCoinName = "USDT"
            receiveDomainState.selectedPairLabel = "USDT/USDT"
            receiveDomainState.availablePairs = []
            receiveDomainState.selectedSellerId = nil
            log("收款网络已选择: \(item.name) [In-App Channel]")
            return
        }

        let payChain = item.allowChain?.chainName ?? item.name
        receiveDomainState.selectedPayChain = payChain
        receiveDomainState.availablePairs = item.allowChain?.exchangePairs ?? []

        if let pair = preferredReceivePair(from: item.allowChain) {
            applyReceivePair(pair)
        } else {
            receiveDomainState.selectedPairLabel = "\(receiveDomainState.selectedSendCoinName)/\(receiveDomainState.selectedRecvCoinName)"
        }
        log("收款网络已选择: \(item.name) [Proxy Settlement]")
    }

    private func applyReceivePair(_ pair: AllowExchangePair) {
        receiveDomainState.selectedSendCoinCode = pair.sendCoinCode ?? receiveDomainState.selectedSendCoinCode
        receiveDomainState.selectedRecvCoinCode = pair.recvCoinCode ?? receiveDomainState.selectedRecvCoinCode
        receiveDomainState.selectedSendCoinName = pair.sendCoinName ?? pair.sendCoinSymbol ?? receiveDomainState.selectedSendCoinName
        receiveDomainState.selectedRecvCoinName = pair.recvCoinName ?? pair.recvCoinSymbol ?? receiveDomainState.selectedRecvCoinName
        let left = pair.sendCoinSymbol ?? pair.sendCoinName ?? receiveDomainState.selectedSendCoinName
        let right = pair.recvCoinSymbol ?? pair.recvCoinName ?? receiveDomainState.selectedRecvCoinName
        receiveDomainState.selectedPairLabel = "\(left)/\(right)"
    }

    private func preferredReceivePair(from chain: ReceiveAllowChainItem?) -> AllowExchangePair? {
        guard let pairs = chain?.exchangePairs, !pairs.isEmpty else {
            return nil
        }
        return pairs.first
    }

    private func refreshReceivePairOptions(for item: ReceiveNetworkItem) async {
        let sendChainName = item.allowChain?.chainName ?? item.name
        guard !sendChainName.isEmpty else { return }

        do {
            let query = AllowListQuery(
                groupByType: 0,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                sendChainName: sendChainName,
                recvChainName: selectedChainId == 199 ? "BTT" : "BTT_TEST",
                env: backendEnvValue()
            )
            let list = try await backend.receive.cpCashAllowList(query: query)
            guard let first = list.first else { return }

            receiveDomainState.availablePairs = first.exchangePairs
            receiveDomainState.selectedPayChain = first.chainName ?? sendChainName
            if let firstPair = first.exchangePairs.first {
                applyReceivePair(firstPair)
            }
            log("收款交易对已刷新: chain=\(receiveDomainState.selectedPayChain), pairs=\(first.exchangePairs.count)")
        } catch {
            log("收款交易对刷新失败: \(error)")
        }
    }

    private func resolvePreferredOrder(from list: [TraceOrderItem]) -> TraceOrderItem? {
        if let marked = list.first(where: { $0.isMarked == true }) {
            return marked
        }
        return list.first
    }

    private func createTraceOrder(isLongTerm: Bool, note: String, silent: Bool = false) async {
        guard !receiveDomainState.selectedIsNormalChannel else {
            if !silent {
                showToast("In-App Channel 无需创建收款订单", theme: .info)
            }
            return
        }

        let sendCoinCode = receiveDomainState.selectedSendCoinCode
        let recvCoinCode = receiveDomainState.selectedRecvCoinCode
        let sellerId = receiveDomainState.selectedSellerId ?? 100000001
        let receiveAddress: String
        do {
            receiveAddress = try resolvedReceiveAddress()
        } catch {
            showToast("收款地址不可用，请重新登录后重试", theme: .error)
            log("收款地址不可用: \(error)")
            return
        }
        let request = CreateTraceRequest(
            sellerId: sellerId,
            recvAddress: receiveAddress,
            sendCoinCode: sendCoinCode,
            recvCoinCode: recvCoinCode,
            recvAmount: receiveDomainState.receiveMinAmount,
            note: note,
            env: backendEnvValue()
        )

        do {
            let result: CreateReceiptResult
            if isLongTerm {
                result = try await backend.receive.createLongTrace(request: request)
                receiveDomainState.activeTab = .business
                receiveDomainState.businessOrderSN = result.orderSn
            } else {
                result = try await backend.receive.createShortTrace(request: request)
                receiveDomainState.activeTab = .individuals
                receiveDomainState.individualOrderSN = result.orderSn
            }
            let resolvedOrderSN = try await resolveCreatedOrderSN(result)
            lastCreatedReceiveOrderSN = resolvedOrderSN ?? result.orderSn ?? result.serialNumber ?? "-"
            if let orderSN = resolvedOrderSN ?? result.orderSn {
                if isLongTerm {
                    receiveDomainState.businessOrderSN = orderSN
                } else {
                    receiveDomainState.individualOrderSN = orderSN
                }
                await refreshTraceShow(orderSN: orderSN)
            } else {
                throw ReceiveFlowError.traceOrderCreationFailed
            }
            await loadReceiveHome(autoCreateIfMissing: false)
            if !silent {
                showToast("收款地址创建成功", theme: .success)
            }
        } catch {
            if case let BackendAPIError.serverError(code, _) = error, code == 60018 {
                showToast("当前收款地址数量已达上限", theme: .error)
                log("收款地址创建失败: 命中地址数量上限")
                return
            }
            if case ReceiveFlowError.traceOrderCreationFailed = error {
                if !silent {
                    showToast("收款地址创建处理中，请稍后刷新", theme: .error)
                }
                log("收款地址创建失败: 轮询未拿到有效订单号")
                return
            }
            if !silent {
                showToast("收款地址创建失败", theme: .error)
            }
            log("收款地址创建失败: \(error)")
        }
    }

    private func resolveCreatedOrderSN(_ result: CreateReceiptResult) async throws -> String? {
        if let orderSN = result.orderSn, !orderSN.isEmpty {
            return orderSN
        }
        guard let serial = result.serialNumber, !serial.isEmpty else {
            return nil
        }
        receiveDomainState.isPolling = true
        defer { receiveDomainState.isPolling = false }

        var attempt = 0
        while attempt < 15 {
            if Task.isCancelled {
                throw CancellationError()
            }
            let detail = try await backend.order.receivingShow(orderSN: serial)
            if detail.status == 1, let orderSN = detail.orderSn, !orderSN.isEmpty {
                return orderSN
            }
            if detail.status == 2 {
                throw ReceiveFlowError.traceOrderCreationFailed
            }
            attempt += 1
            try await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled {
                throw CancellationError()
            }
        }
        throw ReceiveFlowError.traceOrderCreationFailed
    }

    private func backendEnvValue() -> String {
        switch environment.tag {
        case .development:
            return "dev"
        case .staging:
            return "test"
        case .production:
            return "prod"
        }
    }

    private func resolvedReceiveAddress() throws -> String {
        let cached = activeAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cached.isEmpty, cached != "-" {
            return cached
        }
        let secured = try securityService.activeAddress().value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !secured.isEmpty else {
            throw BackendAPIError.serverError(code: 0, message: "active address unavailable")
        }
        return secured
    }

    func log(_ message: String) {
        let sanitized = redactSensitiveLog(message)
        let entry = "[\(Self.logTimeFormatter.string(from: clock.now))] \(sanitized)"
        logs.append(entry)
        appLogger.log(entry)
    }

    private func redactSensitiveLog(_ message: String) -> String {
        var text = message
        text = redact(text, regex: Self.txHashRegex, leading: 10, trailing: 6, threshold: 20)
        text = redact(text, regex: Self.evmAddressRegex, leading: 8, trailing: 4, threshold: 12)
        return text
    }

    private func redact(_ value: String, regex: NSRegularExpression, leading: Int, trailing: Int, threshold: Int) -> String {
        let matches = regex.matches(in: value, range: NSRange(value.startIndex..., in: value))
        guard !matches.isEmpty else { return value }

        var output = value
        for match in matches.reversed() {
            guard let range = Range(match.range, in: output) else { continue }
            let raw = String(output[range])
            output.replaceSubrange(
                range,
                with: AddressFormatter.shortened(
                    raw,
                    leading: leading,
                    trailing: trailing,
                    threshold: threshold
                )
            )
        }
        return output
    }
}
