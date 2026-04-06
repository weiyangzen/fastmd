use std::fmt;

use crate::filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, WindowsMarkdownFilter,
};
use crate::parity::{
    MacOsReferenceBehavior, WindowsExplorerStage2Target, MACOS_REFERENCE_BEHAVIOR,
    WINDOWS_EXPLORER_STAGE2_TARGET,
};
use crate::validation::{windows_validation_manifest, AdapterValidationManifest};

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
    pub detected_surface: Option<String>,
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
    use super::{ExplorerAdapter, HostApi, HostCallState};

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
}
