import Foundation

public protocol ModuleCapabilityServicing {
    func readAddress() throws -> Address
    func readChainConfig() throws -> ChainConfig
    func signMessage(_ message: String) async throws -> Signature
    func signTypedData(_ typedDataJSON: String) async throws -> Signature
    func sendTransaction(_ request: SendTxRequest) async throws -> TxHash
}

public protocol RuntimeContext {
    var moduleId: String { get }
    var capabilities: ModuleCapabilityServicing { get }

    func permissionStatus(_ capability: CapabilityId) -> PermissionStatus
    func requestPermission(_ req: CapabilityRequest) async throws -> PermissionGrant
    func storage(namespace: String) -> NamespacedStorage
    func openRoute(_ path: String)
}
