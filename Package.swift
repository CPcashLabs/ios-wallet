// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WalletAppSwift",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(name: "CoreRuntime", targets: ["CoreRuntime"]),
        .library(name: "SecurityCore", targets: ["SecurityCore"]),
        .library(name: "BackendAPI", targets: ["BackendAPI"]),
        .library(name: "WebDAppContainer", targets: ["WebDAppContainer"]),
        .library(name: "NftGalleryModule", targets: ["NftGalleryModule"]),
        .executable(name: "AppShell", targets: ["AppShell"]),
    ],
    dependencies: [
        .package(url: "https://github.com/web3swift-team/web3swift.git", from: "3.1.0"),
    ],
    targets: [
        .target(
            name: "CoreRuntime",
            path: "packages/CoreRuntime/Sources/CoreRuntime"
        ),
        .target(
            name: "SecurityCore",
            dependencies: [
                "CoreRuntime",
                .product(name: "web3swift", package: "web3swift"),
            ],
            path: "packages/SecurityCore/Sources/SecurityCore"
        ),
        .target(
            name: "BackendAPI",
            path: "packages/BackendAPI/Sources/BackendAPI"
        ),
        .target(
            name: "WebDAppContainer",
            dependencies: ["CoreRuntime"],
            path: "packages/WebDAppContainer/Sources/WebDAppContainer"
        ),
        .target(
            name: "NftGalleryModule",
            dependencies: ["CoreRuntime"],
            path: "modules/NftGallery/Sources/NftGalleryModule"
        ),
        .executableTarget(
            name: "AppShell",
            dependencies: [
                "CoreRuntime",
                "SecurityCore",
                "BackendAPI",
                "WebDAppContainer",
                "NftGalleryModule",
            ],
            path: "apps/cli/AppShell",
            sources: ["Sources/AppShell/main.swift", "Generated/ModuleRegistry.swift"]
        ),
        .testTarget(
            name: "CoreRuntimeTests",
            dependencies: ["CoreRuntime"],
            path: "Tests/CoreRuntimeTests"
        ),
    ]
)
