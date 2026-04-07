# `fastmd-platform-windows`

Windows 11 + Explorer adapter seams for FastMD Stage 2.

This crate is intentionally scoped to one host surface only:

- Windows 11
- Explorer
- parity against the current macOS implementation under `apps/macos`

It does not claim generic Windows shell support, alternate file managers, or Stage 2 completion.

## Current slice

This worker slice keeps the lane buildable and extends the Windows hover-open preview lifecycle with shared-command width-tier and placement parity on top of the existing frontmost, hovered-item, and coordinate translation work:

- crate manifest and `src/` layout added
- macOS reference behavior captured as Rust constants
- Windows-to-macOS parity status captured as validation metadata
- host-integration seams added for frontmost Explorer detection, hovered-item resolution, coordinate translation, and diagnostics
- local `.md` acceptance filtering implemented to mirror the current macOS `FinderItemResolver` file checks
- the authoritative Windows frontmost API stack is encoded explicitly
- frontmost Explorer classification now requires a stable Explorer surface identity instead of a generic foreground-window check
- a live Windows-only frontmost probe now captures foreground HWND, owner process image, window class, and ShellWindows HWND parity data before classification
- Windows monitor enumeration now uses `Screen.AllScreens` plus `Screen.WorkingArea`
- Windows cursor coordinates now normalize into the shared y-up desktop-space model before they reach shared core placement logic
- containing monitor selection now prefers the visible work area under the pointer and falls back to the nearest visible work area only when the pointer is outside every work area
- Windows preview-loop wiring now feeds frontmost Explorer gating, exact hovered-item resolution, and translated monitor context into `fastmd-core`
- Windows preview-loop command dispatch now routes shared `AppCommand::AdjustWidthTier` requests back through the same macOS-parity core geometry rules
- probe-driven tests now cover 560 / 960 / 1440 / 1920 width tiers plus 4:3 reposition-before-shrink behavior on roomy and cramped Windows work areas
- probe-driven tests now cover 1-second hover open, non-Explorer gating, same-item stationary no-reopen, replacement only after a different resolved Markdown target, and same-document pointer motion without dismissal
- shared render-side validation now pins `ui/src/markdown.ts`, `ui/src/styles.css`, and `ui/src/app.ts` to the same macOS-parity Markdown runtime, styling, block mapping, and content-base wiring that Windows consumes through the shared preview shell
- a Windows-only `windows_validation_report` example now emits one markdown evidence report from the live Explorer frontmost probe, hovered-item probe, translated monitor selection, and automated macOS reference feature coverage

The macOS behavior reference for this lane currently lives in:

- `apps/macos/Sources/FastMD/FinderHoverCoordinator.swift`
- `apps/macos/Sources/FastMD/FinderItemResolver.swift`
- `apps/macos/Sources/FastMD/HoverMonitorService.swift`
- `apps/macos/Sources/FastMD/PreviewPanelController.swift`
- `apps/macos/Sources/FastMD/MarkdownRenderer.swift`

## What this crate does today

- restricts the Stage 2 Windows target to Windows 11 + Explorer only
- exposes adapter seams without pretending Explorer parity is already implemented
- names the authoritative Windows frontmost detection stack as `GetForegroundWindow`, `GetWindowThreadProcessId`, `QueryFullProcessImageNameW`, `GetClassNameW`, `IShellWindows`, and `IWebBrowserApp::HWND`
- resolves a stable Explorer surface identity from the matched shell window handle plus owner process id
- probes the live Windows frontmost surface and rejects non-Explorer foreground windows before FastMD treats the host as valid
- accepts only existing local Markdown files as hover candidates
- rejects directories, missing paths, non-Markdown files, and unsupported non-file candidates
- enumerates Windows monitor bounds and work areas and translates them into the shared desktop-space model FastMD core already uses
- prefers the monitor whose translated visible frame contains the pointer and otherwise falls back to the nearest visible frame
- routes Windows width-tier commands through the shared Stage 2 command contract so preview requests keep the same 560 / 960 / 1440 / 1920 tiers and 4:3 reposition-before-shrink policy as macOS
- reuses the shared preview shell Markdown surface, with crate-owned tests locking the shared MarkdownIt, KaTeX, Mermaid, block-wrapper, typography, theme, and content-base behavior back to `apps/macos`
- records which Layer 6 parity items remain pending versus implemented in this crate

## What remains pending

The remaining Windows host work is still pending and should only be claimed once it matches macOS behavior one-to-one:

- validation evidence on a real Windows 11 machine for frontmost Explorer detection
- validation evidence on a real Windows 11 machine for exact hovered-item resolution
- validation evidence on a real Windows 11 machine for multi-monitor coordinate handling
- reviewed Windows-specific evidence proving one-to-one parity with macOS across the Layer 6 feature list

## Validation

Crate-local validation notes live in `VALIDATION.md`.

Expected crate-level verification command:

```bash
cargo check --manifest-path crates/fastmd-platform-windows/Cargo.toml
```

Real Windows 11 evidence capture command:

```bash
cargo run -p fastmd-platform-windows --example windows_validation_report > Docs/Test_Logs/windows11-explorer-validation-YYYYMMDD.md
```
