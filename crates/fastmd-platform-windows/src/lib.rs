#![forbid(unsafe_code)]
#![deny(missing_debug_implementations)]

//! Windows 11 + Explorer adapter seams for FastMD Stage 2.
//!
//! This crate deliberately tracks parity against the current macOS app under
//! `apps/macos`. It only claims what is implemented here today and keeps the
//! remaining Windows work behind explicit adapter seams.

pub mod adapter;
pub mod coordinates;
pub mod filter;
pub mod frontmost;
pub mod hover;
pub mod parity;
pub mod preview;
pub mod validation;

pub use adapter::{AdapterError, ExplorerAdapter, FrontmostSurfaceProbe, HostApi, HostCallState};
pub use coordinates::{
    CoordinateProbeError, WINDOWS_COORDINATE_API_STACK, WindowsCoordinateApi,
    WindowsCoordinateApiStack, WindowsCoordinateTranslation, WindowsMonitorLayoutSnapshot,
    classify_monitor_layout, parse_monitor_layout_snapshot,
};
pub use filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, HoverCandidateSource,
    WindowsMarkdownFilter,
};
#[cfg(target_os = "windows")]
pub use frontmost::probe_frontmost_window_snapshot;
pub use frontmost::{
    EXPLORER_WINDOW_CLASSES, FrontmostProbeError, FrontmostSurfaceRejection,
    FrontmostWindowSnapshot, WINDOWS_FRONTMOST_API_STACK, WindowsFrontmostApi,
    WindowsFrontmostApiStack, parse_frontmost_window_snapshot, resolve_frontmost_surface,
};
#[cfg(target_os = "windows")]
pub use hover::probe_hovered_item_snapshot;
pub use hover::{
    HoverProbeError, HoveredExplorerItemSnapshot, HoveredItemProbeOutcome,
    HoveredItemResolutionRejection, WINDOWS_HOVER_API_STACK, WindowsHoverApi, WindowsHoverApiStack,
    classify_hovered_item_snapshot, parse_hovered_item_snapshot,
};
pub use parity::{
    BackgroundMode, BackgroundToggleKey, BackgroundToggleReference, ClosePolicyReference,
    CoordinateSpaceReference, EditEntryReference, EditModeReference, FrontmostFileManagerReference,
    HintChipReference, HoverResolutionReference, InteractionReference, MACOS_REFERENCE_BEHAVIOR,
    MacOsReferenceBehavior, MathDelimiterReference, MultiMonitorReference, PagingReference,
    PlacementBoundsReference, PreviewGeometryReference, RenderingChromeReference,
    RenderingLayoutReference, RenderingReference, RenderingRuntimeReference,
    RenderingThemeReference, RenderingTypographyReference, WINDOWS_EXPLORER_FRONTMOST_REFERENCE,
    WINDOWS_EXPLORER_STAGE2_TARGET, WindowsExplorerStage2Target,
};
pub use preview::{PreviewLoopError, WindowsPreviewLoop};
pub use validation::{
    AdapterValidationFeature, AdapterValidationManifest, FeatureStatus, WINDOWS_VALIDATION_FEATURES,
};
