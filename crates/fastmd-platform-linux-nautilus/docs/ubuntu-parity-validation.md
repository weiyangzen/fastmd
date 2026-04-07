# Ubuntu 24.04 GNOME Files Parity Validation

This file records what the current `fastmd-platform-linux-nautilus` crate does and does not prove.

## Scope Lock

Implemented in this slice:

- Ubuntu support is encoded as Ubuntu 24.04 plus GNOME only.
- The target file manager is encoded as GNOME Files / Nautilus only.
- The current macOS app under `apps/macos` is named as the behavior reference.

Not claimed:

- support for generic Linux desktops
- support for non-GNOME Ubuntu variants
- support for Caja, Dolphin, Nemo, Thunar, or other file managers

## Adapter Logic Implemented Here

Implemented and unit-tested in this slice:

- the authoritative Wayland/X11 frontmost Nautilus API stacks are encoded explicitly
- live frontmost Nautilus probing now runs through AT-SPI on Wayland and AT-SPI plus `_NET_ACTIVE_WINDOW` on X11 before feeding the shared frontmost classifier
- the authoritative Wayland/X11 hovered-item Nautilus API stacks are encoded explicitly
- live hovered-item Nautilus probing now runs through an AT-SPI hit-test on both Wayland and X11 before feeding the shared hovered-item classifier
- frontmost-file-manager gating only opens when the host snapshot matches Nautilus identifiers and carries a stable surface identity
- accepted frontmost Nautilus surfaces preserve a stable host identity instead of trusting a generic active-window match
- non-Nautilus or identity-less frontmost windows are rejected before hover resolution proceeds
- hovered-item acceptance only allows exact hovered items or direct descendants of the hovered row
- nearby candidates and first-visible-item fallbacks are rejected
- non-Markdown paths, directories, relative paths, and unsupported entities are rejected
- live hovered-item probe output is now confirmed to reject directories, missing paths, and unsupported GTK entities through the same markdown filter path used by the adapter
- multi-monitor handling chooses the containing work area first and falls back to the nearest monitor only when the pointer is outside every work area
- Wayland and X11 backend plans share one semantic guardrail so backend differences do not alter FastMD product behavior

Not yet proven in this slice:

- live Ubuntu 24.04 GNOME Files probing on a real Wayland session
- live Ubuntu 24.04 GNOME Files probing on a real X11 session
- end-to-end parity with macOS preview opening, paging, rendering, editing, and close behavior
- Rust-side validation on this worker host, because the local macOS Rosetta/linker path aborts before `cargo test` can complete

Shared shell parity now covered outside this crate:

- the Linux Tauri shell now uses a 1-second hover debounce before opening a preview, matching the macOS hover-trigger delay
- the Linux hover worker now blocks preview opening unless the live frontmost surface still resolves to GNOME Files / Nautilus
- the Linux hover worker now replaces the preview only when the settled hovered Markdown path truly changes
- repeated reopen is now suppressed while the pointer stays on the same Markdown item, even if ordinary pointer motion keeps resetting the debounce timer
- ordinary pointer motion no longer dismisses the preview when the resolved Markdown target does not change
- the shared preview shell keeps the same four width tiers as the macOS reference
- the compact hint chip and desktop chrome copy now match the macOS shell instead of showing Linux-only helper text
- the Ubuntu shell now advertises the same fastmd-render Stage 2 rendering contract the shared frontend consumes, and fastmd-render pins `ui/src/markdown.ts`, `ui/src/styles.css`, and `ui/src/app.ts` to the current macOS `MarkdownRenderer.swift` runtime and copy
- the Ubuntu shell now surfaces live hovered-item diagnostics through the shared hover-anchor path, keeping rejected paths and unsupported entities visible in hidden shell metadata without changing user-visible product semantics
- `Tab`, paged scrolling, and `Escape` close semantics are validated in the shared Tauri/UI lane
- Linux blur-close handling now distinguishes `outside-click` from `app-switch` by re-checking the live frontmost Nautilus gate before the preview hides; edit lock still blocks both paths
- inline edit entry still starts from the double-clicked rendered block that carries source-line metadata, matching the macOS shell
- inline edit source extraction still uses the same start-line/end-line block mapping model as the macOS shell
- attached-source saves now write Markdown back to the attached file in the shared Tauri shell, while cancel leaves the file untouched
- edit mode still locks close and hotkey handling until save or cancel clears the lock, matching the macOS shell

## Layer-Gate Reminder

The Stage 2 blueprint says Layer 7 cannot claim full parity until Layers 1 through 4 are in place. This crate therefore limits itself to adapter-boundary work and explicit validation notes instead of claiming product completion early.
