use std::fmt;

use crate::filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, WindowsMarkdownFilter,
};
use crate::frontmost::{
    FrontmostSurfaceRejection, FrontmostWindowSnapshot, WINDOWS_FRONTMOST_API_STACK,
    WindowsFrontmostApiStack, resolve_frontmost_surface,
};
use crate::parity::{
    MACOS_REFERENCE_BEHAVIOR, MacOsReferenceBehavior, WINDOWS_EXPLORER_STAGE2_TARGET,
    WindowsExplorerStage2Target,
};
use crate::validation::{AdapterValidationManifest, windows_validation_manifest};
use fastmd_contracts::FrontSurface;

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
        Err(self.host_call_unavailable(
            HostApi::FrontmostExplorerDetection,
            "Windows frontmost Explorer detection with Finder-equivalent gating semantics",
        ))
    }

    pub fn classify_frontmost_surface(
        &self,
        snapshot: FrontmostWindowSnapshot,
    ) -> FrontmostSurfaceProbe {
        match resolve_frontmost_surface(snapshot) {
            Ok(surface) => FrontmostSurfaceProbe {
                allowed: true,
                detected_surface: Some(surface),
                rejection: None,
                api_stack: &WINDOWS_FRONTMOST_API_STACK,
                notes: "Classification is implemented, but live Windows host probing is still pending in this crate.",
            },
            Err(rejection) => FrontmostSurfaceProbe {
                allowed: false,
                detected_surface: None,
                rejection: Some(rejection),
                api_stack: &WINDOWS_FRONTMOST_API_STACK,
                notes: "Strict Explorer gating is classified here, but live Windows host probing is still pending in this crate.",
            },
        }
    }

    pub fn resolve_hovered_item(&self) -> Result<HoverCandidate, AdapterError> {
        Err(self.host_call_unavailable(
            HostApi::HoveredItemResolution,
            "Windows hovered-item resolution that identifies the actual hovered Explorer item",
        ))
    }

    pub fn translate_coordinates(&self) -> Result<(), AdapterError> {
        Err(self.host_call_unavailable(
            HostApi::CoordinateTranslation,
            "Windows multi-monitor coordinate handling with the same placement semantics as macOS",
        ))
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
}

#[cfg(test)]
mod tests {
    use super::{ExplorerAdapter, FrontmostWindowSnapshot, HostApi, HostCallState};
    use crate::frontmost::{FrontmostSurfaceRejection, WindowsFrontmostApi};

    #[test]
    fn keeps_windows_target_and_macos_reference_attached_to_the_adapter() {
        let adapter = ExplorerAdapter::new();

        assert_eq!(adapter.stage2_target().operating_system, "Windows 11");
        assert_eq!(adapter.stage2_target().file_manager, "Explorer");
        assert_eq!(adapter.macos_reference().reference_surface, "apps/macos");
    }

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
        assert_eq!(
            probe.rejection,
            Some(FrontmostSurfaceRejection::MissingShellWindowMatch {
                foreground_window_id: "hwnd:0x10002".to_string(),
                shell_window_id: Some("hwnd:0x20002".to_string()),
            })
        );
    }
}
