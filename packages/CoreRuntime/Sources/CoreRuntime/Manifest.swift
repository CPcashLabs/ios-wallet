import Foundation

public enum CapabilityId: String, Codable, CaseIterable {
    case readAddress
    case readChainConfig
    case signMessage
    case signTypedData
    case sendTransaction
    case storage
    case network
}

public struct CapabilityRequest: Hashable {
    public let id: CapabilityId
    public let constraints: [String: AnyCodable]

    public init(id: CapabilityId, constraints: [String: AnyCodable] = [:]) {
        self.id = id
        self.constraints = constraints
    }
}

public struct ModuleRoute {
    public let path: String
    public let makeView: (RuntimeContext) -> ModuleView

    public init(path: String, makeView: @escaping (RuntimeContext) -> ModuleView) {
        self.path = path
        self.makeView = makeView
    }
}

public struct TabMeta: Hashable, Codable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct HomeCardMeta: Hashable, Codable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public struct SettingsMeta: Hashable, Codable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public enum ExtensionPoint {
    case tabItem(TabMeta)
    case homeCard(HomeCardMeta)
    case settingsEntry(SettingsMeta)
}

public protocol ModuleManifest {
    var moduleId: String { get }
    var version: String { get }
    var displayName: String { get }
    var author: String { get }
    var auditURL: URL? { get }
    var capabilities: [CapabilityRequest] { get }
    var routes: [ModuleRoute] { get }
    var extensionPoints: [ExtensionPoint] { get }
}
