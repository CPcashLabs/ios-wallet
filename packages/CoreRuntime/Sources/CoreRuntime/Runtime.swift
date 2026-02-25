import Foundation

public enum RuntimeError: Error, CustomStringConvertible {
    case moduleNotInstalled(String)
    case routeNotFound(String)
    case permissionDenied(moduleId: String, capability: CapabilityId)
    case confirmRejected(String)

    public var description: String {
        switch self {
        case let .moduleNotInstalled(moduleId):
            return "Module not installed: \(moduleId)"
        case let .routeNotFound(path):
            return "Route not found: \(path)"
        case let .permissionDenied(moduleId, capability):
            return "Permission denied: \(moduleId) -> \(capability.rawValue)"
        case let .confirmRejected(reason):
            return "Confirm rejected: \(reason)"
        }
    }
}

public protocol RuntimeInstalling {
    func install(_ manifests: [ModuleManifest])
    func route(_ path: String) -> ModuleRoute?
    func context(for moduleId: String) throws -> RuntimeContext
    var installedModuleIds: [String] { get }
}

public final class AppRuntime: RuntimeInstalling {
    private var manifestsById: [String: ModuleManifest] = [:]
    private var routesByPath: [String: ModuleRoute] = [:]

    private let securityService: SecurityService
    private let permissionManager: PermissionManaging
    private let confirmFlow: ConfirmFlow
    private let storageHub: InMemoryStorageHub
    private let chainConfigProvider: ChainConfigProviding

    public init(
        securityService: SecurityService,
        permissionManager: PermissionManaging,
        confirmFlow: ConfirmFlow,
        storageHub: InMemoryStorageHub = InMemoryStorageHub(),
        chainConfigProvider: ChainConfigProviding
    ) {
        self.securityService = securityService
        self.permissionManager = permissionManager
        self.confirmFlow = confirmFlow
        self.storageHub = storageHub
        self.chainConfigProvider = chainConfigProvider
    }

    public func install(_ manifests: [ModuleManifest]) {
        for manifest in manifests {
            manifestsById[manifest.moduleId] = manifest
            for route in manifest.routes {
                routesByPath[route.path] = route
            }
        }
    }

    public func route(_ path: String) -> ModuleRoute? {
        routesByPath[path]
    }

    public var installedModuleIds: [String] {
        manifestsById.keys.sorted()
    }

    public func context(for moduleId: String) throws -> RuntimeContext {
        guard let manifest = manifestsById[moduleId] else {
            throw RuntimeError.moduleNotInstalled(moduleId)
        }

        let service = RuntimeCapabilityService(
            moduleId: manifest.moduleId,
            moduleVersion: manifest.version,
            securityService: securityService,
            permissionManager: permissionManager,
            confirmFlow: confirmFlow,
            chainConfigProvider: chainConfigProvider
        )

        return ModuleRuntimeContext(
            moduleId: manifest.moduleId,
            permissionManager: permissionManager,
            capabilitiesService: service,
            storageHub: storageHub,
            routeOpener: { [weak self] path in
                _ = self?.route(path)
            }
        )
    }
}

private final class RuntimeCapabilityService: ModuleCapabilityServicing {
    private let moduleId: String
    private let moduleVersion: String
    private let securityService: SecurityService
    private let permissionManager: PermissionManaging
    private let confirmFlow: ConfirmFlow
    private let chainConfigProvider: ChainConfigProviding

    init(
        moduleId: String,
        moduleVersion: String,
        securityService: SecurityService,
        permissionManager: PermissionManaging,
        confirmFlow: ConfirmFlow,
        chainConfigProvider: ChainConfigProviding
    ) {
        self.moduleId = moduleId
        self.moduleVersion = moduleVersion
        self.securityService = securityService
        self.permissionManager = permissionManager
        self.confirmFlow = confirmFlow
        self.chainConfigProvider = chainConfigProvider
    }

    func readAddress() throws -> Address {
        try ensureGranted(.readAddress)
        return try securityService.activeAddress()
    }

    func readChainConfig() throws -> ChainConfig {
        try ensureGranted(.readChainConfig)
        return try chainConfigProvider.activeChainConfig()
    }

    func signMessage(_ message: String) async throws -> Signature {
        try ensureGranted(.signMessage)
        let account = try securityService.activeAddress()
        let chain = try chainConfigProvider.activeChainConfig()
        let source = RequestSource.module(id: moduleId, version: moduleVersion)
        let req = SignMessageRequest(source: source, account: account, message: message, chainId: chain.chainId)
        return try securityService.signPersonalMessage(req)
    }

    func signTypedData(_ typedDataJSON: String) async throws -> Signature {
        try ensureGranted(.signTypedData)
        let account = try securityService.activeAddress()
        let chain = try chainConfigProvider.activeChainConfig()
        let source = RequestSource.module(id: moduleId, version: moduleVersion)
        let req = SignTypedDataRequest(source: source, account: account, typedDataJSON: typedDataJSON, chainId: chain.chainId)
        return try securityService.signTypedData(req)
    }

    func sendTransaction(_ request: SendTxRequest) async throws -> TxHash {
        try ensureGranted(.sendTransaction)
        return try securityService.signAndSendTransaction(request)
    }

    private func ensureGranted(_ capability: CapabilityId) throws {
        guard permissionManager.status(moduleId: moduleId, capability: capability) == .granted else {
            throw RuntimeError.permissionDenied(moduleId: moduleId, capability: capability)
        }
    }
}

private struct ModuleRuntimeContext: RuntimeContext {
    let moduleId: String
    let permissionManager: PermissionManaging
    let capabilitiesService: ModuleCapabilityServicing
    let storageHub: InMemoryStorageHub
    let routeOpener: (String) -> Void

    var capabilities: ModuleCapabilityServicing { capabilitiesService }

    func permissionStatus(_ capability: CapabilityId) -> PermissionStatus {
        permissionManager.status(moduleId: moduleId, capability: capability)
    }

    func requestPermission(_ req: CapabilityRequest) async throws -> PermissionGrant {
        // Phase 1: use an auto-approval stub to unblock the flow; Phase 2: connect UI confirmation.
        permissionManager.grant(moduleId: moduleId, capability: req.id)
    }

    func storage(namespace: String) -> NamespacedStorage {
        storageHub.namespace(namespace)
    }

    func openRoute(_ path: String) {
        routeOpener(path)
    }
}
