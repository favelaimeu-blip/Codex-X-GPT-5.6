<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/中文-Switch-lightgrey" alt="中文" /></a>
  <a href="README.en.md"><img src="https://img.shields.io/badge/English-Current-blue" alt="English" /></a>
</p>

<div align="center">
  <img src="apps/desktop/src-tauri/icons/icon.png" alt="Codex-X GPT-5.6 Logo" width="150" />

  # Codex-X GPT-5.6-sol Armor-Breaking Edition

  **One-click GPT-5.6-sol armor-breaking · Provider switching · Codex configuration and workflow management**

  Deeply adapted from Codex-X `v0.2.35`, with the dedicated `gpt-5.6-sol-unrestricted.md` armor-breaking prompt, a native GPT-5.6-sol profile, Responses API defaults, Provider model detection, TOML / Auth management, and local session synchronization.

  <p>
    <img src="https://img.shields.io/badge/version-0.2.35--gpt5.6.2-2563eb" alt="version 0.2.35-gpt5.6.2" />
    <img src="https://img.shields.io/badge/model-gpt--5.6--sol-7c3aed" alt="model gpt-5.6-sol" />
    <img src="https://img.shields.io/badge/Armor--Breaking-unrestricted%20prompt%20included-dc2626" alt="armor-breaking prompt included" />
    <img src="https://img.shields.io/badge/Wire%20API-Responses-0ea5e9" alt="Responses API" />
    <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-555" alt="platform" />
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-16a34a" alt="MIT license" /></a>
  </p>

  <p>
    <a href="https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/releases"><b>Downloads</b></a>
    ·
    <a href="GPT56_OPTIMIZATION.md"><b>Optimization Notes</b></a>
    ·
    <a href="https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/issues"><b>Issues</b></a>
  </p>
</div>

---

## Project Scope

Codex-X GPT-5.6-sol Armor-Breaking Edition is an independently maintained derivative of Codex-X focused on configuring and applying enhanced instruction profiles to `gpt-5.6-sol` in Codex Desktop and Codex CLI workflows.

This edition does more than rename the UI. It adds a complete model profile, model-specific defaults, a dedicated prompt file, Provider capability checks, and migration logic for legacy configuration names.

> Availability of `gpt-5.6-sol` depends on whether your OpenAI-compatible Provider actually exposes that model. Codex-X manages and validates the configuration; it cannot create a server-side model that the Provider does not offer.

## Core Feature: One-Click GPT-5.6-sol Armor-Breaking

This project treats **GPT-5.6-sol armor-breaking** as a primary feature rather than an optional extra. The bundled [`gpt-5.6-sol-unrestricted.md`](examples/gpt-5.6-sol-unrestricted.md) file is loaded through Codex's native `model_instructions_file` mechanism to encourage more direct and complete responses in coding, security research, reverse engineering, complex automation, and long-running workflows.

One click on the **Instruction Prompt** page will:

1. Copy the dedicated armor-breaking prompt into the Codex configuration directory.
2. Set `model_instructions_file = "./gpt-5.6-sol-unrestricted.md"` automatically.
3. Pair the prompt with `gpt-5.6-sol`, the Responses API, and `medium` reasoning effort.
4. Allow the prompt to be disabled at any time, returning to the standard no-custom-instruction state.

| State | Configuration | Typical response style |
| --- | --- | --- |
| Before armor-breaking | Dedicated instruction file disabled | Uses the model and Provider defaults; some complex requests may receive conservative or generic responses |
| After armor-breaking | `gpt-5.6-sol-unrestricted.md` enabled | Within the model and Provider's permitted behavior, tends to respond more directly, completely, and step by step |

> “Armor-breaking” in this project means loading an enhanced custom instruction file through Codex. It does not modify model weights or override server-side Provider policies. Results depend on the model, API Provider, server rules, and Codex version.

## Key Changes from Upstream

| Item | GPT-5.6-sol Edition |
| --- | --- |
| Default model | `gpt-5.6-sol` |
| Default Wire API | `responses` |
| Default reasoning effort | `medium` |
| Core armor-breaking template | `gpt-5.6-sol-unrestricted.md`, enabled or disabled with one click |
| Model detection | Reads `/models` during Provider testing and checks for the target model |
| Configuration updates | Uses `toml_edit` for structured TOML updates while preserving existing fields and Unicode paths |
| Legacy aliases | Migrates names such as `gpt5.6`, `gpt5-6`, and `gpt-5-6` to `gpt-5.6` |
| Data mode | Uses the current user's `~/.codex` and `~/.codexx` directly |
| Product identity | `Codex-X GPT-5.6` / `0.2.35-gpt5.6.2` |

See [GPT56_OPTIMIZATION.md](GPT56_OPTIMIZATION.md) for the complete technical change list.

## Features

- **One-click GPT-5.6-sol armor-breaking**: includes a dedicated unrestricted prompt and manages `model_instructions_file` with one click.
- **Native GPT-5.6-sol profile**: model, Responses API, reasoning effort, and prompt settings are managed as one profile.
- **Visual Provider management**: configure Base URL, API Key, model, and Wire API, then switch Providers with one click.
- **Model availability checks**: Provider tests validate connectivity and report whether the target model is present in the model list.
- **Visible armor-breaking status**: clearly displays the dedicated template, enablement state, and target configuration file.
- **Visual TOML editing**: reads and maintains `~/.codex/config.toml`, including Unicode paths and unknown-field preservation.
- **Auth management**: reads and edits `~/.codex/auth.json`, distinguishing ChatGPT login state from third-party API Keys.
- **Session Provider Sync**: checks and synchronizes Provider metadata in SQLite databases and rollout JSONL files.
- **Skills / MCP management**: import, install, enable, or disable Codex Skills and MCP Servers.
- **Cross-platform builds**: built with Tauri 2 for Windows, macOS, and Linux.

## Preview

<p align="center">
  <img src="docs/screenshots/app/preview.png" alt="Codex-X application preview" width="920" />
</p>

## Quick Start

### 1. Download

Visit [GitHub Releases](https://github.com/favelaimeu-blip/Codex-X-GPT-5.6/releases) for packaged builds:

- Windows: `.msi` or portable `.zip`
- macOS: Apple Silicon / Intel `.dmg`
- Linux: `.deb` / `.rpm`

If no release assets are available yet, run or build the project from source.

### 2. Run from Source

Recommended environment:

- Node.js 22
- pnpm 10
- Rust stable (minimum project version: Rust `1.88.0`)
- Microsoft Edge WebView2 Runtime on Windows 10/11

```bash
git clone https://github.com/favelaimeu-blip/Codex-X-GPT-5.6.git
cd Codex-X-GPT-5.6
pnpm install
pnpm dev
```

Build desktop bundles:

```bash
pnpm build
```

Generate only the Windows executable without an installer bundle:

```powershell
pnpm --dir apps/desktop exec tauri build --no-bundle
```

Output path:

```text
apps/desktop/src-tauri/target/release/codex-x.exe
```

## One-Click Armor-Breaking and GPT-5.6-sol Setup

1. Add an official or third-party OpenAI-compatible service on the **Provider** page.
2. Enter the Provider Base URL and API Key.
3. Set the model to `gpt-5.6-sol`.
4. Set Wire API to `responses`.
5. Run the connection test and review both connectivity and model-list results.
6. Click to enable the `gpt-5.6-sol unrestricted armor-breaking` template on the **Instruction Prompt** page.
7. Save and switch to the Provider.

The core configuration looks like this:

```toml
model = "gpt-5.6-sol"
model_reasoning_effort = "medium"
model_instructions_file = "./gpt-5.6-sol-unrestricted.md"

[model_providers.your-provider]
base_url = "https://your-provider.example/v1"
wire_api = "responses"
```

Provider names, authentication fields, and Base URLs must match your actual service.

## Data Directories and Upgrades

The production edition directly uses the existing Codex data directories:

```text
~/.codex/config.toml
~/.codex/auth.json
~/.codex/sessions/
~/.codex/archived_sessions/
~/.codexx/codexx.db
```

Existing Providers, prompt settings, and local sessions therefore remain available when upgrading from the upstream Codex-X edition.

The following scripts are only for development and build verification; they are not required to launch the production application:

```text
scripts/verify-gpt56-isolation.ps1
scripts/build-gpt56-isolated.ps1
scripts/start-gpt56-isolated.ps1
```

## Verified

- TypeScript typecheck
- Vite renderer production build
- Cargo check / clippy
- 52 Rust unit tests
- Windows release build
- GPT-5.6-sol model profile and dedicated prompt UI
- `/models` detection and Responses API recommendations
- Unicode TOML round trips and legacy prompt-name migration

Local verification commands:

```bash
pnpm typecheck
pnpm --dir apps/desktop build:renderer
cargo test --locked --lib --manifest-path apps/desktop/src-tauri/Cargo.toml
```

## Tech Stack

| Category | Technology |
| --- | --- |
| Desktop framework | Tauri 2 |
| Frontend | React 18 / TypeScript / Vite |
| Backend | Rust |
| Local data | SQLite / rusqlite |
| Configuration | TOML / JSON / `toml_edit` |
| Automated releases | GitHub Actions / GitHub Releases |

## Repository Layout

```text
apps/desktop/                       Tauri desktop application
apps/desktop/src/                   React / TypeScript frontend
apps/desktop/src-tauri/src/         Rust backend
examples/gpt-5.6-sol-unrestricted.md
docs/                               Documentation and screenshots
scripts/                            Build and verification scripts
GPT56_OPTIMIZATION.md               GPT-5.6-sol optimization notes
```

## Releases

The `.github/workflows/release.yml` workflow builds cross-platform artifacts and creates a GitHub Release whenever a `v*` tag is pushed.

```bash
git tag v0.2.35-gpt5.6.2
git push origin v0.2.35-gpt5.6.2
```

## Usage Notes

- “Armor-breaking” in this project refers to injecting a dedicated custom instruction through `model_instructions_file` to strengthen GPT-5.6-sol task responses.
- `unrestricted` is the name of the bundled armor-breaking instruction template and UI profile. It is not an official “unrestricted mode” provided by OpenAI or any Provider.
- Actual prompt behavior depends on the model, Provider, server-side policies, and client version.
- Understand the purpose of each setting before changing `config.toml`, `auth.json`, or historical session metadata.

## License

This project retains the upstream [MIT License](LICENSE). Derivative changes are also distributed under the MIT License.

## Credits and Upstream

This project is adapted from **Codex-X by yynxxxxx**:

- Upstream project: [yynxxxxx/Codex-X](https://github.com/yynxxxxx/Codex-X)
- Maintained edition: [favelaimeu-blip/Codex-X-GPT-5.6](https://github.com/favelaimeu-blip/Codex-X-GPT-5.6)

Thanks to the original author for the Codex-X desktop architecture, Provider management, configuration editor, session synchronization, and cross-platform release foundation, and to all community members who contributed testing, feedback, and improvements.
