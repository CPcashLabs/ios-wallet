import BackendAPI
import Foundation

enum AppErrorMapper {
    static func message(for error: Error, defaultMessage: String = "Operation failed, please try again later") -> String {
        if let backendError = error as? BackendAPIError {
            switch backendError {
            case .unauthorized:
                return "Login session expired, please sign in again"
            case .httpStatus:
                return "Network request failed, please try again later"
            case let .serverError(_, message):
                return message
            case .invalidURL, .invalidEnvironmentHost, .emptyData:
                return "Service response is invalid, please try again later"
            }
        }

        if error is URLError {
            return "Network connection failed"
        }

        let lowered = String(describing: error).lowercased()
        if lowered.contains("insufficient funds") || lowered.contains("gas required exceeds allowance") {
            return "Insufficient balance or gas"
        }
        if lowered.contains("token contract missing") || lowered.contains("invalid token contract") {
            return "Coin configuration is invalid, please reselect the network and try again"
        }
        if lowered.contains("invalid recipient") || lowered.contains("invalid to address") {
            return "Invalid receiving address"
        }
        if lowered.contains("nonce too low") || lowered.contains("replacement transaction underpriced") {
            return "Duplicate transaction submission, please try again later"
        }
        if lowered.contains("user rejected") || lowered.contains("user deny") || lowered.contains("cancelled") {
            return "Payment cancelled by user"
        }
        if lowered.contains("timeout") || lowered.contains("timed out") || lowered.contains("rpc") {
            return "Network is busy, please try again later"
        }
        return defaultMessage
    }
}
