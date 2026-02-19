import BackendAPI
import CoreRuntime
import Foundation
import SecurityCore
@testable import AppShelliOS

@MainActor
func makeAppState(_ scenario: UITestScenario = .happy) -> AppState {
    AppState(dependencies: .uiTest(scenario: scenario))
}

@MainActor
func makeAppState(
    scenario: UITestScenario = .happy,
    securityService: SecurityServing
) -> AppState {
    let base = AppDependencies.uiTest(scenario: scenario)
    let deps = AppDependencies(
        securityService: securityService,
        backendFactory: base.backendFactory,
        passkeyService: base.passkeyService,
        clock: base.clock,
        idGenerator: base.idGenerator,
        logger: base.logger
    )
    return AppState(dependencies: deps)
}

func decodeFixture<T: Decodable>(_ object: Any, as type: T.Type = T.self) -> T {
    do {
        let data = try JSONSerialization.data(withJSONObject: object)
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        fatalError("decodeFixture failed for \(T.self): \(error)")
    }
}

struct FixedClock: AppClock {
    var now: Date
}

@MainActor
final class FailingPasskeyService: PasskeyServing {
    enum Failure: Error {
        case failed
    }

    let error: Error

    init(error: Error = Failure.failed) {
        self.error = error
    }

    func accounts() -> [LocalPasskeyAccount] {
        []
    }

    func register(displayName _: String) async throws -> LocalPasskeyAccount {
        throw error
    }

    func login(rawId _: String?) async throws -> LocalPasskeyAccount {
        throw error
    }

    func updateAddress(rawId _: String, address _: String) throws {}
}

struct StaticSecurityService: SecurityServing {
    var address: Address = Address("0x1111111111111111111111111111111111111111")
    var signError: Error?

    func createAccount() throws -> Address {
        address
    }

    func importAccount(_: EncryptedImportBlob) throws -> Address {
        address
    }

    func activeAddress() throws -> Address {
        address
    }

    func signPersonalMessage(_: SignMessageRequest) throws -> Signature {
        if let signError {
            throw signError
        }
        return Signature("0xmock-signature")
    }

    func signTypedData(_: SignTypedDataRequest) throws -> Signature {
        Signature("0xtyped")
    }

    func signAndSendTransaction(_: SendTxRequest) throws -> TxHash {
        TxHash("0x3333333333333333333333333333333333333333333333333333333333333333")
    }

    func waitForTransactionConfirmation(_: WaitTxConfirmationRequest) async throws -> TxConfirmation {
        TxConfirmation(
            txHash: "0x3333333333333333333333333333333333333333333333333333333333333333",
            blockNumber: 1,
            status: 1
        )
    }
}

final class ControlledConfirmationSecurityService: SecurityServing {
    enum ConfirmationMode {
        case success(status: Int?, blockNumber: UInt64 = 1)
        case timeout
        case executionFailed
    }

    var address: Address = Address("0x1111111111111111111111111111111111111111")
    var signError: Error?
    var mode: ConfirmationMode = .success(status: 1)
    private(set) var waitCallCount = 0

    func createAccount() throws -> Address {
        address
    }

    func importAccount(_: EncryptedImportBlob) throws -> Address {
        address
    }

    func activeAddress() throws -> Address {
        address
    }

    func signPersonalMessage(_: SignMessageRequest) throws -> Signature {
        Signature("0xmock-signature")
    }

    func signTypedData(_: SignTypedDataRequest) throws -> Signature {
        Signature("0xtyped")
    }

    func signAndSendTransaction(_: SendTxRequest) throws -> TxHash {
        if let signError {
            throw signError
        }
        return TxHash("0x3333333333333333333333333333333333333333333333333333333333333333")
    }

    func waitForTransactionConfirmation(_ req: WaitTxConfirmationRequest) async throws -> TxConfirmation {
        waitCallCount += 1
        switch mode {
        case let .success(status, blockNumber):
            return TxConfirmation(txHash: req.txHash, blockNumber: blockNumber, status: status)
        case .timeout:
            throw BackendAPIError.serverError(code: -1, message: "Transaction confirmation timeout")
        case .executionFailed:
            return TxConfirmation(txHash: req.txHash, blockNumber: 1, status: 0)
        }
    }
}
