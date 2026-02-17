import Foundation

public enum BackendEnvironmentTag: String, Codable, CaseIterable, Sendable {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
}

public struct EnvironmentConfig: Hashable, Codable, Sendable {
    public let tag: BackendEnvironmentTag
    public let baseURL: URL

    public init(tag: BackendEnvironmentTag, baseURL: URL) {
        self.tag = tag
        self.baseURL = baseURL
    }

    public static let development = EnvironmentConfig(
        tag: .development,
        baseURL: URL(string: "https://charprotocol.dev")!
    )

    public static let staging = EnvironmentConfig(
        tag: .staging,
        baseURL: URL(string: "https://charprotocol.dev")!
    )

    public static let production = EnvironmentConfig(
        tag: .production,
        baseURL: URL(string: "https://cp.cash")!
    )

    public static let `default` = development
}
