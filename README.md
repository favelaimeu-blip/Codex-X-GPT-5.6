<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/中文-当前-blue" alt="中文" /></a>
  <a href="README.en.md"><img src="https://img.shields.io/badge/English-Switch-lightgrey" alt="English" /></a>
</p>

<div align="center">
  <img src="apps/desktop/src-tauri/icons/icon.png" alt="Codex-X GPT-5.6 Logo" width="150" />

  # Codex-X GPT-5.6-sol 专用破甲版

  **GPT-5.6-sol 一键破甲 · Provider 切换 · Codex 配置与工作流管理**

  基于原版 Codex-X `v0.2.35` 深度适配，内置 `gpt-5.6-sol-unrestricted.md` 专用破甲提示词，并提供 GPT-5.6-sol 模型档案、Responses API、Provider 检测、TOML / Auth 管理和本地会话同步。

  <p>
    <img src="https://img.shields.io/badge/version-0.2.35--gpt5.6.2-2563eb" alt="version 0.2.35-gpt5.6.2" />
    <img src="https://img.shields.io/badge/model-gpt--5.6--sol-7c3aed" alt="model gpt-5.6-sol" />
    <img src="https://img.shields.io/badge/一键破甲-unrestricted%20内置-dc2626" alt="内置一键破甲提示词" />
    <img src="https://img.shields.io/badge/Wire%20API-Responses-0ea5e9" alt="Responses API" />
    <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-555" alt="platform" />
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-16a34a" alt="MIT license" /></a>
  </p>

  <p>
    <a href="https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/releases"><b>下载版本</b></a>
    ·
    <a href="GPT56_OPTIMIZATION.md"><b>优化说明</b></a>
    ·
    <a href="https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/issues"><b>问题反馈</b></a>
  </p>
</div>

---

## 项目定位

Codex-X GPT-5.6-sol 专用破甲版是一个独立维护的 Codex-X 衍生版本，重点优化 `gpt-5.6-sol` 在 Codex 桌面端和 Codex CLI 工作流中的配置与破甲体验。

它不是简单地修改界面名称，而是为 GPT-5.6-sol 增加了完整的模型档案、默认参数、提示词文件、Provider 能力检测以及旧配置迁移逻辑。

> `gpt-5.6-sol` 是否可用取决于你所使用的 OpenAI 兼容 Provider 是否实际提供该模型。Codex-X 负责配置、检测和管理，不会在服务端不存在模型时凭空创建模型。

## 核心特色：GPT-5.6-sol 一键破甲

本项目将 **GPT-5.6-sol 破甲**作为主功能，而不是附带选项。内置的 [`gpt-5.6-sol-unrestricted.md`](examples/gpt-5.6-sol-unrestricted.md) 会通过 Codex 原生的 `model_instructions_file` 机制写入专用指令，强化模型在代码生成、安全研究、逆向分析、复杂自动化和长流程任务中的直接响应能力。

在应用的 **指令提示词** 页面点击一次即可完成：

1. 将专用破甲提示词写入 Codex 配置目录。
2. 自动设置 `model_instructions_file = "./gpt-5.6-sol-unrestricted.md"`。
3. 将模型档案与 `gpt-5.6-sol`、Responses API 和 `medium` 推理强度配套使用。
4. 支持随时禁用，恢复不加载该指令文件的状态。

| 状态 | 配置 | 典型响应方式 |
| --- | --- | --- |
| 破甲前 | 未启用专用指令文件 | 使用模型和 Provider 的默认响应风格，部分复杂请求可能较保守或泛化 |
| 破甲后 | 启用 `gpt-5.6-sol-unrestricted.md` | 在模型与 Provider 允许的范围内，更倾向于直接、完整、步骤化地完成任务 |

> 这里的“破甲”指通过 Codex 自定义指令机制加载强化提示词，不修改模型权重，也不能覆盖 Provider 的服务端策略。实际效果取决于模型、API Provider、服务端规则和 Codex 版本。

## 相比原版的主要优化

| 项目 | GPT-5.6-sol 专用版 |
| --- | --- |
| 默认模型 | `gpt-5.6-sol` |
| 默认 Wire API | `responses` |
| 默认推理强度 | `medium` |
| 核心破甲模板 | `gpt-5.6-sol-unrestricted.md`，界面一键启用 / 禁用 |
| 模型检测 | 测试 Provider 连接时读取 `/models` 并检查目标模型 |
| 配置维护 | 使用 `toml_edit` 结构化修改 TOML，尽量保留原有配置与中文路径 |
| 名称兼容 | 将 `gpt5.6`、`gpt5-6`、`gpt-5-6` 等旧写法迁移为 `gpt-5.6` |
| 数据模式 | 正式版直接使用当前用户的 `~/.codex` 与 `~/.codexx` |
| 产品标识 | `Codex-X GPT-5.6` / `0.2.35-gpt5.6.2` |

完整技术变更请参阅 [GPT56_OPTIMIZATION.md](GPT56_OPTIMIZATION.md)。

## 功能特性

- **GPT-5.6-sol 一键破甲**：内置专用 unrestricted 提示词，一键写入、启用或禁用 `model_instructions_file`。
- **GPT-5.6-sol 原生档案**：模型、Responses API、推理强度和专用提示词形成统一配置。
- **Provider 可视化管理**：配置 Base URL、API Key、模型、Wire API，并一键切换当前 Provider。
- **模型可用性检测**：连接测试不仅检查接口连通性，也会提示目标模型是否出现在模型列表中。
- **破甲状态可视化**：界面明确显示专用破甲模板、启用状态和目标配置文件。
- **TOML 可视化编辑**：读取和维护 `~/.codex/config.toml`，支持中文目录与未知字段保留。
- **Auth 管理**：读取和编辑 `~/.codex/auth.json`，区分 ChatGPT 登录态与第三方 API Key。
- **会话 Provider Sync**：检查 SQLite / rollout JSONL 中的 Provider 元数据并同步历史任务。
- **Skills / MCP 管理**：导入、安装、启用或禁用 Codex Skills 与 MCP Server。
- **跨平台构建**：基于 Tauri 2，可构建 Windows、macOS 与 Linux 安装包。

## 软件预览

<p align="center">
  <img src="docs/screenshots/app/preview.png" alt="Codex-X 应用界面预览" width="920" />
</p>

## 快速开始

### 1. 下载

前往 [GitHub Releases](https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/releases) 获取构建产物：

- Windows：`.msi` 或 portable `.zip`
- macOS：Apple Silicon / Intel `.dmg`
- Linux：`.deb` / `.rpm`

如果 Releases 暂无可下载文件，可以按照下方步骤从源码运行或构建。

### 2. 从源码运行

建议环境：

- Node.js 22
- pnpm 10
- Rust stable（项目最低 Rust `1.88.0`）
- Windows 10/11 需具备 Microsoft Edge WebView2 Runtime

```bash
git clone https://github.com/favelaimeu-blip/Codex-X-GPT-5.6.git
cd Codex-X-GPT-5.6
pnpm install
pnpm dev
```

构建桌面安装包：

```bash
pnpm build
```

仅生成 Windows 可执行文件、不打安装包：

```powershell
pnpm --dir apps/desktop exec tauri build --no-bundle
```

生成位置：

```text
apps/desktop/src-tauri/target/release/codex-x.exe
```

## 一键破甲与 GPT-5.6-sol 配置

1. 在 **Provider** 页面添加官方或第三方 OpenAI 兼容服务。
2. 填写 Provider 的 Base URL 与 API Key。
3. 将模型设置为 `gpt-5.6-sol`。
4. 将 Wire API 设置为 `responses`。
5. 执行连接测试，检查接口状态和模型列表检测结果。
6. 在 **指令提示词** 页面点击启用 `gpt-5.6-sol unrestricted 破甲` 模板。
7. 保存并切换到该 Provider。

对应的核心配置类似：

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "medium"
model_instructions_file = "./gpt-5.6-sol-unrestricted.md"

[model_providers.your-provider]
base_url = "https://your-provider.example/v1"
wire_api = "responses"
```

Provider 名称、认证字段和 Base URL 请以你的实际服务为准。

## 数据目录与升级方式

正式版直接使用 Codex 的现有数据目录：

```text
~/.codex/config.toml
~/.codex/auth.json
~/.codex/sessions/
~/.codex/archived_sessions/
~/.codexx/codexx.db
```

因此从原版 Codex-X 升级后，原有 Provider、提示词设置和本地会话仍可继续使用。

以下脚本仅用于开发和构建验证，不是正式版的必需启动方式：

```text
scripts/verify-gpt56-isolation.ps1
scripts/build-gpt56-isolated.ps1
scripts/start-gpt56-isolated.ps1
```

## 已验证项目

- TypeScript typecheck
- Vite renderer production build
- Cargo check / clippy
- Rust 单元测试 52 项
- Windows release 构建
- GPT-5.6-sol 模型档案与专用提示词界面
- `/models` 模型检测与 Responses API 推荐提示
- 中文 TOML 往返与旧提示词名称迁移

本地验证命令：

```bash
pnpm typecheck
pnpm --dir apps/desktop build:renderer
cargo test --locked --lib --manifest-path apps/desktop/src-tauri/Cargo.toml
```

## 技术栈

| 类型 | 技术 |
| --- | --- |
| 桌面框架 | Tauri 2 |
| 前端 | React 18 / TypeScript / Vite |
| 后端 | Rust |
| 本地数据 | SQLite / rusqlite |
| 配置处理 | TOML / JSON / `toml_edit` |
| 自动发布 | GitHub Actions / GitHub Releases |

## 项目结构

```text
apps/desktop/                       Tauri 桌面应用
apps/desktop/src/                   React / TypeScript 前端
apps/desktop/src-tauri/src/         Rust 后端
examples/gpt-5.6-sol-unrestricted.md
docs/                               文档与截图
scripts/                            构建及验证脚本
GPT56_OPTIMIZATION.md               GPT-5.6-sol 优化说明
```

## 发布

仓库中的 `.github/workflows/release.yml` 会在推送 `v*` 标签时构建多平台产物并创建 GitHub Release。

```bash
git tag v0.2.35-gpt5.6.2
git push origin v0.2.35-gpt5.6.2
```

## 使用说明

- 本项目所称的“破甲”是指通过 `model_instructions_file` 注入专用自定义指令，以强化 GPT-5.6-sol 的任务响应方式。
- `unrestricted` 是本项目内置破甲指令模板和界面档案的名称，不代表 OpenAI 或任何 Provider 提供官方的“无限制模式”。
- 提示词的实际表现由模型、Provider、服务端策略和客户端版本共同决定。
- 修改 `config.toml`、`auth.json` 或历史会话前，请确认你了解对应配置的作用。

## 许可证

本项目沿用原项目的 [MIT License](LICENSE)。衍生修改同样依据 MIT License 发布。

## 致谢与上游项目

本项目基于 **yynxxxxx 开发的 Codex-X** 进行适配和扩展：

- 原项目：[yynxxxxx/Codex-X](https://github.com/yynxxxxx/Codex-X)
- 当前维护版：[favelaimeu-blip/Codex-X-GPT-5.6](https://github.com/favelaimeu-blip/Codex-X-GPT-5.6)

感谢原作者提供 Codex-X 的桌面端架构、Provider 管理、配置编辑、会话同步和跨平台发布基础；也感谢所有参与测试、反馈和改进的社区成员。
