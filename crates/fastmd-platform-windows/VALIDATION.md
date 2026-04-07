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
- `WindowsPreviewLoop` now wires frontmost Explorer gating, exact hovered-item resolution, and translated monitor selection into `fastmd_core::observe_hover`
- probe-driven preview-loop tests now cover the 1-second hover open debounce, blocked open while a non-Explorer surface is frontmost, stationary same-item no-reopen, replacement only after a different resolved Markdown target, and same-document pointer motion without dismissal
- `WindowsPreviewLoop::dispatch_command` now routes shared Stage 2 commands into `fastmd_core`, so Windows width-tier changes reuse the same shared macOS-parity semantics instead of a crate-local fork
- probe-driven preview-loop tests now prove that Windows width-tier changes emit the same 560 / 960 / 1440 / 1920 requests as macOS, preserve 4:3 aspect ratio, reposition before shrinking on roomy work areas, and only shrink once the requested tier truly cannot fit the selected work area
- shared contracts now publish one authoritative macOS preview feature list, shared core and render publish the features they own, and `windows_preview_loop_feature_coverage` proves the Windows preview loop covers that entire reference list without claiming real-machine evidence that has not been gathered yet
- shared render-side validation now pins `ui/src/markdown.ts`, `ui/src/styles.css`, and `ui/src/app.ts` to the same macOS Markdown runtime, styling, block-wrapper, and content-base wiring that the Windows preview shell consumes
- `WindowsValidationEvidenceReport` now turns the existing live frontmost, hover, coordinate, and automated feature-coverage outputs into one markdown report that can be captured on a real Windows 11 machine without hand-editing evidence files
- a Windows-only `windows_validation_report` example now probes the live Explorer surface, current pointer target, and translated monitor layout, then prints a report that maps directly onto the remaining real-machine Layer 6 evidence items
- unit tests added for hover API-stack metadata, probe-output parsing, exact-vs-fallback evidence classification, adapter wiring, relative-path rejection, and stable-surface classification behavior
- unit tests added for coordinate API-stack metadata, Windows-to-shared desktop-space translation, containing-monitor selection, and nearest-work-area fallback
- unit tests added for frontmost-surface preservation when Explorer gating fails, shared-contract Windows surface round-trips, and shared-core Explorer hover-open semantics
- unit tests added for evidence-report status mapping, markdown rendering, and macOS reference feature enumeration inside the generated report

## Still pending

- validation evidence on a real Windows 11 machine for frontmost gating, exact hovered-item resolution, and multi-monitor coordinate handling
- reviewed Windows-specific evidence proving one-to-one parity with macOS across the Layer 6 feature list

## Verification commands

Run from the repository root:

```bash
cargo check --manifest-path crates/fastmd-platform-windows/Cargo.toml
```

Crate-local tests:

```bash
cargo test --manifest-path crates/fastmd-platform-windows/Cargo.toml
```

Real Windows 11 evidence capture:

```bash
cargo run -p fastmd-platform-windows --example windows_validation_report > Docs/Test_Logs/windows11-explorer-validation-YYYYMMDD.md
```

Run the evidence capture on an actual Windows 11 machine with Explorer frontmost, the pointer resting on a local `.md` item, and the target monitor arrangement already in place. The generated markdown is evidence only; it does not automatically close any blueprint checklist item until the report is reviewed and checked into the authoritative docs lane.

## Actual results in this worker clone

- `rustup run stable-aarch64-apple-darwin rustfmt --check crates/fastmd-contracts/src/lib.rs crates/fastmd-core/src/lib.rs crates/fastmd-render/src/lib.rs crates/fastmd-platform-windows/src/preview.rs crates/fastmd-platform-windows/src/validation.rs && rustup run stable-aarch64-apple-darwin rustfmt --config skip_children=true --check crates/fastmd-platform-windows/src/lib.rs`: passed
- `rustup run stable-aarch64-apple-darwin rustfmt crates/fastmd-platform-windows/src/evidence.rs crates/fastmd-platform-windows/src/lib.rs crates/fastmd-platform-windows/examples/windows_validation_report.rs`: passed
- `rustup run stable-aarch64-apple-darwin cargo metadata --format-version 1 --no-deps`: passed
- `rustup run stable-aarch64-apple-darwin cargo test -p fastmd-contracts --lib`: blocked before crate tests ran because the local Rosetta linker environment aborted inside `cc` with `Attachment of code signature supplement failed: 1` while compiling dependency build scripts
- `rustup run stable-aarch64-apple-darwin cargo test -p fastmd-platform-windows evidence --lib`: blocked before crate tests ran because the local Rosetta linker environment aborted inside `cc` with `Attachment of code signature supplement failed: 1` while compiling dependency build scripts
- `rustup run stable-aarch64-apple-darwin cargo check -p fastmd-platform-windows --example windows_validation_report`: blocked before the example compiled because the local Rosetta linker environment aborted inside `cc` with `Attachment of code signature supplement failed: 1` while compiling dependency build scripts
