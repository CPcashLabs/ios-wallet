import CoreRuntime
import Foundation

public enum WebDAppBridgeError: Error {
    case unsupportedMethod(String)
    case invalidParameters(String)
}

public struct WebDAppBridgeRequest {
    public let origin: String
    public let method: String
    public let params: [AnyCodable]

    public init(origin: String, method: String, params: [AnyCodable]) {
        self.origin = origin
        self.method = method
        self.params = params
    }
}

public final class WebDAppBridge {
    private let origin: String
    private let capabilities: ModuleCapabilityServicing

    public init(origin: String, capabilities: ModuleCapabilityServicing) {
        self.origin = origin
        self.capabilities = capabilities
    }

    public func handle(_ request: WebDAppBridgeRequest) async throws -> AnyCodable {
        switch request.method {
        case "eth_requestAccounts":
            let address = try capabilities.readAddress()
            return AnyCodable(address.value)

        case "personal_sign":
            guard let message = request.params.first?.value.base as? String else {
                throw WebDAppBridgeError.invalidParameters("personal_sign requires message")
            }
            let signature = try await capabilities.signMessage(message)
            return AnyCodable(signature.value)

        case "eth_signTypedData_v4":
            guard let typedData = request.params.first?.value.base as? String else {
                throw WebDAppBridgeError.invalidParameters("eth_signTypedData_v4 requires typedData JSON")
            }
            let signature = try await capabilities.signTypedData(typedData)
            return AnyCodable(signature.value)

        case "eth_sendTransaction":
            guard request.params.count >= 3,
                  let to = request.params[0].value.base as? String,
                  let value = request.params[1].value.base as? String,
                  let chainId = request.params[2].value.base as? Int
            else {
                throw WebDAppBridgeError.invalidParameters("eth_sendTransaction requires to/value/chainId")
            }

            let from = try capabilities.readAddress()
            let tx = SendTxRequest(
                source: .web(origin: origin),
                from: from,
                to: Address(to),
                value: value,
                data: nil,
                chainId: chainId
            )
            let hash = try await capabilities.sendTransaction(tx)
            return AnyCodable(hash.value)

        default:
            throw WebDAppBridgeError.unsupportedMethod(request.method)
        }
    }
}
