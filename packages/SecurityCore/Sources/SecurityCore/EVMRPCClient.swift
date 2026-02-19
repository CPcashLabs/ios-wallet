import Foundation
import BigInt
import CoreRuntime

enum EVMRPCError: Error, CustomStringConvertible {
    case unsupportedChain(Int)
    case invalidRPCURL(String)
    case invalidResponse
    case rpcFailure(code: Int, message: String)
    case invalidHexQuantity(String)
    case invalidReceiptField(String)
    case transactionConfirmationTimeout(String)
    case transactionExecutionFailed(String)

    var description: String {
        switch self {
        case let .unsupportedChain(chainId):
            return "Unsupported chain id: \(chainId)"
        case let .invalidRPCURL(url):
            return "Invalid RPC url: \(url)"
        case .invalidResponse:
            return "Invalid RPC response"
        case let .rpcFailure(code, message):
            return "RPC failure [\(code)] \(message)"
        case let .invalidHexQuantity(value):
            return "Invalid hex quantity: \(value)"
        case let .invalidReceiptField(value):
            return "Invalid receipt field: \(value)"
        case let .transactionConfirmationTimeout(txHash):
            return "Transaction confirmation timeout: \(txHash)"
        case let .transactionExecutionFailed(txHash):
            return "Transaction execution failed: \(txHash)"
        }
    }
}

private struct RPCEnvelope: Decodable {
    struct RPCErrorBody: Decodable {
        let code: Int
        let message: String
    }

    let result: String?
    let error: RPCErrorBody?
}

struct EVMTransactionReceipt: Hashable, Sendable {
    let txHash: String
    let blockNumber: UInt64?
    let status: Int?
}

private struct RPCReceiptEnvelope: Decodable {
    struct RPCErrorBody: Decodable {
        let code: Int
        let message: String
    }

    struct ReceiptPayload: Decodable {
        let transactionHash: String?
        let blockNumber: String?
        let status: String?

        enum CodingKeys: String, CodingKey {
            case transactionHash
            case blockNumber
            case status
        }
    }

    let result: ReceiptPayload?
    let error: RPCErrorBody?
}

struct EVMRPCClient {
    let rpcURL: URL
    let session: URLSession

    init(chainId: Int, session: URLSession = .shared) throws {
        let rpcURLString = try Self.defaultRPCURL(chainId: chainId)
        guard let rpcURL = URL(string: rpcURLString) else {
            throw EVMRPCError.invalidRPCURL(rpcURLString)
        }
        self.rpcURL = rpcURL
        self.session = session
    }

    @available(*, deprecated, message: "Use async version instead")
    func nextNonce(address: String) throws -> String {
        let result = try call(method: "eth_getTransactionCount", params: [address, "pending"])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func nextNonce(address: String) async throws -> String {
        let result = try await callAsync(method: "eth_getTransactionCount", params: [address, "pending"])
        return try decimalQuantity(fromHexQuantity: result)
    }

    @available(*, deprecated, message: "Use async version instead")
    func gasPrice() throws -> String {
        let result = try call(method: "eth_gasPrice", params: [])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func gasPrice() async throws -> String {
        let result = try await callAsync(method: "eth_gasPrice", params: [])
        return try decimalQuantity(fromHexQuantity: result)
    }

    @available(*, deprecated, message: "Use async version instead")
    func estimateGas(from: String, to: String, value: String, data: String?) throws -> String {
        var txObject: [String: String] = [
            "from": from,
            "to": to,
            "value": hexQuantity(fromDecimalQuantity: value),
        ]
        if let data, !data.isEmpty {
            txObject["data"] = data.hasPrefix("0x") ? data : "0x" + data
        }
        let result = try call(method: "eth_estimateGas", params: [txObject])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func estimateGas(from: String, to: String, value: String, data: String?) async throws -> String {
        var txObject: [String: String] = [
            "from": from,
            "to": to,
            "value": hexQuantity(fromDecimalQuantity: value),
        ]
        if let data, !data.isEmpty {
            txObject["data"] = data.hasPrefix("0x") ? data : "0x" + data
        }
        let result = try await callAsync(method: "eth_estimateGas", params: [txObject])
        return try decimalQuantity(fromHexQuantity: result)
    }

    @available(*, deprecated, message: "Use async version instead")
    func sendRawTransaction(_ rawTransactionHex: String) throws -> String {
        let value = rawTransactionHex.hasPrefix("0x") ? rawTransactionHex : "0x" + rawTransactionHex
        return try call(method: "eth_sendRawTransaction", params: [value])
    }

    func sendRawTransaction(_ rawTransactionHex: String) async throws -> String {
        let value = rawTransactionHex.hasPrefix("0x") ? rawTransactionHex : "0x" + rawTransactionHex
        return try await callAsync(method: "eth_sendRawTransaction", params: [value])
    }

    func transactionReceipt(txHash: String) async throws -> EVMTransactionReceipt? {
        let value = txHash.hasPrefix("0x") ? txHash : "0x" + txHash
        let envelope = try await callAsyncReceipt(method: "eth_getTransactionReceipt", params: [value])
        guard let payload = envelope.result else {
            return nil
        }
        let hash = payload.transactionHash ?? value
        let block = try payload.blockNumber.map(uint64Quantity(fromHexQuantity:))
        let status = try payload.status.map(intQuantity(fromHexQuantity:))
        return EVMTransactionReceipt(txHash: hash, blockNumber: block, status: status)
    }

    func waitForTransactionConfirmation(_ req: WaitTxConfirmationRequest) async throws -> TxConfirmation {
        let timeout = max(0.1, req.timeoutSeconds)
        let interval = max(0.1, req.pollIntervalSeconds)
        let start = Date()

        while Date().timeIntervalSince(start) <= timeout {
            if Task.isCancelled {
                throw CancellationError()
            }
            if let receipt = try await transactionReceipt(txHash: req.txHash),
               let blockNumber = receipt.blockNumber,
               blockNumber > 0
            {
                if let status = receipt.status, status == 0 {
                    throw EVMRPCError.transactionExecutionFailed(receipt.txHash)
                }
                return TxConfirmation(txHash: receipt.txHash, blockNumber: blockNumber, status: receipt.status)
            }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
        }

        throw EVMRPCError.transactionConfirmationTimeout(req.txHash)
    }

    @available(*, deprecated, message: "Use async version instead")
    private func call(method: String, params: [Any]) throws -> String {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params,
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: rpcURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let semaphore = DispatchSemaphore(value: 0)
        var callbackData: Data?
        var callbackResponse: URLResponse?
        var callbackError: Error?

        let task = session.dataTask(with: request) { data, response, error in
            callbackData = data
            callbackResponse = response
            callbackError = error
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()

        if let callbackError {
            throw callbackError
        }
        guard let data = callbackData,
              let http = callbackResponse as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode)
        else {
            throw EVMRPCError.invalidResponse
        }

        let envelope = try JSONDecoder().decode(RPCEnvelope.self, from: data)
        if let error = envelope.error {
            throw EVMRPCError.rpcFailure(code: error.code, message: error.message)
        }
        guard let result = envelope.result else {
            throw EVMRPCError.invalidResponse
        }
        return result
    }

    private func callAsync(method: String, params: [Any]) async throws -> String {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params,
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: rpcURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode)
        else {
            throw EVMRPCError.invalidResponse
        }

        let envelope = try JSONDecoder().decode(RPCEnvelope.self, from: data)
        if let error = envelope.error {
            throw EVMRPCError.rpcFailure(code: error.code, message: error.message)
        }
        guard let result = envelope.result else {
            throw EVMRPCError.invalidResponse
        }
        return result
    }

    private func callAsyncReceipt(method: String, params: [Any]) async throws -> RPCReceiptEnvelope {
        let payload: [String: Any] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": method,
            "params": params,
        ]
        let requestData = try JSONSerialization.data(withJSONObject: payload)

        var request = URLRequest(url: rpcURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestData

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200 ... 299).contains(http.statusCode)
        else {
            throw EVMRPCError.invalidResponse
        }

        let envelope = try JSONDecoder().decode(RPCReceiptEnvelope.self, from: data)
        if let error = envelope.error {
            throw EVMRPCError.rpcFailure(code: error.code, message: error.message)
        }
        return envelope
    }

    private func decimalQuantity(fromHexQuantity value: String) throws -> String {
        let trimmed = value.hasPrefix("0x") ? String(value.dropFirst(2)) : value
        guard !trimmed.isEmpty else {
            return "0"
        }
        guard let decimal = BigUInt(trimmed, radix: 16) else {
            throw EVMRPCError.invalidHexQuantity(value)
        }
        return decimal.description
    }

    private func uint64Quantity(fromHexQuantity value: String) throws -> UInt64 {
        let decimal = try decimalQuantity(fromHexQuantity: value)
        guard let parsed = UInt64(decimal) else {
            throw EVMRPCError.invalidReceiptField(value)
        }
        return parsed
    }

    private func intQuantity(fromHexQuantity value: String) throws -> Int {
        let decimal = try decimalQuantity(fromHexQuantity: value)
        guard let parsed = Int(decimal) else {
            throw EVMRPCError.invalidReceiptField(value)
        }
        return parsed
    }

    private func hexQuantity(fromDecimalQuantity value: String) -> String {
        guard let decimal = BigUInt(value), decimal > 0 else {
            return "0x0"
        }
        let hex = decimal.serialize().map { String(format: "%02x", $0) }.joined()
        let normalized = String(hex.drop(while: { $0 == "0" }))
        return "0x" + (normalized.isEmpty ? "0" : normalized)
    }

    private static func defaultRPCURL(chainId: Int) throws -> String {
        switch chainId {
        case 199:
            return "https://rpc.bt.io/"
        case 1029:
            return "https://pre-rpc.bt.io/"
        default:
            throw EVMRPCError.unsupportedChain(chainId)
        }
    }
}
