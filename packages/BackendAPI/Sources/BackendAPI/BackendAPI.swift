import Foundation

public protocol AuthServicing {
    func signIn(signature: String, address: String, message: String) async throws -> SessionToken
    func currentUser() async throws -> UserProfile
}

public protocol WalletServicing {
    func coinList(chainName: String?) async throws -> [CoinItem]
    func chainList() async throws -> [ChainItem]
    func networkOptions() async throws -> [NetworkOption]
    func recentTransferList() async throws -> [TransferItem]
    func recentTransferReceiveList(sendChainName: String, recvChainName: String) async throws -> [TransferReceiveContact]
}

public protocol ReceiveServicing {
    func createReceipt(request: CreateReceiptRequest) async throws -> CreateReceiptResult
    func cpCashAllowList(query: AllowListQuery) async throws -> [ReceiveAllowChainItem]
    func normalAllowList(chainName: String?, coinCode: String?, isSendAllowed: Bool?, isRecvAllowed: Bool?, coinSymbol: String?) async throws -> [NormalAllowChainItem]
    func normalAllowCoinShow(coinCode: String) async throws -> NormalAllowCoin
    func exchangeShow(sendCoinCode: String, recvCoinCode: String, rateType: Int, env: String) async throws -> ExchangeShowDetail
    func recentValidReceives(page: Int, perPage: Int) async throws -> [ReceiveRecord]
    func recentValidTraces(page: Int, perPage: Int, orderType: String) async throws -> [TraceOrderItem]
    func recentValidTraces(page: Int, perPage: Int, orderType: String, sendCoinCode: String?, recvCoinCode: String?, multisigWalletId: String?) async throws -> [TraceOrderItem]
    func recentInvalidTraces(page: Int, perPage: Int, orderType: String) async throws -> [TraceOrderItem]
    func recentInvalidTraces(page: Int, perPage: Int, orderType: String, sendCoinCode: String?, recvCoinCode: String?, multisigWalletId: String?) async throws -> [TraceOrderItem]
    func traceChildren(orderSN: String, page: Int, perPage: Int) async throws -> PagedResponse<TraceChildItem>
    func createShortTrace(request: CreateTraceRequest) async throws -> CreateReceiptResult
    func createLongTrace(request: CreateTraceRequest) async throws -> CreateReceiptResult
    func traceShow(orderSN: String) async throws -> TraceShowDetail
    func markTraceOrder(orderSN: String, sendCoinCode: String, recvCoinCode: String, orderType: String) async throws
    func receiveShare(orderSN: String) async throws -> ReceiveOrderDetail
}

public protocol OrderServicing {
    func createPayment(request: CreatePaymentRequest) async throws -> CreatePaymentResult
    func receivingShow(orderSN: String) async throws -> ReceiveOrderDetail
    func ship(orderSN: String, txid: String?, message: String?, success: Bool) async throws
    func cpCashTxReport(request: CpCashTxReportRequest) async throws -> CpCashTxReportResult
    func list(page: Int, perPage: Int, address: String?) async throws -> OrderListResponse
    func detail(orderSN: String) async throws -> OrderDetail
}

public protocol MessageServicing {
    func list(page: Int, perPage: Int) async throws -> PagedResponse<MessageItem>
    func markRead(id: String) async throws
    func markAllRead() async throws
}

public protocol AddressBookServicing {
    func list() async throws -> [AddressBookItem]
    func create(request: AddressBookUpsertRequest) async throws
    func update(id: String, request: AddressBookUpsertRequest) async throws
    func delete(id: String) async throws
}

public protocol ProfileServicing {
    func update(request: ProfileUpdateRequest) async throws
    func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> UploadFileResult
}

public protocol BillServicing {
    func list(filter: BillFilter) async throws -> PagedResponse<OrderSummary>
    func statAllAddressPage(range: BillTimeRange, page: Int, perPage: Int) async throws -> PagedResponse<BillAddressAggregateItem>
    func statAllAddressStat(range: BillTimeRange) async throws -> BillStatisticsSummary
}

public protocol SettingsServicing {
    func exchangeRateByUSD() async throws -> [ExchangeRateItem]
    func setTransferEmailNotify(enable: Bool) async throws
    func setRewardEmailNotify(enable: Bool) async throws
    func setReceiptEmailNotify(enable: Bool) async throws
    func setBackupWalletNotify(enable: Bool) async throws
    func traceExpiryCollection() async throws -> ReceiveExpiryConfig
    func updateTraceExpiryMark(duration: Int) async throws
}

public struct CreateReceiptRequest: Hashable, Sendable {
    public let recvAddress: String
    public let sendCoinCode: String
    public let recvCoinCode: String
    public let sendAmount: Double
    public let note: String

    public init(recvAddress: String, sendCoinCode: String, recvCoinCode: String, sendAmount: Double, note: String) {
        self.recvAddress = recvAddress
        self.sendCoinCode = sendCoinCode
        self.recvCoinCode = recvCoinCode
        self.sendAmount = sendAmount
        self.note = note
    }
}

public struct AllowListQuery: Hashable, Sendable {
    public let groupByType: Int
    public let recvCoinSymbol: String
    public let sendCoinSymbol: String
    public let sendChainName: String?
    public let recvChainName: String?
    public let env: String?

    public init(
        groupByType: Int,
        recvCoinSymbol: String,
        sendCoinSymbol: String,
        sendChainName: String? = nil,
        recvChainName: String? = nil,
        env: String? = nil
    ) {
        self.groupByType = groupByType
        self.recvCoinSymbol = recvCoinSymbol
        self.sendCoinSymbol = sendCoinSymbol
        self.sendChainName = sendChainName
        self.recvChainName = recvChainName
        self.env = env
    }
}

public struct CreatePaymentRequest: Hashable, Sendable {
    public let recvAddress: String
    public let sendCoinCode: String
    public let recvCoinCode: String
    public let sendAmount: Double
    public let note: String

    public init(recvAddress: String, sendCoinCode: String, recvCoinCode: String, sendAmount: Double, note: String) {
        self.recvAddress = recvAddress
        self.sendCoinCode = sendCoinCode
        self.recvCoinCode = recvCoinCode
        self.sendAmount = sendAmount
        self.note = note
    }
}

public struct CpCashTxReportRequest: Hashable, Sendable {
    public let txid: String?
    public let chainName: String
    public let coinCode: String
    public let success: Bool
    public let message: String?
    public let direction: String?
    public let multisigWalletId: String?
    public let buyerSendAddress: String?
    public let buyerRecvAddress: String?

    public init(
        txid: String?,
        chainName: String,
        coinCode: String,
        success: Bool,
        message: String? = nil,
        direction: String? = nil,
        multisigWalletId: String? = nil,
        buyerSendAddress: String? = nil,
        buyerRecvAddress: String? = nil
    ) {
        self.txid = txid
        self.chainName = chainName
        self.coinCode = coinCode
        self.success = success
        self.message = message
        self.direction = direction
        self.multisigWalletId = multisigWalletId
        self.buyerSendAddress = buyerSendAddress
        self.buyerRecvAddress = buyerRecvAddress
    }
}

public final class BackendAPI {
    public let auth: AuthServicing
    public let wallet: WalletServicing
    public let receive: ReceiveServicing
    public let order: OrderServicing
    public let message: MessageServicing
    public let addressBook: AddressBookServicing
    public let profile: ProfileServicing
    public let bill: BillServicing
    public let settings: SettingsServicing
    public let executor: RequestExecutor

    public init(environment: EnvironmentConfig = .default, tokenStore: TokenStore = KeychainTokenStore()) {
        let executor = RequestExecutor(environment: environment, tokenStore: tokenStore)
        self.executor = executor
        auth = AuthService(executor: executor)
        wallet = WalletService(executor: executor)
        receive = ReceiveService(executor: executor)
        order = OrderService(executor: executor)
        message = MessageService(executor: executor)
        addressBook = AddressBookService(executor: executor)
        profile = ProfileService(executor: executor)
        bill = BillService(executor: executor)
        settings = SettingsService(executor: executor)
    }
}

private struct AuthService: AuthServicing {
    let executor: RequestExecutor

    func signIn(signature: String, address: String, message: String) async throws -> SessionToken {
        let envelope: APIEnvelope<SessionToken> = try await executor.request(
            method: .POST,
            path: "/api/auth/oauth2/token",
            formBody: [
                "client_id": "MEMBER",
                "client_secret": "123456",
                "grant_type": "message_signature",
                "signature": signature,
                "address": address,
                "message": message,
            ],
            requiresAuth: false
        )

        guard let token = envelope.data else {
            throw BackendAPIError.emptyData
        }

        executor.saveToken(token)
        return token
    }

    func currentUser() async throws -> UserProfile {
        let envelope: APIEnvelope<UserProfile> = try await executor.request(
            method: .GET,
            path: "/api/system/member/security/current"
        )
        guard let profile = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return profile
    }
}

private struct WalletService: WalletServicing {
    let executor: RequestExecutor

    func coinList(chainName: String? = nil) async throws -> [CoinItem] {
        var query: [URLQueryItem] = []
        if let chainName, !chainName.isEmpty {
            query.append(URLQueryItem(name: "chain_name", value: chainName))
        }
        let envelope: APIEnvelope<[CoinItem]> = try await executor.request(
            method: .GET,
            path: "/api/blockchain/member/coin/list",
            query: query
        )
        return envelope.data ?? []
    }

    func chainList() async throws -> [ChainItem] {
        let envelope: APIEnvelope<[ChainItem]> = try await executor.request(
            method: .GET,
            path: "/api/blockchain/member/chain/list"
        )
        return envelope.data ?? []
    }

    func networkOptions() async throws -> [NetworkOption] {
        let chains = try await chainList()
        let bttMain = chains.first { ($0.chainName ?? "").uppercased() == "BTT" }
        let bttTest = chains.first { ($0.chainName ?? "").uppercased().contains("BTT_TEST") || ($0.chainName ?? "").uppercased().contains("TEST") }
        var options: [NetworkOption] = []
        if let bttMain {
            options.append(
                NetworkOption(
                    chainId: 199,
                    chainName: bttMain.chainName ?? "BTT",
                    chainFullName: bttMain.chainFullName ?? "BitTorrent Chain Mainnet",
                    rpcURL: "https://rpc.bt.io/"
                )
            )
        }
        if let bttTest {
            options.append(
                NetworkOption(
                    chainId: 1029,
                    chainName: bttTest.chainName ?? "BTT_TEST",
                    chainFullName: bttTest.chainFullName ?? "BitTorrent Chain Testnet",
                    rpcURL: "https://pre-rpc.bt.io/"
                )
            )
        }
        if options.isEmpty {
            options = [
                NetworkOption(chainId: 199, chainName: "BTT", chainFullName: "BitTorrent Chain Mainnet", rpcURL: "https://rpc.bt.io/"),
                NetworkOption(chainId: 1029, chainName: "BTT_TEST", chainFullName: "BitTorrent Chain Testnet", rpcURL: "https://pre-rpc.bt.io/")
            ]
        }
        return options
    }

    func recentTransferList() async throws -> [TransferItem] {
        let envelope: APIEnvelope<[TransferItem]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/recent-transfer-list-v2"
        )
        return envelope.data ?? []
    }

    func recentTransferReceiveList(sendChainName: String, recvChainName: String) async throws -> [TransferReceiveContact] {
        let envelope: APIEnvelope<[TransferReceiveContact]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/recent-transfer-receive-list",
            query: [
                URLQueryItem(name: "send_chain_name", value: sendChainName),
                URLQueryItem(name: "recv_chain_name", value: recvChainName),
            ]
        )
        return envelope.data ?? []
    }
}

private struct ReceiveService: ReceiveServicing {
    let executor: RequestExecutor

    func cpCashAllowList(query: AllowListQuery) async throws -> [ReceiveAllowChainItem] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "group_by_type", value: String(query.groupByType)),
            URLQueryItem(name: "recv_coin_symbol", value: query.recvCoinSymbol),
            URLQueryItem(name: "send_coin_symbol", value: query.sendCoinSymbol),
        ]
        if let sendChainName = query.sendChainName, !sendChainName.isEmpty {
            queryItems.append(URLQueryItem(name: "send_chain_name", value: sendChainName))
        }
        if let recvChainName = query.recvChainName, !recvChainName.isEmpty {
            queryItems.append(URLQueryItem(name: "recv_chain_name", value: recvChainName))
        }
        if let env = query.env, !env.isEmpty {
            queryItems.append(URLQueryItem(name: "env", value: env))
        }

        let envelope: APIEnvelope<[ReceiveAllowChainItem]> = try await executor.request(
            method: .GET,
            path: "/api/seller/member/exchange/cp-cash-allow-list",
            query: queryItems
        )
        return envelope.data ?? []
    }

    func normalAllowList(chainName: String?, coinCode: String?, isSendAllowed: Bool?, isRecvAllowed: Bool?, coinSymbol: String?) async throws -> [NormalAllowChainItem] {
        var query: [URLQueryItem] = []
        if let isSendAllowed {
            query.append(URLQueryItem(name: "is_send_allowed", value: isSendAllowed ? "true" : "false"))
        }
        if let isRecvAllowed {
            query.append(URLQueryItem(name: "is_recv_allowed", value: isRecvAllowed ? "true" : "false"))
        }
        if let chainName, !chainName.isEmpty {
            query.append(URLQueryItem(name: "chain_name", value: chainName))
        }
        if let coinCode, !coinCode.isEmpty {
            query.append(URLQueryItem(name: "coin_code", value: coinCode))
        }
        if let coinSymbol, !coinSymbol.isEmpty {
            query.append(URLQueryItem(name: "coin_symbol", value: coinSymbol))
        }

        let envelope: APIEnvelope<[NormalAllowChainItem]> = try await executor.request(
            method: .GET,
            path: "/api/system/member/coinallow/allow-list",
            query: query
        )
        return envelope.data ?? []
    }

    func normalAllowCoinShow(coinCode: String) async throws -> NormalAllowCoin {
        let envelope: APIEnvelope<NormalAllowCoin> = try await executor.request(
            method: .GET,
            path: "/api/system/member/coinallow/show",
            query: [URLQueryItem(name: "coin_code", value: coinCode)]
        )
        guard let coin = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return coin
    }

    func exchangeShow(sendCoinCode: String, recvCoinCode: String, rateType: Int, env: String) async throws -> ExchangeShowDetail {
        let envelope: APIEnvelope<ExchangeShowDetail> = try await executor.request(
            method: .GET,
            path: "/api/seller/member/exchange/cp-cash-show",
            query: [
                URLQueryItem(name: "send_coin_code", value: sendCoinCode),
                URLQueryItem(name: "recv_coin_code", value: recvCoinCode),
                URLQueryItem(name: "rate_type", value: String(rateType)),
                URLQueryItem(name: "env", value: env),
            ]
        )
        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func createReceipt(request: CreateReceiptRequest) async throws -> CreateReceiptResult {
        let endpoint = request.sendAmount > 0
            ? "/api/order/member/receiving/create-receipt-fixed"
            : "/api/order/member/receiving/create-receipt"

        let envelope: APIEnvelope<CreateReceiptResult> = try await executor.request(
            method: .POST,
            path: endpoint,
            jsonBody: [
                "recv_address": .string(request.recvAddress),
                "send_coin_code": .string(request.sendCoinCode),
                "recv_coin_code": .string(request.recvCoinCode),
                "send_amount": .number(request.sendAmount),
                "note": .string(request.note),
            ]
        )

        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func recentValidReceives(page: Int, perPage: Int) async throws -> [ReceiveRecord] {
        let envelope: APIEnvelope<[ReceiveRecord]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/recent-valid-receive-page-v2",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage)),
            ]
        )
        return envelope.data ?? []
    }

    func recentValidTraces(page: Int, perPage: Int, orderType: String) async throws -> [TraceOrderItem] {
        try await recentValidTraces(
            page: page,
            perPage: perPage,
            orderType: orderType,
            sendCoinCode: nil,
            recvCoinCode: nil,
            multisigWalletId: nil
        )
    }

    func recentValidTraces(page: Int, perPage: Int, orderType: String, sendCoinCode: String?, recvCoinCode: String?, multisigWalletId: String?) async throws -> [TraceOrderItem] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "order_type", value: orderType),
        ]
        if let sendCoinCode, !sendCoinCode.isEmpty {
            query.append(URLQueryItem(name: "send_coin_code", value: sendCoinCode))
        }
        if let recvCoinCode, !recvCoinCode.isEmpty {
            query.append(URLQueryItem(name: "recv_coin_code", value: recvCoinCode))
        }
        if let multisigWalletId, !multisigWalletId.isEmpty {
            query.append(URLQueryItem(name: "multisig_wallet_id", value: multisigWalletId))
        }

        let envelope: APIEnvelope<[TraceOrderItem]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/recent-valid-trace-page",
            query: query
        )
        return envelope.data ?? []
    }

    func recentInvalidTraces(page: Int, perPage: Int, orderType: String) async throws -> [TraceOrderItem] {
        try await recentInvalidTraces(
            page: page,
            perPage: perPage,
            orderType: orderType,
            sendCoinCode: nil,
            recvCoinCode: nil,
            multisigWalletId: nil
        )
    }

    func recentInvalidTraces(page: Int, perPage: Int, orderType: String, sendCoinCode: String?, recvCoinCode: String?, multisigWalletId: String?) async throws -> [TraceOrderItem] {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "order_type", value: orderType),
        ]
        if let sendCoinCode, !sendCoinCode.isEmpty {
            query.append(URLQueryItem(name: "send_coin_code", value: sendCoinCode))
        }
        if let recvCoinCode, !recvCoinCode.isEmpty {
            query.append(URLQueryItem(name: "recv_coin_code", value: recvCoinCode))
        }
        if let multisigWalletId, !multisigWalletId.isEmpty {
            query.append(URLQueryItem(name: "multisig_wallet_id", value: multisigWalletId))
        }

        let envelope: APIEnvelope<[TraceOrderItem]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/recent-invalid-trace-page",
            query: query
        )
        return envelope.data ?? []
    }

    func traceChildren(orderSN: String, page: Int, perPage: Int) async throws -> PagedResponse<TraceChildItem> {
        let envelope: APIEnvelope<[TraceChildItem]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/trace-child-page",
            query: [
                URLQueryItem(name: "order_sn", value: orderSN),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage)),
            ]
        )
        return PagedResponse(
            data: envelope.data ?? [],
            total: envelope.total,
            page: envelope.page,
            perPage: envelope.perPage
        )
    }

    func createShortTrace(request: CreateTraceRequest) async throws -> CreateReceiptResult {
        let envelope: APIEnvelope<CreateReceiptResult> = try await executor.request(
            method: .POST,
            path: "/api/order/member/receiving/create-trace-v2",
            jsonBody: traceBody(request)
        )
        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func createLongTrace(request: CreateTraceRequest) async throws -> CreateReceiptResult {
        let envelope: APIEnvelope<CreateReceiptResult> = try await executor.request(
            method: .POST,
            path: "/api/order/member/receiving/create-trace-long-term-v2",
            jsonBody: traceBody(request)
        )
        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func traceShow(orderSN: String) async throws -> TraceShowDetail {
        let envelope: APIEnvelope<TraceShowDetail> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/trace-show/\(orderSN)"
        )
        guard let detail = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return detail
    }

    func markTraceOrder(orderSN: String, sendCoinCode: String, recvCoinCode: String, orderType: String) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .POST,
            path: "/api/order/member/order/mark-trace-order",
            formBody: [
                "order_sn": orderSN,
                "send_coin_code": sendCoinCode,
                "recv_coin_code": recvCoinCode,
                "order_type": orderType,
            ]
        )
    }

    func receiveShare(orderSN: String) async throws -> ReceiveOrderDetail {
        let envelope: APIEnvelope<ReceiveOrderDetail> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/receive-share-show-v2/\(orderSN)"
        )

        guard let detail = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return detail
    }

    private func traceBody(_ request: CreateTraceRequest) -> [String: JSONValue] {
        var payload: [String: JSONValue] = [
            "recv_address": .string(request.recvAddress),
            "send_coin_code": .string(request.sendCoinCode),
            "recv_coin_code": .string(request.recvCoinCode),
            "recv_amount": .number(request.recvAmount),
            "note": .string(request.note),
        ]
        if let sellerId = request.sellerId {
            payload["seller_id"] = .number(Double(sellerId))
        }
        if let env = request.env, !env.isEmpty {
            payload["env"] = .string(env)
        }
        if let multisigWalletId = request.multisigWalletId, !multisigWalletId.isEmpty {
            payload["multisig_wallet_id"] = .string(multisigWalletId)
        }
        return payload
    }
}

private struct OrderService: OrderServicing {
    let executor: RequestExecutor

    func createPayment(request: CreatePaymentRequest) async throws -> CreatePaymentResult {
        let envelope: APIEnvelope<CreatePaymentResult> = try await executor.request(
            method: .POST,
            path: "/api/order/member/receiving/create-payment",
            jsonBody: [
                "recv_address": .string(request.recvAddress),
                "send_coin_code": .string(request.sendCoinCode),
                "recv_coin_code": .string(request.recvCoinCode),
                "send_amount": .number(request.sendAmount),
                "note": .string(request.note),
                "env": .string("dev"),
            ]
        )

        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func receivingShow(orderSN: String) async throws -> ReceiveOrderDetail {
        let envelope: APIEnvelope<ReceiveOrderDetail> = try await executor.request(
            method: .GET,
            path: "/api/order/member/receiving/show-v2/\(orderSN)"
        )

        guard let detail = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return detail
    }

    func ship(orderSN: String, txid: String?, message: String?, success: Bool) async throws {
        var payload: [String: JSONValue] = [
            "success": .bool(success),
        ]
        if let txid, !txid.isEmpty {
            payload["txid"] = .string(txid)
        }
        if let message, !message.isEmpty {
            payload["message"] = .string(message)
        }
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: "/api/order/member/order/cp-cash-ship/\(orderSN)",
            jsonBody: payload
        )
    }

    func cpCashTxReport(request: CpCashTxReportRequest) async throws -> CpCashTxReportResult {
        var payload: [String: JSONValue] = [
            "chain_name": .string(request.chainName),
            "coin_code": .string(request.coinCode),
            "success": .bool(request.success),
        ]
        if let txid = request.txid, !txid.isEmpty {
            payload["txid"] = .string(txid)
        }
        if let message = request.message, !message.isEmpty {
            payload["message"] = .string(message)
        }
        if let direction = request.direction, !direction.isEmpty {
            payload["direction"] = .string(direction)
        }
        if let multisigWalletId = request.multisigWalletId, !multisigWalletId.isEmpty {
            payload["multisig_wallet_id"] = .string(multisigWalletId)
        }
        if let buyerSendAddress = request.buyerSendAddress, !buyerSendAddress.isEmpty {
            payload["buyer_send_address"] = .string(buyerSendAddress)
        }
        if let buyerRecvAddress = request.buyerRecvAddress, !buyerRecvAddress.isEmpty {
            payload["buyer_recv_address"] = .string(buyerRecvAddress)
        }

        let envelope: APIEnvelope<CpCashTxReportResult> = try await executor.request(
            method: .POST,
            path: "/api/order/member/order/cp-cash-tx-report",
            jsonBody: payload
        )
        guard let result = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return result
    }

    func list(page: Int, perPage: Int, address: String?) async throws -> OrderListResponse {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "other_address", value: address),
        ].compactMap { item in
            guard let value = item.value else { return nil }
            if value.isEmpty { return nil }
            return item
        }

        let envelope: APIEnvelope<[OrderSummary]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/cp-cash-page",
            query: queryItems
        )

        return OrderListResponse(data: envelope.data ?? [], total: envelope.total, page: envelope.page)
    }

    func detail(orderSN: String) async throws -> OrderDetail {
        let envelope: APIEnvelope<OrderDetail> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/cp-cash-show/\(orderSN)"
        )

        guard let detail = envelope.data else {
            throw BackendAPIError.emptyData
        }

        return detail
    }
}

private struct MessageService: MessageServicing {
    let executor: RequestExecutor

    func list(page: Int, perPage: Int) async throws -> PagedResponse<MessageItem> {
        let envelope: APIEnvelope<[MessageItem]> = try await executor.request(
            method: .GET,
            path: "/api/system/member/message/order-page",
            query: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage)),
            ]
        )
        return PagedResponse(
            data: envelope.data ?? [],
            total: envelope.total,
            page: envelope.page,
            perPage: envelope.perPage
        )
    }

    func markRead(id: String) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: "/api/system/member/message/read/\(id)",
            jsonBody: ["id": .string(id)]
        )
    }

    func markAllRead() async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: "/api/system/member/message/read-all"
        )
    }
}

private struct AddressBookService: AddressBookServicing {
    let executor: RequestExecutor

    func list() async throws -> [AddressBookItem] {
        let envelope: APIEnvelope<[AddressBookItem]> = try await executor.request(
            method: .GET,
            path: "/api/system/member/address-book/list"
        )
        return envelope.data ?? []
    }

    func create(request: AddressBookUpsertRequest) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .POST,
            path: "/api/system/member/address-book/create",
            jsonBody: [
                "name": .string(request.name),
                "wallet_address": .string(request.walletAddress),
                "chain_type": .string(request.chainType),
            ]
        )
    }

    func update(id: String, request: AddressBookUpsertRequest) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: "/api/system/member/address-book/update/\(id)",
            jsonBody: [
                "name": .string(request.name),
                "wallet_address": .string(request.walletAddress),
                "chain_type": .string(request.chainType),
            ]
        )
    }

    func delete(id: String) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .DELETE,
            path: "/api/system/member/address-book/delete/\(id)"
        )
    }
}

private struct ProfileService: ProfileServicing {
    let executor: RequestExecutor

    func update(request: ProfileUpdateRequest) async throws {
        var payload: [String: JSONValue] = [:]
        if let nickname = request.nickname, !nickname.isEmpty {
            payload["nickname"] = .string(nickname)
        }
        if let avatar = request.avatar, !avatar.isEmpty {
            payload["avatar"] = .string(avatar)
        }
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: "/api/system/member/security/update",
            jsonBody: payload
        )
    }

    func uploadAvatar(fileData: Data, fileName: String, mimeType: String) async throws -> UploadFileResult {
        let responseData = try await executor.rawMultipartRequest(
            method: .POST,
            path: "/api/system/member/storage/upload-file",
            fileFieldName: "file",
            fileName: fileName,
            mimeType: mimeType,
            fileData: fileData,
            formFields: [:]
        )
        if let envelope = try? JSONDecoder().decode(APIEnvelope<UploadFileResult>.self, from: responseData),
           let result = envelope.data,
           let url = result.url?.trimmingCharacters(in: .whitespacesAndNewlines),
           !url.isEmpty
        {
            return UploadFileResult(url: url)
        }

        guard let object = (try? JSONSerialization.jsonObject(with: responseData)) as? [String: Any] else {
            throw BackendAPIError.serverError(code: -1, message: "Invalid upload response")
        }

        if let code = object["code"] as? Int, code != 200,
           let message = object["message"] as? String
        {
            throw BackendAPIError.serverError(code: code, message: message)
        }

        if let data = object["data"] as? [String: Any] {
            if let url = data["url"] as? String, !url.isEmpty {
                return UploadFileResult(url: url)
            }
            if let path = data["path"] as? String, !path.isEmpty {
                return UploadFileResult(url: path)
            }
            if let fileURL = data["file_url"] as? String, !fileURL.isEmpty {
                return UploadFileResult(url: fileURL)
            }
        }
        throw BackendAPIError.emptyData
    }
}

private struct BillService: BillServicing {
    let executor: RequestExecutor

    func list(filter: BillFilter) async throws -> PagedResponse<OrderSummary> {
        var query: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(filter.page)),
            URLQueryItem(name: "per_page", value: String(filter.perPage)),
        ]
        if let value = filter.orderType, !value.isEmpty {
            query.append(URLQueryItem(name: "order_type", value: value))
        }
        if let value = filter.otherAddress, !value.isEmpty {
            query.append(URLQueryItem(name: "other_address", value: value))
        }
        for value in filter.orderTypeList where !value.isEmpty {
            query.append(URLQueryItem(name: "order_type_list", value: value))
        }
        for id in filter.categoryIds {
            query.append(URLQueryItem(name: "category_ids", value: String(id)))
        }
        if let range = filter.range {
            query.append(URLQueryItem(name: "started_at", value: range.startedAt))
            query.append(URLQueryItem(name: "ended_at", value: range.endedAt))
            if let startedTimestamp = range.startedTimestamp {
                query.append(URLQueryItem(name: "started_timestamp", value: String(startedTimestamp)))
            }
            if let endedTimestamp = range.endedTimestamp {
                query.append(URLQueryItem(name: "ended_timestamp", value: String(endedTimestamp)))
            }
        }

        let envelope: APIEnvelope<[OrderSummary]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/cp-cash-page",
            query: query
        )

        return PagedResponse(
            data: envelope.data ?? [],
            total: envelope.total,
            page: envelope.page,
            perPage: envelope.perPage
        )
    }

    func statAllAddressPage(range: BillTimeRange, page: Int, perPage: Int) async throws -> PagedResponse<BillAddressAggregateItem> {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "started_at", value: range.startedAt),
            URLQueryItem(name: "ended_at", value: range.endedAt),
            URLQueryItem(name: "started_timestamp", value: range.startedTimestamp.map(String.init)),
            URLQueryItem(name: "ended_timestamp", value: range.endedTimestamp.map(String.init)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
        ].compactMap { item in
            guard let value = item.value else { return nil }
            if value.isEmpty { return nil }
            return item
        }

        let envelope: APIEnvelope<[BillAddressAggregateItem]> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/stat-All-address-page",
            query: query
        )

        return PagedResponse(
            data: envelope.data ?? [],
            total: envelope.total,
            page: envelope.page,
            perPage: envelope.perPage
        )
    }

    func statAllAddressStat(range: BillTimeRange) async throws -> BillStatisticsSummary {
        let query: [URLQueryItem] = [
            URLQueryItem(name: "started_at", value: range.startedAt),
            URLQueryItem(name: "ended_at", value: range.endedAt),
            URLQueryItem(name: "started_timestamp", value: range.startedTimestamp.map(String.init)),
            URLQueryItem(name: "ended_timestamp", value: range.endedTimestamp.map(String.init)),
        ].compactMap { item in
            guard let value = item.value else { return nil }
            if value.isEmpty { return nil }
            return item
        }

        let envelope: APIEnvelope<BillStatisticsSummary> = try await executor.request(
            method: .GET,
            path: "/api/order/member/order/stat-All-address-stat",
            query: query
        )

        guard let summary = envelope.data else {
            throw BackendAPIError.emptyData
        }
        return summary
    }
}

private struct SettingsService: SettingsServicing {
    let executor: RequestExecutor

    private struct TraceExpireOption: Codable {
        let expireDuration: Int?
        let systemDefault: Bool?
        let userMarked: Bool?

        enum CodingKeys: String, CodingKey {
            case expireDuration = "expire_duration"
            case systemDefault = "system_default"
            case userMarked = "user_marked"
        }
    }

    func exchangeRateByUSD() async throws -> [ExchangeRateItem] {
        let envelope: APIEnvelope<[ExchangeRateItem]> = try await executor.request(
            method: .GET,
            path: "/api/system/member/french-currency/exchange-rate-by-usd"
        )
        return envelope.data ?? []
    }

    func setTransferEmailNotify(enable: Bool) async throws {
        try await setSwitch(path: "/api/system/member/security/transfer-email-notify-enable/\(enable)", enable: enable)
    }

    func setRewardEmailNotify(enable: Bool) async throws {
        try await setSwitch(path: "/api/system/member/security/reward-email-notify-enable/\(enable)", enable: enable)
    }

    func setReceiptEmailNotify(enable: Bool) async throws {
        try await setSwitch(path: "/api/system/member/security/receipt-email-notify-enable/\(enable)", enable: enable)
    }

    func setBackupWalletNotify(enable: Bool) async throws {
        try await setSwitch(path: "/api/system/member/security/backup-wallet-notify-enable/\(enable)", enable: enable)
    }

    func traceExpiryCollection() async throws -> ReceiveExpiryConfig {
        let envelope: APIEnvelope<[TraceExpireOption]> = try await executor.request(
            method: .GET,
            path: "/api/system/member/config/trace-order-expire-duration-collection"
        )

        let values = envelope.data ?? []
        let durations = Array(Set(values.compactMap(\.expireDuration))).sorted()
        let selectedDuration = values.first(where: { $0.userMarked == true })?.expireDuration
            ?? values.first(where: { $0.systemDefault == true })?.expireDuration
            ?? durations.first
        return ReceiveExpiryConfig(durations: durations, selectedDuration: selectedDuration)
    }

    func updateTraceExpiryMark(duration: Int) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .POST,
            path: "/api/system/member/config/trace-order-expire-duration-mark",
            formBody: [
                "expire_duration": String(duration),
            ]
        )
    }

    private func setSwitch(path: String, enable: Bool) async throws {
        let _: APIEnvelope<JSONValue> = try await executor.request(
            method: .PUT,
            path: path,
            jsonBody: ["enable": .bool(enable)]
        )
    }
}
