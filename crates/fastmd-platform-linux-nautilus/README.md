# fastmd-platform-linux-nautilus

This crate is the Stage 2 Ubuntu host adapter lane for FastMD.

Its scope is intentionally narrow:

- Ubuntu 24.04 only
- GNOME desktop only
- GNOME Files, also known as `Files` / `Nautilus`, only
- parity with the current macOS behavior under `apps/macos`

This crate does not define a generic Linux abstraction and it does not widen product semantics away from the current macOS app. Any Wayland or X11 difference is treated as a host-probe detail, not a license to invent Linux-specific behavior.

## What this slice implements

- a standalone, buildable Rust crate for the Ubuntu adapter lane
- explicit Stage 2 scope locking to Ubuntu 24.04 plus GNOME Files / Nautilus
- explicit Wayland and X11 frontmost Nautilus API-stack metadata
- explicit Wayland and X11 hovered-item Nautilus API-stack metadata
- adapter seams for:
  - frontmost-file-manager gating
  - hovered-item resolution
  - Markdown-file rejection rules
  - multi-monitor work-area selection
  - Wayland and X11 backend planning with one shared semantic contract
- strict frontmost Nautilus classification that requires a stable surface identity instead of a generic active-window match
- live frontmost Nautilus probe plumbing that uses AT-SPI on Wayland and AT-SPI plus `_NET_ACTIVE_WINDOW` on X11 before feeding the same classifier
- explicit hovered-item probe stacks that name the AT-SPI hit-test, lineage, role, attribute, and text queries expected for real Nautilus wiring
- non-list Nautilus hover reconstruction that treats icon/image/label hits as a subtree anchor and resolves sibling Markdown path or filename evidence instead of staying list-view-only
- explicit Layer 7 live-evidence checklist helpers for Wayland and X11 so the desktop shell can generate one honest Ubuntu validation report without hard-coded item drift
- explicit desktop-shell validation snapshot plumbing so review tooling can capture shell state, host-capability payloads, and the active Ubuntu validation report through one hidden API
- unit tests for the adapter decisions that can be validated without a live Ubuntu desktop session

## What this slice does not claim

- live Nautilus host probing on a real Ubuntu 24.04 machine
- shared-core preview semantics from lower Stage 2 layers
- UI parity items owned by the shared desktop shell and shared frontend
- authoritative parity sign-off while the local Rust linker is blocked by this macOS host

The crate therefore moves the Ubuntu lane forward honestly: the parity-oriented adapter logic is real and testable, while live host wiring remains explicitly visible as follow-up work rather than hidden behind a fake "Linux support" label.

## Validation Notes

Validation notes for this slice live at `docs/ubuntu-parity-validation.md`.
