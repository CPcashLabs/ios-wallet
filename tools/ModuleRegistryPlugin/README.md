# ModuleRegistryPlugin（占位）

Phase 1 先提供 `apps/cli/AppShell/Generated/ModuleRegistry.swift` 作为静态注册表。

后续 Phase 2 将替换为 SPM Build Tool Plugin：
1. 扫描 `modules/*` 的 manifest 声明
2. 自动生成 `Generated/ModuleRegistry.swift`
3. 主壳启动时安装 manifests，无需手改主壳列表
