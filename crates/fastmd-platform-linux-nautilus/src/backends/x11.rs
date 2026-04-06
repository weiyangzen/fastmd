use crate::backends::BackendProbePlan;
use crate::target::DisplayServerKind;

/// Planning metadata for the Ubuntu 24.04 GNOME X11 backend.
pub fn probe_plan() -> BackendProbePlan {
    BackendProbePlan {
        display_server: DisplayServerKind::X11,
        frontmost_probe:
            "EWMH _NET_ACTIVE_WINDOW + Atspi.Application bus_name + GTK/GApplication application-id",
        hovered_item_probe:
            "AT-SPI Component.GetAccessibleAtPoint(screen) + Accessible.GetChildren/GetChildAtIndex + Accessible.GetRole/GetRoleName + Accessible.GetAttributes + Text.GetText within Nautilus GTK list roles",
        monitor_probe: "X11/GDK work-area enumeration for the active GNOME session",
        semantic_guardrail: "Match macOS product semantics exactly; X11 changes host probing only.",
    }
}
