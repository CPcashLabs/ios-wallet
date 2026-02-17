import XCTest
@testable import CoreRuntime

#if canImport(SwiftUI)
import SwiftUI
#endif

final class AppRuntimeTests: XCTestCase {
    func testInstallRegistersModuleAndRoute() {
        let runtime = makeRuntime()
        runtime.install([TestManifest()])

        XCTAssertEqual(runtime.installedModuleIds, ["module.test"])
        XCTAssertNotNil(runtime.route("/test"))
    }

    func testContextThrowsWhenModuleIsMissing() {
        let runtime = makeRuntime()

        XCTAssertThrowsError(try runtime.context(for: "module.unknown")) { error in
            guard case let RuntimeError.moduleNotInstalled(moduleId) = error else {
                XCTFail("Expected moduleNotInstalled, got \(error)")
                return
            }
            XCTAssertEqual(moduleId, "module.unknown")
        }
    }

    func testCapabilityAccessRequiresExplicitPermission() async throws {
        let runtime = makeRuntime()
        runtime.install([TestManifest()])
        let context = try runtime.context(for: "module.test")

        XCTAssertThrowsError(try context.capabilities.readAddress()) { error in
            guard case let RuntimeError.permissionDenied(moduleId, capability) = error else {
                XCTFail("Expected permissionDenied, got \(error)")
                return
            }
            XCTAssertEqual(moduleId, "module.test")
            XCTAssertEqual(capability, .readAddress)
        }

        _ = try await context.requestPermission(CapabilityRequest(id: .readAddress))
        _ = try await context.requestPermission(CapabilityRequest(id: .readChainConfig))

        let address = try context.capabilities.readAddress()
        let chain = try context.capabilities.readChainConfig()

        XCTAssertEqual(address.value, "0x1111111111111111111111111111111111111111")
        XCTAssertEqual(chain.chainId, 199)
    }

    func testContextStorageUsesNamespaces() throws {
        let runtime = makeRuntime()
        runtime.install([TestManifest()])
        let context = try runtime.context(for: "module.test")

        let walletStorage = context.storage(namespace: "wallet")
        let profileStorage = context.storage(namespace: "profile")

        walletStorage.setValue("1", forKey: "counter")

        XCTAssertEqual(walletStorage.value(forKey: "counter"), "1")
        XCTAssertNil(profileStorage.value(forKey: "counter"))
    }
}

private struct TestManifest: ModuleManifest {
    let moduleId = "module.test"
    let version = "1.0.0"
    let displayName = "Test Module"
    let author = "Tests"
    let auditURL: URL? = nil
    let capabilities = [
        CapabilityRequest(id: .readAddress),
        CapabilityRequest(id: .readChainConfig),
    ]
    let routes: [ModuleRoute] = [
        ModuleRoute(path: "/test", makeView: { _ in
            testModuleView()
        }),
    ]
    let extensionPoints: [ExtensionPoint] = []
}

private func makeRuntime() -> AppRuntime {
    AppRuntime(
        securityService: TestSecurityService(),
        permissionManager: PermissionManager(),
        confirmFlow: DefaultConfirmFlow(autoApprove: true),
        chainConfigProvider: StaticChainConfigProvider(
            config: ChainConfig(chainId: 199, rpcURL: "https://rpc.bittorrentchain.io")
        )
    )
}

private struct TestSecurityService: SecurityService {
    func createAccount() throws -> Address {
        Address("0x1111111111111111111111111111111111111111")
    }

    func importAccount(_ encryptedInput: EncryptedImportBlob) throws -> Address {
        Address("0x1111111111111111111111111111111111111111")
    }

    func activeAddress() throws -> Address {
        Address("0x1111111111111111111111111111111111111111")
    }

    func signPersonalMessage(_ req: SignMessageRequest) throws -> Signature {
        Signature("0xsignature")
    }

    func signTypedData(_ req: SignTypedDataRequest) throws -> Signature {
        Signature("0xtyped")
    }

    func signAndSendTransaction(_ req: SendTxRequest) throws -> TxHash {
        TxHash("0xtx")
    }
}

private func testModuleView() -> ModuleView {
#if canImport(SwiftUI)
    AnyView(EmptyView())
#else
    ModuleView("test-view")
#endif
}
