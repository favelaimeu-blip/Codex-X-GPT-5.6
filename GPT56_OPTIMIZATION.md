# Codex-X GPT-5.6 优化版

当前版本：`0.2.35-gpt5.6.1`

这是基于 Codex-X v0.2.35 的 GPT-5.6-sol 原生优化版本。正式便携版直接使用当前用户的 `~/.codex` 和 `~/.codexx`，可接管原 Codex-X 的供应商、提示词和配置数据。

## 主要优化

- 默认模型：`gpt-5.6-sol`
- 默认 Wire API：`responses`
- 默认推理强度：`medium`
- 内置 `gpt-5.6-sol-unrestricted.md` 专用执行配置
- 供应商连接测试同时读取 `/models` 并确认目标模型是否存在
- GPT-5.6-sol 选项、推荐说明和检测结果直接显示在界面中
- 使用 `toml_edit` 结构化维护配置，保留中文项目路径
- 提示词文件名保留 `5.6` 点号
- 兼容 `gpt5.6`、`gpt5-6`、`gpt-5-6` 等旧名称并迁移为 `gpt-5.6`

## 数据位置

正式版直接使用：

- Codex 配置：`%USERPROFILE%\.codex`
- Codex-X 数据：`%USERPROFILE%\.codexx`

因此升级后会继续显示原有供应商和提示词。

## 源码与构建

源码目录：

```text
D:\codex_playground\Codex-X-gpt56
```

构建前检查：

```powershell
pnpm typecheck
cargo test --locked --lib
```

生产构建：

```powershell
pnpm --dir apps/desktop exec tauri build --no-bundle
```

生成的程序位于：

```text
apps\desktop\src-tauri\target\release\codex-x.exe
```

## 测试隔离

`scripts/verify-gpt56-isolation.ps1` 和 `scripts/build-gpt56-isolated.ps1` 只用于开发及构建验证。它们通过临时 `CODEX_HOME`/`CODEXX_HOME` 运行测试，避免测试过程改动正式配置；最终正式版不要求隔离启动。

## 已验证

- TypeScript typecheck
- Vite renderer production build
- Cargo check / clippy
- Rust 单元测试 52 项
- Windows release 构建
- GPT-5.6-sol 模型档案界面
- GPT-5.6-sol 专用提示词界面
- 中文 TOML 往返
- 旧提示词名称迁移