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
  - 路由层仅负责 TabBar 可见性，不再包裹页面背景容器
- 防连点：`NavigationGuard` 对 route push 做 cooldown 去重

## Safe Area 规范
- 根页统一使用 `TopSafeAreaHeaderScaffold`
  - 通过 `safeAreaInset(edge: .top)` 注入固定头部
  - 内容区域从头部下方开始滚动
  - 禁止使用固定像素（如 `topClearance`）做机型适配
- 子页面统一使用 `SafeAreaScreen`
  - `SafeAreaScreen` 内部复用 `FullscreenScaffold`，统一背景与安全区契约
  - 背景层可全屏（`ignoresSafeArea`），内容层必须遵守 safe area
  - 底部固定操作统一通过 `safeAreaInset(edge: .bottom)` 注入
- 背景层统一走 `GlobalFullscreenBackground`，确保全面屏与横竖屏一致
- 避免双层容器：页面内部不再叠加路由层 `fullscreenScaffold`，防止导航层与 safe area 叠压

## iOS 分层边界（AppShelliOS）
- `Sources/Views`：仅负责渲染、交互和路由触发，不承载业务编排
- `Sources/State`：Store 负责页面态聚合与发布（`@Published` 最小字段原则）
- `Sources/Domain/UseCases`：领域编排层，承接 `AppState` 对外能力并组织流程
- `Sources/Data`：Repository/Service 适配层，隔离后端与链路访问细节
- `Sources/Infrastructure`：依赖注入、格式化、错误映射、日志等基础能力

> 兼容策略：`AppState` 仍对外保持原方法与语义，内部逐步委派到 UseCase，不允许业务行为漂移。

## 列表与输入统一规范
- 稳定 identity：列表行统一通过 `StableRowID` 生成稳定主键，禁止以 `index` 作为唯一标识。
- 分页并发门禁：滚动分页场景统一使用 `PaginationGate`，避免重复请求与乱序 append。
- 地址输入解析：扫码/输入归一化统一走 `AddressInputParser`，避免页面各自维护正则与裁剪逻辑。
- 聚合快照：账单分组统计采用快照构建（`BillSectionSnapshot`）并在数据变更时重建，避免 `body` 周期内重算。

## 依赖注入约定
- 统一入口：`AppDependencies`
- 协议边界：
  - `BackendServing`
  - `SecurityServing`
  - `PasskeyServing`
  - `AppClock`
  - `AppIDGenerator`
  - `AppLogger`
- `AppState` 必须支持注入构造，同时保留默认 `init()` 的线上行为一致性
- 单测优先注入假时钟/假 ID/假日志，避免依赖系统时间与副作用

## 并发与任务生命周期规范
- 禁止在 UI 关键路径使用阻塞式等待（如信号量阻塞网络）
- `onChange + Task` 需具备取消策略（`task(id:)` 或显式 `Task` 句柄）
- 可延迟行为使用可取消 `Task.sleep`，不使用不可取消的 `DispatchQueue.main.asyncAfter`
- 长流程与轮询必须检查 `Task.isCancelled`
- UI 状态写入必须在 `@MainActor` 边界内完成

## 死代码清理准入规则
- 删除动作必须满足“双重准入”：
  1. 全仓引用扫描为 0（`rg` 证据）
  2. 三道门禁全部通过：`make swift-build`、`make swift-test`、`make ios-build`
- 删除提交需独立 commit，确保可单独回滚
- 对迁移期兼容层，先收敛调用方再删除旧入口，禁止跨阶段混删

## 日志与敏感信息规范
- 日志默认最小化，禁止输出完整地址、完整交易哈希、token 等敏感值
- 地址/哈希统一脱敏后记录（前后缀保留，中间打码）
- 错误日志优先结构化短消息，避免直接透传底层原始异常文本到用户面

## iOS 测试基线
- iOS 测试目标：`AppShelliOSTests`
- 命令入口：`make ios-test`
- CI 需同时执行：
  - `make swift-build`
  - `make swift-test`
  - `make ios-build`
  - `make ios-test`
