use std::fmt;

use crate::probes::FrontmostAppSnapshot;
use crate::target::DisplayServerKind;

pub const NAUTILUS_CANONICAL_APP_ID: &str = "org.gnome.Nautilus";

/// Authoritative host-facing inputs for frontmost Nautilus detection.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NautilusFrontmostApi {
    /// Focused accessible/window source from the desktop accessibility tree.
    AtspiFocusedAccessible,
    /// Stable application bus name from the AT-SPI application root.
    AtspiApplicationBusName,
    /// GTK/GApplication application id, which is expected to match the desktop
    /// file basename and Wayland `app_id`.
    GtkApplicationId,
    /// EWMH `_NET_ACTIVE_WINDOW` surface identity on X11.
    X11NetActiveWindow,
}

/// Explicit frontmost detection stack for one Linux display-server backend.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NautilusFrontmostApiStack {
    pub display_server: DisplayServerKind,
    pub focus_source: NautilusFrontmostApi,
    pub application_bus_name: NautilusFrontmostApi,
    pub application_id: NautilusFrontmostApi,
    pub stable_surface_id: NautilusFrontmostApi,
}

pub static WAYLAND_FRONTMOST_API_STACK: NautilusFrontmostApiStack = NautilusFrontmostApiStack {
    display_server: DisplayServerKind::Wayland,
    focus_source: NautilusFrontmostApi::AtspiFocusedAccessible,
    application_bus_name: NautilusFrontmostApi::AtspiApplicationBusName,
    application_id: NautilusFrontmostApi::GtkApplicationId,
    stable_surface_id: NautilusFrontmostApi::AtspiFocusedAccessible,
};

pub static X11_FRONTMOST_API_STACK: NautilusFrontmostApiStack = NautilusFrontmostApiStack {
    display_server: DisplayServerKind::X11,
    focus_source: NautilusFrontmostApi::AtspiFocusedAccessible,
    application_bus_name: NautilusFrontmostApi::AtspiApplicationBusName,
    application_id: NautilusFrontmostApi::GtkApplicationId,
    stable_surface_id: NautilusFrontmostApi::X11NetActiveWindow,
};

pub fn api_stack_for_display_server(
    display_server: DisplayServerKind,
) -> &'static NautilusFrontmostApiStack {
    match display_server {
        DisplayServerKind::Wayland => &WAYLAND_FRONTMOST_API_STACK,
        DisplayServerKind::X11 => &X11_FRONTMOST_API_STACK,
    }
}

/// Stable Nautilus surface identity required by the Linux frontmost gate.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct NautilusSurfaceIdentity {
    pub display_server: DisplayServerKind,
    pub native_surface_id: String,
    pub process_id: Option<u32>,
}

/// Accepted frontmost Nautilus surface.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrontmostNautilusSurface {
    pub canonical_app_id: &'static str,
    pub observed_identifier: String,
    pub stable_identity: NautilusSurfaceIdentity,
    pub window_title: Option<String>,
}

/// Why a host snapshot failed strict frontmost Nautilus classification.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum FrontmostSurfaceRejection {
    NonNautilusApp {
        app_id: Option<String>,
        desktop_entry: Option<String>,
        window_class: Option<String>,
        executable: Option<String>,
    },
    MissingStableSurfaceId {
        display_server: DisplayServerKind,
    },
}

impl fmt::Display for FrontmostSurfaceRejection {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NonNautilusApp {
                app_id,
                desktop_entry,
                window_class,
                executable,
            } => write!(
                f,
                "frontmost surface is not Nautilus: app_id={:?}, desktop_entry={:?}, window_class={:?}, executable={:?}",
                app_id, desktop_entry, window_class, executable
            ),
            Self::MissingStableSurfaceId { display_server } => write!(
                f,
                "frontmost {:?} surface is missing a stable Nautilus identity",
                display_server
            ),
        }
    }
}

impl std::error::Error for FrontmostSurfaceRejection {}

pub fn resolve_frontmost_surface(
    display_server: DisplayServerKind,
    snapshot: &FrontmostAppSnapshot,
) -> Result<FrontmostNautilusSurface, FrontmostSurfaceRejection> {
    let observed_identifier = snapshot.matched_nautilus_identifier().ok_or_else(|| {
        FrontmostSurfaceRejection::NonNautilusApp {
            app_id: snapshot.app_id.clone(),
            desktop_entry: snapshot.desktop_entry.clone(),
            window_class: snapshot.window_class.clone(),
            executable: snapshot.executable.clone(),
        }
    })?;

    let native_surface_id = snapshot
        .stable_surface_id
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .ok_or(FrontmostSurfaceRejection::MissingStableSurfaceId { display_server })?;

    Ok(FrontmostNautilusSurface {
        canonical_app_id: NAUTILUS_CANONICAL_APP_ID,
        observed_identifier: observed_identifier.to_string(),
        stable_identity: NautilusSurfaceIdentity {
            display_server,
            native_surface_id: native_surface_id.to_string(),
            process_id: snapshot.process_id,
        },
        window_title: snapshot.window_title.clone(),
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn authoritative_frontmost_api_stacks_are_explicit() {
        assert_eq!(
            WAYLAND_FRONTMOST_API_STACK.focus_source,
            NautilusFrontmostApi::AtspiFocusedAccessible
        );
        assert_eq!(
            WAYLAND_FRONTMOST_API_STACK.application_bus_name,
            NautilusFrontmostApi::AtspiApplicationBusName
        );
        assert_eq!(
            WAYLAND_FRONTMOST_API_STACK.application_id,
            NautilusFrontmostApi::GtkApplicationId
        );
        assert_eq!(
            WAYLAND_FRONTMOST_API_STACK.stable_surface_id,
            NautilusFrontmostApi::AtspiFocusedAccessible
        );
        assert_eq!(
            X11_FRONTMOST_API_STACK.stable_surface_id,
            NautilusFrontmostApi::X11NetActiveWindow
        );
    }

    #[test]
    fn resolves_a_wayland_frontmost_nautilus_surface_with_a_stable_identity() {
        let surface = resolve_frontmost_surface(
            DisplayServerKind::Wayland,
            &FrontmostAppSnapshot {
                app_id: Some("org.gnome.Nautilus".to_string()),
                desktop_entry: Some("org.gnome.Nautilus.desktop".to_string()),
                window_class: None,
                executable: Some("nautilus".to_string()),
                window_title: Some("Docs".to_string()),
                process_id: Some(4_212),
                stable_surface_id: Some("atspi:app/org.gnome.Nautilus/window/3".to_string()),
            },
        )
        .expect("matching Wayland Nautilus surface should resolve");

        assert_eq!(surface.canonical_app_id, NAUTILUS_CANONICAL_APP_ID);
        assert_eq!(surface.observed_identifier, "org.gnome.Nautilus");
        assert_eq!(
            surface.stable_identity.native_surface_id,
            "atspi:app/org.gnome.Nautilus/window/3"
        );
    }

    #[test]
    fn resolves_an_x11_frontmost_nautilus_surface_with_a_stable_identity() {
        let surface = resolve_frontmost_surface(
            DisplayServerKind::X11,
            &FrontmostAppSnapshot {
                app_id: None,
                desktop_entry: Some("org.gnome.Nautilus.desktop".to_string()),
                window_class: Some("org.gnome.Nautilus".to_string()),
                executable: Some("nautilus".to_string()),
                window_title: Some("Projects".to_string()),
                process_id: Some(4_213),
                stable_surface_id: Some("x11:0x4200011".to_string()),
            },
        )
        .expect("matching X11 Nautilus surface should resolve");

        assert_eq!(
            surface.stable_identity.display_server,
            DisplayServerKind::X11
        );
        assert_eq!(surface.stable_identity.native_surface_id, "x11:0x4200011");
    }

    #[test]
    fn rejects_non_nautilus_surfaces_even_if_a_surface_id_exists() {
        let rejection = resolve_frontmost_surface(
            DisplayServerKind::Wayland,
            &FrontmostAppSnapshot {
                app_id: Some("org.gnome.Terminal".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: None,
                window_title: None,
                process_id: Some(91),
                stable_surface_id: Some("atspi:app/org.gnome.Terminal/window/1".to_string()),
            },
        )
        .expect_err("non-Nautilus surfaces must be rejected");

        assert!(matches!(
            rejection,
            FrontmostSurfaceRejection::NonNautilusApp { .. }
        ));
    }

    #[test]
    fn rejects_missing_stable_surface_ids() {
        let rejection = resolve_frontmost_surface(
            DisplayServerKind::X11,
            &FrontmostAppSnapshot {
                app_id: Some("org.gnome.Nautilus".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: Some("nautilus".to_string()),
                window_title: Some("Missing identity".to_string()),
                process_id: Some(92),
                stable_surface_id: None,
            },
        )
        .expect_err("a stable surface id is required");

        assert_eq!(
            rejection,
            FrontmostSurfaceRejection::MissingStableSurfaceId {
                display_server: DisplayServerKind::X11,
            }
        );
    }
}
