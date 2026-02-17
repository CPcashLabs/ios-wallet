import Foundation

public enum JSONValue: Hashable, Codable, Sendable, CustomStringConvertible {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value):
            try container.encode(value)
        case let .number(value):
            try container.encode(value)
        case let .bool(value):
            try container.encode(value)
        case let .object(value):
            try container.encode(value)
        case let .array(value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    public var description: String {
        switch self {
        case let .string(value):
            return value
        case let .number(value):
            if value.rounded() == value {
                return String(Int(value))
            }
            return String(value)
        case let .bool(value):
            return value ? "true" : "false"
        case let .object(value):
            if let data = try? JSONEncoder().encode(value), let text = String(data: data, encoding: .utf8) {
                return text
            }
            return "{}"
        case let .array(value):
            if let data = try? JSONEncoder().encode(value), let text = String(data: data, encoding: .utf8) {
                return text
            }
            return "[]"
        case .null:
            return "null"
        }
    }

    public var stringValue: String? {
        switch self {
        case let .string(value): return value
        case let .number(value): return String(value)
        case let .bool(value): return value ? "true" : "false"
        case .object, .array, .null: return nil
        }
    }

    public var intValue: Int? {
        switch self {
        case let .number(value): return Int(value)
        case let .string(value): return Int(value)
        default: return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case let .number(value): return value
        case let .string(value): return Double(value)
        default: return nil
        }
    }

    public var objectValue: [String: JSONValue]? {
        guard case let .object(value) = self else { return nil }
        return value
    }

    public var arrayValue: [JSONValue]? {
        guard case let .array(value) = self else { return nil }
        return value
    }
}

public struct APIEnvelope<T: Decodable>: Decodable {
    public let code: Int
    public let message: String?
    public let data: T?
    public let page: Int?
    public let perPage: Int?
    public let total: Int?

    enum CodingKeys: String, CodingKey {
        case code
        case message
        case data
        case page
        case perPage = "per_page"
        case total
    }
}

public enum BackendAPIError: Error, CustomStringConvertible {
    case invalidURL
    case invalidEnvironmentHost(expected: String, actual: String)
    case unauthorized
    case httpStatus(Int)
    case serverError(code: Int, message: String)
    case emptyData

    public var description: String {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case let .invalidEnvironmentHost(expected, actual):
            return "Invalid backend host. expected=\(expected), actual=\(actual)"
        case .unauthorized:
            return "Unauthorized (401)"
        case let .httpStatus(code):
            return "HTTP status error: \(code)"
        case let .serverError(code, message):
            return "Server error: [\(code)] \(message)"
        case .emptyData:
            return "Response missing required data field"
        }
    }
}

public struct SessionToken: Hashable, Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

public struct UserProfile: Hashable, Codable, Sendable {
    public let userId: Int?
    public let nickname: String?
    public let walletAddress: String?
    public let email: String?
    public let avatar: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nickname
        case walletAddress = "wallet_address"
        case email
        case avatar
    }

    public init(userId: Int?, nickname: String?, walletAddress: String?, email: String?, avatar: String?) {
        self.userId = userId
        self.nickname = nickname
        self.walletAddress = walletAddress
        self.email = email
        self.avatar = avatar
    }
}

public struct CoinItem: Hashable, Decodable, Sendable {
    public let code: String?
    public let coinCode: String?
    public let coinName: String?
    public let coinSymbol: String?
    public let fullName: String?
    public let coinLogo: String?
    public let coinPrice: Double?
    public let chainName: String?
    public let chainFullName: String?
    public let chainLogo: String?
    public let contract: String?
    public let precision: Int?
    public let balance: JSONValue?

    enum CodingKeys: String, CodingKey {
        case code
        case coinCode = "coin_code"
        case name
        case coinName = "coin_name"
        case coinSymbol = "coin_symbol"
        case symbol
        case fullName = "full_name"
        case coinLogo = "coin_logo"
        case logo
        case coinPrice = "coin_price"
        case price
        case chainName = "chain_name"
        case chainFullName = "chain_full_name"
        case chainLogo = "chain_logo"
        case contract
        case precision
        case balance
    }

    public init(
        code: String?,
        coinCode: String?,
        coinName: String?,
        coinSymbol: String?,
        fullName: String?,
        coinLogo: String?,
        coinPrice: Double?,
        chainName: String?,
        chainFullName: String?,
        chainLogo: String?,
        contract: String?,
        precision: Int?,
        balance: JSONValue?
    ) {
        self.code = code
        self.coinCode = coinCode
        self.coinName = coinName
        self.coinSymbol = coinSymbol
        self.fullName = fullName
        self.coinLogo = coinLogo
        self.coinPrice = coinPrice
        self.chainName = chainName
        self.chainFullName = chainFullName
        self.chainLogo = chainLogo
        self.contract = contract
        self.precision = precision
        self.balance = balance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        code = try container.decodeIfPresent(String.self, forKey: .code)
        coinCode = try container.decodeIfPresent(String.self, forKey: .coinCode)
        let primaryName = try container.decodeIfPresent(String.self, forKey: .coinName)
        let fallbackName = try container.decodeIfPresent(String.self, forKey: .name)
        coinName = primaryName ?? fallbackName
        let primarySymbol = try container.decodeIfPresent(String.self, forKey: .coinSymbol)
        let fallbackSymbol = try container.decodeIfPresent(String.self, forKey: .symbol)
        coinSymbol = primarySymbol ?? fallbackSymbol
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName)
        let primaryLogo = try container.decodeIfPresent(String.self, forKey: .coinLogo)
        let fallbackLogo = try container.decodeIfPresent(String.self, forKey: .logo)
        coinLogo = primaryLogo ?? fallbackLogo
        if let value = try container.decodeIfPresent(Double.self, forKey: .coinPrice) {
            coinPrice = value
        } else if let value = try container.decodeIfPresent(Double.self, forKey: .price) {
            coinPrice = value
        } else if let text = try container.decodeIfPresent(String.self, forKey: .coinPrice), let value = Double(text) {
            coinPrice = value
        } else if let text = try container.decodeIfPresent(String.self, forKey: .price), let value = Double(text) {
            coinPrice = value
        } else {
            coinPrice = nil
        }
        chainName = try container.decodeIfPresent(String.self, forKey: .chainName)
        chainFullName = try container.decodeIfPresent(String.self, forKey: .chainFullName)
        chainLogo = try container.decodeIfPresent(String.self, forKey: .chainLogo)
        contract = try container.decodeIfPresent(String.self, forKey: .contract)
        precision = try container.decodeIfPresent(Int.self, forKey: .precision)
        balance = try container.decodeIfPresent(JSONValue.self, forKey: .balance)
    }
}

public struct ChainItem: Hashable, Codable, Sendable {
    public let chainName: String?
    public let chainFullName: String?

    enum CodingKeys: String, CodingKey {
        case chainName = "chain_name"
        case chainFullName = "chain_full_name"
    }
}

public struct TransferItem: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let createdAt: Int?
    public let sendAmount: JSONValue?
    public let recvAmount: JSONValue?
    public let sendCoinName: String?
    public let recvCoinName: String?
    public let status: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case createdAt = "created_at"
        case sendAmount = "send_amount"
        case recvAmount = "recv_amount"
        case sendCoinName = "send_coin_name"
        case recvCoinName = "recv_coin_name"
        case status
    }
}

public struct TransferReceiveContact: Hashable, Codable, Sendable {
    public let address: String?
    public let amount: Double?
    public let coinName: String?
    public let createdAt: Int?
    public let direction: String?
    public let walletAddress: String?
    public let avatar: String?

    enum CodingKeys: String, CodingKey {
        case address
        case amount
        case coinName = "coin_name"
        case createdAt = "created_at"
        case direction
        case walletAddress = "wallet_address"
        case avatar
    }
}

public struct ReceiveRecord: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let address: String?
    public let amount: JSONValue?
    public let coinName: String?
    public let createdAt: Int?
    public let expiredAt: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case address
        case amount
        case coinName = "coin_name"
        case createdAt = "created_at"
        case expiredAt = "expired_at"
    }
}

public struct OrderListResponse: Hashable, Codable, Sendable {
    public let data: [OrderSummary]
    public let total: Int?
    public let page: Int?

    public init(data: [OrderSummary], total: Int?, page: Int?) {
        self.data = data
        self.total = total
        self.page = page
    }
}

public struct OrderSummary: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let orderType: String?
    public let status: Int?
    public let sendAmount: JSONValue?
    public let recvAmount: JSONValue?
    public let sendCoinName: String?
    public let recvCoinName: String?
    public let paymentAddress: String?
    public let receiveAddress: String?
    public let avatar: String?
    public let createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case orderType = "order_type"
        case status
        case sendAmount = "send_amount"
        case recvAmount = "recv_amount"
        case sendCoinName = "send_coin_name"
        case recvCoinName = "recv_coin_name"
        case paymentAddress = "payment_address"
        case receiveAddress = "receive_address"
        case avatar
        case createdAt = "created_at"
    }
}

public struct OrderDetail: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let status: Int?
    public let orderType: String?
    public let receiveAddress: String?
    public let paymentAddress: String?
    public let depositAddress: String?
    public let transferAddress: String?
    public let sendAmount: JSONValue?
    public let sendActualAmount: JSONValue?
    public let sendEstimateAmount: JSONValue?
    public let sendFeeAmount: JSONValue?
    public let sendActualFeeAmount: JSONValue?
    public let sendEstimateFeeAmount: JSONValue?
    public let recvAmount: JSONValue?
    public let recvActualAmount: JSONValue?
    public let recvEstimateAmount: JSONValue?
    public let sendCoinCode: String?
    public let recvCoinCode: String?
    public let sendCoinName: String?
    public let recvCoinName: String?
    public let sendCoinContract: String?
    public let sendCoinPrecision: Int?
    public let sendChainName: String?
    public let recvChainName: String?
    public let multisigWalletId: Int?
    public let multisigWalletAddress: String?
    public let multisigWalletName: String?
    public let isBuyer: Bool?
    public let txid: String?
    public let createdAt: Int?
    public let recvActualReceivedAt: Int?
    public let note: String?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case status
        case orderType = "order_type"
        case receiveAddress = "receive_address"
        case paymentAddress = "payment_address"
        case depositAddress = "deposit_address"
        case transferAddress = "transfer_address"
        case sendAmount = "send_amount"
        case sendActualAmount = "send_actual_amount"
        case sendEstimateAmount = "send_estimate_amount"
        case sendFeeAmount = "send_fee_amount"
        case sendActualFeeAmount = "send_actual_fee_amount"
        case sendEstimateFeeAmount = "send_estimate_fee_amount"
        case recvAmount = "recv_amount"
        case recvActualAmount = "recv_actual_amount"
        case recvEstimateAmount = "recv_estimate_amount"
        case sendCoinCode = "send_coin_code"
        case recvCoinCode = "recv_coin_code"
        case sendCoinName = "send_coin_name"
        case recvCoinName = "recv_coin_name"
        case sendCoinContract = "send_coin_contract"
        case sendCoinPrecision = "send_coin_precision"
        case sendChainName = "send_chain_name"
        case recvChainName = "recv_chain_name"
        case multisigWalletId = "multisig_wallet_id"
        case multisigWalletAddress = "multisig_wallet_address"
        case multisigWalletName = "multisig_wallet_name"
        case isBuyer = "is_buyer"
        case txid
        case createdAt = "created_at"
        case recvActualReceivedAt = "recv_actual_received_at"
        case note
    }
}

public struct CreatePaymentResult: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let serialNumber: String?
    public let status: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case serialNumber = "serial_number"
        case status
    }
}

public struct CreateReceiptResult: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let serialNumber: String?
    public let status: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case serialNumber = "serial_number"
        case status
    }
}

public struct ReceiveOrderDetail: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let serialNumber: String?
    public let status: Int?
    public let depositAddress: String?
    public let receiveAddress: String?
    public let sendCoinCode: String?
    public let recvCoinCode: String?
    public let sendAmount: JSONValue?
    public let recvAmount: JSONValue?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case serialNumber = "serial_number"
        case status
        case depositAddress = "deposit_address"
        case receiveAddress = "receive_address"
        case sendCoinCode = "send_coin_code"
        case recvCoinCode = "recv_coin_code"
        case sendAmount = "send_amount"
        case recvAmount = "recv_amount"
    }
}

public struct PagedResponse<T: Hashable & Codable & Sendable>: Hashable, Codable, Sendable {
    public let data: [T]
    public let total: Int?
    public let page: Int?
    public let perPage: Int?

    public init(data: [T], total: Int?, page: Int?, perPage: Int?) {
        self.data = data
        self.total = total
        self.page = page
        self.perPage = perPage
    }
}

public struct MessageItem: Hashable, Codable, Sendable {
    public let id: Int?
    public let type: String?
    public let title: String?
    public let content: String?
    public let isRead: Bool?
    public let orderSn: String?
    public let multisigWalletId: Int?
    public let createdAt: Int?
    public let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case content
        case isRead = "is_read"
        case orderSn = "order_sn"
        case multisigWalletId = "multisig_wallet_id"
        case createdAt = "created_at"
        case avatar
    }
}

public struct AddressBookItem: Hashable, Codable, Sendable {
    public let id: Int?
    public let name: String?
    public let walletAddress: String?
    public let chainName: String?
    public let chainType: String?
    public let logo: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case walletAddress = "wallet_address"
        case chainName = "chain_name"
        case chainType = "chain_type"
        case logo
    }
}

public struct AddressBookUpsertRequest: Hashable, Sendable {
    public let name: String
    public let walletAddress: String
    public let chainType: String

    public init(name: String, walletAddress: String, chainType: String = "EVM") {
        self.name = name
        self.walletAddress = walletAddress
        self.chainType = chainType
    }
}

public struct ProfileUpdateRequest: Hashable, Sendable {
    public let nickname: String?
    public let avatar: String?

    public init(nickname: String? = nil, avatar: String? = nil) {
        self.nickname = nickname
        self.avatar = avatar
    }
}

public struct UploadFileResult: Hashable, Decodable, Sendable {
    public let url: String?

    enum CodingKeys: String, CodingKey {
        case url
        case path
        case fileURL = "file_url"
        case fileUrl
        case fullURL = "full_url"
        case location
    }

    public init(url: String?) {
        self.url = url
    }

    public init(from decoder: Decoder) throws {
        if let single = try? decoder.singleValueContainer(),
           let value = try? single.decode(String.self)
        {
            url = value
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .url) {
            url = value
            return
        }
        if let value = try container.decodeIfPresent(String.self, forKey: .path) {
            url = value
            return
        }
        if let value = try container.decodeIfPresent(String.self, forKey: .fileURL) {
            url = value
            return
        }
        if let value = try container.decodeIfPresent(String.self, forKey: .fileUrl) {
            url = value
            return
        }
        if let value = try container.decodeIfPresent(String.self, forKey: .fullURL) {
            url = value
            return
        }
        url = try container.decodeIfPresent(String.self, forKey: .location)
    }
}

public enum BillPresetRange: String, Hashable, Codable, Sendable {
    case today = "TODAY"
    case yesterday = "YESTERDAY"
    case last7Days = "LAST_7_DAYS"
    case monthly = "MONTHLY"
}

public struct BillTimeRange: Hashable, Codable, Sendable {
    public let startedAt: String
    public let endedAt: String
    public let startedTimestamp: Int64?
    public let endedTimestamp: Int64?
    public let preset: BillPresetRange?

    public init(
        startedAt: String,
        endedAt: String,
        startedTimestamp: Int64? = nil,
        endedTimestamp: Int64? = nil,
        preset: BillPresetRange? = nil
    ) {
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.startedTimestamp = startedTimestamp
        self.endedTimestamp = endedTimestamp
        self.preset = preset
    }
}

public struct BillFilter: Hashable, Sendable {
    public let page: Int
    public let perPage: Int
    public let orderType: String?
    public let orderTypeList: [String]
    public let otherAddress: String?
    public let categoryIds: [Int]
    public let range: BillTimeRange?

    public init(
        page: Int = 1,
        perPage: Int = 20,
        orderType: String? = nil,
        orderTypeList: [String] = [],
        otherAddress: String? = nil,
        categoryIds: [Int] = [],
        range: BillTimeRange? = nil
    ) {
        self.page = page
        self.perPage = perPage
        self.orderType = orderType
        self.orderTypeList = orderTypeList
        self.otherAddress = otherAddress
        self.categoryIds = categoryIds
        self.range = range
    }
}

public struct BillStatisticsSummary: Hashable, Codable, Sendable {
    public let paymentAmount: JSONValue?
    public let receiptAmount: JSONValue?
    public let fee: JSONValue?
    public let transactions: Int?

    enum CodingKeys: String, CodingKey {
        case paymentAmount = "payment_amount"
        case receiptAmount = "receipt_amount"
        case fee
        case transactions
    }
}

public struct BillAddressAggregateItem: Hashable, Codable, Sendable {
    public let adversaryAddress: String?
    public let paymentAmount: JSONValue?
    public let receiptAmount: JSONValue?
    public let avatar: String?
    public let name: String?

    enum CodingKeys: String, CodingKey {
        case adversaryAddress = "adversary_address"
        case paymentAmount = "payment_amount"
        case receiptAmount = "receipt_amount"
        case avatar
        case name
    }
}

public struct ExchangeRateItem: Hashable, Codable, Sendable {
    public let currency: String?
    public let value: String?
    public let symbol: String?
}

public struct NetworkOption: Hashable, Codable, Sendable, Identifiable {
    public let id: Int
    public let chainId: Int
    public let chainName: String
    public let chainFullName: String
    public let rpcURL: String

    public init(chainId: Int, chainName: String, chainFullName: String, rpcURL: String) {
        id = chainId
        self.chainId = chainId
        self.chainName = chainName
        self.chainFullName = chainFullName
        self.rpcURL = rpcURL
    }
}

public struct AllowExchangePair: Hashable, Codable, Sendable {
    public let recvChainName: String?
    public let recvCoinCode: String?
    public let recvCoinContract: String?
    public let recvCoinFullName: String?
    public let recvCoinLogo: String?
    public let recvCoinName: String?
    public let recvCoinPrecision: Int?
    public let recvCoinSymbol: String?
    public let sendChainName: String?
    public let sendCoinCode: String?
    public let sendCoinContract: String?
    public let sendCoinFullName: String?
    public let sendCoinLogo: String?
    public let sendCoinName: String?
    public let sendCoinPrecision: Int?
    public let sendCoinSymbol: String?
    public let balance: JSONValue?

    enum CodingKeys: String, CodingKey {
        case recvChainName = "recv_chain_name"
        case recvCoinCode = "recv_coin_code"
        case recvCoinContract = "recv_coin_contract"
        case recvCoinFullName = "recv_coin_full_name"
        case recvCoinLogo = "recv_coin_logo"
        case recvCoinName = "recv_coin_name"
        case recvCoinPrecision = "recv_coin_precision"
        case recvCoinSymbol = "recv_coin_symbol"
        case sendChainName = "send_chain_name"
        case sendCoinCode = "send_coin_code"
        case sendCoinContract = "send_coin_contract"
        case sendCoinFullName = "send_coin_full_name"
        case sendCoinLogo = "send_coin_logo"
        case sendCoinName = "send_coin_name"
        case sendCoinPrecision = "send_coin_precision"
        case sendCoinSymbol = "send_coin_symbol"
        case balance
    }
}

public struct ReceiveAllowChainItem: Hashable, Codable, Sendable {
    public let chainName: String?
    public let chainFullName: String?
    public let chainLogo: String?
    public let chainColor: String?
    public let chainAddressFormatRegex: [String]?
    public let exchangePairs: [AllowExchangePair]

    enum CodingKeys: String, CodingKey {
        case chainName = "chain_name"
        case chainFullName = "chain_full_name"
        case chainLogo = "chain_logo"
        case chainColor = "chain_color"
        case chainAddressFormatRegex = "chain_address_format_regex"
        case exchangePairs = "exchange_pairs"
    }

    public init(
        chainName: String?,
        chainFullName: String?,
        chainLogo: String?,
        chainColor: String?,
        chainAddressFormatRegex: [String]?,
        exchangePairs: [AllowExchangePair]
    ) {
        self.chainName = chainName
        self.chainFullName = chainFullName
        self.chainLogo = chainLogo
        self.chainColor = chainColor
        self.chainAddressFormatRegex = chainAddressFormatRegex
        self.exchangePairs = exchangePairs
    }
}

public struct NormalAllowCoin: Hashable, Codable, Sendable {
    public let coinCode: String?
    public let coinName: String?
    public let coinFullName: String?
    public let coinLogo: String?
    public let coinContract: String?
    public let coinPrecision: Int?
    public let coinSymbol: String?
    public let chainName: String?
    public let chainFullName: String?
    public let isSendAllowed: Bool?
    public let isRecvAllowed: Bool?
    public let minAmount: Double?
    public let feeAmount: Double?
    public let feeValue: Double?

    enum CodingKeys: String, CodingKey {
        case coinCode = "coin_code"
        case coinName = "coin_name"
        case coinFullName = "coin_full_name"
        case coinLogo = "coin_logo"
        case coinContract = "coin_contract"
        case coinPrecision = "coin_precision"
        case coinSymbol = "coin_symbol"
        case chainName = "chain_name"
        case chainFullName = "chain_full_name"
        case isSendAllowed = "is_send_allowed"
        case isRecvAllowed = "is_recv_allowed"
        case minAmount = "min_amount"
        case feeAmount = "fee_amount"
        case feeValue = "fee_value"
    }
}

public struct CpCashTxReportResult: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let duplicated: Bool?
    public let status: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case duplicated
        case status
    }
}

public struct NormalAllowChainItem: Hashable, Codable, Sendable {
    public let chainName: String?
    public let chainFullName: String?
    public let chainLogo: String?
    public let chainColor: String?
    public let chainAddressFormatRegex: [String]?
    public let coins: [NormalAllowCoin]

    enum CodingKeys: String, CodingKey {
        case chainName = "chain_name"
        case chainFullName = "chain_full_name"
        case chainLogo = "chain_logo"
        case chainColor = "chain_color"
        case chainAddressFormatRegex = "chain_address_format_regex"
        case coins
    }

    public init(
        chainName: String?,
        chainFullName: String?,
        chainLogo: String?,
        chainColor: String?,
        chainAddressFormatRegex: [String]?,
        coins: [NormalAllowCoin]
    ) {
        self.chainName = chainName
        self.chainFullName = chainFullName
        self.chainLogo = chainLogo
        self.chainColor = chainColor
        self.chainAddressFormatRegex = chainAddressFormatRegex
        self.coins = coins
    }
}

public struct ExchangeShowDetail: Hashable, Codable, Sendable {
    public let sendCoinCode: String?
    public let sendCoinName: String?
    public let sendMinAmount: Double?
    public let sendMaxAmount: Double?
    public let recvCoinCode: String?
    public let recvCoinName: String?
    public let recvMinAmount: Double?
    public let recvMaxAmount: Double?
    public let recvAmount: Double?
    public let sellerId: Int?

    enum CodingKeys: String, CodingKey {
        case sendCoinCode = "send_coin_code"
        case sendCoinName = "send_coin_name"
        case sendMinAmount = "send_min_amount"
        case sendMaxAmount = "send_max_amount"
        case recvCoinCode = "recv_coin_code"
        case recvCoinName = "recv_coin_name"
        case recvMinAmount = "recv_min_amount"
        case recvMaxAmount = "recv_max_amount"
        case recvAmount = "recv_amount"
        case sellerId = "seller_id"
    }
}

public enum ReceiveAddressValidityState: String, Hashable, Codable, Sendable {
    case valid
    case invalid
}

public struct CreateTraceRequest: Hashable, Sendable {
    public let sellerId: Int?
    public let recvAddress: String
    public let sendCoinCode: String
    public let recvCoinCode: String
    public let recvAmount: Double
    public let note: String
    public let env: String?
    public let multisigWalletId: String?

    public init(
        sellerId: Int? = nil,
        recvAddress: String,
        sendCoinCode: String,
        recvCoinCode: String,
        recvAmount: Double,
        note: String = "",
        env: String? = nil,
        multisigWalletId: String? = nil
    ) {
        self.sellerId = sellerId
        self.recvAddress = recvAddress
        self.sendCoinCode = sendCoinCode
        self.recvCoinCode = recvCoinCode
        self.recvAmount = recvAmount
        self.note = note
        self.env = env
        self.multisigWalletId = multisigWalletId
    }
}

public struct TraceOrderItem: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let status: Int?
    public let address: String?
    public let depositAddress: String?
    public let paymentAddress: String?
    public let receiveAddress: String?
    public let sendCoinCode: String?
    public let recvCoinCode: String?
    public let sendChainName: String?
    public let recvChainName: String?
    public let sendCoinName: String?
    public let recvCoinName: String?
    public let recvAmount: JSONValue?
    public let recvMinAmount: JSONValue?
    public let recvMaxAmount: JSONValue?
    public let addressRemarksName: String?
    public let isRareAddress: Int?
    public let createdAt: Int?
    public let expiredAt: Int?
    public let isMarked: Bool?
    public let orderType: String?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case status
        case address
        case depositAddress = "deposit_address"
        case paymentAddress = "payment_address"
        case receiveAddress = "receive_address"
        case sendCoinCode = "send_coin_code"
        case recvCoinCode = "recv_coin_code"
        case sendChainName = "send_chain_name"
        case recvChainName = "recv_chain_name"
        case sendCoinName = "send_coin_name"
        case recvCoinName = "recv_coin_name"
        case recvAmount = "recv_amount"
        case recvMinAmount = "recv_min_amount"
        case recvMaxAmount = "recv_max_amount"
        case addressRemarksName = "address_remarks_name"
        case isRareAddress = "is_rare_address"
        case createdAt = "created_at"
        case expiredAt = "expired_at"
        case isMarked = "is_marked"
        case orderType = "order_type"
    }
}

public struct TraceShowDetail: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let status: Int?
    public let depositAddress: String?
    public let paymentAddress: String?
    public let receiveAddress: String?
    public let sendCoinCode: String?
    public let recvCoinCode: String?
    public let sendChainName: String?
    public let recvChainName: String?
    public let sendCoinName: String?
    public let recvCoinName: String?
    public let recvAmount: JSONValue?
    public let recvMinAmount: JSONValue?
    public let recvMaxAmount: JSONValue?
    public let addressRemarksName: String?
    public let isRareAddress: Int?
    public let createdAt: Int?
    public let expiredAt: Int?
    public let orderType: String?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case status
        case depositAddress = "deposit_address"
        case paymentAddress = "payment_address"
        case receiveAddress = "receive_address"
        case sendCoinCode = "send_coin_code"
        case recvCoinCode = "recv_coin_code"
        case sendChainName = "send_chain_name"
        case recvChainName = "recv_chain_name"
        case sendCoinName = "send_coin_name"
        case recvCoinName = "recv_coin_name"
        case recvAmount = "recv_amount"
        case recvMinAmount = "recv_min_amount"
        case recvMaxAmount = "recv_max_amount"
        case addressRemarksName = "address_remarks_name"
        case isRareAddress = "is_rare_address"
        case createdAt = "created_at"
        case expiredAt = "expired_at"
        case orderType = "order_type"
    }
}

public struct TraceChildItem: Hashable, Codable, Sendable {
    public let orderSn: String?
    public let status: Int?
    public let receiveAddress: String?
    public let sendActualAmount: JSONValue?
    public let recvActualAmount: JSONValue?
    public let createdAt: Int?

    enum CodingKeys: String, CodingKey {
        case orderSn = "order_sn"
        case status
        case receiveAddress = "receive_address"
        case sendActualAmount = "send_actual_amount"
        case recvActualAmount = "recv_actual_amount"
        case createdAt = "created_at"
    }
}

public struct ReceiveExpiryConfig: Hashable, Codable, Sendable {
    public let durations: [Int]
    public let selectedDuration: Int?

    public init(durations: [Int], selectedDuration: Int?) {
        self.durations = durations
        self.selectedDuration = selectedDuration
    }
}
