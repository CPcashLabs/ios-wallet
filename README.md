# WalletApp Swift Monorepo

一个面向 iOS 钱包场景的 Swift Monorepo，采用 `apps + packages + modules + tools` 分层组织，支持：
- iOS App 壳（SwiftUI）
- CLI 壳（本地联调与自动化）
- 可插拔业务模块
- 可复用的运行时/安全/后端能力包

## 特性
- `Swift Package Manager` 统一依赖与模块管理
- `xcodegen` 生成 iOS 工程，避免手工维护 project 文件
- 运行时能力边界清晰（`CoreRuntime`/`SecurityCore`/`BackendAPI`）
- 模块注册支持脚本化生成（`tools/ModuleRegistryPlugin`）

## 目录结构

```text
.
├── apps/
│   ├── cli/AppShell                # CLI 可执行壳
│   └── ios/AppShelliOS             # iOS SwiftUI 主壳
├── modules/
│   └── NftGallery                  # 示例业务模块
├── packages/
│   ├── CoreRuntime                 # 运行时协议/权限/路由/存储
│   ├── SecurityCore                # 签名与交易安全能力
│   ├── BackendAPI                  # 后端接口封装
│   └── WebDAppContainer            # WebView + EIP-1193 桥接
├── tools/
│   └── ModuleRegistryPlugin        # 模块注册生成工具（Phase 1 脚本）
├── Tests/
│   └── CoreRuntimeTests            # 核心运行时 smoke tests
├── Makefile
└── Package.swift
```

## 环境要求
- macOS
- Xcode 17+
- Swift 5.9+
- [xcodegen](https://github.com/yonaskolb/XcodeGen)

## 快速开始

### 1) Swift 包构建

```bash
make swift-build
```

### 2) 运行 CLI 壳

```bash
make cli-run
```

说明：若本地 keychain 中不存在测试私钥，CLI 会打印错误并退出，这是预期行为。

### 3) 生成 iOS 工程

```bash
make ios-generate
```

### 4) 构建 iOS 模拟器产物

```bash
make ios-build
```

## 测试

```bash
make swift-test
```

## 本地 CI（与仓库工作流对齐）

```bash
make ci
```

## 模块注册生成

```bash
make registry
```

该命令会扫描 `modules/*/*Manifest.swift`，并更新：
- `apps/cli/AppShell/Generated/ModuleRegistry.swift`

## 开源协作文档
- 贡献指南：`CONTRIBUTING.md`
- 安全策略：`SECURITY.md`
- 行为准则：`CODE_OF_CONDUCT.md`
- 架构说明：`docs/architecture.md`

## 兼容性路径
为兼容旧脚本，仓库根目录保留符号链接：
- `AppShell -> apps/cli/AppShell`
- `AppShelliOS -> apps/ios/AppShelliOS`
