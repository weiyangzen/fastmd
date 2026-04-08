use crate::target::DisplayServerKind;

pub const DIAGNOSTIC_STATUS_EMITTED: &str = "emitted";
pub const DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE: &str = "pending-live-probe";
pub const MONITOR_SELECTION_POLICY: &str = "containing-work-area-then-nearest";
pub const PREVIEW_PLACEMENT_POLICY: &str = "4:3-reposition-before-shrink";
pub const EDIT_LIFECYCLE_POLICY: &str = "edit-lock-disables-blur-close";

pub const MONITOR_SELECTION_RUNTIME_NOTE: &str = "Monitor-selection diagnostics now emit the anchor point, selected monitor id, work area, and whether nearest-monitor fallback was required.";
pub const PREVIEW_PLACEMENT_RUNTIME_NOTE: &str = "Preview-placement diagnostics now emit the requested width tier and the applied 4:3 geometry after reposition-before-shrink rules run.";
pub const EDIT_LIFECYCLE_RUNTIME_NOTE: &str = "Edit-lifecycle diagnostics now emit whether inline edit lock is active, whether blur-close is armed, whether attached-source saves are currently allowed, and the last emitted close reason.";

pub fn display_server_label(display_server: Option<DisplayServerKind>) -> &'static str {
    match display_server {
        Some(DisplayServerKind::Wayland) => "wayland",
        Some(DisplayServerKind::X11) => "x11",
        None => "unknown",
    }
}

pub fn frontmost_gate_pending_note(display_server: Option<DisplayServerKind>) -> &'static str {
    match display_server {
        Some(DisplayServerKind::Wayland) => {
            "Wayland frontmost-gate diagnostics are emitted now, but live AT-SPI Nautilus probes still need Ubuntu validation before accepted surfaces can be reported."
        }
        Some(DisplayServerKind::X11) => {
            "X11 frontmost-gate diagnostics are emitted now, but live AT-SPI plus _NET_ACTIVE_WINDOW Nautilus probes still need Ubuntu validation before accepted surfaces can be reported."
        }
        None => {
            "Frontmost-gate diagnostics are emitted now, but the active Linux display server is unresolved until the host session identifies Wayland or X11."
        }
    }
}

pub fn hovered_item_pending_note(display_server: Option<DisplayServerKind>) -> &'static str {
    match display_server {
        Some(DisplayServerKind::Wayland) => {
            "Wayland hovered-item diagnostics are emitted now; exact-item and hovered-row path reconstruction plus markdown filtering are implemented, but live AT-SPI hit-testing still needs Ubuntu validation before accepted hovered Markdown paths can be reported."
        }
        Some(DisplayServerKind::X11) => {
            "X11 hovered-item diagnostics are emitted now; exact-item and hovered-row path reconstruction plus markdown filtering are implemented, but live AT-SPI hit-testing still needs Ubuntu validation before accepted hovered Markdown paths can be reported."
        }
        None => {
            "Hovered-item diagnostics are emitted now, but the active Linux display server is unresolved until the host session identifies Wayland or X11."
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn display_server_labels_cover_wayland_x11_and_unknown() {
        assert_eq!(
            display_server_label(Some(DisplayServerKind::Wayland)),
            "wayland"
        );
        assert_eq!(display_server_label(Some(DisplayServerKind::X11)), "x11");
        assert_eq!(display_server_label(None), "unknown");
    }

    #[test]
    fn pending_notes_stay_display_server_specific() {
        assert!(frontmost_gate_pending_note(Some(DisplayServerKind::Wayland)).contains("Wayland"));
        assert!(frontmost_gate_pending_note(Some(DisplayServerKind::X11)).contains("X11"));
        assert!(hovered_item_pending_note(Some(DisplayServerKind::Wayland)).contains("Wayland"));
        assert!(hovered_item_pending_note(Some(DisplayServerKind::X11)).contains("X11"));
        assert!(
            hovered_item_pending_note(Some(DisplayServerKind::Wayland))
                .contains("path reconstruction plus markdown filtering")
        );
    }
}
