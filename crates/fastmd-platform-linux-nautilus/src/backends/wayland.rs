use crate::backends::BackendProbePlan;
use crate::target::DisplayServerKind;

/// Planning metadata for the Ubuntu 24.04 GNOME Wayland backend.
pub fn probe_plan() -> BackendProbePlan {
    BackendProbePlan {
        display_server: DisplayServerKind::Wayland,
        frontmost_probe: "GNOME Shell / compositor-facing focus probe",
        hovered_item_probe: "AT-SPI or equivalent direct hover resolution for Nautilus rows/items",
        monitor_probe: "GNOME/GDK work-area enumeration for the active Wayland session",
        semantic_guardrail:
            "Match macOS product semantics exactly; Wayland changes host probing only.",
    }
}
