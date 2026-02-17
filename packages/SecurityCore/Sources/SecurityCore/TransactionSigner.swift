import CoreRuntime
import Foundation
import BigInt
import web3swift
import Web3Core

enum TransactionSignerError: Error, CustomStringConvertible {
    case invalidFromAddress
    case invalidToAddress
    case invalidPrivateKey
    case invalidValue
    case invalidNonce
    case invalidGasPrice
    case invalidGasLimit
    case signFailed

    var description: String {
        switch self {
        case .invalidFromAddress:
            return "Invalid from address"
        case .invalidToAddress:
            return "Invalid to address"
        case .invalidPrivateKey:
            return "Invalid private key"
        case .invalidValue:
            return "Invalid value"
        case .invalidNonce:
            return "Invalid nonce"
        case .invalidGasPrice:
            return "Invalid gas price"
        case .invalidGasLimit:
            return "Invalid gas limit"
        case .signFailed:
            return "Failed to sign transaction"
        }
    }
}

struct SignedTransaction {
    let rawTransactionHex: String
    let txHashHex: String
}

struct TransactionSigner {
    func signLegacyTransaction(
        _ req: SendTxRequest,
        privateKey: Data,
        nonce: String,
        gasPrice: String,
        gasLimit: String
    ) throws -> SignedTransaction {
        guard let from = EthereumAddress(req.from.value, ignoreChecksum: true) else {
            throw TransactionSignerError.invalidFromAddress
        }
        guard let to = EthereumAddress(req.to.value, ignoreChecksum: true) else {
            throw TransactionSignerError.invalidToAddress
        }
        guard SECP256K1.verifyPrivateKey(privateKey: privateKey) else {
            throw TransactionSignerError.invalidPrivateKey
        }
        guard let numericValue = BigUInt(req.value) else {
            throw TransactionSignerError.invalidValue
        }

        guard let numericNonce = BigUInt(nonce) else {
            throw TransactionSignerError.invalidNonce
        }
        guard let numericGasPrice = BigUInt(gasPrice) else {
            throw TransactionSignerError.invalidGasPrice
        }
        guard let numericGasLimit = BigUInt(gasLimit) else {
            throw TransactionSignerError.invalidGasLimit
        }

        var tx = CodableTransaction(
            type: .legacy,
            to: to,
            nonce: numericNonce,
            chainID: BigUInt(req.chainId),
            value: numericValue,
            data: Data.fromHex(req.data ?? "") ?? Data(),
            gasLimit: numericGasLimit,
            gasPrice: numericGasPrice
        )
        tx.from = from

        do {
            try tx.sign(privateKey: privateKey)
        } catch {
            throw TransactionSignerError.signFailed
        }

        guard let rawData = tx.encode(for: .transaction),
              let hash = tx.hash?.toHexString().addHexPrefix()
        else {
            throw TransactionSignerError.signFailed
        }

        return SignedTransaction(
            rawTransactionHex: rawData.toHexString().addHexPrefix(),
            txHashHex: hash
        )
    }
}
