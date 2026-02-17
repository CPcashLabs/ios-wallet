import Foundation
import BigInt

enum EVMRPCError: Error, CustomStringConvertible {
    case unsupportedChain(Int)
    case invalidRPCURL(String)
    case invalidResponse
    case rpcFailure(code: Int, message: String)
    case invalidHexQuantity(String)

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

    func nextNonce(address: String) throws -> String {
        let result = try call(method: "eth_getTransactionCount", params: [address, "pending"])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func nextNonce(address: String) async throws -> String {
        let result = try await callAsync(method: "eth_getTransactionCount", params: [address, "pending"])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func gasPrice() throws -> String {
        let result = try call(method: "eth_gasPrice", params: [])
        return try decimalQuantity(fromHexQuantity: result)
    }

    func gasPrice() async throws -> String {
        let result = try await callAsync(method: "eth_gasPrice", params: [])
        return try decimalQuantity(fromHexQuantity: result)
    }

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

    func sendRawTransaction(_ rawTransactionHex: String) throws -> String {
        let value = rawTransactionHex.hasPrefix("0x") ? rawTransactionHex : "0x" + rawTransactionHex
        return try call(method: "eth_sendRawTransaction", params: [value])
    }

    func sendRawTransaction(_ rawTransactionHex: String) async throws -> String {
        let value = rawTransactionHex.hasPrefix("0x") ? rawTransactionHex : "0x" + rawTransactionHex
        return try await callAsync(method: "eth_sendRawTransaction", params: [value])
    }

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
