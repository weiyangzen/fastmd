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
- the shared Tauri shell now exports that one semantic guardrail into hidden Linux probe-plan metadata, and shared UI tests confirm that switching the display-server plan from Wayland to X11 does not change the user-visible preview shell
- shared contracts, shared core, shared render, and the Ubuntu adapter now publish one explicit macOS-reference feature-coverage summary, and the shared Tauri/UI lane surfaces that summary as hidden parity metadata instead of relying on an implicit parity claim
- the Ubuntu lane now publishes one automated preview-loop validation summary for Wayland and one for X11, and both summaries prove that the shared core, shared render, and Ubuntu Nautilus adapter cover the full macOS reference feature list without claiming the still-open real Ubuntu host-evidence items
- the shared Tauri shell now exposes one hidden Ubuntu validation-report capture path that bundles the current frontmost, hovered-item, monitor-selection, preview-placement, and automated parity diagnostics into one markdown evidence report for the active Wayland or X11 session without changing visible shell copy
- the shared Tauri shell now exposes one hidden desktop-shell validation snapshot path that bundles the current shell state, current host-capability payloads, and the active Ubuntu validation report into one typed capture for review tooling without changing visible shell copy
- the shared Tauri shell now exposes one hidden desktop-shell validation export path that writes the current snapshot plus the active Ubuntu validation report into `Docs/Test_Logs/` so real Wayland/X11 review runs can persist evidence without manual copy/paste
- that hidden validation-report path now stays explicit about scope: one captured report can make the active Wayland or X11 live-evidence items reviewable, but it does not mark the umbrella Ubuntu parity-evidence checklist item ready without reviewed real-machine evidence from both display servers

Not yet proven in this slice:

- live Ubuntu 24.04 GNOME Files probing on a real Wayland session
- live Ubuntu 24.04 GNOME Files probing on a real X11 session
- end-to-end parity with macOS preview opening, paging, rendering, editing, and close behavior
- cross-session closure of the umbrella Ubuntu parity-evidence checklist item, because a single report only captures one live display server at a time
- reviewed Ubuntu-specific real-machine evidence proving one-to-one parity with macOS across the remaining Layer 7 checklist
- targeted `fastmd-desktop-tauri` Rust validation on this worker host, because the current Tauri test build aborts before the slice test runs when `tauri::generate_context!()` cannot find `apps/desktop-tauri/src-tauri/icons/icon.png`

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
- the Ubuntu shell now keeps the Wayland/X11 semantic guardrail in hidden shell metadata, so backend probe differences remain inspectable without leaking Linux-only copy into the visible macOS-parity shell
- the Ubuntu shell now keeps the Wayland and X11 automated preview-loop validation summaries in hidden shell metadata, so reviewers can inspect full feature-list coverage for each display server without changing visible preview copy
- the Ubuntu shell now keeps one hidden desktop-shell validation snapshot API alongside the report API, so live review tooling can capture current shell state and host diagnostics from one place instead of stitching together separate bridge calls
- `Tab`, paged scrolling, and `Escape` close semantics are validated in the shared Tauri/UI lane
- Linux blur-close handling now distinguishes `outside-click` from `app-switch` by re-checking the live frontmost Nautilus gate before the preview hides; edit lock still blocks both paths
- the shared Tauri/UI lane now keeps the inferred blur-close reason plus edit-lifecycle policy, persistence eligibility, and last close reason in hidden shell metadata so Ubuntu close-path parity stays inspectable without diverging from the macOS-visible shell
- inline edit entry still starts from the double-clicked rendered block that carries source-line metadata, matching the macOS shell
- inline edit source extraction still uses the same start-line/end-line block mapping model as the macOS shell
- attached-source saves now write Markdown back to the attached file in the shared Tauri shell, while cancel leaves the file untouched
- edit mode still locks close and hotkey handling until save or cancel clears the lock, matching the macOS shell

## Layer-Gate Reminder

The Stage 2 blueprint says Layer 7 cannot claim full parity until Layers 1 through 4 are in place. This crate therefore limits itself to adapter-boundary work and explicit validation notes instead of claiming product completion early.
