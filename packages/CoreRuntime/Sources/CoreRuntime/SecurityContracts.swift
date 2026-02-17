import Foundation

public protocol SecurityService {
    func createAccount() throws -> Address
    func importAccount(_ encryptedInput: EncryptedImportBlob) throws -> Address
    func activeAddress() throws -> Address

    func signPersonalMessage(_ req: SignMessageRequest) throws -> Signature
    func signTypedData(_ req: SignTypedDataRequest) throws -> Signature
    func signAndSendTransaction(_ req: SendTxRequest) throws -> TxHash
}

public protocol ChainConfigProviding {
    func activeChainConfig() throws -> ChainConfig
}

public struct StaticChainConfigProvider: ChainConfigProviding {
    private let config: ChainConfig

    public init(config: ChainConfig) {
        self.config = config
    }

    public func activeChainConfig() throws -> ChainConfig {
        config
    }
}
