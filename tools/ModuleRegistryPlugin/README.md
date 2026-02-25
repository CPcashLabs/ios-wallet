# ModuleRegistryPlugin (Placeholder)

Phase 1 First provide `apps/cli/AppShell/Generated/ModuleRegistry.swift` as a static registry.

Later in Phase 2, replace with an SPM Build Tool Plugin:
1. Scan manifest declarations under `modules/*`
2. Auto-generate `Generated/ModuleRegistry.swift`
3. Install manifests at shell startup, without manually editing shell lists
