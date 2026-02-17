import Foundation
import web3swift
import Web3Core

enum EthereumSignerError: Error, CustomStringConvertible {
    case invalidAccount
    case signFailed
    case typedDataParseFailed

    var description: String {
        switch self {
        case .invalidAccount:
            return "Invalid Ethereum account"
        case .signFailed:
            return "Failed to sign payload"
        case .typedDataParseFailed:
            return "Failed to parse EIP-712 typed data"
        }
    }
}

struct EthereumSigner {
    func signPersonalMessage(_ message: String, privateKey: Data, expectedAddress: String?) throws -> String {
        guard let keystore = PlainKeystore(privateKey: privateKey),
              let account = keystore.addresses?.first
        else {
            throw EthereumSignerError.invalidAccount
        }

        if let expectedAddress,
           !expectedAddress.isEmpty,
           account.address.lowercased() != expectedAddress.lowercased()
        {
            throw EthereumSignerError.invalidAccount
        }

        guard let signature = try Web3Signer.signPersonalMessage(Data(message.utf8), keystore: keystore, account: account, password: "") else {
            throw EthereumSignerError.signFailed
        }

        return signature.toHexString().addHexPrefix()
    }

    func signTypedData(_ typedDataJSON: String, privateKey: Data, expectedAddress: String?) throws -> String {
        guard let keystore = PlainKeystore(privateKey: privateKey),
              let account = keystore.addresses?.first
        else {
            throw EthereumSignerError.invalidAccount
        }

        if let expectedAddress,
           !expectedAddress.isEmpty,
           account.address.lowercased() != expectedAddress.lowercased()
        {
            throw EthereumSignerError.invalidAccount
        }

        let parsed = try EIP712Parser.parse(typedDataJSON)
        let signature = try Web3Signer.signEIP712(parsed, keystore: keystore, account: account, password: "")
        return signature.toHexString().addHexPrefix()
    }
}
