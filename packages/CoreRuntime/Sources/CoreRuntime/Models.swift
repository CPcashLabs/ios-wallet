import Foundation

public struct Address: Hashable, Codable, Sendable, CustomStringConvertible {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var description: String { value }
}

public struct Signature: Hashable, Codable, Sendable, CustomStringConvertible {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var description: String { value }
}

public struct TxHash: Hashable, Codable, Sendable, CustomStringConvertible {
    public let value: String

    public init(_ value: String) {
        self.value = value
    }

    public var description: String { value }
}

public struct WaitTxConfirmationRequest: Hashable, Codable, Sendable {
    public let txHash: String
    public let chainId: Int
    public let timeoutSeconds: TimeInterval
    public let pollIntervalSeconds: TimeInterval

    public init(
        txHash: String,
        chainId: Int,
        timeoutSeconds: TimeInterval = 90,
        pollIntervalSeconds: TimeInterval = 2
    ) {
        self.txHash = txHash
        self.chainId = chainId
        self.timeoutSeconds = timeoutSeconds
        self.pollIntervalSeconds = pollIntervalSeconds
    }
}

public struct TxConfirmation: Hashable, Codable, Sendable {
    public let txHash: String
    public let blockNumber: UInt64
    public let status: Int?

    public init(txHash: String, blockNumber: UInt64, status: Int?) {
        self.txHash = txHash
        self.blockNumber = blockNumber
        self.status = status
    }
}

public struct EncryptedImportBlob: Hashable, Codable, Sendable {
    public let payload: String

    public init(payload: String) {
        self.payload = payload
    }
}

public enum RequestSource: Hashable, Codable, Sendable, CustomStringConvertible {
    case module(id: String, version: String)
    case web(origin: String)
    case system(name: String)

    public var description: String {
        switch self {
        case let .module(id, version):
            return "module:\(id)@\(version)"
        case let .web(origin):
            return "web:\(origin)"
        case let .system(name):
            return "system:\(name)"
        }
    }
}

public struct SignMessageRequest: Hashable, Codable, Sendable {
    public let source: RequestSource
    public let account: Address
    public let message: String
    public let chainId: Int

    public init(source: RequestSource, account: Address, message: String, chainId: Int) {
        self.source = source
        self.account = account
        self.message = message
        self.chainId = chainId
    }
}

public struct SignTypedDataRequest: Hashable, Codable, Sendable {
    public let source: RequestSource
    public let account: Address
    public let typedDataJSON: String
    public let chainId: Int

    public init(source: RequestSource, account: Address, typedDataJSON: String, chainId: Int) {
        self.source = source
        self.account = account
        self.typedDataJSON = typedDataJSON
        self.chainId = chainId
    }
}

public struct SendTxRequest: Hashable, Codable, Sendable {
    public let source: RequestSource
    public let from: Address
    public let to: Address
    public let value: String
    public let data: String?
    public let chainId: Int
    public let gasLimit: String?
    public let maxFeePerGas: String?
    public let maxPriorityFeePerGas: String?

    public init(
        source: RequestSource,
        from: Address,
        to: Address,
        value: String,
        data: String?,
        chainId: Int,
        gasLimit: String? = nil,
        maxFeePerGas: String? = nil,
        maxPriorityFeePerGas: String? = nil
    ) {
        self.source = source
        self.from = from
        self.to = to
        self.value = value
        self.data = data
        self.chainId = chainId
        self.gasLimit = gasLimit
        self.maxFeePerGas = maxFeePerGas
        self.maxPriorityFeePerGas = maxPriorityFeePerGas
    }
}

public struct ChainConfig: Hashable, Codable, Sendable {
    public let chainId: Int
    public let rpcURL: String

    public init(chainId: Int, rpcURL: String) {
        self.chainId = chainId
        self.rpcURL = rpcURL
    }
}
