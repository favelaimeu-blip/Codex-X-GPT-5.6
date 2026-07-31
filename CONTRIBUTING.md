# Contributing to Codex-X GPT-5.6

Thank you for helping improve Codex-X GPT-5.6. Keep changes focused, explain user-visible behavior, and avoid including credentials or private Codex configuration in issues, commits, logs, or screenshots.

## Development environment

- Node.js 22
- pnpm 10
- Rust 1.88.0 or newer
- Platform dependencies required by Tauri 2

Install dependencies and start the desktop application:

```bash
pnpm install
pnpm dev
```

## Required checks

Run these checks before opening a pull request:

```bash
pnpm typecheck
pnpm --dir apps/desktop build:renderer
cargo fmt --manifest-path apps/desktop/src-tauri/Cargo.toml --all -- --check
cargo test --locked --lib --manifest-path apps/desktop/src-tauri/Cargo.toml
```

## Pull requests

1. Open an issue first for broad behavioral changes or changes that affect stored user data.
2. Keep each pull request focused on one problem.
3. Add or update tests for behavior changes.
4. Update `CHANGELOG.md` and user documentation when behavior changes.
5. Preserve unknown TOML fields, existing authentication data, and local session data unless the change explicitly migrates them.

## Security reports

Do not report vulnerabilities in a public issue. Follow [SECURITY.md](SECURITY.md) to submit a private report.

By contributing, you agree that your contributions will be licensed under the repository's MIT License.
