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
- authoritative Windows hovered-item API stack encoded as UI Automation `ElementFromPoint`, `ControlViewWalker`, `AutomationElement.Current.Name`, `IShellWindows`, `IWebBrowserApp::HWND`, `Folder.ParseName`, and `FolderItem.Path`
- live Windows-only hovered-item probing wired through a PowerShell UI Automation hit-test plus Explorer shell-window path reconstruction
- exact-item and hovered-row descendant evidence accepted; nearby or first-visible fallbacks explicitly rejected before preview open
- crate-local local `.md` acceptance filtering now runs inside the Explorer hovered-item pipeline and rejects relative paths, missing paths, directories, unsupported entities, and non-Markdown extensions
- authoritative Windows coordinate API stack encoded as `Cursor.Position`, `Screen.AllScreens`, `Screen.Bounds`, `Screen.WorkingArea`, and `SystemInformation.VirtualScreen`
- live Windows-only monitor probing wired through PowerShell-backed `System.Windows.Forms` monitor enumeration plus cursor capture
- Windows top-left desktop coordinates now translate into the shared y-up desktop space before they reach shared core placement logic
- `Screen.WorkingArea` is now preserved as the Windows equivalent of the macOS `visibleFrame` contract in shared monitor metadata
- monitor selection now prefers the containing translated work area and falls back to the nearest work area via shared-core monitor selection helpers
- unit tests added for hover API-stack metadata, probe-output parsing, exact-vs-fallback evidence classification, adapter wiring, relative-path rejection, and stable-surface classification behavior
- unit tests added for coordinate API-stack metadata, Windows-to-shared desktop-space translation, containing-monitor selection, and nearest-work-area fallback

## Still pending

- preview placement parity
- preview interaction parity wiring; the shared edit-lock and close-policy rules are now validated in `fastmd-core`, but Explorer/Tauri wiring is still pending
- runtime diagnostics parity
- validation evidence on a real Windows 11 machine for frontmost gating, exact hovered-item resolution, and multi-monitor coordinate handling

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

- `rustup run stable-aarch64-apple-darwin cargo fmt --all`: passed
- `rustup run stable-aarch64-apple-darwin cargo fmt --all --check`: passed
- `rustup run stable-aarch64-apple-darwin cargo metadata --format-version 1 --no-deps`: passed
- `rustup run stable-aarch64-apple-darwin cargo test -p fastmd-contracts -p fastmd-core -p fastmd-platform-windows`: blocked before crate tests ran because the local Rosetta linker environment aborted inside `cc` with `Attachment of code signature supplement failed: 1` while compiling dependency build scripts
