import CoreRuntime
import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

public struct NftGalleryManifest: ModuleManifest {
    public let moduleId = "module.nft.gallery"
    public let version = "0.1.0"
    public let displayName = "NFT Gallery"
    public let author = "Foundation"
    public let auditURL: URL? = URL(string: "https://example.org/audit/nft-gallery")

    public let capabilities: [CapabilityRequest] = [
        CapabilityRequest(id: .readAddress),
        CapabilityRequest(id: .readChainConfig),
    ]

    public var routes: [ModuleRoute] {
        [
            ModuleRoute(path: "/nft/home") { context in
#if canImport(SwiftUI)
                let status = context.permissionStatus(.readAddress).rawValue
                return AnyView(
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NFT Gallery")
                        Text("module: \(context.moduleId)")
                        Text("readAddress: \(status)")
                    }
                    .padding()
                )
#else
                return ModuleView("NFT Gallery Home - module=\(context.moduleId)")
#endif
            },
        ]
    }

    public let extensionPoints: [ExtensionPoint] = [
        .homeCard(HomeCardMeta(id: "nft-home", title: "NFT Gallery")),
        .settingsEntry(SettingsMeta(id: "nft-settings", title: "NFT Settings")),
    ]

    public init() {}
}
