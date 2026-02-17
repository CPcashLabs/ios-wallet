# Contributing Guide

感谢你为 WalletApp Swift Monorepo 做贡献。

## 开发前提
- macOS
- Xcode 17+
- Swift 5.9+
- xcodegen

## 本地开发流程
1. 拉取代码后先执行 `make swift-build`
2. 执行 `make swift-test`
3. 涉及 iOS 代码时执行 `make ios-generate && make ios-build`
4. 如修改模块清单，执行 `make registry`

## 分支与提交建议
- 建议从 `main` 拉取新分支
- 提交信息尽量包含变更范围，例如：
  - `core: add runtime smoke tests`
  - `docs: refresh README and architecture docs`

## 代码风格
- 仓库使用 `.editorconfig`
- Swift 代码使用 4 空格缩进
- Makefile 使用 tab 缩进

## Pull Request 要求
- PR 描述需包含：
  - 变更目的
  - 关键实现点
  - 验证结果（构建/测试命令与结果）
- 不要在同一个 PR 混入无关重构

## 讨论与反馈
如涉及架构调整，建议先开 issue 讨论边界与迁移策略，再提交实现。
