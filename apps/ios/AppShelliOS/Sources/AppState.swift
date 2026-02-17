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
    @Published private(set) var environment: EnvironmentConfig
    @Published private(set) var activeAddress: String = "-"
    @Published private(set) var userProfile: UserProfile?
    @Published private(set) var coins: [CoinItem] = []
    @Published private(set) var recentTransfers: [TransferItem] = []
    @Published private(set) var transferRecentContacts: [TransferReceiveContact] = []
    @Published private(set) var homeRecentMessages: [MessageItem] = []
    @Published private(set) var receives: [ReceiveRecord] = []
    @Published private(set) var orders: [OrderSummary] = []
    @Published private(set) var selectedOrderDetail: OrderDetail?
    @Published private(set) var lastCreatedReceiveOrderSN: String = "-"
    @Published private(set) var lastCreatedPaymentOrderSN: String = "-"
    @Published private(set) var lastTxHash: String = "-"
    @Published private(set) var meProfile: UserProfile?
    @Published private(set) var messageList: [MessageItem] = []
    @Published private(set) var messagePage: Int = 1
    @Published private(set) var messageLastPage = false
    @Published private(set) var addressBooks: [AddressBookItem] = []
    @Published private(set) var billList: [OrderSummary] = []
    @Published private(set) var billFilter = BillFilter()
    @Published private(set) var billAddressFilter: String?
    @Published private(set) var billStats: BillStatisticsSummary?
    @Published private(set) var billAddressAggList: [BillAddressAggregateItem] = []
    @Published private(set) var billCurrentPage: Int = 1
    @Published private(set) var billTotal: Int = 0
    @Published private(set) var billLastPage = false
    @Published private(set) var exchangeRates: [ExchangeRateItem] = []
    @Published private(set) var selectedCurrency = "USD"
    @Published private(set) var uiLoadingMap: [String: Bool] = [:]
    @Published private(set) var uiErrorMap: [String: String] = [:]
    @Published private(set) var transferEmailNotify = false
    @Published private(set) var rewardEmailNotify = false
    @Published private(set) var receiptEmailNotify = false
    @Published private(set) var backupWalletNotify = false
    @Published private(set) var logs: [String] = []
    @Published private(set) var passkeyAccounts: [LocalPasskeyAccount] = []
    @Published var selectedPasskeyRawId: String = ""

    @Published private(set) var isAuthenticated = false
    @Published private(set) var loginBusy = false
    @Published private(set) var loginCooldownUntil: Date?
    @Published private(set) var loginErrorKind: LoginErrorKind?
    @Published private(set) var toast: ToastState?

    @Published private(set) var selectedChainId: Int = 1029
    @Published private(set) var selectedChainName: String = "BTT_TEST"
    @Published private(set) var networkOptions: [NetworkOption] = []
    @Published private(set) var approvalSessionState: ApprovalSessionState = .locked

    @Published private(set) var receiveDomainState = ReceiveDomainState()
    @Published private(set) var receiveSelectNetworks: [ReceiveNetworkItem] = []
    @Published private(set) var receiveNormalNetworks: [ReceiveNetworkItem] = []
    @Published private(set) var receiveProxyNetworks: [ReceiveNetworkItem] = []
    @Published private(set) var receiveSelectedNetworkId: String?
    @Published private(set) var individualTraceOrder: TraceOrderItem?
    @Published private(set) var businessTraceOrder: TraceOrderItem?
    @Published private(set) var receiveRecentValid: [TraceOrderItem] = []
    @Published private(set) var receiveRecentInvalid: [TraceOrderItem] = []
    @Published private(set) var receiveTraceChildren: [TraceChildItem] = []
    @Published private(set) var individualTraceDetail: TraceShowDetail?
    @Published private(set) var businessTraceDetail: TraceShowDetail?
    @Published private(set) var receiveShareDetail: ReceiveOrderDetail?
    @Published private(set) var receiveExpiryConfig = ReceiveExpiryConfig(durations: [24, 72, 168], selectedDuration: 72)
    @Published private(set) var transferDomainState = TransferDomainState()
    @Published private(set) var transferSelectNetworks: [TransferNetworkItem] = []
    @Published private(set) var transferNormalNetworks: [TransferNetworkItem] = []
    @Published private(set) var transferProxyNetworks: [TransferNetworkItem] = []
    @Published private(set) var transferSelectedNetworkId: String?
    @Published private(set) var transferDraft = TransferDraft()

    var rootScreen: RootScreen {
        isAuthenticated ? .home : .login
    }

    private var toastDismissTask: Task<Void, Never>?
    private let securityService: SecurityService
    private var backend: BackendAPI
    private static let logTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    private let passkeyService: LocalPasskeyService
    private let selectedChainStorageKey = "cpcash.selected.chain.id"

    init() {
        let env = EnvironmentConfig.default
        environment = env
        securityService = StubSecurityCore()
        backend = BackendAPI(environment: env)
        passkeyService = LocalPasskeyService()
    }

    deinit {
        toastDismissTask?.cancel()
    }

    func boot() {
        do {
            let address = try securityService.activeAddress()
            activeAddress = address.value
            refreshPasskeyAccounts()
            restoreSelectedChain()
            log("钱包已就绪: \(address.value)")
            log("当前后端环境: \(environment.tag.rawValue) -> \(environment.baseURL.absoluteString)")
            Task {
                await refreshNetworkOptions()
                await loadReceiveExpiryConfig()
                await loadTransferSelectNetwork()
            }
        } catch {
            log("钱包初始化失败: \(error)")
        }
    }

    func refreshPasskeyAccounts() {
        passkeyAccounts = passkeyService.accounts()
        if selectedPasskeyRawId.isEmpty {
            selectedPasskeyRawId = passkeyAccounts.first?.rawId ?? ""
        }
    }

    func registerPasskey(displayName: String) async {
        guard beginLoginFlow() else { return }
        defer { endLoginFlow() }

        do {
            let normalizedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let account = try await passkeyService.register(displayName: normalizedName.isEmpty ? "CPCash" : normalizedName)
            let address = try securityService.importAccount(EncryptedImportBlob(payload: account.privateKeyHex))
            try passkeyService.updateAddress(rawId: account.rawId, address: address.value)
            refreshPasskeyAccounts()
            selectedPasskeyRawId = account.rawId
            activeAddress = address.value
            log("Passkey 注册成功: \(account.displayName) / \(address.value)")
            try await performSignInFlow()
        } catch {
            handleLoginFailure(error)
        }
    }

    func loginWithPasskey(rawId: String?) async {
        guard beginLoginFlow() else { return }
        defer { endLoginFlow() }

        do {
            let account = try await passkeyService.login(rawId: rawId)
            let importedAddress = try securityService.importAccount(EncryptedImportBlob(payload: account.privateKeyHex))
            if account.address != importedAddress.value {
                try? passkeyService.updateAddress(rawId: account.rawId, address: importedAddress.value)
            }
            activeAddress = importedAddress.value
            log("Passkey 认证成功: \(account.displayName) / \(importedAddress.value)")
            try await performSignInFlow()
        } catch {
            handleLoginFailure(error)
        }
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
        setLoading("me.root", true)
        defer { setLoading("me.root", false) }

        do {
            async let profileTask = backend.auth.currentUser()
            async let messagesTask = backend.message.list(page: 1, perPage: 10)
            async let ratesTask = backend.settings.exchangeRateByUSD()

            let profile = try await profileTask
            let messages = try await messagesTask
            let rates = try await ratesTask
            meProfile = profile
            messageList = messages.data
            messagePage = messages.page ?? 1
            messageLastPage = computeLastPage(page: messages.page, perPage: messages.perPage, total: messages.total)
            exchangeRates = rates
            if let current = rates.first?.currency, !current.isEmpty {
                selectedCurrency = current
            }
            clearError("me.root")
        } catch {
            setError("me.root", error)
            log("我的页面基础数据加载失败: \(error)")
        }
    }

    func loadMessages(page: Int, append: Bool) async {
        guard !isLoading("me.message.list") else { return }
        setLoading("me.message.list", true)
        defer { setLoading("me.message.list", false) }
        do {
            let response = try await backend.message.list(page: page, perPage: 10)
            if append {
                messageList.append(contentsOf: response.data)
            } else {
                messageList = response.data
            }
            messagePage = response.page ?? page
            messageLastPage = computeLastPage(page: response.page, perPage: response.perPage, total: response.total)
            clearError("me.message.list")
            log("消息列表加载成功: page=\(messagePage), count=\(messageList.count)")
        } catch {
            setError("me.message.list", error)
            log("消息列表加载失败: \(error)")
        }
    }

    func markMessageRead(id: String) async {
        do {
            try await backend.message.markRead(id: id)
            await loadMessages(page: 1, append: false)
            clearError("me.message.read")
        } catch {
            setError("me.message.read", error)
            showToast("标记已读失败", theme: .error)
            log("标记消息已读失败: \(error)")
        }
    }

    func markAllMessagesRead() async {
        do {
            try await backend.message.markAllRead()
            await loadMessages(page: 1, append: false)
            showToast("已全部标记为已读", theme: .success)
            clearError("me.message.readall")
        } catch {
            setError("me.message.readall", error)
            showToast("全部已读失败", theme: .error)
            log("全部标记已读失败: \(error)")
        }
    }

    func loadAddressBooks() async {
        setLoading("me.addressbook.list", true)
        defer { setLoading("me.addressbook.list", false) }
        do {
            addressBooks = try await backend.addressBook.list()
            clearError("me.addressbook.list")
            log("地址簿加载成功: \(addressBooks.count)")
        } catch {
            setError("me.addressbook.list", error)
            log("地址簿加载失败: \(error)")
        }
    }

    func createAddressBook(name: String, walletAddress: String, chainType: String = "EVM") async -> Bool {
        do {
            try await backend.addressBook.create(
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            showToast("地址簿添加成功", theme: .success)
            await loadAddressBooks()
            clearError("me.addressbook.create")
            return true
        } catch {
            setError("me.addressbook.create", error)
            showToast("地址簿添加失败", theme: .error)
            log("地址簿新增失败: \(error)")
            return false
        }
    }

    func updateAddressBook(id: String, name: String, walletAddress: String, chainType: String = "EVM") async -> Bool {
        do {
            try await backend.addressBook.update(
                id: id,
                request: AddressBookUpsertRequest(name: name, walletAddress: walletAddress, chainType: chainType)
            )
            showToast("地址簿更新成功", theme: .success)
            await loadAddressBooks()
            clearError("me.addressbook.update")
            return true
        } catch {
            setError("me.addressbook.update", error)
            showToast("地址簿更新失败", theme: .error)
            log("地址簿更新失败: \(error)")
            return false
        }
    }

    func deleteAddressBook(id: String) async {
        do {
            try await backend.addressBook.delete(id: id)
            showToast("地址簿删除成功", theme: .success)
            addressBooks.removeAll { "\($0.id ?? -1)" == id }
            clearError("me.addressbook.delete")
        } catch {
            setError("me.addressbook.delete", error)
            showToast("地址簿删除失败", theme: .error)
            log("地址簿删除失败: \(error)")
        }
    }

    func loadBillList(filter: BillFilter, append: Bool = false) async {
        setLoading("me.bill.list", true)
        defer { setLoading("me.bill.list", false) }
        do {
            let response = try await backend.bill.list(filter: filter)
            billFilter = filter
            billAddressFilter = filter.otherAddress
            if append {
                billList.append(contentsOf: response.data)
            } else {
                billList = response.data
            }
            billCurrentPage = response.page ?? filter.page
            billTotal = response.total ?? billList.count
            billLastPage = computeLastPage(page: response.page, perPage: response.perPage, total: response.total)
            clearError("me.bill.list")
            log("账单列表加载成功: \(billList.count)")
        } catch {
            setError("me.bill.list", error)
            log("账单列表加载失败: \(error)")
        }
    }

    func setBillAddressFilter(_ address: String?) {
        let normalized = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let normalized, !normalized.isEmpty {
            billAddressFilter = normalized
        } else {
            billAddressFilter = nil
        }
    }

    func loadBillStatistics(range: BillTimeRange) async {
        setLoading("me.bill.stat", true)
        defer { setLoading("me.bill.stat", false) }
        do {
            billStats = try await backend.bill.statAllAddressStat(range: range)
            clearError("me.bill.stat")
        } catch {
            setError("me.bill.stat", error)
            log("账单统计加载失败: \(error)")
        }
    }

    func loadBillAddressAggregate(range: BillTimeRange, page: Int = 1, perPage: Int = 50) async {
        setLoading("me.bill.aggregate", true)
        defer { setLoading("me.bill.aggregate", false) }
        do {
            let response = try await backend.bill.statAllAddressPage(range: range, page: page, perPage: perPage)
            billAddressAggList = response.data
            clearError("me.bill.aggregate")
            log("账单地址聚合加载成功: \(billAddressAggList.count)")
        } catch {
            setError("me.bill.aggregate", error)
            log("账单地址聚合加载失败: \(error)")
        }
    }

    func updateNickname(_ nickname: String) async {
        do {
            try await backend.profile.update(request: ProfileUpdateRequest(nickname: nickname, avatar: nil))
            meProfile = try await backend.auth.currentUser()
            showToast("昵称更新成功", theme: .success)
            clearError("me.profile.nickname")
        } catch {
            setError("me.profile.nickname", error)
            showToast("昵称更新失败", theme: .error)
            log("昵称更新失败: \(error)")
        }
    }

    func updateAvatar(fileData: Data, fileName: String = "avatar.jpg", mimeType: String = "image/jpeg") async {
        setLoading("me.profile.avatar", true)
        defer { setLoading("me.profile.avatar", false) }
        do {
            let upload = try await backend.profile.uploadAvatar(fileData: fileData, fileName: fileName, mimeType: mimeType)
            let avatarURL = upload.url?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !avatarURL.isEmpty else {
                throw BackendAPIError.serverError(code: -1, message: "头像上传失败，请重试")
            }
            try await backend.profile.update(request: ProfileUpdateRequest(nickname: nil, avatar: avatarURL))
            let profile = try await backend.auth.currentUser()
            meProfile = profile
            userProfile = profile
            showToast("头像更新成功", theme: .success)
            clearError("me.profile.avatar")
        } catch {
            setError("me.profile.avatar", error)
            showToast(simplifyError(error), theme: .error)
            log("头像更新失败: \(error)")
        }
    }

    func loadExchangeRates() async {
        setLoading("me.settings.rates", true)
        defer { setLoading("me.settings.rates", false) }
        do {
            exchangeRates = try await backend.settings.exchangeRateByUSD()
            let current = selectedCurrency.uppercased()
            let hasCurrent = exchangeRates.contains { ($0.currency ?? "").uppercased() == current }
            if !hasCurrent, let currency = exchangeRates.first?.currency, !currency.isEmpty {
                selectedCurrency = currency
            }
            clearError("me.settings.rates")
        } catch {
            setError("me.settings.rates", error)
            log("汇率列表加载失败: \(error)")
        }
    }

    func saveCurrencyUnit(currency: String) {
        selectedCurrency = currency
        showToast("修改成功", theme: .success)
    }

    func setTransferEmailNotify(_ enable: Bool) async {
        do {
            try await backend.settings.setTransferEmailNotify(enable: enable)
            transferEmailNotify = enable
            clearError("me.settings.transferNotify")
        } catch {
            setError("me.settings.transferNotify", error)
            showToast("转账通知更新失败", theme: .error)
        }
    }

    func setRewardEmailNotify(_ enable: Bool) async {
        do {
            try await backend.settings.setRewardEmailNotify(enable: enable)
            rewardEmailNotify = enable
            clearError("me.settings.rewardNotify")
        } catch {
            setError("me.settings.rewardNotify", error)
            showToast("奖励通知更新失败", theme: .error)
        }
    }

    func setReceiptEmailNotify(_ enable: Bool) async {
        do {
            try await backend.settings.setReceiptEmailNotify(enable: enable)
            receiptEmailNotify = enable
            clearError("me.settings.receiptNotify")
        } catch {
            setError("me.settings.receiptNotify", error)
            showToast("收据通知更新失败", theme: .error)
        }
    }

    func setBackupWalletNotify(_ enable: Bool) async {
        do {
            try await backend.settings.setBackupWalletNotify(enable: enable)
            backupWalletNotify = enable
            clearError("me.settings.backupNotify")
        } catch {
            setError("me.settings.backupNotify", error)
            showToast("备份通知更新失败", theme: .error)
        }
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
            applyNetworkOption(option)
            Task {
                await loadReceiveSelectNetwork()
                await loadTransferSelectNetwork()
            }
        }
    }

    func loadTransferSelectNetwork() async {
        setLoading("transfer.selectNetwork", true)
        defer { setLoading("transfer.selectNetwork", false) }

        do {
            let query = AllowListQuery(
                groupByType: 1,
                recvCoinSymbol: "USDT",
                sendCoinSymbol: "USDT",
                sendChainName: selectedChainName,
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

            var normalNetworks: [TransferNetworkItem] = []
            if let normalEntry {
                normalNetworks = [
                    TransferNetworkItem(
                        id: "normal:\(normalEntry.chainName ?? "CPcash")",
                        name: "CPcash",
                        logoURL: normalEntry.chainLogo,
                        chainColor: normalEntry.chainColor ?? "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        normalChain: normalEntry,
                        isNormalChannel: true
                    ),
                ]
            } else {
                normalNetworks = [
                    TransferNetworkItem(
                        id: "normal:CPcash",
                        name: "CPcash",
                        logoURL: nil,
                        chainColor: "#1677FF",
                        category: .appChannel,
                        allowChain: nil,
                        normalChain: nil,
                        isNormalChannel: true
                    ),
                ]
            }

            let proxyNetworks = cpList.map { item in
                TransferNetworkItem(
                    id: "proxy:\(item.chainName ?? UUID().uuidString)",
                    name: item.chainName ?? "-",
                    logoURL: item.chainLogo,
                    chainColor: item.chainColor ?? "#1677FF",
                    category: .proxySettlement,
                    allowChain: item,
                    normalChain: nil,
                    isNormalChannel: false,
                    balance: chainTotalBalance(item.exchangePairs)
                )
            }

            transferNormalNetworks = normalNetworks
            transferProxyNetworks = proxyNetworks
            transferSelectNetworks = normalNetworks + proxyNetworks

            if let selectedId = transferSelectedNetworkId,
               !transferSelectNetworks.contains(where: { $0.id == selectedId })
            {
                transferSelectedNetworkId = nil
            }
            if transferSelectedNetworkId == nil, let first = transferSelectNetworks.first {
                configureTransferNetwork(first)
            }
            clearError("transfer.selectNetwork")
        } catch {
            setError("transfer.selectNetwork", error)
            transferNormalNetworks = [
                TransferNetworkItem(
                    id: "normal:CPcash",
                    name: "CPcash",
                    logoURL: nil,
                    chainColor: "#1677FF",
                    category: .appChannel,
                    allowChain: nil,
                    normalChain: nil,
                    isNormalChannel: true
                ),
            ]
            transferProxyNetworks = []
            transferSelectNetworks = transferNormalNetworks
            if let first = transferSelectNetworks.first {
                configureTransferNetwork(first)
            }
            log("转账网络加载失败: \(error)")
        }
    }

    func selectTransferNetwork(item: TransferNetworkItem) async {
        if !item.isAvailable {
            showToast("余额不足，请切换其他网络", theme: .error)
            return
        }
        configureTransferNetwork(item)
        transferDraft = TransferDraft(mode: item.isNormalChannel ? .normal : .proxy)
        if addressBooks.isEmpty {
            await loadAddressBooks()
        }
        await loadTransferAddressCandidates()
    }

    func selectTransferPair(sendCoinCode: String, recvCoinCode: String) {
        guard let pair = transferDomainState.availablePairs.first(where: {
            $0.sendCoinCode == sendCoinCode && $0.recvCoinCode == recvCoinCode
        }) else {
            return
        }
        applyTransferPair(pair)
        transferDraft.orderSN = nil
        transferDraft.orderDetail = nil
    }

    func selectTransferNormalCoin(coinCode: String) async {
        guard let coin = transferDomainState.availableNormalCoins.first(where: { $0.coinCode == coinCode }) else {
            return
        }
        applyTransferNormalCoin(coin)
        do {
            let detail = try await backend.receive.normalAllowCoinShow(coinCode: coinCode)
            applyTransferNormalCoin(detail)
        } catch {
            log("转账币种详情加载失败: \(error)")
        }
    }

    func updateTransferRecipientAddress(_ address: String) {
        let compact = address
            .components(separatedBy: .whitespacesAndNewlines)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        transferDraft.recipientAddress = compact
    }

    func resetTransferFlow() {
        transferDraft = TransferDraft(mode: transferDomainState.selectedIsNormalChannel ? .normal : .proxy)
    }

    func transferAddressValidationMessage(_ address: String) -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return isValidTransferAddress(trimmed) ? nil : "请输入正确地址"
    }

    func isValidTransferAddress(_ address: String) -> Bool {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        if transferDomainState.selectedIsNormalChannel {
            return isValidEvmAddress(trimmed)
        }

        let patterns = transferDomainState.selectedAddressRegex
        if patterns.isEmpty {
            return false
        }
        for pattern in patterns {
            if let regex = buildTransferRegex(pattern), regex.firstMatch(in: trimmed, range: NSRange(location: 0, length: trimmed.utf16.count)) != nil {
                return true
            }
        }
        return false
    }

    func transferAddressBookCandidates() -> [AddressBookItem] {
        let isTron = transferDomainState.selectedPayChain.uppercased().contains("TRON")
        return addressBooks.filter { item in
            let type = (item.chainType ?? "EVM").uppercased()
            return isTron ? type == "TRON" : type != "TRON"
        }
    }

    func detectAddressChainType(_ address: String) -> String? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let evm = "^(0x|0X)?[a-fA-F0-9]{40}$"
        let tron = "^T[a-zA-Z0-9]{33}$"
        if trimmed.range(of: evm, options: .regularExpression) != nil {
            return "EVM"
        }
        if trimmed.range(of: tron, options: .regularExpression) != nil {
            return "TRON"
        }
        return nil
    }

    func loadTransferAddressCandidates() async {
        let sendChain = selectedChainId == 199 ? "BTT" : "BTT_TEST"
        let recvChain = transferDomainState.selectedPayChain
        do {
            transferRecentContacts = try await backend.wallet.recentTransferReceiveList(
                sendChainName: sendChain,
                recvChainName: recvChain
            )
            clearError("transfer.address.candidates")
            log("转账最近联系人加载成功: \(transferRecentContacts.count)")
        } catch {
            setError("transfer.address.candidates", error)
            transferRecentContacts = []
            log("转账最近联系人加载失败: \(error)")
        }
    }

    func prepareTransferPayment(amountText: String, note: String) async -> Bool {
        let address = transferDraft.recipientAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidTransferAddress(address) else {
            showToast("地址格式错误", theme: .error)
            return false
        }
        let normalizedAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let amount = Decimal(string: normalizedAmount), amount > 0 else {
            showToast("请输入正确金额", theme: .error)
            return false
        }

        transferDraft.recipientAddress = address
        transferDraft.amountText = normalizedAmount
        transferDraft.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        transferDraft.orderDetail = nil
        transferDraft.orderSN = nil
        transferDraft.mode = transferDomainState.selectedIsNormalChannel ? .normal : .proxy

        if transferDomainState.selectedIsNormalChannel {
            do {
                let detail = try await backend.receive.normalAllowCoinShow(coinCode: transferDomainState.selectedSendCoinCode)
                applyTransferNormalCoin(detail)
            } catch {
                log("normal 币种详情加载失败，使用 allow-list 数据回退: \(error)")
            }
            let contract = transferDomainState.selectedCoinContract ?? ""
            guard isValidEvmAddress(contract) else {
                showToast("币种配置异常，请重新选择网络后再试", theme: .error)
                return false
            }
            return true
        }

        setLoading("transfer.prepare", true)
        defer { setLoading("transfer.prepare", false) }
        do {
            let result = try await backend.order.createPayment(
                request: CreatePaymentRequest(
                    recvAddress: address,
                    sendCoinCode: transferDomainState.selectedSendCoinCode,
                    recvCoinCode: transferDomainState.selectedRecvCoinCode,
                    sendAmount: NSDecimalNumber(decimal: amount).doubleValue,
                    note: transferDraft.note
                )
            )
            let orderSN = try await resolveTransferOrderSN(result)
            let detail = try await backend.order.detail(orderSN: orderSN)
            transferDraft.orderSN = orderSN
            transferDraft.orderDetail = detail
            lastCreatedPaymentOrderSN = orderSN
            log("转账订单创建成功: order_sn=\(orderSN)")
            return true
        } catch {
            showToast("转账订单创建失败", theme: .error)
            log("转账订单创建失败: \(error)")
            return false
        }
    }

    func executeTransferPayment() async -> Bool {
        guard case .unlocked = approvalSessionState else {
            showToast("登录会话失效，请重新登录", theme: .error)
            return false
        }
        guard !isLoading("transfer.pay") else { return false }
        setLoading("transfer.pay", true)
        defer { setLoading("transfer.pay", false) }

        do {
            let payment = try buildTransferExecutionContext()
            let from = try securityService.activeAddress()
            let amountMinor = toMinorUnits(amountText: payment.amountText, decimals: payment.coinPrecision)
            guard let data = erc20TransferData(to: payment.recipientAddress, amountMinor: amountMinor) else {
                throw BackendAPIError.serverError(code: -1, message: "erc20 data encode failed")
            }

            let payChainId = resolveTransferChainId(for: payment.chainName)
            let txHash = try securityService.signAndSendTransaction(
                SendTxRequest(
                    source: .system(name: "wallet_transfer"),
                    from: from,
                    to: Address(payment.tokenContract),
                    value: "0",
                    data: data,
                    chainId: payChainId
                )
            )
            lastTxHash = txHash.value
            log("转账签名广播成功: tx=\(txHash.value), chain=\(payChainId)")

            var callbackError: Error?
            if payment.mode == .proxy, let orderSN = payment.orderSN {
                do {
                    try await backend.order.ship(orderSN: orderSN, txid: txHash.value, message: nil, success: true)
                    await loadOrderDetail(orderSN: orderSN)
                } catch {
                    callbackError = error
                    log("转账成功但订单回写失败(proxy): \(error)")
                }
            } else {
                do {
                    let report = try await backend.order.cpCashTxReport(
                        request: CpCashTxReportRequest(
                            txid: txHash.value,
                            chainName: payment.chainName,
                            coinCode: payment.coinCode,
                            success: true,
                            message: transferDraft.note.isEmpty ? nil : transferDraft.note,
                            direction: "TRANSFER_OUT",
                            multisigWalletId: nil,
                            buyerSendAddress: from.value,
                            buyerRecvAddress: transferDraft.recipientAddress
                        )
                    )
                    if let orderSN = report.orderSn, !orderSN.isEmpty {
                        transferDraft.orderSN = orderSN
                    }
                } catch {
                    callbackError = error
                    log("转账成功但回执上报失败(normal): \(error)")
                }
            }

            await refreshOrdersOnly()
            if callbackError != nil {
                showToast("支付已提交，回执同步失败，请稍后在账单查看", theme: .info)
            } else {
                showToast("支付成功", theme: .success)
            }
            return true
        } catch {
            log("转账支付失败: \(error)")
            let failedMessage = transferPaymentFailureMessage(error)
            if transferDraft.mode == .proxy, let orderSN = transferDraft.orderSN {
                do {
                    try await backend.order.ship(orderSN: orderSN, txid: nil, message: failedMessage, success: false)
                } catch {
                    log("转账失败回写订单失败: \(error)")
                }
            } else {
                do {
                    _ = try await backend.order.cpCashTxReport(
                        request: CpCashTxReportRequest(
                            txid: nil,
                            chainName: transferDomainState.selectedPayChain,
                            coinCode: transferDomainState.selectedSendCoinCode,
                            success: false,
                            message: failedMessage,
                            direction: "TRANSFER_OUT",
                            multisigWalletId: nil,
                            buyerSendAddress: activeAddress,
                            buyerRecvAddress: transferDraft.recipientAddress
                        )
                    )
                } catch {
                    log("normal 转账失败回写失败: \(error)")
                }
            }
            showToast(failedMessage, theme: .error)
            return false
        }
    }

    func loadReceiveSelectNetwork() async {
        setLoading("receive.selectNetwork", true)
        defer { setLoading("receive.selectNetwork", false) }

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
                    id: "proxy:\(item.chainName ?? UUID().uuidString)",
                    name: item.chainName ?? "-",
                    logoURL: item.chainLogo,
                    chainColor: item.chainColor ?? "#1677FF",
                    category: .proxySettlement,
                    allowChain: item,
                    isNormalChannel: false
                )
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
            clearError("receive.selectNetwork")
        } catch {
            setError("receive.selectNetwork", error)
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
        setLoading("receive.home", true)
        defer { setLoading("receive.home", false) }

        if receiveDomainState.selectedIsNormalChannel {
            individualTraceOrder = nil
            businessTraceOrder = nil
            individualTraceDetail = nil
            businessTraceDetail = nil
            receiveDomainState.individualOrderSN = nil
            receiveDomainState.businessOrderSN = nil
            receiveDomainState.receiveMinAmount = 0
            receiveDomainState.receiveMaxAmount = 0
            clearError("receive.home")
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
            clearError("receive.home")
        } catch {
            setError("receive.home", error)
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
            clearError("receive.detail")
        } catch {
            setError("receive.detail", error)
            log("收款详情刷新失败: \(error)")
        }
    }

    func loadReceiveAddresses(validity: ReceiveAddressValidityState) async {
        receiveDomainState.validityStatus = validity
        switch validity {
        case .valid:
            await loadReceiveHome()
        case .invalid:
            setLoading("receive.invalid", true)
            defer { setLoading("receive.invalid", false) }
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
                clearError("receive.invalid")
            } catch {
                setError("receive.invalid", error)
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
            clearError("receive.mark")
        } catch {
            setError("receive.mark", error)
            showToast("更新默认地址失败", theme: .error)
            log("更新默认收款地址失败: \(error)")
        }
    }

    func loadReceiveTraceChildren(orderSN: String, page: Int = 1, perPage: Int = 20) async {
        setLoading("receive.children", true)
        defer { setLoading("receive.children", false) }
        do {
            let pageData = try await backend.receive.traceChildren(orderSN: orderSN, page: page, perPage: perPage)
            receiveTraceChildren = pageData.data
            clearError("receive.children")
        } catch {
            setError("receive.children", error)
            log("收款记录加载失败: \(error)")
        }
    }

    func loadReceiveShare(orderSN: String) async {
        setLoading("receive.share", true)
        defer { setLoading("receive.share", false) }
        do {
            receiveShareDetail = try await backend.receive.receiveShare(orderSN: orderSN)
            clearError("receive.share")
        } catch {
            setError("receive.share", error)
            log("收款分享数据加载失败: \(error)")
        }
    }

    func loadReceiveExpiryConfig() async {
        do {
            let config = try await backend.settings.traceExpiryCollection()
            if !config.durations.isEmpty {
                receiveExpiryConfig = config
            }
            clearError("receive.expiry")
        } catch {
            setError("receive.expiry", error)
            log("收款地址有效期配置加载失败: \(error)")
        }
    }

    func updateReceiveExpiry(duration: Int) async {
        do {
            try await backend.settings.updateTraceExpiryMark(duration: duration)
            receiveExpiryConfig = ReceiveExpiryConfig(
                durations: receiveExpiryConfig.durations,
                selectedDuration: duration
            )
            showToast("有效期已更新", theme: .success)
            clearError("receive.expiry.update")
        } catch {
            setError("receive.expiry.update", error)
            showToast("有效期更新失败", theme: .error)
            log("收款地址有效期更新失败: \(error)")
        }
    }

    func createReceive(amountText: String, note: String, sendCoinCode: String, recvCoinCode: String) async {
        do {
            let amount = Double(amountText) ?? 0
            let result = try await backend.receive.createReceipt(
                request: CreateReceiptRequest(
                    recvAddress: activeAddress,
                    sendCoinCode: sendCoinCode,
                    recvCoinCode: recvCoinCode,
                    sendAmount: amount,
                    note: note
                )
            )
            lastCreatedReceiveOrderSN = result.orderSn ?? "-"
            log("收款单创建成功: order_sn=\(result.orderSn ?? "-")")
            receives = try await backend.receive.recentValidReceives(page: 1, perPage: 20)
            showToast("收款单创建成功", theme: .success)
        } catch {
            showToast("收款单创建失败", theme: .error)
            log("收款单创建失败: \(error)")
        }
    }

    func createTransferOrder(toAddress: String, amountText: String, note: String, sendCoinCode: String, recvCoinCode: String) async {
        guard isValidEvmAddress(toAddress) else {
            showToast("地址格式错误", theme: .error)
            log("转账地址格式错误: \(toAddress)")
            return
        }

        do {
            let amount = Double(amountText) ?? 0
            let result = try await backend.order.createPayment(
                request: CreatePaymentRequest(
                    recvAddress: toAddress,
                    sendCoinCode: sendCoinCode,
                    recvCoinCode: recvCoinCode,
                    sendAmount: amount,
                    note: note
                )
            )
            lastCreatedPaymentOrderSN = result.orderSn ?? "-"
            log("转账订单创建成功: order_sn=\(result.orderSn ?? "-")")
            showToast("转账订单创建成功", theme: .success)
        } catch {
            showToast("转账订单创建失败", theme: .error)
            log("转账订单创建失败: \(error)")
        }
    }

    func confirmAndPay(orderSN: String, toAddress: String, amountText: String) async {
        guard case .unlocked = approvalSessionState else {
            showToast("登录会话失效，请重新登录", theme: .error)
            log("发交易被拒绝: 会话未解锁")
            return
        }

        guard isValidEvmAddress(toAddress) else {
            showToast("地址格式错误", theme: .error)
            log("交易目标地址格式错误: \(toAddress)")
            return
        }

        do {
            let amountMinor = toMinorUnits(amountText: amountText, decimals: 6)
            let from = try securityService.activeAddress()
            let source = RequestSource.system(name: "wallet_transfer")

            let txHash = try securityService.signAndSendTransaction(
                SendTxRequest(
                    source: source,
                    from: from,
                    to: Address(toAddress),
                    value: amountMinor,
                    data: nil,
                    chainId: selectedChainId
                )
            )
            lastTxHash = txHash.value
            log("签名广播完成: tx=\(txHash.value), chain=\(selectedChainId)")

            try await backend.order.ship(orderSN: orderSN, txid: txHash.value, message: nil, success: true)
            log("订单回写成功: \(orderSN)")
            showToast("支付成功", theme: .success)
            await refreshOrdersOnly()
            await loadOrderDetail(orderSN: orderSN)
        } catch {
            showToast("交易失败", theme: .error)
            log("交易流程失败: \(error)")
            if !orderSN.isEmpty {
                do {
                    try await backend.order.ship(orderSN: orderSN, txid: nil, message: "iOS transaction failed", success: false)
                    log("失败状态已回写订单: \(orderSN)")
                } catch {
                    log("失败状态回写失败: \(error)")
                }
            }
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
        do {
            let detail = try await backend.order.detail(orderSN: orderSN)
            selectedOrderDetail = detail
            log("订单详情加载成功: \(detail.orderSn ?? orderSN)")
        } catch {
            log("订单详情加载失败: \(error)")
        }
    }

    func signOutToLogin() {
        isAuthenticated = false
        approvalSessionState = .locked
        backend.executor.clearToken()
        messageList = []
        homeRecentMessages = []
        addressBooks = []
        billList = []
        billAddressFilter = nil
        billAddressAggList = []
        receiveSelectNetworks = []
        receiveNormalNetworks = []
        receiveProxyNetworks = []
        receiveSelectedNetworkId = nil
        receiveDomainState = ReceiveDomainState()
        receiveRecentValid = []
        receiveRecentInvalid = []
        receiveTraceChildren = []
        individualTraceDetail = nil
        businessTraceDetail = nil
        transferSelectNetworks = []
        transferNormalNetworks = []
        transferProxyNetworks = []
        transferSelectedNetworkId = nil
        transferDomainState = TransferDomainState()
        transferDraft = TransferDraft()
        transferRecentContacts = []
    }

    func showInfoToast(_ message: String) {
        showToast(message, theme: .info)
    }

    #if DEBUG
    func cycleEnvironmentForDebug() {
        let next: EnvironmentConfig
        switch environment.tag {
        case .development:
            next = .staging
        case .staging:
            next = .production
        case .production:
            next = .development
        }
        environment = next
        backend = BackendAPI(environment: next)
        log("Debug 环境切换完成: \(next.tag.rawValue) -> \(next.baseURL.absoluteString)")
    }
    #endif

    private func performSignInFlow() async throws {
        let address = try securityService.activeAddress()
        let message = loginMessage(address: address.value)
        let source = RequestSource.system(name: "message_signature_login")

        let signature = try securityService.signPersonalMessage(
            SignMessageRequest(
                source: source,
                account: address,
                message: message,
                chainId: selectedChainId
            )
        )

        let token = try await backend.auth.signIn(
            signature: signature.value,
            address: address.value,
            message: message
        )
        log("登录成功，token 前缀: \(token.accessToken.prefix(14))...")
        isAuthenticated = true
        approvalSessionState = .unlocked(lastVerifiedAt: Date())
        loginErrorKind = nil
        showToast("登录成功", theme: .success)
        await refreshHomeData()
    }

    private func beginLoginFlow() -> Bool {
        let now = Date()
        if loginBusy {
            log("登录请求已忽略: 当前请求仍在执行")
            return false
        }
        if let cooldown = loginCooldownUntil, now < cooldown {
            log("登录请求已忽略: 2 秒防抖生效中")
            return false
        }
        loginBusy = true
        loginCooldownUntil = now.addingTimeInterval(2)
        loginErrorKind = nil
        return true
    }

    private func endLoginFlow() {
        loginBusy = false
    }

    private func handleLoginFailure(_ error: Error) {
        let kind = classifyLoginError(error)
        loginErrorKind = kind
        approvalSessionState = .locked
        isAuthenticated = false
        showToast(messageForLoginError(kind), theme: .error)
        log("登录失败[\(kind.rawValue)]: \(error)")
    }

    private func classifyLoginError(_ error: Error) -> LoginErrorKind {
        if let local = error as? LocalPasskeyError {
            switch local {
            case .biometricUnavailable, .biometricFailed, .accountNotFound:
                return .authFailed
            }
        }

        if let la = error as? LAError {
            switch la.code {
            case .userCancel, .systemCancel, .appCancel, .userFallback:
                return .rejectSign
            default:
                return .authFailed
            }
        }

        if let backendError = error as? BackendAPIError {
            switch backendError {
            case .unauthorized:
                return .authFailed
            case let .serverError(code, _):
                if code == 401 {
                    return .authFailed
                }
                return .networkFailed
            case .httpStatus, .invalidURL, .invalidEnvironmentHost, .emptyData:
                return .networkFailed
            }
        }

        if error is URLError {
            return .networkFailed
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return .networkFailed
        }

        let lowercased = String(describing: error).lowercased()
        if lowercased.contains("network") || lowercased.contains("timed out") || lowercased.contains("offline") {
            return .networkFailed
        }
        return .authFailed
    }

    private func messageForLoginError(_ kind: LoginErrorKind) -> String {
        switch kind {
        case .rejectSign:
            return "用户拒绝该请求"
        case .authFailed:
            return "身份验证失败"
        case .networkFailed:
            return "网络连接失败"
        }
    }

    private func showToast(_ message: String, theme: ToastTheme, duration: TimeInterval = 2) {
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

    private func loginMessage(address: String) -> String {
        let loginTime = Int(Date().timeIntervalSince1970 * 1000)
        let payload: [String: String] = [
            "address": address,
            "login_time": String(loginTime),
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]),
              let text = String(data: data, encoding: .utf8)
        else {
            return "{\"address\":\"\(address)\",\"login_time\":\"\(loginTime)\"}"
        }

        return text
    }

    private func configureTransferNetwork(_ item: TransferNetworkItem) {
        transferSelectedNetworkId = item.id
        transferDomainState.selectedNetworkName = item.name
        transferDomainState.selectedChainColor = item.chainColor
        transferDomainState.selectedIsNormalChannel = item.isNormalChannel
        transferDomainState.availablePairs = []
        transferDomainState.availableNormalCoins = []
        transferDomainState.selectedSellerId = nil
        transferDraft = TransferDraft(mode: item.isNormalChannel ? .normal : .proxy)

        if item.isNormalChannel {
            let activeChain = selectedChainId == 199 ? "BTT" : "BTT_TEST"
            transferDomainState.selectedPayChain = activeChain
            transferDomainState.selectedAddressRegex = ["^(0x|0X)?[a-fA-F0-9]{40}$"]
            let normalCoins = item.normalChain?.coins.filter { ($0.isSendAllowed ?? true) && ($0.isRecvAllowed ?? true) } ?? []
            transferDomainState.availableNormalCoins = normalCoins
            if let preferred = preferredTransferNormalCoin(from: normalCoins) {
                applyTransferNormalCoin(preferred)
            } else {
                transferDomainState.selectedSendCoinCode = "USDT_\(activeChain)"
                transferDomainState.selectedRecvCoinCode = "USDT_\(activeChain)"
                transferDomainState.selectedSendCoinName = "USDT"
                transferDomainState.selectedRecvCoinName = "USDT"
                transferDomainState.selectedCoinSymbol = "USDT"
                transferDomainState.selectedPairLabel = "USDT/USDT"
                transferDomainState.selectedCoinContract = nil
                transferDomainState.selectedCoinPrecision = 6
            }
            log("转账网络已选择: \(item.name) [In-App Channel]")
            return
        }

        let payChain = item.allowChain?.chainName ?? item.name
        transferDomainState.selectedPayChain = payChain
        transferDomainState.availablePairs = item.allowChain?.exchangePairs ?? []
        transferDomainState.selectedAddressRegex = item.allowChain?.chainAddressFormatRegex ?? []
        transferDomainState.selectedSellerId = nil

        if let pair = preferredTransferPair(from: item.allowChain) {
            applyTransferPair(pair)
        } else {
            transferDomainState.selectedPairLabel = "\(transferDomainState.selectedSendCoinName)/\(transferDomainState.selectedRecvCoinName)"
        }
        log("转账网络已选择: \(item.name) [Proxy Settlement]")
    }

    private func preferredTransferPair(from chain: ReceiveAllowChainItem?) -> AllowExchangePair? {
        guard let pairs = chain?.exchangePairs, !pairs.isEmpty else {
            return nil
        }
        if let usdtPair = pairs.first(where: {
            ($0.sendCoinSymbol ?? "").uppercased() == "USDT" && ($0.recvCoinSymbol ?? "").uppercased() == "USDT"
        }) {
            return usdtPair
        }
        return pairs.first
    }

    private func preferredTransferNormalCoin(from coins: [NormalAllowCoin]) -> NormalAllowCoin? {
        if let usdt = coins.first(where: {
            (($0.coinSymbol ?? "").uppercased() == "USDT") || (($0.coinName ?? "").uppercased() == "USDT")
        }) {
            return usdt
        }
        return coins.first
    }

    private func applyTransferPair(_ pair: AllowExchangePair) {
        transferDomainState.selectedSendCoinCode = pair.sendCoinCode ?? transferDomainState.selectedSendCoinCode
        transferDomainState.selectedRecvCoinCode = pair.recvCoinCode ?? transferDomainState.selectedRecvCoinCode
        transferDomainState.selectedSendCoinName = pair.sendCoinName ?? pair.sendCoinSymbol ?? transferDomainState.selectedSendCoinName
        transferDomainState.selectedRecvCoinName = pair.recvCoinName ?? pair.recvCoinSymbol ?? transferDomainState.selectedRecvCoinName
        transferDomainState.selectedCoinContract = pair.sendCoinContract ?? transferDomainState.selectedCoinContract
        transferDomainState.selectedCoinPrecision = pair.sendCoinPrecision ?? transferDomainState.selectedCoinPrecision
        transferDomainState.selectedCoinSymbol = pair.sendCoinSymbol ?? pair.sendCoinName ?? transferDomainState.selectedCoinSymbol
        let left = pair.sendCoinSymbol ?? pair.sendCoinName ?? transferDomainState.selectedSendCoinName
        let right = pair.recvCoinSymbol ?? pair.recvCoinName ?? transferDomainState.selectedRecvCoinName
        transferDomainState.selectedPairLabel = "\(left)/\(right)"
    }

    private func chainTotalBalance(_ pairs: [AllowExchangePair]) -> Double? {
        if pairs.isEmpty { return nil }
        var total = 0.0
        var hit = false
        for pair in pairs {
            if let number = pair.balance?.doubleValue {
                total += number
                hit = true
                continue
            }
            if let text = pair.balance?.stringValue, let value = Double(text) {
                total += value
                hit = true
            }
        }
        return hit ? total : nil
    }

    private func applyTransferNormalCoin(_ coin: NormalAllowCoin) {
        let chain = transferDomainState.selectedPayChain
        let coinCode = coin.coinCode ?? transferDomainState.selectedSendCoinCode
        transferDomainState.selectedSendCoinCode = coinCode
        transferDomainState.selectedRecvCoinCode = coinCode
        transferDomainState.selectedSendCoinName = coin.coinName ?? coin.coinSymbol ?? transferDomainState.selectedSendCoinName
        transferDomainState.selectedRecvCoinName = coin.coinName ?? coin.coinSymbol ?? transferDomainState.selectedRecvCoinName
        transferDomainState.selectedCoinContract = coin.coinContract
        transferDomainState.selectedCoinPrecision = coin.coinPrecision ?? transferDomainState.selectedCoinPrecision
        transferDomainState.selectedCoinSymbol = coin.coinSymbol ?? coin.coinName ?? transferDomainState.selectedCoinSymbol
        let symbol = coin.coinSymbol ?? coin.coinName ?? "USDT"
        transferDomainState.selectedPairLabel = "\(symbol)/\(symbol)"
        transferDomainState.selectedPayChain = coin.chainName ?? chain
        transferDomainState.selectedAddressRegex = ["^(0x|0X)?[a-fA-F0-9]{40}$"]
    }

    private func buildTransferRegex(_ rawPattern: String) -> NSRegularExpression? {
        let trimmed = rawPattern.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("/") && trimmed.hasSuffix("/") {
            let body = String(trimmed.dropFirst().dropLast())
            return try? NSRegularExpression(pattern: body, options: [])
        }
        return try? NSRegularExpression(pattern: trimmed, options: [])
    }

    private func resolveTransferOrderSN(_ result: CreatePaymentResult) async throws -> String {
        let knownOrderSN = result.orderSn?.trimmingCharacters(in: .whitespacesAndNewlines)
        let serial = result.serialNumber?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let serial, !serial.isEmpty else {
            if let knownOrderSN, !knownOrderSN.isEmpty {
                return knownOrderSN
            }
            throw BackendAPIError.emptyData
        }

        for attempt in 1 ... 3 {
            if Task.isCancelled {
                throw CancellationError()
            }
            try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            if Task.isCancelled {
                throw CancellationError()
            }
            let detail = try await backend.order.receivingShow(orderSN: serial)
            if detail.status == 1 {
                if let resolved = detail.orderSn, !resolved.isEmpty {
                    return resolved
                }
                if let knownOrderSN, !knownOrderSN.isEmpty {
                    return knownOrderSN
                }
            }
        }

        if let knownOrderSN, !knownOrderSN.isEmpty {
            return knownOrderSN
        }
        throw BackendAPIError.serverError(code: 0, message: "transfer order not ready")
    }

    private struct TransferExecutionContext {
        let mode: TransferPayMode
        let orderSN: String?
        let recipientAddress: String
        let amountText: String
        let tokenContract: String
        let coinPrecision: Int
        let coinCode: String
        let chainName: String
    }

    private func buildTransferExecutionContext() throws -> TransferExecutionContext {
        let trimmedAddress = transferDraft.recipientAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidTransferAddress(trimmedAddress) else {
            throw BackendAPIError.serverError(code: 0, message: "invalid recipient")
        }

        if transferDraft.mode == .proxy {
            guard let detail = transferDraft.orderDetail else {
                throw BackendAPIError.serverError(code: 0, message: "order detail missing")
            }
            let recipient = resolveProxyRecipientAddress(from: detail)
            guard isValidEvmAddress(recipient) else {
                throw BackendAPIError.serverError(code: 0, message: "invalid deposit address")
            }
            let amountText = decimalString(from: detail.sendAmount) ?? transferDraft.amountText
            let contract = detail.sendCoinContract ?? transferDomainState.selectedCoinContract ?? ""
            guard isValidEvmAddress(contract) else {
                throw BackendAPIError.serverError(code: 0, message: "invalid token contract")
            }
            let precision = detail.sendCoinPrecision ?? transferDomainState.selectedCoinPrecision
            let coinCode = detail.sendCoinCode ?? transferDomainState.selectedSendCoinCode
            let chainName = detail.sendChainName ?? transferDomainState.selectedPayChain
            return TransferExecutionContext(
                mode: .proxy,
                orderSN: transferDraft.orderSN,
                recipientAddress: recipient,
                amountText: amountText,
                tokenContract: contract,
                coinPrecision: precision,
                coinCode: coinCode,
                chainName: chainName
            )
        }

        let contract = transferDomainState.selectedCoinContract ?? ""
        guard isValidEvmAddress(contract) else {
            throw BackendAPIError.serverError(code: 0, message: "token contract missing")
        }
        return TransferExecutionContext(
            mode: .normal,
            orderSN: nil,
            recipientAddress: trimmedAddress,
            amountText: transferDraft.amountText,
            tokenContract: contract,
            coinPrecision: transferDomainState.selectedCoinPrecision,
            coinCode: transferDomainState.selectedSendCoinCode,
            chainName: transferDomainState.selectedPayChain
        )
    }

    private func resolveProxyRecipientAddress(from detail: OrderDetail) -> String {
        if detail.orderType == "PAYMENT_NORMAL", let receiveAddress = detail.receiveAddress, !receiveAddress.isEmpty {
            return receiveAddress
        }
        if let depositAddress = detail.depositAddress, !depositAddress.isEmpty {
            return depositAddress
        }
        return detail.receiveAddress ?? transferDraft.recipientAddress
    }

    private func decimalString(from value: JSONValue?) -> String? {
        guard let value else { return nil }
        switch value {
        case let .string(text):
            return text
        case let .number(number):
            return NSDecimalNumber(value: number).stringValue
        case let .bool(flag):
            return flag ? "1" : "0"
        case .object, .array, .null:
            return nil
        }
    }

    private func erc20TransferData(to: String, amountMinor: String) -> String? {
        let toHex = sanitizeHexAddress(to)
        guard toHex.count == 40 else { return nil }
        let amountHex = decimalToHex(amountMinor)
        guard !amountHex.isEmpty else { return nil }

        let method = "a9059cbb"
        let paddedTo = String(repeating: "0", count: 64 - toHex.count) + toHex
        let paddedAmount = String(repeating: "0", count: max(0, 64 - amountHex.count)) + amountHex
        return "0x\(method)\(paddedTo)\(paddedAmount)"
    }

    private func sanitizeHexAddress(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            return String(trimmed.dropFirst(2)).lowercased()
        }
        return trimmed.lowercased()
    }

    private func decimalToHex(_ decimalString: String) -> String {
        var number = decimalString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !number.isEmpty else { return "" }
        if number == "0" { return "0" }
        guard number.allSatisfy({ $0.isNumber }) else { return "" }

        var hexDigits = ""
        while number != "0" {
            var quotient = ""
            var remainder = 0
            for character in number {
                guard let digit = character.wholeNumberValue else { return "" }
                let accumulator = remainder * 10 + digit
                let q = accumulator / 16
                remainder = accumulator % 16
                if !quotient.isEmpty || q != 0 {
                    quotient.append(String(q))
                }
            }
            let hex = String(remainder, radix: 16)
            hexDigits = hex + hexDigits
            number = quotient.isEmpty ? "0" : quotient
        }
        return hexDigits
    }

    private func toMinorUnits(amountText: String, decimals: Int) -> String {
        guard let amountDecimal = Decimal(string: amountText), amountDecimal >= 0 else {
            return "0"
        }
        var multiplier = Decimal(1)
        for _ in 0 ..< decimals {
            multiplier *= 10
        }
        let scaled = amountDecimal * multiplier
        let normalized = NSDecimalNumber(decimal: scaled)
        return normalized.stringValue.components(separatedBy: ".").first ?? "0"
    }

    private func resolveTransferChainId(for chainName: String) -> Int {
        let normalized = chainName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let option = networkOptions.first(where: { $0.chainName.uppercased() == normalized }) {
            return option.chainId
        }
        if normalized == "BTT" || normalized.contains("BITTORRENT") {
            return 199
        }
        if normalized == "BTT_TEST" || normalized == "BTTTEST" || normalized.contains("BTT_TEST") || normalized.contains("TESTNET") {
            return 1029
        }
        return selectedChainId
    }

    private func isValidEvmAddress(_ value: String) -> Bool {
        let pattern = "^0x[a-fA-F0-9]{40}$"
        return value.range(of: pattern, options: .regularExpression) != nil
    }

    func billRangeForPreset(_ preset: BillPresetRange, selectedMonth: Date = Date()) -> BillTimeRange {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
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

    func errorMessage(_ key: String) -> String? {
        uiErrorMap[key]
    }

    private func computeLastPage(page: Int?, perPage: Int?, total: Int?) -> Bool {
        guard let page, let perPage, let total, perPage > 0 else {
            return false
        }
        return page * perPage >= total
    }

    private func setLoading(_ key: String, _ loading: Bool) {
        uiLoadingMap[key] = loading
    }

    private func setError(_ key: String, _ error: Error) {
        uiErrorMap[key] = simplifyError(error)
    }

    private func clearError(_ key: String) {
        uiErrorMap[key] = nil
    }

    private func simplifyError(_ error: Error) -> String {
        if let backendError = error as? BackendAPIError {
            switch backendError {
            case .unauthorized:
                return "登录状态失效，请重新登录"
            case .httpStatus:
                return "网络请求失败，请稍后重试"
            case let .serverError(_, message):
                return message
            case .invalidURL, .invalidEnvironmentHost, .emptyData:
                return "服务响应异常，请稍后重试"
            }
        }
        if error is URLError {
            return "网络连接失败"
        }
        let lowered = String(describing: error).lowercased()
        if lowered.contains("insufficient funds") || lowered.contains("gas required exceeds allowance") {
            return "余额不足或 Gas 不足"
        }
        if lowered.contains("token contract missing") || lowered.contains("invalid token contract") {
            return "币种配置异常，请重新选择网络后再试"
        }
        if lowered.contains("invalid recipient") || lowered.contains("invalid to address") {
            return "收款地址无效"
        }
        if lowered.contains("nonce too low") || lowered.contains("replacement transaction underpriced") {
            return "交易重复提交，请稍后重试"
        }
        if lowered.contains("user rejected") || lowered.contains("user deny") || lowered.contains("cancelled") {
            return "用户取消支付"
        }
        if lowered.contains("timeout") || lowered.contains("timed out") || lowered.contains("rpc") {
            return "链路繁忙，请稍后重试"
        }
        return "操作失败，请稍后重试"
    }

    private func transferPaymentFailureMessage(_ error: Error) -> String {
        let message = simplifyError(error)
        if message == "操作失败，请稍后重试" {
            return "支付失败，请稍后重试"
        }
        return message
    }

    private func fallbackNetworkOptions() -> [NetworkOption] {
        [
            NetworkOption(chainId: 199, chainName: "BTT", chainFullName: "BitTorrent Chain Mainnet", rpcURL: "https://rpc.bt.io/"),
            NetworkOption(chainId: 1029, chainName: "BTT_TEST", chainFullName: "BitTorrent Chain Testnet", rpcURL: "https://pre-rpc.bt.io/"),
        ]
    }

    private func restoreSelectedChain() {
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

    private func log(_ message: String) {
        logs.append("[\(Self.logTimeFormatter.string(from: Date()))] \(message)")
    }
}
