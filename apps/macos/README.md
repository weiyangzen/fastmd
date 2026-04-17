This directory contains the current macOS Swift/AppKit implementation of FastMD.

Stage 2 keeps this app buildable while the shared Rust/Tauri architecture is introduced.

Current macOS host-shell responsibilities include:

- a menu-bar status item at the top-right of the screen
- a host-level monitoring switch in that status item
- the native preview-window pin button and external-link window policy
