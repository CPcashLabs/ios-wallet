import Foundation
import Security
import web3swift
import Web3Core

enum KeyStoreError: Error, CustomStringConvertible {
    case invalidPrivateKey
    case missingPrivateKey
    case keychainFailure(OSStatus)

    var description: String {
        switch self {
        case .invalidPrivateKey:
            return "Invalid private key"
        case .missingPrivateKey:
            return "Missing private key in keychain"
        case let .keychainFailure(status):
            return "Keychain failure: \(status)"
        }
    }
}

final class KeyStoreService {
    private let service = "com.cpcash.securitycore"
    private let privateKeyAccount = "active-private-key"
    private let addressAccount = "active-address"

    func createAccount() throws -> String {
        guard let privateKey = SECP256K1.generatePrivateKey() else {
            throw KeyStoreError.invalidPrivateKey
        }
        return try persistPrivateKey(privateKey)
    }

    func importAccount(privateKeyHex: String) throws -> String {
        let normalized = privateKeyHex.stripHexPrefix()
        guard let privateKey = Data.fromHex(normalized), SECP256K1.verifyPrivateKey(privateKey: privateKey) else {
            throw KeyStoreError.invalidPrivateKey
        }
        return try persistPrivateKey(privateKey)
    }

    func activeAddress() throws -> String {
        if let address = try readAddress() {
            return address
        }
        let address = try deriveAddress(from: try loadPrivateKeyData())
        try writeAddress(address)
        return address
    }

    func loadPrivateKeyData() throws -> Data {
        guard let data = try readData(account: privateKeyAccount) else {
            throw KeyStoreError.missingPrivateKey
        }
        return data
    }

    private func persistPrivateKey(_ privateKey: Data) throws -> String {
        let address = try deriveAddress(from: privateKey)
        try writeData(privateKey, account: privateKeyAccount)
        try writeAddress(address)
        return address
    }

    private func deriveAddress(from privateKey: Data) throws -> String {
        guard let publicKey = Utilities.privateToPublic(privateKey, compressed: false),
              let address = Utilities.publicToAddress(publicKey)?.address
        else {
            throw KeyStoreError.invalidPrivateKey
        }
        return address
    }

    private func writeAddress(_ address: String) throws {
        try writeData(Data(address.utf8), account: addressAccount)
    }

    private func readAddress() throws -> String? {
        guard let data = try readData(account: addressAccount) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func writeData(_ data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        SecItemDelete(query as CFDictionary)

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeyStoreError.keychainFailure(status)
        }
    }

    private func readData(account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw KeyStoreError.keychainFailure(status)
        }

        return result as? Data
    }
}
