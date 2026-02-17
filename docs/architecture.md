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

## iOS 状态分域（`apps/ios/AppShelliOS/Sources/State`）
- `AppStore`：应用门面，持有 `AppState` 与各领域 Store，作为 UI 层唯一入口
- `SessionStore`：登录态、地址、网络环境等会话域
- `HomeStore`：首页数据域（余额、消息、转账摘要）
- `MeStore`：我的域（个人资料、账单、地址簿、设置）
- `ReceiveStore`：收款域（网络选择、地址生命周期、分享）
- `TransferStore`：转账域（网络、地址候选、下单与支付）
- `UIStore`：Toast/Loading/Error 等 UI 状态域

> 当前策略：保持 `AppState` 作为兼容层，新增领域 Store 做解耦；后续页面逐步从 `AppState` 直接依赖迁移到领域 Store。

## iOS 导航契约
- 根导航容器：`HomeShellView` 维护 `homePath` 与 `mePath` 两套路径状态
- 根页（首页、我的）：
  - 隐藏系统导航栏
  - 底部 TabBar 常驻
- 子页面（push 进入）：
  - 使用系统导航栏（inline）
  - 默认隐藏 TabBar（保持沉浸式业务流）
- 防连点：`NavigationGuard` 对 route push 做 cooldown 去重

## Safe Area 规范
- 根页统一使用 `TopSafeAreaHeaderScaffold`
  - 通过 `safeAreaInset(edge: .top)` 注入固定头部
  - 内容区域从头部下方开始滚动
  - 禁止使用固定像素（如 `topClearance`）做机型适配
- 子页面统一使用 `FullscreenScaffold`
  - 仅负责背景与导航外观，不负责“魔法位移补偿”
- 背景层统一走 `GlobalFullscreenBackground`，确保全面屏与横竖屏一致
