import BackendAPI
import Foundation

enum AppErrorMapper {
    static func message(for error: Error, defaultMessage: String = "操作失败，请稍后重试") -> String {
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
        return defaultMessage
    }
}
