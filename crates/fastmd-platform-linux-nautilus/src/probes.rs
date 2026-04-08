use crate::error::AdapterError;
use crate::geometry::{MonitorLayout, ScreenPoint};
use crate::hover::HoveredItemSnapshot;
use crate::target::SessionContext;

const NAUTILUS_IDENTIFIERS: &[&str] = &[
    "org.gnome.Nautilus",
    "org.gnome.Nautilus.desktop",
    "nautilus",
];

/// Snapshot of the frontmost application as observed by a host probe.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct FrontmostAppSnapshot {
    /// Desktop application id.
    pub app_id: Option<String>,
    /// Desktop entry id.
    pub desktop_entry: Option<String>,
    /// X11 window class or equivalent session identifier.
    pub window_class: Option<String>,
    /// Executable name when available.
    pub executable: Option<String>,
    /// Window title when the host probe can provide it.
    pub window_title: Option<String>,
    /// Process id when the host probe can provide it.
    pub process_id: Option<u32>,
    /// Stable host-surface identifier for the active Nautilus window.
    pub stable_surface_id: Option<String>,
    /// Focused accessible role when the frontmost Nautilus surface currently
    /// has a text-input control active.
    pub focused_role_name: Option<String>,
    /// Focused accessible name when the frontmost Nautilus surface currently
    /// has a text-input control active.
    pub focused_name: Option<String>,
    /// True when the frontmost Nautilus surface is currently editing text,
    /// such as a rename field, search field, or path-bar entry.
    pub focused_is_text_input: bool,
}

impl FrontmostAppSnapshot {
    /// Returns true only when the observed application is Nautilus.
    pub fn matches_nautilus(&self) -> bool {
        self.matched_nautilus_identifier().is_some()
    }

    /// Returns the first identifier that matches Nautilus.
    pub fn matched_nautilus_identifier(&self) -> Option<&str> {
        [
            self.app_id.as_deref(),
            self.desktop_entry.as_deref(),
            self.window_class.as_deref(),
            self.executable.as_deref(),
        ]
        .into_iter()
        .flatten()
        .find(|value| matches_known_identifier(Some(*value)))
    }
}

fn matches_known_identifier(value: Option<&str>) -> bool {
    let Some(value) = value else {
        return false;
    };

    NAUTILUS_IDENTIFIERS
        .iter()
        .any(|candidate| value.eq_ignore_ascii_case(candidate))
}

/// Probe for the current session information.
pub trait SessionProbe {
    /// Returns the current desktop session context.
    fn current_session(&self) -> Result<SessionContext, AdapterError>;
}

/// Probe for the frontmost application.
pub trait FrontmostAppProbe {
    /// Returns the current frontmost application snapshot.
    fn frontmost_app(&self, session: &SessionContext)
    -> Result<FrontmostAppSnapshot, AdapterError>;
}

/// Probe for the currently hovered file-manager item.
pub trait HoveredItemProbe {
    /// Returns the current hovered item at the supplied desktop point.
    fn hovered_item(
        &self,
        session: &SessionContext,
        point: ScreenPoint,
    ) -> Result<Option<HoveredItemSnapshot>, AdapterError>;
}

/// Probe for multi-monitor layout information.
pub trait MonitorProbe {
    /// Returns the current monitor layout for the session.
    fn monitor_layout(&self, session: &SessionContext) -> Result<MonitorLayout, AdapterError>;
}

/// Convenience trait for the full Nautilus adapter probe bundle.
pub trait NautilusProbeSuite:
    SessionProbe + FrontmostAppProbe + HoveredItemProbe + MonitorProbe
{
}

impl<T> NautilusProbeSuite for T where
    T: SessionProbe + FrontmostAppProbe + HoveredItemProbe + MonitorProbe
{
}
