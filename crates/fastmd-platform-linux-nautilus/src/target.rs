/// The only supported Linux distribution family for this Stage 2 lane.
pub const TARGET_DISTRO_NAME: &str = "Ubuntu";
/// The required Ubuntu version prefix for the Stage 2 lane.
pub const TARGET_DISTRO_VERSION_PREFIX: &str = "24.04";
/// The only supported desktop environment for this Stage 2 lane.
pub const TARGET_DESKTOP: &str = "GNOME";
/// The only supported file manager surface for this Stage 2 lane.
pub const TARGET_FILE_MANAGER: &str = "Files / Nautilus";
/// The current macOS app remains the behavioral reference implementation.
pub const MACOS_REFERENCE_ROOT: &str = "apps/macos";

/// The Linux display server used by the current desktop session.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DisplayServerKind {
    /// GNOME Wayland session.
    Wayland,
    /// GNOME X11 session.
    X11,
}

/// Session details consumed by the adapter.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SessionContext {
    /// Distribution name, typically read from `/etc/os-release`.
    pub distro_name: String,
    /// Distribution version string, for example `24.04.1 LTS`.
    pub distro_version: String,
    /// Desktop environment identifier, for example `GNOME` or `ubuntu:GNOME`.
    pub desktop: String,
    /// Wayland or X11.
    pub display_server: DisplayServerKind,
}

impl SessionContext {
    /// Returns true only for the explicitly supported Stage 2 surface.
    pub fn is_supported_surface(&self) -> bool {
        self.distro_name.eq_ignore_ascii_case(TARGET_DISTRO_NAME)
            && self
                .distro_version
                .trim()
                .starts_with(TARGET_DISTRO_VERSION_PREFIX)
            && desktop_matches_gnome(&self.desktop)
    }
}

fn desktop_matches_gnome(value: &str) -> bool {
    value
        .split(':')
        .any(|segment| segment.trim().eq_ignore_ascii_case(TARGET_DESKTOP))
}

/// Human-readable label for the Stage 2 Linux target.
pub fn supported_surface_label() -> &'static str {
    "Ubuntu 24.04 + GNOME Files / Nautilus"
}
