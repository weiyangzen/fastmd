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
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "The acceptance rules are implemented and tested; live Nautilus probe wiring remains to be validated.",
        },
        ValidationNote {
            item: "Implement Ubuntu multi-monitor coordinate handling with the same placement semantics as macOS",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "Containing-monitor and nearest-monitor selection are implemented; real GNOME monitor snapshots still need validation.",
        },
        ValidationNote {
            item: "Implement preview opening, rendering, editing, and close behavior parity",
            status: ValidationStatus::BlockedByLowerLayers,
            note: "Shared shell parity now covers width tiers, hint-chip chrome, Tab toggle, paged scrolling, and Escape close; hover-driven opening, edit persistence, and host-driven close paths still depend on shared-core and live Nautilus wiring.",
        },
    ]
}
