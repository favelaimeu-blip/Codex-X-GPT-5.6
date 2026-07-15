# Codex-X GPT56 优化版

## 定位

这是从 Codex-X 派生的 **GPT-5.6-sol 独立优化版**。它位于单独的源码目录，使用独立产品名称、应用标识、版本号和数据目录，不会覆盖电脑上正在使用的 Codex-X、Codex 或 ChatGPT。

当前优化版标识：

| 项目 | GPT56 优化版 | 原版/当前环境 |
| --- | --- | --- |
| 产品名称 | `Codex-X GPT56` | `Codex-X` |
| 应用标识 | `com.yynxxxxx.codexx.gpt56` | `com.yynxxxxx.codexx` |
| 应用数据默认目录 | `~/.codexx-gpt56` | `~/.codexx` |
| 便携版 Codex 配置 | `portable/data/codex` | `~/.codex` |
| 便携版 Codex-X 数据 | `portable/data/codexx` | `~/.codexx` |
| 默认模型 | `gpt-5.6-sol` | 由原版配置决定 |

> 安全使用的关键：便携版请通过 `Launch-Codex-X-GPT56.cmd` 启动，不要直接双击 EXE。启动器只给子进程设置临时的 `CODEX_HOME` 和 `CODEXX_HOME`，不会修改注册表或用户级环境变量。

## 已完成的 GPT-5.6-sol 优化

### 1. 原生模型配置档案

- 将 `gpt-5.6-sol` 设为本分支默认模型。
- 供应商和 OpenAI Official 编辑页提供 GPT-5.6-sol 推荐入口，同时保留 GPT-5.5、GPT-5.4 和自定义模型。
- GPT-5.6-sol 默认使用 `responses` Wire API。
- GPT-5.6-sol 默认推理强度为 `medium`；旧模型仍保持兼容默认值。
- 不再把模型名称散落硬编码在多个表单和 TOML 预览逻辑中。

### 2. GPT-5.6-sol 专用提示词

- 内置 `examples/gpt-5.6-sol-unrestricted.md`。
- 模板 ID 和界面名称统一为 `gpt-5.6-sol-unrestricted`。
- 提示词文件名规范化时保留模型版本号中的点号，不会再把 `5.6` 静默改成 `5-6`。
- 仍可切换 GPT-5.5、GPT-5.4 或自定义提示词。

专用提示词属于本地模型指令配置。它用于改善编码工作流和工具使用习惯，但不会改变服务端模型权限，也不能覆盖服务端或更高优先级的指令。

### 3. 供应商能力检测

- “测试连接”同时提交模型 ID 和 Wire API。
- 优先请求 `/models` 并解析常见模型目录格式。
- 显示目标模型是否出现在供应商返回的模型列表中。
- 显示检测地址、模型数量、Wire API 和配置提示。
- HTTP `401`、`403` 或其他非 2xx 状态不会再被标记为连接成功。
- 当 GPT-5.6-sol 未使用 `responses` 时给出明确提示。

能力检测只能反映供应商当次响应。部分兼容接口不公开 `/models`，这时“连接正常但未返回模型目录”不等于模型一定可调用，仍应新建一次测试会话确认。

### 4. 配置兼容性与回归测试

- 继续使用结构化 TOML 读写，避免用文本替换破坏引号或中文路径。
- 增加中文项目路径 TOML 往返测试。
- 增加 GPT-5.6-sol 默认推理强度测试。
- 增加提示词文件名点号保留测试。
- 增加 `/models` 可用、缺失模型以及 403 失败判定测试。
- 增加独立应用数据目录测试。

## 隔离策略

### 源码和产物隔离

- 源码目录：`D:\codex_playground\Codex-X-gpt56`
- 构建产物：`D:\codex_playground\Codex-X-gpt56\artifacts`
- Rust 工具链：`D:\codex_playground\.toolchains`
- MSVC/Windows SDK：`D:\codex_playground\.toolchains\vs-buildtools`

构建脚本不会替换桌面的 `Codex-X.lnk`，不会写入现用 Codex-X 安装目录，也不会启动或关闭正在运行的 Codex/ChatGPT。

### 配置和运行数据隔离

隔离启动器为 GPT56 子进程设置：

```text
CODEX_HOME=<便携版目录>\data\codex
CODEXX_HOME=<便携版目录>\data\codexx
```

启动器在创建目录前会检查目标路径，若目标等于或位于当前用户的 `~/.codex` 内部则直接拒绝启动。变量只存在于 GPT56 子进程及其子进程中，脚本退出后不会留在系统环境中。

应用自身还使用不同的 Tauri 标识 `com.yynxxxxx.codexx.gpt56`，因此窗口/WebView 应用数据也与原版分开。

## 验证

在 PowerShell 中运行：

```powershell
Set-Location D:\codex_playground\Codex-X-gpt56
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify-gpt56-isolation.ps1
```

验证内容包括：

1. 产品名、应用标识和各处版本号是否一致。
2. 前端和 Rust 后端默认模型是否均为 `gpt-5.6-sol`。
3. Responses API、推理强度和专用提示词是否已登记。
4. `CODEX_HOME`、`CODEXX_HOME` 和 `.codexx-gpt56` 隔离逻辑是否存在。
5. 是否使用工作区 Rust 工具链。
6. TypeScript 类型检查和 Rust 测试是否通过。
7. 如提供 `-ArtifactPath`，检查 EXE 大小并生成 SHA-256。

默认报告写入：

```text
artifacts/gpt56-isolation-report.json
```

只做静态检查、不运行 TypeScript/Rust 命令：

```powershell
.\scripts\verify-gpt56-isolation.ps1 -SkipCommands
```

验证脚本只在系统临时目录创建测试用的 `CODEX_HOME` 和 `CODEXX_HOME`，不会读取或写入当前用户的 `~/.codex`。

## 构建独立便携版

```powershell
Set-Location D:\codex_playground\Codex-X-gpt56
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\build-gpt56-isolated.ps1
```

默认流程：

1. 使用 `D:\codex_playground\.toolchains\cargo` 和 `rustup`。
2. 从工作区 `vs-buildtools\Common7\Tools\VsDevCmd.bat` 导入 MSVC Linker 和 Windows SDK 环境。
3. 创建临时、隔离的 `CODEX_HOME` 与 `CODEXX_HOME`。
4. 运行完整隔离验证、TypeScript 类型检查和 Rust 测试。
5. 构建不带安装器的 Windows release EXE。
6. 生成带隔离启动器的 portable 文件夹。
7. 生成 SHA-256、验证报告和 portable ZIP。
8. 成功后删除临时测试目录并恢复构建进程的环境变量。

输出目录格式：

```text
artifacts/
└─ Codex-X-GPT56-<版本>-<时间>/
   ├─ gpt56-isolation-report.json
   ├─ gpt56-prebuild-report.json
   ├─ Codex-X-GPT56-<版本>-portable.zip
   └─ portable/
      ├─ Codex-X GPT56.exe
      ├─ Launch-Codex-X-GPT56.cmd
      ├─ Start-Codex-X-GPT56.ps1
      ├─ README-PORTABLE.txt
      ├─ SHA256.txt
      ├─ GPT56_OPTIMIZATION.md
      └─ LICENSE
```

常用构建选项：

```powershell
# node_modules 不存在时安装锁定版本依赖
.\scripts\build-gpt56-isolated.ps1 -InstallDependencies

# 同时生成 Tauri 原生安装器
.\scripts\build-gpt56-isolated.ps1 -NativeInstaller

# 仅调试构建问题时跳过测试
.\scripts\build-gpt56-isolated.ps1 -SkipChecks

# 不生成 ZIP
.\scripts\build-gpt56-isolated.ps1 -NoZip

# 保留临时隔离目录用于排查
.\scripts\build-gpt56-isolated.ps1 -KeepSandbox
```

## 使用便携版

1. 解压 portable ZIP 到一个新目录。
2. 双击 `Launch-Codex-X-GPT56.cmd`。
3. 首次启动后，在“关于”或诊断页确认 `CODEX_HOME` 指向该便携目录的 `data\codex`。
4. 单独配置 GPT56 版的供应商/API Key；不要在目录选择器中手动选择现用的 `C:\Users\<用户名>\.codex`。
5. 新建测试会话验证供应商是否真正开放 `gpt-5.6-sol`。

当前 Codex/ChatGPT 可以保持运行。GPT56 版与现用版本的数据目录不同，不需要卸载或覆盖任何程序。

## 恢复或删除

GPT56 版没有改动原版，因此不需要传统“回滚”。退出 GPT56 后直接删除它的 portable 文件夹及本项目 `artifacts` 中对应产物即可。原 Codex-X、Codex、ChatGPT 及 `~/.codex` 保持原样。
