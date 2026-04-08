use std::path::PathBuf;

use crate::error::AdapterError;
use crate::filter::LinuxMarkdownFilter;
use crate::frontmost::{
    FrontmostNautilusSurface, FrontmostSurfaceRejection, NautilusFrontmostApiStack,
    api_stack_for_display_server, resolve_frontmost_surface,
};
use crate::geometry::{Monitor, ScreenPoint};
use crate::hover::{HoveredItemProbeOutcome, HoveredItemSnapshot, classify_hovered_item_snapshot};
use crate::probes::{FrontmostAppSnapshot, NautilusProbeSuite};
use crate::target::{SessionContext, supported_surface_label};

/// Result of the frontmost-file-manager gating decision.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct FrontmostGate {
    /// Session used to evaluate the gate.
    pub session: SessionContext,
    /// Frontmost application snapshot used by the gate.
    pub frontmost_app: FrontmostAppSnapshot,
    /// Accepted frontmost Nautilus surface when the gate is open.
    pub detected_surface: Option<FrontmostNautilusSurface>,
    /// Strict rejection reason when the gate is closed.
    pub rejection: Option<FrontmostSurfaceRejection>,
    /// Explicit host API stack for the current display server.
    pub api_stack: &'static NautilusFrontmostApiStack,
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
    filter: LinuxMarkdownFilter,
}

impl<P> NautilusPlatformAdapter<P> {
    /// Creates a new adapter instance.
    pub fn new(probes: P) -> Self {
        Self {
            probes,
            filter: LinuxMarkdownFilter,
        }
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
        let api_stack = api_stack_for_display_server(session.display_server);

        Ok(
            match resolve_frontmost_surface(session.display_server, &frontmost_app) {
                Ok(surface) => FrontmostGate {
                    session,
                    frontmost_app,
                    detected_surface: Some(surface),
                    rejection: None,
                    api_stack,
                    is_open: true,
                },
                Err(rejection) => FrontmostGate {
                    session,
                    frontmost_app,
                    detected_surface: None,
                    rejection: Some(rejection),
                    api_stack,
                    is_open: false,
                },
            },
        )
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

        let outcome = self.classify_hovered_item(snapshot);
        let Some(accepted) = outcome.accepted else {
            return Ok(None);
        };
        let snapshot = outcome.snapshot;

        Ok(Some(ResolvedHover {
            path: accepted.path().to_path_buf(),
            snapshot,
        }))
    }

    /// Classifies one normalized Nautilus hovered-item snapshot through the
    /// parity-preserving evidence gate and local-Markdown acceptance filter.
    pub fn classify_hovered_item(&self, snapshot: HoveredItemSnapshot) -> HoveredItemProbeOutcome {
        classify_hovered_item_snapshot(snapshot, &self.filter)
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

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use crate::backends;
    use crate::filter::{HoverCandidateRejection, HoverCandidateSource};
    use crate::geometry::{MonitorLayout, ScreenRect};
    use crate::hover::{
        HoverResolutionScope, HoveredEntityKind, HoveredItemObservation,
        HoveredItemResolutionRejection, build_hovered_item_snapshot,
    };
    use crate::probes::{
        FrontmostAppProbe, FrontmostAppSnapshot, HoveredItemProbe, MonitorProbe, SessionProbe,
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
    fn frontmost_gate_only_opens_for_nautilus_with_a_stable_surface_identity() {
        let adapter = NautilusPlatformAdapter::new(base_probes(
            FrontmostAppSnapshot {
                app_id: Some("org.gnome.Nautilus".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: None,
                window_title: Some("Docs".to_string()),
                process_id: Some(4_201),
                stable_surface_id: Some("atspi:app/org.gnome.Nautilus/window/1".to_string()),
                focused_role_name: None,
                focused_name: None,
                focused_is_text_input: false,
            },
            None,
        ));

        let gate = adapter.frontmost_gate().unwrap();
        assert!(gate.is_open);
        assert_eq!(
            gate.detected_surface
                .as_ref()
                .map(|surface| surface.stable_identity.native_surface_id.as_str()),
            Some("atspi:app/org.gnome.Nautilus/window/1")
        );

        let closed = NautilusPlatformAdapter::new(base_probes(
            FrontmostAppSnapshot {
                app_id: Some("org.gnome.Terminal".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: None,
                window_title: Some("Terminal".to_string()),
                process_id: Some(4_202),
                stable_surface_id: Some("atspi:app/org.gnome.Terminal/window/1".to_string()),
                focused_role_name: None,
                focused_name: None,
                focused_is_text_input: false,
            },
            None,
        ));

        assert!(!closed.frontmost_gate().unwrap().is_open);
    }

    #[test]
    fn frontmost_gate_rejects_missing_stable_surface_identity() {
        let adapter = NautilusPlatformAdapter::new(base_probes(
            FrontmostAppSnapshot {
                app_id: Some("org.gnome.Nautilus".to_string()),
                desktop_entry: None,
                window_class: None,
                executable: Some("nautilus".to_string()),
                window_title: Some("Missing".to_string()),
                process_id: Some(4_203),
                stable_surface_id: None,
                focused_role_name: None,
                focused_name: None,
                focused_is_text_input: false,
            },
            None,
        ));

        let gate = adapter.frontmost_gate().unwrap();

        assert!(!gate.is_open);
        assert_eq!(
            gate.rejection,
            Some(FrontmostSurfaceRejection::MissingStableSurfaceId {
                display_server: DisplayServerKind::Wayland,
            })
        );
    }

    #[test]
    fn resolve_hovered_markdown_accepts_exact_markdown_file() {
        let file = temp_path("exact.md");
        write_file(&file);

        let adapter = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test".to_string(),
                absolute_path: Some(file.clone()),
                parent_directory: None,
                item_name: Some("exact.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            })),
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
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::HoveredRowDescendant,
                backend: "test".to_string(),
                absolute_path: None,
                parent_directory: file.parent().map(Path::to_path_buf),
                item_name: file
                    .file_name()
                    .and_then(|value| value.to_str())
                    .map(ToOwned::to_owned),
                path_source: HoverCandidateSource::HoveredRowLabelWithParentDirectory,
                visible_markdown_peer_count: Some(3),
                unsupported_description: None,
            })),
        ));

        assert!(
            adapter
                .resolve_hovered_markdown(ScreenPoint { x: 4.0, y: 8.0 })
                .unwrap()
                .is_some()
        );

        cleanup_path(&file);
    }

    #[test]
    fn resolve_hovered_markdown_rejects_nearby_or_first_visible_candidates() {
        let nearby_file = temp_path("nearby.md");
        write_file(&nearby_file);

        let nearby = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::NearbyCandidate,
                backend: "test".to_string(),
                absolute_path: Some(nearby_file.clone()),
                parent_directory: None,
                item_name: Some("nearby.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(4),
                unsupported_description: None,
            })),
        ));
        assert!(
            nearby
                .resolve_hovered_markdown(ScreenPoint { x: 1.0, y: 1.0 })
                .unwrap()
                .is_none()
        );

        let first_visible = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::FirstVisibleItem,
                backend: "test".to_string(),
                absolute_path: Some(nearby_file.clone()),
                parent_directory: None,
                item_name: Some("nearby.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(4),
                unsupported_description: None,
            })),
        ));
        assert!(
            first_visible
                .resolve_hovered_markdown(ScreenPoint { x: 1.0, y: 1.0 })
                .unwrap()
                .is_none()
        );

        cleanup_path(&nearby_file);
    }

    #[test]
    fn resolve_hovered_markdown_rejects_non_markdown_and_directories() {
        let txt_file = temp_path("notes.txt");
        write_file(&txt_file);

        let non_markdown = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test".to_string(),
                absolute_path: Some(txt_file.clone()),
                parent_directory: None,
                item_name: Some("notes.txt".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            })),
        ));
        assert!(
            non_markdown
                .resolve_hovered_markdown(ScreenPoint { x: 0.0, y: 0.0 })
                .unwrap()
                .is_none()
        );

        let directory = temp_directory("folder.md");
        let directory_probe = NautilusPlatformAdapter::new(base_probes(
            nautilus_frontmost(),
            Some(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::Directory,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test".to_string(),
                absolute_path: Some(directory.clone()),
                parent_directory: None,
                item_name: Some("folder.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            })),
        ));
        assert!(
            directory_probe
                .resolve_hovered_markdown(ScreenPoint { x: 0.0, y: 0.0 })
                .unwrap()
                .is_none()
        );

        cleanup_path(&txt_file);
        cleanup_path(&directory);
    }

    #[test]
    fn classify_hovered_item_wires_the_markdown_filter_into_the_nautilus_pipeline() {
        let adapter = NautilusPlatformAdapter::new(base_probes(nautilus_frontmost(), None));
        let missing =
            adapter.classify_hovered_item(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test".to_string(),
                absolute_path: Some(temp_path("missing.md")),
                parent_directory: None,
                item_name: Some("missing.md".to_string()),
                path_source: HoverCandidateSource::AtspiPathAttribute,
                visible_markdown_peer_count: Some(2),
                unsupported_description: None,
            }));
        assert!(matches!(
            missing.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::MissingPath { .. }
            })
        ));

        let unsupported =
            adapter.classify_hovered_item(build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::Unsupported,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "test".to_string(),
                absolute_path: None,
                parent_directory: None,
                item_name: None,
                path_source: HoverCandidateSource::AtspiUriAttribute,
                visible_markdown_peer_count: None,
                unsupported_description: Some("hovered widget is not a file row".to_string()),
            }));
        assert!(matches!(
            unsupported.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::UnsupportedItem { .. }
            })
        ));
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
            .monitor_for_point(ScreenPoint {
                x: 2400.0,
                y: 300.0,
            })
            .unwrap()
            .unwrap();
        assert_eq!(second.id, "secondary");

        let outside = adapter
            .monitor_for_point(ScreenPoint {
                x: 5000.0,
                y: 5000.0,
            })
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
            window_title: Some("Docs".to_string()),
            process_id: Some(4_200),
            stable_surface_id: Some("atspi:app/org.gnome.Nautilus/window/0".to_string()),
            focused_role_name: None,
            focused_name: None,
            focused_is_text_input: false,
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
