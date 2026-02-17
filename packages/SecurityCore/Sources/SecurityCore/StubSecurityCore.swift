import CoreRuntime
import Foundation

public final class StubSecurityCore: SecurityService {
    private let keyStore = KeyStoreService()
    private let signer = EthereumSigner()
    private let txSigner = TransactionSigner()

    public init(initialAddress: Address = Address("0x1111111111111111111111111111111111111111")) {
        if (try? keyStore.activeAddress()) == nil {
            _ = try? keyStore.createAccount()
        }
    }

    public func createAccount() throws -> Address {
        Address(try keyStore.createAccount())
    }

    public func importAccount(_ encryptedInput: EncryptedImportBlob) throws -> Address {
        Address(try keyStore.importAccount(privateKeyHex: encryptedInput.payload))
    }

    public func activeAddress() throws -> Address {
        Address(try keyStore.activeAddress())
    }

    public func signPersonalMessage(_ req: SignMessageRequest) throws -> Signature {
        let privateKey = try keyStore.loadPrivateKeyData()
        let signature = try signer.signPersonalMessage(req.message, privateKey: privateKey, expectedAddress: req.account.value)
        return Signature(signature)
    }

    public func signTypedData(_ req: SignTypedDataRequest) throws -> Signature {
        let privateKey = try keyStore.loadPrivateKeyData()
        let signature = try signer.signTypedData(req.typedDataJSON, privateKey: privateKey, expectedAddress: req.account.value)
        return Signature(signature)
    }

    public func signAndSendTransaction(_ req: SendTxRequest) throws -> TxHash {
        let privateKey = try keyStore.loadPrivateKeyData()
        let rpc = try EVMRPCClient(chainId: req.chainId)

        let nonce = try rpc.nextNonce(address: req.from.value)
        let gasPrice = try rpc.gasPrice()
        let gasLimit: String
        if let value = req.gasLimit, !value.isEmpty {
            gasLimit = value
        } else {
            gasLimit = try rpc.estimateGas(
                from: req.from.value,
                to: req.to.value,
                value: req.value,
                data: req.data
            )
        }

        let signed = try txSigner.signLegacyTransaction(
            req,
            privateKey: privateKey,
            nonce: nonce,
            gasPrice: req.maxFeePerGas ?? gasPrice,
            gasLimit: gasLimit
        )

        let rpcHash = try rpc.sendRawTransaction(signed.rawTransactionHex)
        return TxHash(rpcHash)
    }
}
