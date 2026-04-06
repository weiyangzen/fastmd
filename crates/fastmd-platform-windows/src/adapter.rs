use std::fmt;

#[cfg(target_os = "windows")]
use crate::coordinates::probe_monitor_layout_snapshot;
use crate::coordinates::{
    CoordinateProbeError, WindowsCoordinateTranslation, classify_monitor_layout,
    parse_monitor_layout_snapshot,
};
use crate::filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, WindowsMarkdownFilter,
};
#[cfg(target_os = "windows")]
use crate::frontmost::probe_frontmost_window_snapshot;
use crate::frontmost::{
    FrontmostProbeError, FrontmostSurfaceRejection, FrontmostWindowSnapshot,
    WINDOWS_FRONTMOST_API_STACK, WindowsFrontmostApiStack, parse_frontmost_window_snapshot,
    resolve_frontmost_surface,
};
#[cfg(target_os = "windows")]
use crate::hover::probe_hovered_item_snapshot;
use crate::hover::{
    HoverProbeError, HoveredExplorerItemSnapshot, HoveredItemProbeOutcome,
    classify_hovered_item_snapshot, parse_hovered_item_snapshot,
};
use crate::parity::{
    MACOS_REFERENCE_BEHAVIOR, MacOsReferenceBehavior, WINDOWS_EXPLORER_STAGE2_TARGET,
    WindowsExplorerStage2Target,
};
use crate::validation::{AdapterValidationManifest, windows_validation_manifest};
use fastmd_contracts::{FrontSurface, ScreenPoint};

/// Windows host API seams that still need real Explorer-backed implementations.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HostApi {
    FrontmostExplorerDetection,
    HoveredItemResolution,
    CoordinateTranslation,
    PreviewWindowPlacement,
    RuntimeDiagnostics,
}

/// Why a host API seam is not executable yet from this crate.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HostCallState {
    PendingWindowsImplementation,
    UnsupportedOnCurrentHost,
}

/// Snapshot the adapter should eventually produce when probing whether Explorer
/// is the only allowed active surface.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrontmostSurfaceProbe {
    pub allowed: bool,
    pub observed_surface: FrontSurface,
    pub detected_surface: Option<FrontSurface>,
    pub rejection: Option<FrontmostSurfaceRejection>,
    pub api_stack: &'static WindowsFrontmostApiStack,
    pub notes: &'static str,
}

/// Error returned when a host-integration seam is intentionally still pending.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AdapterError {
    HostCallUnavailable {
        api: HostApi,
        state: HostCallState,
        parity_requirement: &'static str,
    },
    HostProbeFailed {
        api: HostApi,
        parity_requirement: &'static str,
        message: String,
    },
}

impl fmt::Display for AdapterError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::HostCallUnavailable {
                api,
                state,
                parity_requirement,
            } => write!(
                f,
                "host API {:?} unavailable ({:?}); required for {}",
                api, state, parity_requirement
            ),
            Self::HostProbeFailed {
                api,
                parity_requirement,
                message,
            } => write!(
                f,
                "host API {:?} probe failed for {}: {}",
                api, parity_requirement, message
            ),
        }
    }
}

impl std::error::Error for AdapterError {}

/// Explorer adapter entrypoint for the Windows lane.
#[derive(Clone, Debug, Default)]
pub struct ExplorerAdapter {
    filter: WindowsMarkdownFilter,
}

impl ExplorerAdapter {
    pub fn new() -> Self {
        Self {
            filter: WindowsMarkdownFilter,
        }
    }

    pub fn stage2_target(&self) -> &'static WindowsExplorerStage2Target {
        &WINDOWS_EXPLORER_STAGE2_TARGET
    }

    pub fn macos_reference(&self) -> &'static MacOsReferenceBehavior {
        &MACOS_REFERENCE_BEHAVIOR
    }

    pub fn validation_manifest(&self) -> AdapterValidationManifest {
        windows_validation_manifest()
    }

    /// Applies the current macOS file acceptance rules to a Windows/Explorer
    /// hover candidate.
    pub fn accept_hover_candidate(
        &self,
        candidate: HoverCandidate,
    ) -> Result<AcceptedMarkdownPath, HoverCandidateRejection> {
        self.filter.accept_candidate(candidate)
    }

    pub fn probe_frontmost_surface(&self) -> Result<FrontmostSurfaceProbe, AdapterError> {
        #[cfg(target_os = "windows")]
        {
            let snapshot = probe_frontmost_window_snapshot().map_err(|error| {
                self.host_probe_failed(
                    HostApi::FrontmostExplorerDetection,
                    "Windows frontmost Explorer detection with Finder-equivalent gating semantics",
                    error,
                )
            })?;

            Ok(self.classify_frontmost_surface(snapshot))
        }

        #[cfg(not(target_os = "windows"))]
        {
            Err(self.host_call_unavailable(
                HostApi::FrontmostExplorerDetection,
                "Windows frontmost Explorer detection with Finder-equivalent gating semantics",
            ))
        }
    }

    pub fn classify_frontmost_surface(
        &self,
        snapshot: FrontmostWindowSnapshot,
    ) -> FrontmostSurfaceProbe {
        let observed_surface = snapshot.observed_surface();

        match resolve_frontmost_surface(snapshot) {
            Ok(surface) => FrontmostSurfaceProbe {
                allowed: true,
                observed_surface,
                detected_surface: Some(surface),
                rejection: None,
                api_stack: &WINDOWS_FRONTMOST_API_STACK,
                notes: "Strict Explorer gating is wired through the live Windows probe snapshot plus the classifier in this crate.",
            },
            Err(rejection) => FrontmostSurfaceProbe {
                allowed: false,
                observed_surface,
                detected_surface: None,
                rejection: Some(rejection),
                api_stack: &WINDOWS_FRONTMOST_API_STACK,
                notes: "The live Windows probe feeds the strict Explorer classifier, so non-Explorer foreground windows are rejected here before FastMD opens.",
            },
        }
    }

    pub fn classify_frontmost_surface_from_probe_output(
        &self,
        raw_output: &str,
    ) -> Result<FrontmostSurfaceProbe, FrontmostProbeError> {
        parse_frontmost_window_snapshot(raw_output)
            .map(|snapshot| self.classify_frontmost_surface(snapshot))
    }

    pub fn classify_hovered_item(
        &self,
        snapshot: HoveredExplorerItemSnapshot,
    ) -> HoveredItemProbeOutcome {
        classify_hovered_item_snapshot(snapshot, &self.filter)
    }

    pub fn classify_hovered_item_from_probe_output(
        &self,
        raw_output: &str,
    ) -> Result<HoveredItemProbeOutcome, HoverProbeError> {
        parse_hovered_item_snapshot(raw_output).map(|snapshot| self.classify_hovered_item(snapshot))
    }

    pub fn resolve_hovered_item(
        &self,
        front_surface: &FrontSurface,
        cursor: ScreenPoint,
    ) -> Result<HoveredItemProbeOutcome, AdapterError> {
        #[cfg(target_os = "windows")]
        {
            let snapshot = probe_hovered_item_snapshot(front_surface, cursor).map_err(|error| {
                self.host_probe_failed(
                    HostApi::HoveredItemResolution,
                    "Windows hovered-item resolution that identifies the actual hovered Explorer item",
                    error,
                )
            })?;

            Ok(self.classify_hovered_item(snapshot))
        }

        #[cfg(not(target_os = "windows"))]
        {
            let _ = (front_surface, cursor);
            Err(self.host_call_unavailable(
                HostApi::HoveredItemResolution,
                "Windows hovered-item resolution that identifies the actual hovered Explorer item",
            ))
        }
    }

    pub fn classify_coordinate_translation_from_probe_output(
        &self,
        raw_output: &str,
    ) -> Result<WindowsCoordinateTranslation, CoordinateProbeError> {
        parse_monitor_layout_snapshot(raw_output).and_then(classify_monitor_layout)
    }

    pub fn translate_coordinates(
        &self,
        cursor: ScreenPoint,
    ) -> Result<WindowsCoordinateTranslation, AdapterError> {
        #[cfg(target_os = "windows")]
        {
            let _ = cursor;
            let snapshot = probe_monitor_layout_snapshot().map_err(|error| {
                self.host_probe_failed(
                    HostApi::CoordinateTranslation,
                    "Windows multi-monitor coordinate handling with the same placement semantics as macOS",
                    error,
                )
            })?;

            classify_monitor_layout(snapshot).map_err(|error| {
                self.host_probe_failed(
                    HostApi::CoordinateTranslation,
                    "Windows multi-monitor coordinate handling with the same placement semantics as macOS",
                    error,
                )
            })
        }

        #[cfg(not(target_os = "windows"))]
        {
            let _ = cursor;
            Err(self.host_call_unavailable(
                HostApi::CoordinateTranslation,
                "Windows multi-monitor coordinate handling with the same placement semantics as macOS",
            ))
        }
    }

    pub fn place_preview_window(&self) -> Result<(), AdapterError> {
        Err(self.host_call_unavailable(
            HostApi::PreviewWindowPlacement,
            "4:3 preview placement with the same width tiers and reposition-before-shrink rule as macOS",
        ))
    }

    pub fn emit_runtime_diagnostic(&self, _message: &str) -> Result<(), AdapterError> {
        Err(self.host_call_unavailable(
            HostApi::RuntimeDiagnostics,
            "runtime diagnostics coverage matching the macOS adapter where Windows host APIs permit",
        ))
    }

    fn host_call_unavailable(
        &self,
        api: HostApi,
        parity_requirement: &'static str,
    ) -> AdapterError {
        AdapterError::HostCallUnavailable {
            api,
            state: if cfg!(target_os = "windows") {
                HostCallState::PendingWindowsImplementation
            } else {
                HostCallState::UnsupportedOnCurrentHost
            },
            parity_requirement,
        }
    }

    fn host_probe_failed(
        &self,
        api: HostApi,
        parity_requirement: &'static str,
        error: impl std::fmt::Display,
    ) -> AdapterError {
        AdapterError::HostProbeFailed {
            api,
            parity_requirement,
            message: error.to_string(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{ExplorerAdapter, FrontmostWindowSnapshot, HostApi, HostCallState};
    use crate::frontmost::{FrontmostProbeError, FrontmostSurfaceRejection, WindowsFrontmostApi};
    use crate::hover::{HoverProbeError, HoveredItemResolutionRejection, WindowsHoverApi};
    use crate::{HoverCandidateRejection, HoverCandidateSource};
    use fastmd_contracts::{
        DocumentPath, FrontSurface, FrontSurfaceIdentity, FrontSurfaceKind, PlatformId, ScreenPoint,
    };
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    #[derive(Debug)]
    struct TempFixture {
        root: PathBuf,
    }

    impl TempFixture {
        fn new() -> Self {
            let nonce = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .expect("system time should be after unix epoch")
                .as_nanos();
            let root = std::env::temp_dir().join(format!(
                "fastmd-platform-windows-adapter-{nonce}-{}",
                std::process::id()
            ));
            fs::create_dir_all(&root).expect("temp directory should be created");
            Self { root }
        }

        fn write_file(&self, relative_path: impl AsRef<Path>, contents: &str) -> PathBuf {
            let path = self.root.join(relative_path);
            fs::write(&path, contents).expect("temp file should be written");
            path
        }
    }

    impl Drop for TempFixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }

    fn explorer_surface() -> FrontSurface {
        FrontSurface {
            platform_id: PlatformId::WindowsExplorer,
            surface_kind: FrontSurfaceKind::ExplorerListView,
            app_identifier: "explorer.exe".to_string(),
            window_title: Some("Docs".to_string()),
            directory: Some(DocumentPath::from(r"C:\Users\example\Docs")),
            stable_identity: Some(FrontSurfaceIdentity::new("hwnd:0x10001").with_process_id(4_012)),
            expected_host: true,
        }
    }

    #[test]
    fn keeps_windows_target_and_macos_reference_attached_to_the_adapter() {
        let adapter = ExplorerAdapter::new();

        assert_eq!(adapter.stage2_target().operating_system, "Windows 11");
        assert_eq!(adapter.stage2_target().file_manager, "Explorer");
        assert_eq!(adapter.macos_reference().reference_surface, "apps/macos");
    }

    #[cfg(not(target_os = "windows"))]
    #[test]
    fn unresolved_host_calls_stay_honest_about_their_state() {
        let adapter = ExplorerAdapter::new();

        let error = adapter
            .probe_frontmost_surface()
            .expect_err("host call should be unavailable in this slice");

        match error {
            super::AdapterError::HostCallUnavailable { api, state, .. } => {
                assert_eq!(api, HostApi::FrontmostExplorerDetection);
                let expected = if cfg!(target_os = "windows") {
                    HostCallState::PendingWindowsImplementation
                } else {
                    HostCallState::UnsupportedOnCurrentHost
                };
                assert_eq!(state, expected);
            }
        }

        let hover_error = adapter
            .resolve_hovered_item(&explorer_surface(), ScreenPoint::new(120.0, 240.0))
            .expect_err("hover probe should be unavailable off Windows");

        match hover_error {
            super::AdapterError::HostCallUnavailable { api, state, .. } => {
                assert_eq!(api, HostApi::HoveredItemResolution);
                assert_eq!(state, HostCallState::UnsupportedOnCurrentHost);
            }
            other => panic!("unexpected hover error: {other:?}"),
        }

        let coordinate_error = adapter
            .translate_coordinates(ScreenPoint::new(120.0, 240.0))
            .expect_err("coordinate probe should be unavailable off Windows");

        match coordinate_error {
            super::AdapterError::HostCallUnavailable { api, state, .. } => {
                assert_eq!(api, HostApi::CoordinateTranslation);
                assert_eq!(state, HostCallState::UnsupportedOnCurrentHost);
            }
            other => panic!("unexpected coordinate error: {other:?}"),
        }
    }

    #[test]
    fn frontmost_probe_output_roundtrips_through_the_adapter_classifier() {
        let adapter = ExplorerAdapter::new();
        let probe = adapter
            .classify_frontmost_surface_from_probe_output(
                r#"{
                    "foreground_window_id":"hwnd:0x10001",
                    "process_id":4012,
                    "process_image_name":"C:\\Windows\\explorer.exe",
                    "window_class":"CabinetWClass",
                    "window_title":"Docs",
                    "shell_window_id":"hwnd:0x10001"
                }"#,
            )
            .expect("probe JSON should parse");

        assert!(probe.allowed);
        assert_eq!(
            probe.api_stack.foreground_window,
            WindowsFrontmostApi::GetForegroundWindow
        );
        assert!(probe.observed_surface.expected_host);
    }

    #[test]
    fn frontmost_probe_output_rejects_invalid_json() {
        let adapter = ExplorerAdapter::new();
        let error = adapter
            .classify_frontmost_surface_from_probe_output("not json")
            .expect_err("invalid probe output should fail");

        assert!(matches!(
            error,
            FrontmostProbeError::InvalidProbeOutput { .. }
        ));
    }

    #[test]
    fn frontmost_classification_uses_the_authoritative_api_stack_and_surface_identity() {
        let adapter = ExplorerAdapter::new();
        let probe = adapter.classify_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10001",
                4_012,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_shell_window_id("hwnd:0x10001")
            .with_window_title("Docs"),
        );

        assert!(probe.allowed);
        assert!(probe.observed_surface.expected_host);
        assert_eq!(
            probe.api_stack.foreground_window,
            WindowsFrontmostApi::GetForegroundWindow
        );
        assert_eq!(
            probe
                .detected_surface
                .as_ref()
                .and_then(|surface| surface.stable_identity())
                .map(|identity| identity.native_window_id.as_str()),
            Some("hwnd:0x10001")
        );
    }

    #[test]
    fn frontmost_classification_rejects_unmatched_shell_windows() {
        let adapter = ExplorerAdapter::new();
        let probe = adapter.classify_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10002",
                4_013,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_shell_window_id("hwnd:0x20002"),
        );

        assert!(!probe.allowed);
        assert!(!probe.observed_surface.expected_host);
        assert_eq!(probe.observed_surface.app_identifier, "explorer.exe");
        assert_eq!(
            probe.rejection,
            Some(FrontmostSurfaceRejection::MissingShellWindowMatch {
                foreground_window_id: "hwnd:0x10002".to_string(),
                shell_window_id: Some("hwnd:0x20002".to_string()),
            })
        );
    }

    #[test]
    fn hover_probe_output_roundtrips_through_the_adapter_classifier() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hi");
        let adapter = ExplorerAdapter::new();
        let probe = adapter
            .classify_hovered_item_from_probe_output(&format!(
                r#"{{
                    "resolution_scope":"exact-item-under-pointer",
                    "backend":"uiautomation-element-from-point+shell-parse-name",
                    "path":"{}",
                    "element_name":"notes.md",
                    "shell_window_id":"hwnd:0x10001"
                }}"#,
                path.display()
            ))
            .expect("hover probe JSON should parse");

        assert_eq!(
            probe.accepted.as_ref().map(|accepted| accepted.path()),
            Some(path.as_path())
        );
        assert!(probe.rejection.is_none());
        assert_eq!(
            probe.api_stack.element_from_point,
            WindowsHoverApi::ElementFromPoint
        );
    }

    #[test]
    fn coordinate_probe_output_roundtrips_through_the_adapter_classifier() {
        let adapter = ExplorerAdapter::new();
        let translation = adapter
            .classify_coordinate_translation_from_probe_output(
                r#"{
                    "cursor":{"x":120.0,"y":100.0},
                    "virtual_desktop":{"x":-1920.0,"y":0.0,"width":3840.0,"height":1080.0},
                    "monitors":[
                        {
                            "id":"left",
                            "name":"left",
                            "is_primary":false,
                            "scale_factor":1.0,
                            "frame":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1080.0},
                            "working_area":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1040.0}
                        },
                        {
                            "id":"right",
                            "name":"right",
                            "is_primary":true,
                            "scale_factor":1.0,
                            "frame":{"x":0.0,"y":0.0,"width":1920.0,"height":1080.0},
                            "working_area":{"x":0.0,"y":0.0,"width":1920.0,"height":1040.0}
                        }
                    ]
                }"#,
            )
            .expect("coordinate probe JSON should parse");

        assert_eq!(translation.cursor.y, 980.0);
        assert_eq!(translation.selected_monitor.id, "right");
    }

    #[test]
    fn hover_probe_output_rejects_non_parity_scope_and_filter_failures() {
        let adapter = ExplorerAdapter::new();
        let scope_error = adapter
            .classify_hovered_item_from_probe_output(
                r#"{
                    "resolution_scope":"nearby-candidate",
                    "backend":"uiautomation-element-from-point+shell-parse-name",
                    "path":"C:\\Users\\example\\Docs\\notes.md",
                    "element_name":"notes.md"
                }"#,
            )
            .expect("hover probe JSON should parse");
        assert_eq!(
            scope_error.rejection,
            Some(HoveredItemResolutionRejection::InsufficientEvidence {
                scope: fastmd_contracts::HoverResolutionScope::NearbyCandidate,
            })
        );

        let unsupported = adapter
            .classify_hovered_item_from_probe_output(
                r#"{
                    "resolution_scope":"exact-item-under-pointer",
                    "backend":"uiautomation-element-from-point+shell-parse-name",
                    "unsupported_description":"Pointer did not resolve to an Explorer list item.",
                    "element_name":"Address"
                }"#,
            )
            .expect("unsupported probe JSON should parse");
        assert_eq!(
            unsupported.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::UnsupportedItem {
                    description: "Pointer did not resolve to an Explorer list item.".to_string(),
                    source: HoverCandidateSource::ExplorerUiAutomation,
                },
            })
        );
    }

    #[test]
    fn hover_probe_output_rejects_invalid_json() {
        let adapter = ExplorerAdapter::new();
        let error = adapter
            .classify_hovered_item_from_probe_output("not json")
            .expect_err("invalid hover probe output should fail");

        assert!(matches!(error, HoverProbeError::InvalidProbeOutput { .. }));
    }
}
