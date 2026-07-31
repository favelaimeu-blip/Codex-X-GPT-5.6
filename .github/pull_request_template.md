## Summary

Describe the problem and the approach used to solve it.

## Validation

- [ ] `pnpm typecheck`
- [ ] `pnpm --dir apps/desktop build:renderer`
- [ ] `cargo test --locked --lib --manifest-path apps/desktop/src-tauri/Cargo.toml`
- [ ] I tested the affected user workflow manually, when applicable.

## Safety checklist

- [ ] This change does not commit API keys, tokens, credentials, or private user data.
- [ ] Configuration and session migrations preserve existing user data.
- [ ] User-facing changes include updated documentation or release notes.
