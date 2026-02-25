import Foundation
import LocalAuthentication
import Security

struct LocalPasskeyAccount: Codable, Hashable, Identifiable {
    let rawId: String
    let displayName: String
    let privateKeyHex: String
    let address: String
    let createdAt: Date

    var id: String { rawId }
}

enum LocalPasskeyError: Error, CustomStringConvertible {
    case biometricUnavailable
    case biometricFailed
    case accountNotFound

    var description: String {
        switch self {
        case .biometricUnavailable:
            return "Biometric or system authentication is unavailable on this device"
        case .biometricFailed:
            return "Passkey authentication failed"
        case .accountNotFound:
            return "No Passkey account found"
        }
    }
}

@MainActor
final class LocalPasskeyService {
    private let defaults: UserDefaults
    private let storageKey = "cpcash.local.passkey.accounts"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func accounts() -> [LocalPasskeyAccount] {
        guard let data = defaults.data(forKey: storageKey),
              let accounts = try? JSONDecoder().decode([LocalPasskeyAccount].self, from: data)
        else {
            return []
        }
        return accounts.sorted { $0.createdAt > $1.createdAt }
    }

    func register(displayName: String) async throws -> LocalPasskeyAccount {
        try await requireDeviceOwnerAuthentication(reason: "Use Passkey to register CPCash")

        let privateKeyHex = Self.randomPrivateKeyHex()
        let account = LocalPasskeyAccount(
            rawId: UUID().uuidString.lowercased(),
            displayName: displayName,
            privateKeyHex: privateKeyHex,
            address: "",
            createdAt: Date()
        )

        var all = accounts()
        all.insert(account, at: 0)
        try persist(all)
        return account
    }

    func login(rawId: String?) async throws -> LocalPasskeyAccount {
        try await requireDeviceOwnerAuthentication(reason: "Use Passkey to sign in to CPCash")
        let all = accounts()
        guard !all.isEmpty else { throw LocalPasskeyError.accountNotFound }

        if let rawId {
            guard let account = all.first(where: { $0.rawId == rawId }) else {
                throw LocalPasskeyError.accountNotFound
            }
            return account
        }

        return all[0]
    }

    func updateAddress(rawId: String, address: String) throws {
        var all = accounts()
        guard let index = all.firstIndex(where: { $0.rawId == rawId }) else {
            throw LocalPasskeyError.accountNotFound
        }
        let account = all[index]
        all[index] = LocalPasskeyAccount(
            rawId: account.rawId,
            displayName: account.displayName,
            privateKeyHex: account.privateKeyHex,
            address: address,
            createdAt: account.createdAt
        )
        try persist(all)
    }

    private func persist(_ accounts: [LocalPasskeyAccount]) throws {
        let data = try JSONEncoder().encode(accounts)
        defaults.set(data, forKey: storageKey)
    }

    private func requireDeviceOwnerAuthentication(reason: String) async throws {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            throw LocalPasskeyError.biometricUnavailable
        }

        let success = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { ok, err in
                if let err {
                    continuation.resume(throwing: err)
                    return
                }
                continuation.resume(returning: ok)
            }
        }

        if !success {
            throw LocalPasskeyError.biometricFailed
        }
    }

    private static func randomPrivateKeyHex() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        if result != errSecSuccess {
            let fallback = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            return "0x" + fallback.padding(toLength: 64, withPad: "0", startingAt: 0)
        }
        return "0x" + bytes.map { String(format: "%02x", $0) }.joined()
    }
}
