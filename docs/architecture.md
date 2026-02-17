# Architecture Overview

## 设计目标
- 业务模块可插拔
- 钱包核心能力边界清晰
- 壳层（CLI/iOS）可复用同一套核心能力

## 分层

### 1) App Layer (`apps/*`)
- `apps/ios/AppShelliOS`: UI 壳，负责界面与导航编排
- `apps/cli/AppShell`: CLI 壳，负责本地联调和自动化验证

### 2) Runtime Layer (`packages/CoreRuntime`)
- 模块协议（`ModuleManifest`）
- 权限模型（`PermissionManaging`）
- 路由与上下文（`RuntimeContext`）
- 命名空间存储（`InMemoryStorageHub`）

### 3) Capability Layer
- `packages/SecurityCore`: 账户、签名、交易发送
- `packages/BackendAPI`: 业务 API 与模型封装
- `packages/WebDAppContainer`: DApp 桥接能力

### 4) Module Layer (`modules/*`)
- 每个业务模块独立声明 manifest 与扩展点
- 通过注册表接入壳层运行时

## 模块装配流程
1. 壳层加载 `GeneratedModuleRegistry` 产出的模块清单
2. `AppRuntime` 安装 manifests 并建立路由索引
3. 模块通过 `RuntimeContext` 访问受控能力
4. 权限通过 `PermissionManager` 进行统一管理

## 工程约束
- 业务逻辑放在 `packages`/`modules`，壳层只做装配与表现
- 目录命名采用语义化分层，避免按技术细节横向散落
- 通过 `Makefile` 统一开发命令入口
