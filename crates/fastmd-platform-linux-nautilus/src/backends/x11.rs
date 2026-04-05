use crate::backends::BackendProbePlan;
use crate::target::DisplayServerKind;

/// Planning metadata for the Ubuntu 24.04 GNOME X11 backend.
pub fn probe_plan() -> BackendProbePlan {
    BackendProbePlan {
        display_server: DisplayServerKind::X11,
        frontmost_probe: "X11 active-window identity probe for Nautilus",
        hovered_item_probe: "AT-SPI or equivalent direct hover resolution for Nautilus rows/items",
        monitor_probe: "X11/GDK work-area enumeration for the active GNOME session",
        semantic_guardrail: "Match macOS product semantics exactly; X11 changes host probing only.",
    }
}
