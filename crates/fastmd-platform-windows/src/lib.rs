#![forbid(unsafe_code)]
#![deny(missing_debug_implementations)]

//! Windows 11 + Explorer adapter seams for FastMD Stage 2.
//!
//! This crate deliberately tracks parity against the current macOS app under
//! `apps/macos`. It only claims what is implemented here today and keeps the
//! remaining Windows work behind explicit adapter seams.

pub mod adapter;
pub mod coordinates;
pub mod evidence;
pub mod filter;
pub mod frontmost;
pub mod hover;
pub mod parity;
pub mod preview;
pub mod validation;

pub use adapter::{AdapterError, ExplorerAdapter, FrontmostSurfaceProbe, HostApi, HostCallState};
pub use coordinates::{
    classify_monitor_layout, parse_monitor_layout_snapshot, CoordinateProbeError,
    WindowsCoordinateApi, WindowsCoordinateApiStack, WindowsCoordinateTranslation,
    WindowsMonitorLayoutSnapshot, WINDOWS_COORDINATE_API_STACK,
};
#[cfg(target_os = "windows")]
pub use evidence::capture_live_windows_validation_evidence_report;
pub use evidence::{
    build_windows_validation_evidence_report, EvidenceSectionStatus, ValidationEvidenceSection,
    WindowsValidationEvidenceReport,
};
pub use filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, HoverCandidateSource,
    WindowsMarkdownFilter,
};
#[cfg(target_os = "windows")]
pub use frontmost::probe_frontmost_window_snapshot;
pub use frontmost::{
    parse_frontmost_window_snapshot, resolve_frontmost_surface, FrontmostProbeError,
    FrontmostSurfaceRejection, FrontmostWindowSnapshot, WindowsFrontmostApi,
    WindowsFrontmostApiStack, EXPLORER_WINDOW_CLASSES, WINDOWS_FRONTMOST_API_STACK,
};
#[cfg(target_os = "windows")]
pub use hover::probe_hovered_item_snapshot;
pub use hover::{
    classify_hovered_item_snapshot, parse_hovered_item_snapshot, HoverProbeError,
    HoveredExplorerItemSnapshot, HoveredItemProbeOutcome, HoveredItemResolutionRejection,
    WindowsHoverApi, WindowsHoverApiStack, WINDOWS_HOVER_API_STACK,
};
pub use parity::{
    BackgroundMode, BackgroundToggleKey, BackgroundToggleReference, ClosePolicyReference,
    CoordinateSpaceReference, EditEntryReference, EditModeReference, FrontmostFileManagerReference,
    HintChipReference, HoverResolutionReference, InteractionReference, MacOsReferenceBehavior,
    MathDelimiterReference, MultiMonitorReference, PagingReference, PlacementBoundsReference,
    PreviewGeometryReference, RenderingChromeReference, RenderingLayoutReference,
    RenderingReference, RenderingRuntimeReference, RenderingThemeReference,
    RenderingTypographyReference, WindowsExplorerStage2Target, MACOS_REFERENCE_BEHAVIOR,
    WINDOWS_EXPLORER_FRONTMOST_REFERENCE, WINDOWS_EXPLORER_STAGE2_TARGET,
};
pub use preview::{
    windows_adapter_preview_feature_coverage, windows_preview_loop_feature_coverage,
    PreviewLoopError, WindowsPreviewLoop,
};
pub use validation::{
    AdapterValidationFeature, AdapterValidationManifest, FeatureStatus, WINDOWS_VALIDATION_FEATURES,
};
