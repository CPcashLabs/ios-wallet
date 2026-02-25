import CoreRuntime
import SecurityCore
import WebDAppContainer
import Foundation

func runAppShell() async throws {
    let security = StubSecurityCore()
    let permissionManager = PermissionManager()
    let confirmFlow = DefaultConfirmFlow(autoApprove: true)
    let chainConfigProvider = StaticChainConfigProvider(
        config: ChainConfig(chainId: 199, rpcURL: "https://rpc.bittorrentchain.io")
    )

    let runtime = AppRuntime(
        securityService: security,
        permissionManager: permissionManager,
        confirmFlow: confirmFlow,
        chainConfigProvider: chainConfigProvider
    )

    let manifests = GeneratedModuleRegistry.all()
    runtime.install(manifests)

    print("== AppShell Phase1 Boot ==")
    print("Installed modules: \(runtime.installedModuleIds)")

    guard let first = manifests.first else {
        print("No modules found")
        return
    }

    let context = try runtime.context(for: first.moduleId)

    // Phase 1: Grant manifest-declared capabilities to demo modules
    for capability in first.capabilities {
        let grant = try await context.requestPermission(capability)
        print("Granted: \(grant.moduleId) -> \(grant.capability.rawValue)")
    }

    // Read address and chain configuration
    let address = try context.capabilities.readAddress()
    let chain = try context.capabilities.readChainConfig()
    print("Active address: \(address.value)")
    print("Chain config: chainId=\(chain.chainId), rpc=\(chain.rpcURL)")

    // Explicitly request high-risk capabilities and trigger confirmation flow (stub auto-approves)
    _ = try await context.requestPermission(CapabilityRequest(id: .signMessage))
    let sig = try await context.capabilities.signMessage("hello phase1")
    print("Signature: \(sig.value)")

    _ = try await context.requestPermission(CapabilityRequest(id: .sendTransaction))
    let tx = SendTxRequest(
        source: .module(id: first.moduleId, version: first.version),
        from: address,
        to: Address("0x2222222222222222222222222222222222222222"),
        value: "1000000",
        data: nil,
        chainId: chain.chainId
    )
    let txHash = try await context.capabilities.sendTransaction(tx)
    print("TxHash: \(txHash.value)")

    // WebDApp container request demo
    let bridge = WebDAppBridge(origin: "https://example-dapp.org", capabilities: context.capabilities)
    let dappSig = try await bridge.handle(
        WebDAppBridgeRequest(
            origin: "https://example-dapp.org",
            method: "personal_sign",
            params: [AnyCodable("hello from dapp")]
        )
    )
    print("DApp personal_sign: \(dappSig.value)")

    print("== Phase1 Ready ==")
}

do {
    try await runAppShell()
} catch {
    fputs("AppShell failed: \(error)\n", stderr)
    exit(1)
}
