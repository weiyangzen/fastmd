//! Backend planning for session-specific host probes.
//!
//! The important invariant is that Wayland and X11 only change how host data is
//! gathered. They must not change FastMD product semantics.

pub mod wayland;
pub mod x11;

use crate::target::DisplayServerKind;

/// Summary of how a display-server-specific backend is expected to gather data.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BackendProbePlan {
    /// Wayland or X11.
    pub display_server: DisplayServerKind,
    /// Planned focus probe mechanism.
    pub frontmost_probe: &'static str,
    /// Planned hovered-item probe mechanism.
    pub hovered_item_probe: &'static str,
    /// Planned monitor-layout probe mechanism.
    pub monitor_probe: &'static str,
    /// Shared semantic invariant for all display servers.
    pub semantic_guardrail: &'static str,
}
