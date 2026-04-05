use std::path::PathBuf;

use crate::error::AdapterError;
use crate::geometry::{MonitorLayout, ScreenPoint};
use crate::target::SessionContext;

const NAUTILUS_IDENTIFIERS: &[&str] = &[
    "org.gnome.Nautilus",
    "org.gnome.Nautilus.desktop",
    "nautilus",
];

/// Snapshot of the frontmost application as observed by a host probe.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrontmostAppSnapshot {
    /// Desktop application id.
    pub app_id: Option<String>,
    /// Desktop entry id.
    pub desktop_entry: Option<String>,
    /// X11 window class or equivalent session identifier.
    pub window_class: Option<String>,
    /// Executable name when available.
    pub executable: Option<String>,
}

impl FrontmostAppSnapshot {
    /// Returns true only when the observed application is Nautilus.
    pub fn matches_nautilus(&self) -> bool {
        matches_known_identifier(self.app_id.as_deref())
            || matches_known_identifier(self.desktop_entry.as_deref())
            || matches_known_identifier(self.window_class.as_deref())
            || matches_known_identifier(self.executable.as_deref())
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

/// How strongly the backend can prove that a resolved item came from the
/// pointer location.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HoverResolutionScope {
    /// The backend identified the item directly under the pointer.
    ExactItemUnderPointer,
    /// The backend identified the hovered row/container and then resolved the
    /// item inside that hovered row. This matches the macOS fallback shape.
    HoveredRowDescendant,
    /// A nearby candidate was chosen heuristically.
    NearbyCandidate,
    /// The first visible item was used as a fallback.
    FirstVisibleItem,
}

impl HoverResolutionScope {
    /// Returns true only for scopes that preserve macOS parity expectations.
    pub fn supports_macos_parity(self) -> bool {
        matches!(
            self,
            Self::ExactItemUnderPointer | Self::HoveredRowDescendant
        )
    }
}

/// What kind of entity the backend believes it resolved.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HoveredEntityKind {
    /// Regular file.
    File,
    /// Directory or folder.
    Directory,
    /// Anything else that FastMD should reject.
    Unsupported,
}

/// Host snapshot for the currently hovered file-manager item.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HoveredItemSnapshot {
    /// Absolute path observed by the backend.
    pub path: PathBuf,
    /// File, directory, or unsupported entity.
    pub entity_kind: HoveredEntityKind,
    /// Evidence quality for the resolved item.
    pub resolution_scope: HoverResolutionScope,
    /// Backend label for runtime diagnostics.
    pub backend: &'static str,
}

/// Probe for the current session information.
pub trait SessionProbe {
    /// Returns the current desktop session context.
    fn current_session(&self) -> Result<SessionContext, AdapterError>;
}

/// Probe for the frontmost application.
pub trait FrontmostAppProbe {
    /// Returns the current frontmost application snapshot.
    fn frontmost_app(
        &self,
        session: &SessionContext,
    ) -> Result<FrontmostAppSnapshot, AdapterError>;
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
