# `fastmd-platform-windows`

Windows 11 + Explorer adapter seams for FastMD Stage 2.

This crate is intentionally scoped to one host surface only:

- Windows 11
- Explorer
- parity against the current macOS implementation under `apps/macos`

It does not claim generic Windows shell support, alternate file managers, or Stage 2 completion.

## Current slice

This worker slice keeps the lane buildable and closes the frontmost Explorer gating implementation slice:

- crate manifest and `src/` layout added
- macOS reference behavior captured as Rust constants
- Windows-to-macOS parity status captured as validation metadata
- host-integration seams added for frontmost Explorer detection, hovered-item resolution, coordinate translation, and diagnostics
- local `.md` acceptance filtering implemented to mirror the current macOS `FinderItemResolver` file checks
- the authoritative Windows frontmost API stack is encoded explicitly
- frontmost Explorer classification now requires a stable Explorer surface identity instead of a generic foreground-window check
- a live Windows-only frontmost probe now captures foreground HWND, owner process image, window class, and ShellWindows HWND parity data before classification

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
- records which Layer 6 parity items remain pending versus implemented in this crate

## What remains pending

The remaining Windows host work is still pending and should only be claimed once it matches macOS behavior one-to-one:

- Explorer hovered-item resolution
- Windows multi-monitor coordinate translation
- preview lifecycle wiring
- interaction parity for width tiers, background toggling, paging, editing, and close rules
- runtime diagnostics parity
- validation evidence on a real Windows 11 machine

## Validation

Crate-local validation notes live in `VALIDATION.md`.

Expected crate-level verification command:

```bash
cargo check --manifest-path crates/fastmd-platform-windows/Cargo.toml
```
