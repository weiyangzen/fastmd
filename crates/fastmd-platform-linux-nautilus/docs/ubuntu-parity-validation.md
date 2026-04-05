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

- frontmost-file-manager gating only opens when the host snapshot matches Nautilus identities
- hovered-item acceptance only allows exact hovered items or direct descendants of the hovered row
- nearby candidates and first-visible-item fallbacks are rejected
- non-Markdown paths, directories, relative paths, and unsupported entities are rejected
- multi-monitor handling chooses the containing work area first and falls back to the nearest monitor only when the pointer is outside every work area
- Wayland and X11 backend plans share one semantic guardrail so backend differences do not alter FastMD product behavior

Not yet proven in this slice:

- live Ubuntu 24.04 GNOME Files probing on a real Wayland session
- live Ubuntu 24.04 GNOME Files probing on a real X11 session
- end-to-end parity with macOS preview opening, paging, rendering, editing, and close behavior

## Layer-Gate Reminder

The Stage 2 blueprint says Layer 7 cannot claim full parity until Layers 1 through 4 are in place. This crate therefore limits itself to adapter-boundary work and explicit validation notes instead of claiming product completion early.
