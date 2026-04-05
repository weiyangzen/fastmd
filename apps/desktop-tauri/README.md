This directory now contains the Stage 2 Tauri desktop shell scaffold for FastMD.

Current scope of this shell:

- real Tauri 2 manifest and Rust entrypoint
- preview-window geometry logic aligned with the macOS 4:3 width-tier shell
- shared frontend wiring from `ui/`
- host-capability bootstrap and event emission into the shared frontend
- a minimal global shortcut integration that can re-show the preview shell after a focus-loss close

This is intentionally a parity-focused shell slice, not a claim of full cross-platform feature parity.
