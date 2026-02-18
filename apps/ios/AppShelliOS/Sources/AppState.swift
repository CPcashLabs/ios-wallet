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

    func selectReceiveNetwork(item: ReceiveNetworkItem, preloadHome: Bool = true) async {
        await receiveUseCase.selectReceiveNetwork(item: item, preloadHome: preloadHome)
    }

    func selectReceivePair(sendCoinCode: String, recvCoinCode: String) async {
        await receiveUseCase.selectReceivePair(sendCoinCode: sendCoinCode, recvCoinCode: recvCoinCode)
    }

    func setReceiveActiveTab(_ tab: ReceiveTabMode) {
        receiveUseCase.setReceiveActiveTab(tab)
    }

    func loadReceiveHome(autoCreateIfMissing: Bool = true) async {
        await receiveUseCase.loadReceiveHome(autoCreateIfMissing: autoCreateIfMissing)
    }

    func createShortTraceOrder(note: String = "") async {
        await receiveUseCase.createShortTraceOrder(note: note)
    }

    func createLongTraceOrder(note: String = "") async {
        await receiveUseCase.createLongTraceOrder(note: note)
    }

    func refreshTraceShow(orderSN: String) async {
        await receiveUseCase.refreshTraceShow(orderSN: orderSN)
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        await receiveUseCase.loadReceiveAddresses(validity: validity)
    }

    func markTraceOrder(
        orderSN: String,
        sendCoinCode: String? = nil,
        recvCoinCode: String? = nil,
        orderType: String? = nil
    ) async {
        await receiveUseCase.markTraceOrder(
            orderSN: orderSN,
            sendCoinCode: sendCoinCode,
            recvCoinCode: recvCoinCode,
            orderType: orderType
        )
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        await receiveUseCase.loadReceiveTraceChildren(orderSN: orderSN, page: page, perPage: perPage)
    }

    func loadReceiveShare(orderSN: String) async {
        await receiveUseCase.loadReceiveShare(orderSN: orderSN)
    }

    func loadReceiveExpiryConfig() async {
        await receiveUseCase.loadReceiveExpiryConfig()
    }

    func updateReceiveExpiry(duration: Int) async {
        await receiveUseCase.updateReceiveExpiry(duration: duration)
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
