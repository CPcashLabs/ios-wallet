import Foundation

public enum PermissionStatus: String, Codable {
    case notDetermined
    case granted
    case denied
}

public struct PermissionGrant {
    public let moduleId: String
    public let capability: CapabilityId
    public let status: PermissionStatus
    public let grantedAt: Date

    public init(moduleId: String, capability: CapabilityId, status: PermissionStatus, grantedAt: Date = Date()) {
        self.moduleId = moduleId
        self.capability = capability
        self.status = status
        self.grantedAt = grantedAt
    }
}

public protocol PermissionManaging: AnyObject {
    func status(moduleId: String, capability: CapabilityId) -> PermissionStatus
    @discardableResult
    func grant(moduleId: String, capability: CapabilityId) -> PermissionGrant
    @discardableResult
    func deny(moduleId: String, capability: CapabilityId) -> PermissionGrant
    func revoke(moduleId: String, capability: CapabilityId)
}

public final class PermissionManager: PermissionManaging {
    private var store: [String: PermissionStatus] = [:]
    private let lock = NSLock()

    public init() {}

    public func status(moduleId: String, capability: CapabilityId) -> PermissionStatus {
        lock.lock()
        defer { lock.unlock() }
        return store[key(moduleId, capability)] ?? .notDetermined
    }

    @discardableResult
    public func grant(moduleId: String, capability: CapabilityId) -> PermissionGrant {
        lock.lock()
        defer { lock.unlock() }
        store[key(moduleId, capability)] = .granted
        return PermissionGrant(moduleId: moduleId, capability: capability, status: .granted)
    }

    @discardableResult
    public func deny(moduleId: String, capability: CapabilityId) -> PermissionGrant {
        lock.lock()
        defer { lock.unlock() }
        store[key(moduleId, capability)] = .denied
        return PermissionGrant(moduleId: moduleId, capability: capability, status: .denied)
    }

    public func revoke(moduleId: String, capability: CapabilityId) {
        lock.lock()
        defer { lock.unlock() }
        store[key(moduleId, capability)] = .notDetermined
    }

    private func key(_ moduleId: String, _ capability: CapabilityId) -> String {
        "\(moduleId)::\(capability.rawValue)"
    }
}
