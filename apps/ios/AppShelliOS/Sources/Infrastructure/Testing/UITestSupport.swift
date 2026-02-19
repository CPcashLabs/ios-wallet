import BackendAPI
import CoreRuntime
import Foundation
import SecurityCore

enum UITestScenario: String, CaseIterable {
    case happy = "happy"
    case empty = "empty"
    case error = "error"
    case limitExceeded = "limitExceeded"
    case slowConfirm = "slowConfirm"
}

struct UITestLaunchOptions {
    let scenario: UITestScenario
    let skipLogin: Bool

    static func from(arguments: [String]) -> UITestLaunchOptions? {
        guard arguments.contains("--ui-testing") else {
            return nil
        }

        let scenario = parseScenario(arguments: arguments)
        let skipLogin = arguments.contains("--uitest-skip-login")
        return UITestLaunchOptions(scenario: scenario, skipLogin: skipLogin)
    }

    private static func parseScenario(arguments: [String]) -> UITestScenario {
        guard let raw = arguments.first(where: { $0.hasPrefix("--uitest-scenario=") })?
            .split(separator: "=", maxSplits: 1)
            .last
        else {
            return .happy
        }
        return UITestScenario(rawValue: String(raw)) ?? .happy
    }
}

@MainActor
enum UITestBootstrap {
    static func makeAppStore(arguments: [String]) -> AppStore? {
        guard let options = UITestLaunchOptions.from(arguments: arguments) else {
            return nil
        }

        let dependencies = AppDependencies.uiTest(scenario: options.scenario)
        let appState = AppState(dependencies: dependencies)

        if options.skipLogin {
            appState.isAuthenticated = true
            appState.approvalSessionState = .unlocked(lastVerifiedAt: Date())
        }

        return AppStore(appState: appState)
    }
}

extension AppDependencies {
    @MainActor
    static func uiTest(scenario: UITestScenario) -> AppDependencies {
        let backend = MockBackend(scenario: scenario)
        let passkey = MockPasskeyService()
        return AppDependencies(
            securityService: MockSecurityService(scenario: scenario),
            backendFactory: { _ in backend },
            passkeyService: passkey,
            clock: SystemAppClock(),
            idGenerator: UUIDAppIDGenerator(),
            logger: SilentAppLogger()
        )
    }
}

private final class InMemoryTokenStore: TokenStore {
    var accessToken: String?
    var refreshToken: String?
}

private final class MockBackend: BackendServing,
    AuthServicing,
    WalletServicing,
    ReceiveServicing,
    OrderServicing,
    MessageServicing,
    AddressBookServicing,
    ProfileServicing,
    BillServicing,
    SettingsServicing
{
    var auth: AuthServicing { self }
    var wallet: WalletServicing { self }
    var receive: ReceiveServicing { self }
    var order: OrderServicing { self }
    var message: MessageServicing { self }
    var addressBook: AddressBookServicing { self }
    var profile: ProfileServicing { self }
    var bill: BillServicing { self }
    var settings: SettingsServicing { self }

    let executor: RequestExecutor

    private let scenario: UITestScenario
    private let activeAddress = "0x1111111111111111111111111111111111111111"
    private let usdtContract = "0x2222222222222222222222222222222222222222"
    private let nowMillis = Int(Date().timeIntervalSince1970 * 1000)

    private var addressBookStore: [AddressBookItem]

    init(scenario: UITestScenario) {
        self.scenario = scenario
        executor = RequestExecutor(environment: .default, tokenStore: InMemoryTokenStore())
        addressBookStore = MockJSON.decode(
            [
                [
                    "id": 1,
                    "name": "Alice",
                    "wallet_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "chain_name": "BTT_TEST",
                    "chain_type": "EVM",
                    "logo": "",
                ],
                [
                    "id": 2,
                    "name": "Bob",
                    "wallet_address": "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                    "chain_name": "BTT_TEST",
                    "chain_type": "EVM",
                    "logo": "",
                ],
            ]
        )
    }

    // MARK: - AuthServicing

    func signIn(signature _: String, address _: String, message _: String) async throws -> SessionToken {
        SessionToken(accessToken: "mock-access-token", refreshToken: "mock-refresh-token")
    }

    func currentUser() async throws -> UserProfile {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock current-user failed")
        }
        return UserProfile(
            userId: 1,
            nickname: "UI Tester",
            walletAddress: activeAddress,
            email: "test@cpcash.dev",
            avatar: nil
        )
    }

    // MARK: - WalletServicing

    func coinList(chainName _: String?) async throws -> [CoinItem] {
        if scenario == .empty {
            return []
        }
        return MockJSON.decode(
            [
                [
                    "coin_code": "USDT_BTT_TEST",
                    "coin_name": "USDT",
                    "coin_symbol": "USDT",
                    "coin_price": 1,
                    "chain_name": "BTT_TEST",
                    "balance": "1024.56",
                    "coin_contract": usdtContract,
                    "coin_precision": 6,
                ],
            ]
        )
    }

    func chainList() async throws -> [ChainItem] {
        MockJSON.decode(
            [
                [
                    "chain_id": 1029,
                    "chain_name": "BTT_TEST",
                    "chain_full_name": "BitTorrent Chain Testnet",
                    "rpc_url": "https://pre-rpc.bt.io/",
                ],
            ]
        )
    }

    func networkOptions() async throws -> [NetworkOption] {
        [
            NetworkOption(chainId: 1029, chainName: "BTT_TEST", chainFullName: "BitTorrent Chain Testnet", rpcURL: "https://pre-rpc.bt.io/"),
            NetworkOption(chainId: 199, chainName: "BTT", chainFullName: "BitTorrent Chain Mainnet", rpcURL: "https://rpc.bt.io/"),
        ]
    }

    func recentTransferList() async throws -> [TransferItem] {
        if scenario == .empty {
            return []
        }
        return MockJSON.decode(
            [
                [
                    "order_sn": "TX-MOCK-1",
                    "created_at": nowMillis,
                    "send_amount": "10",
                    "recv_amount": "10",
                    "send_coin_name": "USDT",
                    "recv_coin_name": "USDT",
                    "status": 1,
                ],
            ]
        )
    }

    func recentTransferReceiveList(sendChainName _: String, recvChainName _: String) async throws -> [TransferReceiveContact] {
        if scenario == .empty {
            return []
        }
        return MockJSON.decode(
            [
                [
                    "address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "amount": 12.34,
                    "coin_name": "USDT",
                    "created_at": nowMillis,
                    "direction": "IN",
                    "wallet_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "avatar": "",
                ],
                [
                    "address": "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                    "amount": 9.87,
                    "coin_name": "USDT",
                    "created_at": nowMillis,
                    "direction": "IN",
                    "wallet_address": "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
                    "avatar": "",
                ],
            ]
        )
    }

    // MARK: - ReceiveServicing

    func createReceipt(request _: CreateReceiptRequest) async throws -> CreateReceiptResult {
        MockJSON.decode(["order_sn": "RECEIVE-CREATE-1", "serial_number": "SERIAL-RECEIVE-1", "status": 1])
    }

    func cpCashAllowList(query: AllowListQuery) async throws -> [ReceiveAllowChainItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock cp-cash-allow-list failed")
        }
        if scenario == .empty {
            return []
        }

        let pair: AllowExchangePair = MockJSON.decode(
            [
                "recv_chain_name": "BTT_TEST",
                "recv_coin_code": "USDT_BTT_TEST",
                "recv_coin_contract": usdtContract,
                "recv_coin_full_name": "Tether",
                "recv_coin_logo": "",
                "recv_coin_name": "USDT",
                "recv_coin_precision": 6,
                "recv_coin_symbol": "USDT",
                "send_chain_name": query.sendChainName ?? "TRON",
                "send_coin_code": "USDT_TRON",
                "send_coin_contract": usdtContract,
                "send_coin_full_name": "Tether",
                "send_coin_logo": "",
                "send_coin_name": "USDT",
                "send_coin_precision": 6,
                "send_coin_symbol": "USDT",
                "balance": 2000,
            ]
        )

        return [
            ReceiveAllowChainItem(
                chainName: query.sendChainName ?? "TRON",
                chainFullName: "Tron",
                chainLogo: nil,
                chainColor: "#1677FF",
                chainAddressFormatRegex: ["^0x[a-fA-F0-9]{40}$"],
                exchangePairs: [pair]
            ),
        ]
    }

    func normalAllowList(chainName _: String?, coinCode _: String?, isSendAllowed _: Bool?, isRecvAllowed _: Bool?, coinSymbol _: String?) async throws -> [NormalAllowChainItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock normal-allow-list failed")
        }

        let coin = MockJSON.decode(
            [
                "coin_code": "USDT_BTT_TEST",
                "coin_name": "USDT",
                "coin_full_name": "Tether",
                "coin_logo": "",
                "coin_contract": usdtContract,
                "coin_precision": 6,
                "coin_symbol": "USDT",
                "chain_name": "BTT_TEST",
                "chain_full_name": "BitTorrent Chain Testnet",
                "is_send_allowed": true,
                "is_recv_allowed": true,
                "min_amount": 1,
                "fee_amount": 0,
                "fee_value": 0,
            ],
            as: NormalAllowCoin.self
        )

        return [
            NormalAllowChainItem(
                chainName: "BTT_TEST",
                chainFullName: "BitTorrent Chain Testnet",
                chainLogo: nil,
                chainColor: "#1677FF",
                chainAddressFormatRegex: ["^0x[a-fA-F0-9]{40}$"],
                coins: [coin]
            ),
        ]
    }

    func normalAllowCoinShow(coinCode _: String) async throws -> NormalAllowCoin {
        MockJSON.decode(
            [
                "coin_code": "USDT_BTT_TEST",
                "coin_name": "USDT",
                "coin_full_name": "Tether",
                "coin_logo": "",
                "coin_contract": usdtContract,
                "coin_precision": 6,
                "coin_symbol": "USDT",
                "chain_name": "BTT_TEST",
                "chain_full_name": "BitTorrent Chain Testnet",
                "is_send_allowed": true,
                "is_recv_allowed": true,
                "min_amount": 1,
                "fee_amount": 0,
                "fee_value": 0,
            ],
            as: NormalAllowCoin.self
        )
    }

    func exchangeShow(sendCoinCode _: String, recvCoinCode _: String, rateType _: Int, env _: String) async throws -> ExchangeShowDetail {
        MockJSON.decode(
            [
                "send_coin_code": "USDT_TRON",
                "send_coin_name": "USDT",
                "send_min_amount": 1,
                "send_max_amount": 100000,
                "recv_coin_code": "USDT_BTT_TEST",
                "recv_coin_name": "USDT",
                "recv_min_amount": 10,
                "recv_max_amount": 1000,
                "recv_amount": 10,
                "seller_id": 100000001,
            ],
            as: ExchangeShowDetail.self
        )
    }

    func recentValidReceives(page _: Int, perPage _: Int) async throws -> [ReceiveRecord] {
        if scenario == .empty {
            return []
        }
        return MockJSON.decode(
            [
                [
                    "order_sn": "RECEIVE-1",
                    "address": activeAddress,
                    "amount": "10",
                    "coin_name": "USDT",
                    "created_at": nowMillis,
                    "expired_at": nowMillis + 86_400_000,
                ],
            ]
        )
    }

    func recentValidTraces(page _: Int, perPage _: Int, orderType: String) async throws -> [TraceOrderItem] {
        try await recentValidTraces(page: 1, perPage: 20, orderType: orderType, sendCoinCode: nil, recvCoinCode: nil, multisigWalletId: nil)
    }

    func recentValidTraces(page _: Int, perPage _: Int, orderType: String, sendCoinCode _: String?, recvCoinCode _: String?, multisigWalletId _: String?) async throws -> [TraceOrderItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock recent-valid-traces failed")
        }
        if scenario == .empty {
            return []
        }

        if orderType.uppercased().contains("LONG") {
            return [traceOrder(sn: "TRACE-BIZ-1", name: "经营地址", marked: false, longTerm: true)]
        }
        return [traceOrder(sn: "TRACE-IND-1", name: "个人地址", marked: true, longTerm: false)]
    }

    func recentInvalidTraces(page _: Int, perPage _: Int, orderType: String) async throws -> [TraceOrderItem] {
        try await recentInvalidTraces(page: 1, perPage: 20, orderType: orderType, sendCoinCode: nil, recvCoinCode: nil, multisigWalletId: nil)
    }

    func recentInvalidTraces(page _: Int, perPage _: Int, orderType _: String, sendCoinCode _: String?, recvCoinCode _: String?, multisigWalletId _: String?) async throws -> [TraceOrderItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock recent-invalid-traces failed")
        }
        if scenario == .empty {
            return []
        }
        return [traceOrder(sn: "TRACE-INVALID-1", name: "失效地址", marked: false, longTerm: false)]
    }

    func traceChildren(orderSN _: String, page _: Int, perPage _: Int) async throws -> PagedResponse<TraceChildItem> {
        let children: [TraceChildItem] = MockJSON.decode(
            [
                [
                    "order_sn": "TRACE-CHILD-1",
                    "status": 1,
                    "receive_address": activeAddress,
                    "send_actual_amount": "10",
                    "recv_actual_amount": "10",
                    "created_at": nowMillis,
                ],
            ]
        )
        return PagedResponse(data: children, total: children.count, page: 1, perPage: 20)
    }

    func createShortTrace(request _: CreateTraceRequest) async throws -> CreateReceiptResult {
        if scenario == .limitExceeded {
            throw BackendAPIError.serverError(code: 60018, message: "mock trace limit reached")
        }
        return MockJSON.decode(["order_sn": "TRACE-IND-NEW", "serial_number": "TRACE-IND-SERIAL", "status": 1])
    }

    func createLongTrace(request _: CreateTraceRequest) async throws -> CreateReceiptResult {
        if scenario == .limitExceeded {
            throw BackendAPIError.serverError(code: 60018, message: "mock trace limit reached")
        }
        return MockJSON.decode(["order_sn": "TRACE-BIZ-NEW", "serial_number": "TRACE-BIZ-SERIAL", "status": 1])
    }

    func traceShow(orderSN: String) async throws -> TraceShowDetail {
        MockJSON.decode(
            [
                "order_sn": orderSN,
                "status": 1,
                "deposit_address": activeAddress,
                "payment_address": activeAddress,
                "receive_address": activeAddress,
                "send_coin_code": "USDT_TRON",
                "recv_coin_code": "USDT_BTT_TEST",
                "send_chain_name": "TRON",
                "recv_chain_name": "BTT_TEST",
                "send_coin_name": "USDT",
                "recv_coin_name": "USDT",
                "recv_amount": "10",
                "recv_min_amount": "10",
                "recv_max_amount": "1000",
                "address_remarks_name": "Mock Address",
                "is_rare_address": 0,
                "created_at": nowMillis,
                "expired_at": nowMillis + 86_400_000,
                "order_type": orderSN.contains("BIZ") ? "TRACE_LONG_TERM" : "TRACE",
            ],
            as: TraceShowDetail.self
        )
    }

    func markTraceOrder(orderSN _: String, sendCoinCode _: String, recvCoinCode _: String, orderType _: String) async throws {}

    func receiveShare(orderSN: String) async throws -> ReceiveOrderDetail {
        MockJSON.decode(
            [
                "order_sn": orderSN,
                "serial_number": "SHARE-SERIAL-1",
                "status": 1,
                "deposit_address": activeAddress,
                "receive_address": activeAddress,
                "send_coin_code": "USDT_TRON",
                "recv_coin_code": "USDT_BTT_TEST",
                "send_amount": "10",
                "recv_amount": "10",
            ],
            as: ReceiveOrderDetail.self
        )
    }

    func limitCount(orderType _: String, sendCoinCode _: String, recvCoinCode _: String) async throws -> Int {
        switch scenario {
        case .happy:
            return 5
        case .empty:
            return 5
        case .error:
            throw BackendAPIError.serverError(code: 500, message: "mock limit-count failed")
        case .limitExceeded:
            return 5
        case .slowConfirm:
            return 5
        }
    }

    func editAddressInfo(orderSN _: String, remarkName _: String, address _: String) async throws {}

    // MARK: - OrderServicing

    func createPayment(request _: CreatePaymentRequest) async throws -> CreatePaymentResult {
        MockJSON.decode(["order_sn": "PAYMENT-ORDER-1", "serial_number": "PAYMENT-SERIAL-1", "status": 1])
    }

    func receivingShow(orderSN: String) async throws -> ReceiveOrderDetail {
        MockJSON.decode(
            [
                "order_sn": orderSN,
                "serial_number": orderSN,
                "status": 1,
                "deposit_address": activeAddress,
                "receive_address": activeAddress,
                "send_coin_code": "USDT_BTT_TEST",
                "recv_coin_code": "USDT_BTT_TEST",
                "send_amount": "10",
                "recv_amount": "10",
            ],
            as: ReceiveOrderDetail.self
        )
    }

    func ship(orderSN _: String, txid _: String?, message _: String?, success _: Bool) async throws {}

    func cpCashTxReport(request _: CpCashTxReportRequest) async throws -> CpCashTxReportResult {
        MockJSON.decode(["order_sn": "PAYMENT-NORMAL-REPORT-1", "duplicated": false, "status": 1])
    }

    func list(page _: Int, perPage _: Int, address _: String?) async throws -> OrderListResponse {
        if scenario == .empty {
            return OrderListResponse(data: [], total: 0, page: 1)
        }

        let rows: [OrderSummary] = MockJSON.decode(
            [
                [
                    "order_sn": "ORDER-1",
                    "order_type": "PAYMENT",
                    "status": 1,
                    "send_amount": "10",
                    "recv_amount": "10",
                    "send_coin_name": "USDT",
                    "recv_coin_name": "USDT",
                    "payment_address": activeAddress,
                    "receive_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "avatar": "",
                    "created_at": nowMillis,
                ],
            ]
        )
        return OrderListResponse(data: rows, total: rows.count, page: 1)
    }

    func detail(orderSN: String) async throws -> OrderDetail {
        MockJSON.decode(
            [
                "order_sn": orderSN,
                "status": 1,
                "order_type": "PAYMENT",
                "receive_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                "payment_address": activeAddress,
                "deposit_address": activeAddress,
                "transfer_address": activeAddress,
                "send_amount": "10",
                "send_actual_amount": "10",
                "send_estimate_amount": "10",
                "send_fee_amount": "0",
                "send_actual_fee_amount": "0",
                "send_estimate_fee_amount": "0",
                "recv_amount": "10",
                "recv_actual_amount": "10",
                "recv_estimate_amount": "10",
                "send_coin_code": "USDT_BTT_TEST",
                "recv_coin_code": "USDT_BTT_TEST",
                "send_coin_name": "USDT",
                "recv_coin_name": "USDT",
                "send_coin_contract": usdtContract,
                "send_coin_precision": 6,
                "send_chain_name": "BTT_TEST",
                "recv_chain_name": "BTT_TEST",
                "is_buyer": true,
                "txid": "0x3333333333333333333333333333333333333333333333333333333333333333",
                "created_at": nowMillis,
                "recv_actual_received_at": nowMillis,
                "note": "mock detail",
            ],
            as: OrderDetail.self
        )
    }

    // MARK: - MessageServicing

    func list(page: Int, perPage: Int) async throws -> PagedResponse<MessageItem> {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock message-list failed")
        }
        if scenario == .empty {
            return PagedResponse(data: [], total: 0, page: page, perPage: perPage)
        }
        let rows: [MessageItem] = MockJSON.decode(
            [
                [
                    "id": 1,
                    "type": "ORDER",
                    "title": "订单已完成",
                    "content": "你的订单已完成",
                    "is_read": false,
                    "order_sn": "ORDER-1",
                    "multisig_wallet_id": 0,
                    "created_at": nowMillis,
                    "avatar": "",
                ],
                [
                    "id": 2,
                    "type": "SYSTEM",
                    "title": "欢迎使用",
                    "content": "欢迎来到 AppShell",
                    "is_read": true,
                    "order_sn": "",
                    "multisig_wallet_id": 0,
                    "created_at": nowMillis - 60_000,
                    "avatar": "",
                ],
            ]
        )
        return PagedResponse(data: rows, total: rows.count, page: page, perPage: perPage)
    }

    func markRead(id _: String) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock mark-read failed")
        }
    }

    func markAllRead() async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock mark-all-read failed")
        }
    }

    // MARK: - AddressBookServicing

    func list() async throws -> [AddressBookItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock addressbook-list failed")
        }
        return addressBookStore
    }

    func create(request: AddressBookUpsertRequest) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock addressbook-create failed")
        }
        let newID = (addressBookStore.compactMap(\.id).max() ?? 0) + 1
        let item: AddressBookItem = MockJSON.decode(
            [
                "id": newID,
                "name": request.name,
                "wallet_address": request.walletAddress,
                "chain_name": "BTT_TEST",
                "chain_type": request.chainType,
                "logo": "",
            ]
        )
        addressBookStore.append(item)
    }

    func update(id: String, request: AddressBookUpsertRequest) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock addressbook-update failed")
        }
        guard let idValue = Int(id), let index = addressBookStore.firstIndex(where: { $0.id == idValue }) else {
            return
        }
        addressBookStore[index] = MockJSON.decode(
            [
                "id": idValue,
                "name": request.name,
                "wallet_address": request.walletAddress,
                "chain_name": "BTT_TEST",
                "chain_type": request.chainType,
                "logo": "",
            ]
        )
    }

    func delete(id: String) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock addressbook-delete failed")
        }
        guard let idValue = Int(id) else { return }
        addressBookStore.removeAll { $0.id == idValue }
    }

    // MARK: - ProfileServicing

    func update(request _: ProfileUpdateRequest) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock profile-update failed")
        }
    }

    func uploadAvatar(fileData _: Data, fileName _: String, mimeType _: String) async throws -> UploadFileResult {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock upload-avatar failed")
        }
        return UploadFileResult(url: "https://example.com/mock-avatar.png")
    }

    // MARK: - BillServicing

    func list(filter: BillFilter) async throws -> PagedResponse<OrderSummary> {
        if scenario == .empty {
            return PagedResponse(data: [], total: 0, page: filter.page, perPage: filter.perPage)
        }

        let rows: [OrderSummary] = MockJSON.decode(
            [
                [
                    "order_sn": "BILL-1",
                    "order_type": "PAYMENT",
                    "status": 1,
                    "send_amount": "10",
                    "recv_amount": "10",
                    "send_coin_name": "USDT",
                    "recv_coin_name": "USDT",
                    "payment_address": activeAddress,
                    "receive_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "avatar": "",
                    "created_at": nowMillis,
                ],
            ]
        )
        return PagedResponse(data: rows, total: rows.count, page: filter.page, perPage: filter.perPage)
    }

    func statAllAddressPage(range _: BillTimeRange, page: Int, perPage: Int) async throws -> PagedResponse<BillAddressAggregateItem> {
        if scenario == .empty {
            return PagedResponse(data: [], total: 0, page: page, perPage: perPage)
        }

        let rows: [BillAddressAggregateItem] = MockJSON.decode(
            [
                [
                    "adversary_address": "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                    "payment_amount": "30",
                    "receipt_amount": "20",
                    "avatar": "",
                    "name": "Alice",
                ],
            ]
        )
        return PagedResponse(data: rows, total: rows.count, page: page, perPage: perPage)
    }

    func statAllAddressStat(range _: BillTimeRange) async throws -> BillStatisticsSummary {
        MockJSON.decode(
            [
                "payment_amount": "100",
                "receipt_amount": "80",
                "fee": "1.2",
                "transactions": 8,
            ],
            as: BillStatisticsSummary.self
        )
    }

    // MARK: - SettingsServicing

    func exchangeRateByUSD() async throws -> [ExchangeRateItem] {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock exchange-rate failed")
        }
        return MockJSON.decode(
            [
                [
                    "currency": "USD",
                    "value": "1",
                    "symbol": "$",
                ],
            ]
        )
    }

    func setTransferEmailNotify(enable _: Bool) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock transfer-notify failed")
        }
    }

    func setRewardEmailNotify(enable _: Bool) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock reward-notify failed")
        }
    }

    func setReceiptEmailNotify(enable _: Bool) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock receipt-notify failed")
        }
    }

    func setBackupWalletNotify(enable _: Bool) async throws {
        if scenario == .error {
            throw BackendAPIError.serverError(code: 500, message: "mock backup-notify failed")
        }
    }

    func traceExpiryCollection() async throws -> ReceiveExpiryConfig {
        ReceiveExpiryConfig(durations: [24, 72, 168], selectedDuration: 72)
    }

    func updateTraceExpiryMark(duration _: Int) async throws {}

    // MARK: - Fixtures

    private func traceOrder(sn: String, name: String, marked: Bool, longTerm: Bool) -> TraceOrderItem {
        MockJSON.decode(
            [
                "order_sn": sn,
                "status": 1,
                "address": activeAddress,
                "deposit_address": activeAddress,
                "payment_address": activeAddress,
                "receive_address": activeAddress,
                "send_coin_code": longTerm ? "USDT_TRON" : "USDT_BTT_TEST",
                "recv_coin_code": "USDT_BTT_TEST",
                "send_chain_name": longTerm ? "TRON" : "BTT_TEST",
                "recv_chain_name": "BTT_TEST",
                "send_coin_name": "USDT",
                "recv_coin_name": "USDT",
                "recv_amount": "10",
                "recv_min_amount": "10",
                "recv_max_amount": "1000",
                "address_remarks_name": name,
                "is_rare_address": longTerm ? 1 : 0,
                "created_at": nowMillis,
                "expired_at": nowMillis + 86_400_000,
                "is_marked": marked,
                "order_type": longTerm ? "TRACE_LONG_TERM" : "TRACE",
            ],
            as: TraceOrderItem.self
        )
    }
}

@MainActor
private final class MockPasskeyService: PasskeyServing {
    private var accountList: [LocalPasskeyAccount] = [
        LocalPasskeyAccount(
            rawId: "mock-passkey-1",
            displayName: "Mock User",
            privateKeyHex: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            address: "0x1111111111111111111111111111111111111111",
            createdAt: Date()
        ),
    ]

    func accounts() -> [LocalPasskeyAccount] {
        accountList
    }

    func register(displayName: String) async throws -> LocalPasskeyAccount {
        let account = LocalPasskeyAccount(
            rawId: "mock-passkey-\(accountList.count + 1)",
            displayName: displayName.isEmpty ? "Mock User" : displayName,
            privateKeyHex: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
            address: "0x1111111111111111111111111111111111111111",
            createdAt: Date()
        )
        accountList.insert(account, at: 0)
        return account
    }

    func login(rawId: String?) async throws -> LocalPasskeyAccount {
        if let rawId, let account = accountList.first(where: { $0.rawId == rawId }) {
            return account
        }
        guard let first = accountList.first else {
            throw LocalPasskeyError.accountNotFound
        }
        return first
    }

    func updateAddress(rawId: String, address: String) throws {
        guard let index = accountList.firstIndex(where: { $0.rawId == rawId }) else {
            throw LocalPasskeyError.accountNotFound
        }
        let old = accountList[index]
        accountList[index] = LocalPasskeyAccount(
            rawId: old.rawId,
            displayName: old.displayName,
            privateKeyHex: old.privateKeyHex,
            address: address,
            createdAt: old.createdAt
        )
    }
}

private struct MockSecurityService: SecurityServing {
    private let scenario: UITestScenario
    private let address = Address("0x1111111111111111111111111111111111111111")

    init(scenario: UITestScenario) {
        self.scenario = scenario
    }

    func createAccount() throws -> Address {
        address
    }

    func importAccount(_: EncryptedImportBlob) throws -> Address {
        address
    }

    func activeAddress() throws -> Address {
        address
    }

    func signPersonalMessage(_: SignMessageRequest) throws -> Signature {
        Signature("0xmock-signature")
    }

    func signTypedData(_: SignTypedDataRequest) throws -> Signature {
        Signature("0xmock-typed-signature")
    }

    func signAndSendTransaction(_: SendTxRequest) throws -> TxHash {
        TxHash("0x3333333333333333333333333333333333333333333333333333333333333333")
    }

    func waitForTransactionConfirmation(_ req: WaitTxConfirmationRequest) async throws -> TxConfirmation {
        if scenario == .slowConfirm {
            try await Task.sleep(nanoseconds: 2_000_000_000)
        }
        return TxConfirmation(txHash: req.txHash, blockNumber: 1, status: 1)
    }
}

private enum MockJSON {
    static func decode<T: Decodable>(_ object: Any, as type: T.Type = T.self) -> T {
        do {
            let data = try JSONSerialization.data(withJSONObject: object)
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Mock decode failed for \(T.self): \(error)")
        }
    }
}
