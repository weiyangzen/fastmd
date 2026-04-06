use crate::backends::BackendProbePlan;
use crate::target::DisplayServerKind;

/// Planning metadata for the Ubuntu 24.04 GNOME Wayland backend.
pub fn probe_plan() -> BackendProbePlan {
    BackendProbePlan {
        display_server: DisplayServerKind::Wayland,
        frontmost_probe:
            "AT-SPI focused accessible + Atspi.Application bus_name + GTK/GApplication application-id / Wayland app_id",
        hovered_item_probe:
            "AT-SPI Component.GetAccessibleAtPoint(screen) + Accessible.GetChildren/GetChildAtIndex + Accessible.GetRole/GetRoleName + Accessible.GetAttributes + Text.GetText within Nautilus GTK list roles",
        monitor_probe: "GNOME/GDK work-area enumeration for the active Wayland session",
        semantic_guardrail:
            "Match macOS product semantics exactly; Wayland changes host probing only.",
    }
}
