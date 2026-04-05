use std::ffi::OsStr;
use std::fs;
use std::path::PathBuf;

use crate::error::AdapterError;
use crate::geometry::{Monitor, ScreenPoint};
use crate::probes::{
    FrontmostAppSnapshot, HoveredEntityKind, HoveredItemSnapshot, NautilusProbeSuite,
};
use crate::target::{supported_surface_label, SessionContext};

/// Result of the frontmost-file-manager gating decision.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrontmostGate {
    /// Session used to evaluate the gate.
    pub session: SessionContext,
    /// Frontmost application snapshot used by the gate.
    pub frontmost_app: FrontmostAppSnapshot,
    /// Whether the gate is open for FastMD semantics.
    pub is_open: bool,
}

/// Resolved hovered Markdown file that survives the adapter acceptance rules.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolvedHover {
    /// Absolute Markdown file path.
    pub path: PathBuf,
    /// Host snapshot that produced the accepted resolution.
    pub snapshot: HoveredItemSnapshot,
}

/// Ubuntu 24.04 GNOME Files / Nautilus adapter.
#[derive(Debug, Clone)]
pub struct NautilusPlatformAdapter<P> {
    probes: P,
}

impl<P> NautilusPlatformAdapter<P> {
    /// Creates a new adapter instance.
    pub fn new(probes: P) -> Self {
        Self { probes }
    }

    /// Returns the Stage 2 target label encoded by this crate.
    pub fn supported_surface(&self) -> &'static str {
        supported_surface_label()
    }
}

impl<P> NautilusPlatformAdapter<P>
where
    P: NautilusProbeSuite,
{
    /// Evaluates the frontmost-file-manager gate.
    pub fn frontmost_gate(&self) -> Result<FrontmostGate, AdapterError> {
        let session = self.supported_session()?;
        let frontmost_app = self.probes.frontmost_app(&session)?;
        let is_open = frontmost_app.matches_nautilus();

        Ok(FrontmostGate {
            session,
            frontmost_app,
            is_open,
        })
    }

    /// Resolves the currently hovered Markdown file when the adapter can prove
    /// that the candidate matches macOS parity constraints.
    pub fn resolve_hovered_markdown(
        &self,
        point: ScreenPoint,
    ) -> Result<Option<ResolvedHover>, AdapterError> {
        let gate = self.frontmost_gate()?;
        if !gate.is_open {
            return Ok(None);
        }

        let Some(snapshot) = self.probes.hovered_item(&gate.session, point)? else {
            return Ok(None);
        };

        if !snapshot.resolution_scope.supports_macos_parity() {
            return Ok(None);
        }

        if snapshot.entity_kind != HoveredEntityKind::File {
            return Ok(None);
        }

        if !snapshot.path.is_absolute() {
            return Ok(None);
        }

        if !is_markdown_path(&snapshot.path) {
            return Ok(None);
        }

        let Ok(metadata) = fs::metadata(&snapshot.path) else {
            return Ok(None);
        };

        if !metadata.is_file() {
            return Ok(None);
        }

        Ok(Some(ResolvedHover {
            path: snapshot.path.clone(),
            snapshot,
        }))
    }

    /// Returns the monitor whose work area should be used for a given desktop
    /// point. This mirrors the current macOS behavior of preferring the screen
    /// containing the pointer and only falling back when the pointer is outside
    /// every visible work area.
    pub fn monitor_for_point(&self, point: ScreenPoint) -> Result<Option<Monitor>, AdapterError> {
        let session = self.supported_session()?;
        let layout = self.probes.monitor_layout(&session)?;
        Ok(layout.monitor_for_point(point).cloned())
    }

    fn supported_session(&self) -> Result<SessionContext, AdapterError> {
        let session = self.probes.current_session()?;
        if session.is_supported_surface() {
            Ok(session)
        } else {
            Err(AdapterError::UnsupportedTargetSurface {
                distro_name: session.distro_name,
                distro_version: session.distro_version,
                desktop: session.desktop,
            })
        }
    }
}

fn is_markdown_path(path: &PathBuf) -> bool {
    path.extension()
        .and_then(OsStr::to_str)
        .map(|extension| extension.eq_ignore_ascii_case("md"))
        .unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use crate::backends;
    use crate::geometry::{MonitorLayout, ScreenRect};
    use crate::probes::{
        FrontmostAppProbe, FrontmostAppSnapshot, HoverResolutionScope, HoveredEntityKind,
        HoveredItemProbe, HoveredItemSnapshot, MonitorProbe, SessionProbe,
    };
    use crate::target::{DisplayServerKind, SessionContext};

    use super::*;

    #[derive(Debug, Clone)]
    struct FixedProbes {
        session: SessionContext,
        frontmost: FrontmostAppSnapshot,
        hovered: Option<HoveredItemSnapshot>,
        monitors: MonitorLayout,
    }

    impl SessionProbe for FixedProbes {
        fn current_session(&self) -> Result<SessionContext, AdapterError> {
            Ok(self.session.clone())
        }
    }

    impl FrontmostAppProbe for FixedProbes {
        fn frontmost_app(
            &self,
            _session: &SessionContext,
        ) -> Result<FrontmostAppSnapshot, AdapterError> {
            Ok(self.frontmost.clone())
        }
    }

    impl HoveredItemProbe for FixedProbes {
        fn hovered_item(
            &self,
            _session: &SessionContext,
            _point: ScreenPoint,
        ) -> Result<Option<HoveredItemSnapshot>, AdapterError> {
            Ok(self.hovered.clone())
        }
    }

    impl MonitorProbe for FixedProbes {
        fn monitor_layout(&self, _session: &SessionContext) -> Result<MonitorLayout, AdapterError> {
            Ok(self.monitors.clone())
        }
    }

    #[test]
    fn supported_surface_only_allows_ubuntu_24_04_gnome() {
        let session = SessionContext {
            distro_name: "Ubuntu".to_string(),
            distro_version: "24.04.1 LTS".to_string(),
            desktop: "ubuntu:GNOME".to_string(),
            display_server: DisplayServerKind::Wayland,
        };

        assert!(session.is_supported_surface());
    }

    #[test]
    fn frontmost_gate_only_opens_for_nautilus() {
        let adapter = NautilusPlatformAdapter::new(base_probes(
            FrontmostAppSnapshot {
                app_id: Some("org.gnome.Nautilus".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: None,
            },
            None,
        ));

        assert!(adapter.frontmost_gate().unwrap().is_open);

        let closed = NautilusPlatformAdapter::new(base_probes(
            FrontmostAppSnapshot {
                app_id: Some("org.gnome.Terminal".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: None,
            },
            None,
        ));

        assert!(!closed.frontmost_gate().unwrap().is_open);
    }

    #[test]
    fn resolve_hovered_markdown_accepts_exact_markdown_file() {
        let file = temp_path("exact.md");
        write_file(&file);

        let adapter = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: file.clone(),
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test",
            }),
        ));

        let resolved = adapter
            .resolve_hovered_markdown(ScreenPoint { x: 100.0, y: 100.0 })
            .unwrap()
            .unwrap();

        assert_eq!(resolved.path, file);

        cleanup_path(&resolved.path);
    }

    #[test]
    fn resolve_hovered_markdown_accepts_hovered_row_descendant() {
        let file = temp_path("row-descendant.MD");
        write_file(&file);

        let adapter = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: file.clone(),
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::HoveredRowDescendant,
                backend: "test",
            }),
        ));

        assert!(adapter
            .resolve_hovered_markdown(ScreenPoint { x: 4.0, y: 8.0 })
            .unwrap()
            .is_some());

        cleanup_path(&file);
    }

    #[test]
    fn resolve_hovered_markdown_rejects_nearby_or_first_visible_candidates() {
        let nearby_file = temp_path("nearby.md");
        write_file(&nearby_file);

        let nearby = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: nearby_file.clone(),
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::NearbyCandidate,
                backend: "test",
            }),
        ));
        assert!(nearby
            .resolve_hovered_markdown(ScreenPoint { x: 1.0, y: 1.0 })
            .unwrap()
            .is_none());

        let first_visible = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: nearby_file.clone(),
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::FirstVisibleItem,
                backend: "test",
            }),
        ));
        assert!(first_visible
            .resolve_hovered_markdown(ScreenPoint { x: 1.0, y: 1.0 })
            .unwrap()
            .is_none());

        cleanup_path(&nearby_file);
    }

    #[test]
    fn resolve_hovered_markdown_rejects_non_markdown_and_directories() {
        let txt_file = temp_path("notes.txt");
        write_file(&txt_file);

        let non_markdown = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: txt_file.clone(),
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test",
            }),
        ));
        assert!(non_markdown
            .resolve_hovered_markdown(ScreenPoint { x: 0.0, y: 0.0 })
            .unwrap()
            .is_none());

        let directory = temp_directory("folder.md");
        let directory_probe = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(HoveredItemSnapshot {
                path: directory.clone(),
                entity_kind: HoveredEntityKind::Directory,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test",
            }),
        ));
        assert!(directory_probe
            .resolve_hovered_markdown(ScreenPoint { x: 0.0, y: 0.0 })
            .unwrap()
            .is_none());

        cleanup_path(&txt_file);
        cleanup_path(&directory);
    }

    #[test]
    fn monitor_selection_prefers_containing_work_area_then_nearest() {
        let adapter = NautilusPlatformAdapter::new(base_probes(nautilus_frontmost(), None));

        let first = adapter
            .monitor_for_point(ScreenPoint { x: 100.0, y: 100.0 })
            .unwrap()
            .unwrap();
        assert_eq!(first.id, "primary");

        let second = adapter
            .monitor_for_point(ScreenPoint { x: 2400.0, y: 300.0 })
            .unwrap()
            .unwrap();
        assert_eq!(second.id, "secondary");

        let outside = adapter
            .monitor_for_point(ScreenPoint { x: 5000.0, y: 5000.0 })
            .unwrap()
            .unwrap();
        assert_eq!(outside.id, "secondary");
    }

    #[test]
    fn wayland_and_x11_plans_share_the_same_semantic_guardrail() {
        let wayland = backends::wayland::probe_plan();
        let x11 = backends::x11::probe_plan();

        assert_ne!(wayland.display_server, x11.display_server);
        assert_eq!(wayland.semantic_guardrail, x11.semantic_guardrail);
    }

    fn base_probes(
        frontmost: FrontmostAppSnapshot,
        hovered: Option<HoveredItemSnapshot>,
    ) -> FixedProbes {
        FixedProbes {
            session: SessionContext {
                distro_name: "Ubuntu".to_string(),
                distro_version: "24.04.1".to_string(),
                desktop: "ubuntu:GNOME".to_string(),
                display_server: DisplayServerKind::Wayland,
            },
            frontmost,
            hovered,
            monitors: MonitorLayout {
                monitors: vec![
                    Monitor {
                        id: "primary".to_string(),
                        frame: ScreenRect {
                            x: 0.0,
                            y: 0.0,
                            width: 1920.0,
                            height: 1080.0,
                        },
                        work_area: ScreenRect {
                            x: 0.0,
                            y: 0.0,
                            width: 1920.0,
                            height: 1040.0,
                        },
                        primary: true,
                    },
                    Monitor {
                        id: "secondary".to_string(),
                        frame: ScreenRect {
                            x: 1920.0,
                            y: 0.0,
                            width: 2560.0,
                            height: 1440.0,
                        },
                        work_area: ScreenRect {
                            x: 1920.0,
                            y: 0.0,
                            width: 2560.0,
                            height: 1400.0,
                        },
                        primary: false,
                    },
                ],
            },
        }
    }

    fn nautilus_frontmost() -> FrontmostAppSnapshot {
        FrontmostAppSnapshot {
            app_id: Some("org.gnome.Nautilus".to_string()),
            desktop_entry: None,
            window_class: None,
            executable: Some("nautilus".to_string()),
        }
    }

    fn temp_path(name: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir().join(format!("fastmd-nautilus-{nonce}-{name}"))
    }

    fn temp_directory(name: &str) -> PathBuf {
        let path = temp_path(name);
        fs::create_dir_all(&path).unwrap();
        path
    }

    fn write_file(path: &Path) {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).unwrap();
        }
        fs::write(path, "# hello\n").unwrap();
    }

    fn cleanup_path(path: &Path) {
        if path.is_dir() {
            let _ = fs::remove_dir_all(path);
        } else {
            let _ = fs::remove_file(path);
        }
    }
}
