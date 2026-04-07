/// Validation status for this crate slice.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ValidationStatus {
    /// Implemented directly in this crate slice.
    ImplementedInSlice,
    /// Requires live Ubuntu validation after host probes are wired.
    NeedsUbuntuHostValidation,
    /// Blocked by lower Stage 2 layers outside this worker lane.
    BlockedByLowerLayers,
}

/// One parity-validation note for the Ubuntu adapter lane.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ValidationNote {
    /// Blueprint checklist item or feature name.
    pub item: &'static str,
    /// Current status.
    pub status: ValidationStatus,
    /// Short explanation for the status.
    pub note: &'static str,
}

/// Returns the validation notes for this bounded worker slice.
pub fn crate_slice_validation_notes() -> Vec<ValidationNote> {
    vec![
        ValidationNote {
            item: "Restrict Linux support target to Ubuntu 24.04 plus GNOME Files / Nautilus only",
            status: ValidationStatus::ImplementedInSlice,
            note: "The crate rejects non-Ubuntu-24.04 or non-GNOME sessions at the adapter boundary.",
        },
        ValidationNote {
            item: "Create fastmd-platform-linux-nautilus as a buildable crate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The crate now has a real Cargo manifest, module layout, and unit tests.",
        },
        ValidationNote {
            item: "Implement Wayland and X11 behavior handling without changing product semantics",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland and X11 have separate backend plans with one shared semantic guardrail.",
        },
        ValidationNote {
            item: "Implement Ubuntu frontmost GNOME Files detection with the same gating semantics as macOS Finder",
            status: ValidationStatus::ImplementedInSlice,
            note: "The adapter now applies explicit Wayland/X11 frontmost API-stack metadata plus a stable Nautilus surface classifier before the gate opens.",
        },
        ValidationNote {
            item: "Identify the authoritative Ubuntu 24.04 GNOME host API stack for frontmost Nautilus detection",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland now names AT-SPI focused-accessible + application-bus + GTK application-id inputs, while X11 names EWMH _NET_ACTIVE_WINDOW + application-bus + GTK application-id inputs.",
        },
        ValidationNote {
            item: "Resolve the active GNOME Files / Nautilus surface to a stable Nautilus identity instead of a generic active-window check",
            status: ValidationStatus::ImplementedInSlice,
            note: "The frontmost classifier now requires a stable surface id from the host snapshot and preserves it in the accepted Nautilus surface record.",
        },
        ValidationNote {
            item: "Reject non-Nautilus foreground windows with the same strict gating semantics as macOS Finder",
            status: ValidationStatus::ImplementedInSlice,
            note: "Frontmost classification now rejects non-Nautilus identifiers and missing stable surface ids before hover resolution can proceed.",
        },
        ValidationNote {
            item: "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "The classifier is implemented and unit-tested, but the live Wayland host probe still needs Ubuntu validation evidence.",
        },
        ValidationNote {
            item: "Validate frontmost Nautilus detection on a real Ubuntu 24.04 X11 session",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "The classifier is implemented and unit-tested, but the live X11 host probe still needs Ubuntu validation evidence.",
        },
        ValidationNote {
            item: "Implement Ubuntu hovered-item resolution so the actual hovered .md item is resolved rather than a nearby or first visible candidate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus hover pipeline now normalizes raw probe observations into exact-item or hovered-row candidates, reconstructs file-system paths from direct metadata or hovered-row context, and rejects nearby / first-visible fallbacks before preview open.",
        },
        ValidationNote {
            item: "Identify the authoritative Ubuntu 24.04 GNOME host API stack for hovered Nautilus item resolution",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland and X11 now explicitly name AT-SPI Component.GetAccessibleAtPoint plus Accessible children, role, attributes, and text queries within Nautilus GTK list roles as the hover-resolution stack.",
        },
        ValidationNote {
            item: "Resolve the exact hovered Nautilus item rather than a nearby candidate or first visible candidate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus hover classifier now accepts only exact-item-under-pointer or hovered-row-descendant evidence and rejects nearby or first-visible scopes before preview open.",
        },
        ValidationNote {
            item: "Preserve the macOS rule that three or more visible Markdown files must still resolve the actually hovered item",
            status: ValidationStatus::ImplementedInSlice,
            note: "Hovered-row classification now keeps the hovered row identity and reconstructs that specific row's path even when multiple visible Markdown peers are present, rather than falling back to the first visible candidate.",
        },
        ValidationNote {
            item: "Reconstruct or retrieve an absolute filesystem path for the hovered Nautilus item",
            status: ValidationStatus::ImplementedInSlice,
            note: "The pipeline now accepts direct path-like AT-SPI metadata when available and otherwise reconstructs a file-system path from the hovered row label plus the front Nautilus directory context.",
        },
        ValidationNote {
            item: "Validate that the hovered-item path exists and points to a regular file before preview opens",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux markdown filter now rejects relative paths, missing paths, directories, unsupported entities, and non-Markdown extensions before the adapter returns a resolved hover.",
        },
        ValidationNote {
            item: "Implement Ubuntu multi-monitor coordinate handling with the same placement semantics as macOS",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "Containing-monitor and nearest-monitor selection are implemented, and the shared Tauri shell now consumes Linux monitor work_area rectangles in desktop-space coordinates; real GNOME monitor snapshots still need Ubuntu validation.",
        },
        ValidationNote {
            item: "Implement preview opening on 1-second hover with the same semantics as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux Tauri shell now polls the desktop cursor, debounces for the same 1-second dwell window as the macOS hover monitor, and only opens the preview after the live Nautilus probe still resolves a Markdown file at the settled anchor.",
        },
        ValidationNote {
            item: "Wire Ubuntu host signals into the shared 1-second hover debounce lifecycle",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux hover worker now treats cursor movement, frontmost Nautilus surface changes, and hovered-target changes from the live AT-SPI probe as the debounce input stream before the preview opens or replaces.",
        },
        ValidationNote {
            item: "Prevent repeated reopen while the pointer stays stationary over the same Markdown item",
            status: ValidationStatus::ImplementedInSlice,
            note: "Once one settled hover observation has already opened the preview, the Linux hover lifecycle records that observation and suppresses repeated reopen until the pointer or resolved Nautilus target changes again.",
        },
        ValidationNote {
            item: "Ensure preview opening is blocked while the foreground surface is not Nautilus",
            status: ValidationStatus::ImplementedInSlice,
            note: "The hover worker now checks the live frontmost Nautilus gate before every debounce decision, so non-Nautilus or identity-less foreground surfaces never reach the preview-open path.",
        },
        ValidationNote {
            item: "Implement preview replacement on a different hovered .md with the same semantics as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "When the preview is already visible and a later settled hover resolves a different Markdown path, the shared shell now replaces the preview document instead of reopening or dismissing the window.",
        },
        ValidationNote {
            item: "Ensure replacement happens only when the resolved document actually changes",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux hover lifecycle compares the resolved Markdown path against the currently visible preview source and only issues a replace action when the document path truly changes.",
        },
        ValidationNote {
            item: "Ensure ordinary pointer motion does not dismiss the preview if the hovered Markdown target did not change",
            status: ValidationStatus::ImplementedInSlice,
            note: "Pointer movement now only resets the Linux hover debounce timer; it never issues a close action, and the same resolved Markdown path still suppresses reopen after the dwell window expires.",
        },
        ValidationNote {
            item: "Wire the current adapter-level rejection logic into the real Nautilus hovered-item pipeline",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus adapter now classifies raw hover observations through the same Linux markdown filter used for path acceptance, so hover evidence and file acceptance run in one pipeline.",
        },
        ValidationNote {
            item: "Confirm directory rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now feed the shared markdown filter, and unit tests confirm that directory paths from the AT-SPI hit-test path still reject before preview open.",
        },
        ValidationNote {
            item: "Confirm missing-path rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now feed the shared markdown filter, and unit tests confirm that stale or missing paths from the AT-SPI hit-test path still reject before preview open.",
        },
        ValidationNote {
            item: "Confirm unsupported-entity rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now preserve unsupported GTK entities and unit tests confirm that they still reject through the shared markdown filter before preview open.",
        },
        ValidationNote {
            item: "Implement the same hot interaction-surface behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared Tauri shell reveals the preview with window focus, the shared frontend keeps the shell root focusable after re-renders, and Linux parity can now rely on one hot surface instead of pointer re-entry.",
        },
        ValidationNote {
            item: "Keep the preview keyboard-hot without forcing the user to re-hover inside the preview",
            status: ValidationStatus::ImplementedInSlice,
            note: "Linux desktop shells now combine Tauri reveal-focus behavior with shared-frontend shell focus retention so width, background, paging, and close keys stay active without an extra re-hover step.",
        },
        ValidationNote {
            item: "Implement the same mouse-wheel and touchpad scrolling behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now normalizes wheel deltas into the same direct preview-scroll path used by the macOS reference instead of depending on browser-default scrolling behavior.",
        },
        ValidationNote {
            item: "Implement the same inline block editing entry rule as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now enters inline edit mode only from the double-clicked rendered block that carries source-line metadata, matching the macOS preview shell entry rule.",
        },
        ValidationNote {
            item: "Implement the same edit source mapping behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now extracts raw Markdown from the same start-line/end-line block metadata model used by the macOS reference shell before opening the inline editor.",
        },
        ValidationNote {
            item: "Implement the same edit save and cancel behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared Tauri shell now preserves an attached Markdown source path, writes saved edits back to that file, and the shared frontend still cancels without mutating disk when edit mode is dismissed.",
        },
        ValidationNote {
            item: "Implement the same edit-mode lock behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "Linux desktop shells now disable blur-close while editing, suppress preview close requests and hotkeys during the lock, and only re-arm normal preview behavior after save or cancel clears edit mode.",
        },
        ValidationNote {
            item: "Implement the same Markdown rendering surface as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Ubuntu shell now exposes the fastmd-render Stage 2 rendering contract to the shared frontend, and fastmd-render already pins ui/src/markdown.ts, ui/src/styles.css, and ui/src/app.ts to the current macOS MarkdownRenderer runtime, typography, theme, layout, and compact chrome copy.",
        },
        ValidationNote {
            item: "Implement preview opening, rendering, editing, and close behavior parity",
            status: ValidationStatus::BlockedByLowerLayers,
            note: "Shared shell parity now covers macOS-matching hover-driven opening and replacement, the rendering surface, width tiers, work-area-based 4:3 placement, hint-chip chrome, Tab toggle, paged scrolling, and Escape close; outside-click/app-switch close parity and real Ubuntu session validation remain open.",
        },
        ValidationNote {
            item: "Implement the same runtime diagnostics coverage as macOS where host APIs permit",
            status: ValidationStatus::BlockedByLowerLayers,
            note: "The shell now emits live frontmost and hovered-item Ubuntu diagnostics plus hover-lifecycle state when the Linux debounce worker is active, but full macOS-equivalent runtime coverage still depends on the remaining close-path work and real-session validation.",
        },
        ValidationNote {
            item: "Emit Ubuntu-side diagnostics for frontmost gating, hovered-item resolution, monitor selection, preview placement, and edit lifecycle",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux adapter now defines one diagnostics vocabulary consumed by the Tauri shell and shared UI, with live frontmost probes wired continuously and live hovered-item probes wired through the shared hover-anchor path.",
        },
        ValidationNote {
            item: "Implement real Wayland probe plumbing behind the existing semantic guardrail",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland now runs a live AT-SPI hovered-item hit-test probe that normalizes exact-item or hovered-row evidence through the same markdown filter and diagnostics path used elsewhere in the Linux adapter.",
        },
        ValidationNote {
            item: "Implement real X11 probe plumbing behind the existing semantic guardrail",
            status: ValidationStatus::ImplementedInSlice,
            note: "X11 now runs the same live AT-SPI hovered-item hit-test probe and reuses the identical markdown-filter and diagnostics path, so the backend difference stays in host data gathering only.",
        },
    ]
}
