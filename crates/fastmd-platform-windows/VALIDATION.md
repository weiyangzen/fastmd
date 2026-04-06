# `fastmd-platform-windows` Validation Notes

Reference surface:

- `apps/macos`

Stage 2 target locked by this crate:

- Windows 11
- Explorer

This validation file is crate-local evidence only. It does not claim full Windows parity and it does not replace the Stage 2 layer gates.

## Implemented in this slice

- buildable Rust library crate created
- Windows 11 + Explorer-only target encoded in crate docs and constants
- macOS reference behavior encoded as crate-local parity metadata
- authoritative Windows frontmost API stack encoded as `GetForegroundWindow`, `GetWindowThreadProcessId`, `QueryFullProcessImageNameW`, `GetClassNameW`, `IShellWindows`, and `IWebBrowserApp::HWND`
- stable Explorer surface identity encoded as matched shell HWND plus owner process id instead of a generic foreground-window check
- live Windows-only frontmost probing wired through PowerShell-backed foreground-window, process-image, class-name, and ShellWindows HWND collection calls
- non-Explorer foreground windows now rejected by the same strict process/class/shell-identity classifier that the live probe feeds
- crate-local local `.md` acceptance filtering implemented to mirror the macOS file checks
- unit tests added for local Markdown acceptance, frontmost API-stack metadata, probe-output parsing, and stable-surface classification behavior

## Still pending

- Explorer hovered-item resolution
- coordinate translation and placement parity
- preview interaction parity wiring; the shared edit-lock and close-policy rules are now validated in `fastmd-core`, but Explorer/Tauri wiring is still pending
- runtime diagnostics parity
- validation evidence on a real Windows 11 machine

## Verification commands

Run from the repository root:

```bash
cargo check --manifest-path crates/fastmd-platform-windows/Cargo.toml
```

Crate-local tests:

```bash
cargo test --manifest-path crates/fastmd-platform-windows/Cargo.toml
```

## Actual results in this worker clone

- `rustup run stable-aarch64-apple-darwin cargo fmt --all --check`: passed
- `rustup run stable-aarch64-apple-darwin cargo metadata --manifest-path crates/fastmd-platform-windows/Cargo.toml --format-version 1 --no-deps`: passed
- `rustup run stable-aarch64-apple-darwin cargo test --manifest-path crates/fastmd-platform-windows/Cargo.toml`: blocked by the local Rosetta linker environment aborting inside `cc` with `Attachment of code signature supplement failed: 1`
- `rustup run stable-aarch64-apple-darwin cargo check -p fastmd-contracts -p fastmd-core -p fastmd-platform -p fastmd-platform-windows`: blocked by the local Rosetta linker environment aborting inside `cc` with `Attachment of code signature supplement failed: 1`
