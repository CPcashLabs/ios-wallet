import Foundation

public enum RequestType: String, Codable {
    case signMessage
    case signTypedData
    case sendTransaction
}

public struct RiskHint: Hashable, Codable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
        self.code = code
        self.message = message
    }
}

public struct ConfirmSummary: Hashable, Codable {
    public let title: String
    public let fields: [String: String]

    public init(title: String, fields: [String: String]) {
        self.title = title
        self.fields = fields
    }
}

public struct ConfirmRequest {
    public let source: RequestSource
    public let requestType: RequestType
    public let chainId: Int
    public let summary: ConfirmSummary
    public let riskHints: [RiskHint]

    public init(
        source: RequestSource,
        requestType: RequestType,
        chainId: Int,
        summary: ConfirmSummary,
        riskHints: [RiskHint] = []
    ) {
        self.source = source
        self.requestType = requestType
        self.chainId = chainId
        self.summary = summary
        self.riskHints = riskHints
    }
}

public enum ConfirmDecision {
    case approved
    case rejected(reason: String)
}

public enum ConfirmError: Error {
    case rejected(String)
}

public protocol ConfirmFlow {
    func confirm(_ request: ConfirmRequest) async throws -> ConfirmDecision
}

public final class DefaultConfirmFlow: ConfirmFlow {
    private let autoApprove: Bool

    public init(autoApprove: Bool = true) {
        self.autoApprove = autoApprove
    }

    public func confirm(_ request: ConfirmRequest) async throws -> ConfirmDecision {
        if autoApprove {
            return .approved
        }
        return .rejected(reason: "User rejected in stub confirm flow")
    }
}
