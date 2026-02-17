import BackendAPI
import CoreRuntime
import Foundation
import SecurityCore

protocol BackendServing {
    var auth: AuthServicing { get }
    var wallet: WalletServicing { get }
    var receive: ReceiveServicing { get }
    var order: OrderServicing { get }
    var message: MessageServicing { get }
    var addressBook: AddressBookServicing { get }
    var profile: ProfileServicing { get }
    var bill: BillServicing { get }
    var settings: SettingsServicing { get }
    var executor: RequestExecutor { get }
}

extension BackendAPI: BackendServing {}

protocol SecurityServing {
    func createAccount() throws -> Address
    func importAccount(_ encryptedInput: EncryptedImportBlob) throws -> Address
    func activeAddress() throws -> Address

    func signPersonalMessage(_ req: SignMessageRequest) throws -> Signature
    func signTypedData(_ req: SignTypedDataRequest) throws -> Signature
    func signAndSendTransaction(_ req: SendTxRequest) throws -> TxHash
    func signAndSendTransactionAsync(_ req: SendTxRequest) async throws -> TxHash
}

extension SecurityServing {
    func signAndSendTransactionAsync(_ req: SendTxRequest) async throws -> TxHash {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    continuation.resume(returning: try signAndSendTransaction(req))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension StubSecurityCore: SecurityServing {}

@MainActor
protocol PasskeyServing: AnyObject {
    func accounts() -> [LocalPasskeyAccount]
    func register(displayName: String) async throws -> LocalPasskeyAccount
    func login(rawId: String?) async throws -> LocalPasskeyAccount
    func updateAddress(rawId: String, address: String) throws
}

extension LocalPasskeyService: PasskeyServing {}

protocol AppClock {
    var now: Date { get }
}

struct SystemAppClock: AppClock {
    var now: Date { Date() }
}

protocol AppIDGenerator {
    func makeID() -> String
}

struct UUIDAppIDGenerator: AppIDGenerator {
    func makeID() -> String { UUID().uuidString }
}

protocol AppLogger {
    func log(_ message: String)
}

struct SilentAppLogger: AppLogger {
    func log(_ message: String) {}
}

struct AppDependencies {
    let securityService: SecurityServing
    let backendFactory: (EnvironmentConfig) -> BackendServing
    let passkeyService: PasskeyServing
    let clock: AppClock
    let idGenerator: AppIDGenerator
    let logger: AppLogger

    @MainActor
    static func live() -> AppDependencies {
        AppDependencies(
            securityService: StubSecurityCore(),
            backendFactory: { environment in
                BackendAPI(environment: environment)
            },
            passkeyService: LocalPasskeyService(),
            clock: SystemAppClock(),
            idGenerator: UUIDAppIDGenerator(),
            logger: SilentAppLogger()
        )
    }
}
