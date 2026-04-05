use std::collections::BTreeMap;
use std::fmt;
use std::path::Path;

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PlatformId {
    MacosFinder,
    WindowsExplorer,
    UbuntuGnomeFiles,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PermissionState {
    Unknown,
    NotRequired,
    Missing,
    Promptable,
    Granted,
    Denied,
    Restricted,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum FrontSurfaceKind {
    FinderListView,
    ExplorerListView,
    GnomeFilesListView,
    Other,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DocumentOrigin {
    LocalFileSystem,
    RemoteUrl,
    Generated,
    Unknown,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum DocumentKind {
    File,
    Directory,
    Virtual,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum BackgroundMode {
    White,
    Black,
}

impl BackgroundMode {
    pub fn opposite(self) -> Self {
        match self {
            Self::White => Self::Black,
            Self::Black => Self::White,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PageDirection {
    Backward,
    Forward,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PageInput {
    Space,
    ShiftSpace,
    PageUp,
    PageDown,
}

impl PageInput {
    pub fn direction(self) -> PageDirection {
        match self {
            Self::Space | Self::PageDown => PageDirection::Forward,
            Self::ShiftSpace | Self::PageUp => PageDirection::Backward,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum EditingPhase {
    Inactive,
    Active,
    Saving,
}

impl EditingPhase {
    pub fn is_locked(self) -> bool {
        !matches!(self, Self::Inactive)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum CloseReason {
    OutsideClick,
    AppSwitch,
    Escape,
    ForceStop,
    FrontSurfaceLost,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum HostErrorCode {
    PermissionDenied,
    SurfaceUnavailable,
    HoverResolutionFailed,
    DocumentLoadFailed,
    DocumentSaveFailed,
    WindowOperationFailed,
    UnsupportedOperation,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DocumentPath(pub String);

impl DocumentPath {
    pub fn new(path: impl Into<String>) -> Self {
        Self(path.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }

    pub fn file_name(&self) -> Option<&str> {
        Path::new(self.as_str())
            .file_name()
            .and_then(|name| name.to_str())
    }

    pub fn extension(&self) -> Option<&str> {
        Path::new(self.as_str())
            .extension()
            .and_then(|ext| ext.to_str())
    }

    pub fn is_markdown_file(&self) -> bool {
        matches!(self.extension(), Some(ext) if ext.eq_ignore_ascii_case("md"))
    }
}

impl From<&str> for DocumentPath {
    fn from(value: &str) -> Self {
        Self::new(value)
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ScreenPoint {
    pub x: f64,
    pub y: f64,
}

impl ScreenPoint {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ScreenRect {
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl ScreenRect {
    pub fn new(x: f64, y: f64, width: f64, height: f64) -> Self {
        Self {
            x,
            y,
            width,
            height,
        }
    }

    pub fn min_x(&self) -> f64 {
        self.x
    }

    pub fn min_y(&self) -> f64 {
        self.y
    }

    pub fn max_x(&self) -> f64 {
        self.x + self.width
    }

    pub fn max_y(&self) -> f64 {
        self.y + self.height
    }

    pub fn contains(&self, point: &ScreenPoint) -> bool {
        point.x >= self.min_x()
            && point.x <= self.max_x()
            && point.y >= self.min_y()
            && point.y <= self.max_y()
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MonitorMetadata {
    pub id: String,
    pub name: Option<String>,
    pub frame: ScreenRect,
    pub visible_frame: ScreenRect,
    pub scale_factor: f64,
    pub is_primary: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ResolvedDocument {
    pub path: DocumentPath,
    pub display_name: String,
    pub origin: DocumentOrigin,
    pub kind: DocumentKind,
}

impl ResolvedDocument {
    pub fn new(
        path: impl Into<DocumentPath>,
        display_name: impl Into<String>,
        origin: DocumentOrigin,
        kind: DocumentKind,
    ) -> Self {
        Self {
            path: path.into(),
            display_name: display_name.into(),
            origin,
            kind,
        }
    }

    pub fn is_local_markdown_file(&self) -> bool {
        self.origin == DocumentOrigin::LocalFileSystem
            && self.kind == DocumentKind::File
            && self.path.is_markdown_file()
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LoadedDocument {
    pub document: ResolvedDocument,
    pub encoding: String,
    pub markdown: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct FrontSurface {
    pub platform_id: PlatformId,
    pub surface_kind: FrontSurfaceKind,
    pub app_identifier: String,
    pub window_title: Option<String>,
    pub directory: Option<DocumentPath>,
    pub expected_host: bool,
}

impl FrontSurface {
    pub fn is_expected_host(&self) -> bool {
        self.expected_host
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HoveredItem {
    pub document: ResolvedDocument,
    pub screen_point: ScreenPoint,
    pub element_description: String,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HostCapabilities {
    pub supports_front_surface_detection: bool,
    pub supports_hover_resolution: bool,
    pub supports_preview_window: bool,
    pub supports_inline_editing: bool,
    pub supports_multi_monitor_placement: bool,
    pub supports_global_mouse_monitoring: bool,
    pub supports_background_toggle: bool,
    pub supports_paging: bool,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PreviewWindowRequest {
    pub document: ResolvedDocument,
    pub title: String,
    pub anchor: ScreenPoint,
    pub frame: ScreenRect,
    pub selected_width_tier_index: usize,
    pub requested_width_px: u32,
    pub background_mode: BackgroundMode,
    pub interaction_hot: bool,
    pub monitor_id: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct HoverState {
    pub pending: Option<HoveredItem>,
    pub candidate_started_at_ms: Option<u64>,
    pub hover_trigger_ms: u64,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PreviewVisibilityState {
    pub visible: bool,
    pub last_request: Option<PreviewWindowRequest>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PagingMotion {
    pub direction: PageDirection,
    pub page_fraction: f64,
    pub overshoot_factor: f64,
    pub max_overshoot_px: f64,
    pub first_segment_ms: u16,
    pub settle_segment_ms: u16,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PagingState {
    pub last_scroll_delta_y: Option<f64>,
    pub last_motion: Option<PagingMotion>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct EditingState {
    pub phase: EditingPhase,
    pub target_start_line: Option<u32>,
    pub target_end_line: Option<u32>,
    pub draft_markdown: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PreviewState {
    pub current_document: Option<ResolvedDocument>,
    pub hover: HoverState,
    pub visibility: PreviewVisibilityState,
    pub paging: PagingState,
    pub editing: EditingState,
    pub last_close_reason: Option<CloseReason>,
    pub selected_width_tier_index: usize,
    pub background_mode: BackgroundMode,
    pub interaction_hot: bool,
}

impl Default for PreviewState {
    fn default() -> Self {
        Self {
            current_document: None,
            hover: HoverState {
                pending: None,
                candidate_started_at_ms: None,
                hover_trigger_ms: 1_000,
            },
            visibility: PreviewVisibilityState {
                visible: false,
                last_request: None,
            },
            paging: PagingState {
                last_scroll_delta_y: None,
                last_motion: None,
            },
            editing: EditingState {
                phase: EditingPhase::Inactive,
                target_start_line: None,
                target_end_line: None,
                draft_markdown: None,
            },
            last_close_reason: None,
            selected_width_tier_index: 0,
            background_mode: BackgroundMode::White,
            interaction_hot: false,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
pub enum AppCommand {
    ObserveHover {
        at_ms: u64,
        front_surface: FrontSurface,
        hovered_item: Option<HoveredItem>,
        monitor: Option<MonitorMetadata>,
    },
    SetInteractionHot {
        hot: bool,
    },
    AdjustWidthTier {
        delta: i8,
        monitor: Option<MonitorMetadata>,
    },
    ToggleBackgroundMode,
    ScrollPreview {
        raw_delta_y: f64,
        precise: bool,
    },
    PagePreview {
        input: PageInput,
    },
    OutsideClick,
    FrontSurfaceChanged {
        front_surface: FrontSurface,
    },
    Escape,
    RequestEdit {
        target_line: u32,
    },
    SaveEdit {
        replacement_markdown: String,
    },
    CompleteSave {
        success: bool,
        persisted_markdown: Option<String>,
        message: Option<String>,
    },
    CancelEdit,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "kebab-case")]
pub enum AppEvent {
    PreviewWindowRequested {
        request: PreviewWindowRequest,
    },
    PreviewWindowHidden {
        reason: CloseReason,
    },
    WidthTierChanged {
        selected_width_tier_index: usize,
        requested_width_px: u32,
    },
    BackgroundModeChanged {
        background_mode: BackgroundMode,
    },
    ScrollApplied {
        delta_y: f64,
    },
    PageMotionRequested {
        motion: PagingMotion,
    },
    EditSessionChanged {
        editing: EditingState,
    },
    MarkdownSaveRequested {
        document: ResolvedDocument,
        replacement_markdown: String,
    },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HostError {
    pub code: HostErrorCode,
    pub message: String,
    pub platform: PlatformId,
    pub recoverable: bool,
    pub context: BTreeMap<String, String>,
}

impl HostError {
    pub fn new(
        code: HostErrorCode,
        message: impl Into<String>,
        platform: PlatformId,
        recoverable: bool,
    ) -> Self {
        Self {
            code,
            message: message.into(),
            platform,
            recoverable,
            context: BTreeMap::new(),
        }
    }

    pub fn with_context(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.context.insert(key.into(), value.into());
        self
    }
}

impl fmt::Display for HostError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(
            f,
            "{:?} on {:?}: {}",
            self.code, self.platform, self.message
        )
    }
}

impl std::error::Error for HostError {}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_document() -> ResolvedDocument {
        ResolvedDocument::new(
            "/Users/example/Notes/spec.md",
            "spec.md",
            DocumentOrigin::LocalFileSystem,
            DocumentKind::File,
        )
    }

    fn sample_point() -> ScreenPoint {
        ScreenPoint::new(120.0, 340.0)
    }

    fn sample_rect() -> ScreenRect {
        ScreenRect::new(64.0, 96.0, 960.0, 720.0)
    }

    fn sample_monitor() -> MonitorMetadata {
        MonitorMetadata {
            id: "display-main".to_string(),
            name: Some("Studio Display".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 3024.0, 1964.0),
            visible_frame: ScreenRect::new(0.0, 25.0, 3024.0, 1910.0),
            scale_factor: 2.0,
            is_primary: true,
        }
    }

    fn sample_front_surface() -> FrontSurface {
        FrontSurface {
            platform_id: PlatformId::MacosFinder,
            surface_kind: FrontSurfaceKind::FinderListView,
            app_identifier: "com.apple.finder".to_string(),
            window_title: Some("Specs".to_string()),
            directory: Some(DocumentPath::from("/Users/example/Notes")),
            expected_host: true,
        }
    }

    fn sample_hovered_item() -> HoveredItem {
        HoveredItem {
            document: sample_document(),
            screen_point: sample_point(),
            element_description: "Finder row subtree direct path".to_string(),
        }
    }

    fn sample_preview_request() -> PreviewWindowRequest {
        PreviewWindowRequest {
            document: sample_document(),
            title: "spec.md".to_string(),
            anchor: sample_point(),
            frame: sample_rect(),
            selected_width_tier_index: 1,
            requested_width_px: 960,
            background_mode: BackgroundMode::White,
            interaction_hot: true,
            monitor_id: Some("display-main".to_string()),
        }
    }

    fn sample_editing_state() -> EditingState {
        EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(4),
            target_end_line: Some(9),
            draft_markdown: Some("updated".to_string()),
        }
    }

    fn assert_roundtrip<T>(value: &T)
    where
        T: Serialize + for<'de> Deserialize<'de> + PartialEq + fmt::Debug,
    {
        let encoded = serde_json::to_string(value).expect("serialize");
        let decoded: T = serde_json::from_str(&encoded).expect("deserialize");
        assert_eq!(*value, decoded);
    }

    #[test]
    fn document_paths_match_macos_markdown_acceptance() {
        let markdown = DocumentPath::from("/tmp/notes.md");
        let upper_case = DocumentPath::from("/tmp/NOTES.MD");
        let other = DocumentPath::from("/tmp/notes.txt");

        assert!(markdown.is_markdown_file());
        assert!(upper_case.is_markdown_file());
        assert!(!other.is_markdown_file());
        assert_eq!(markdown.file_name(), Some("notes.md"));
    }

    #[test]
    fn resolved_document_rejects_non_local_markdown_contracts() {
        let remote = ResolvedDocument::new(
            "https://example.com/spec.md",
            "spec.md",
            DocumentOrigin::RemoteUrl,
            DocumentKind::File,
        );
        let directory = ResolvedDocument::new(
            "/Users/example/spec.md",
            "spec.md",
            DocumentOrigin::LocalFileSystem,
            DocumentKind::Directory,
        );

        assert!(sample_document().is_local_markdown_file());
        assert!(!remote.is_local_markdown_file());
        assert!(!directory.is_local_markdown_file());
    }

    #[test]
    fn page_inputs_match_macos_direction_contract() {
        assert_eq!(PageInput::Space.direction(), PageDirection::Forward);
        assert_eq!(PageInput::PageDown.direction(), PageDirection::Forward);
        assert_eq!(PageInput::ShiftSpace.direction(), PageDirection::Backward);
        assert_eq!(PageInput::PageUp.direction(), PageDirection::Backward);
    }

    #[test]
    fn shared_contracts_round_trip_over_serde() {
        let hover = HoverState {
            pending: Some(sample_hovered_item()),
            candidate_started_at_ms: Some(1_000),
            hover_trigger_ms: 1_000,
        };
        let paging = PagingState {
            last_scroll_delta_y: Some(84.0),
            last_motion: Some(PagingMotion {
                direction: PageDirection::Forward,
                page_fraction: 0.92,
                overshoot_factor: 0.06,
                max_overshoot_px: 34.0,
                first_segment_ms: 520,
                settle_segment_ms: 180,
            }),
        };
        let preview_state = PreviewState {
            current_document: Some(sample_document()),
            hover,
            visibility: PreviewVisibilityState {
                visible: true,
                last_request: Some(sample_preview_request()),
            },
            paging,
            editing: sample_editing_state(),
            last_close_reason: Some(CloseReason::OutsideClick),
            selected_width_tier_index: 1,
            background_mode: BackgroundMode::Black,
            interaction_hot: true,
        };
        let command = AppCommand::ObserveHover {
            at_ms: 1_500,
            front_surface: sample_front_surface(),
            hovered_item: Some(sample_hovered_item()),
            monitor: Some(sample_monitor()),
        };
        let event = AppEvent::PreviewWindowRequested {
            request: sample_preview_request(),
        };
        let error = HostError::new(
            HostErrorCode::HoverResolutionFailed,
            "AX hit-test failed",
            PlatformId::MacosFinder,
            true,
        )
        .with_context("point", "120,340");

        assert_roundtrip(&sample_front_surface());
        assert_roundtrip(&sample_point());
        assert_roundtrip(&sample_rect());
        assert_roundtrip(&sample_monitor());
        assert_roundtrip(&sample_document());
        assert_roundtrip(&LoadedDocument {
            document: sample_document(),
            encoding: "utf-8".to_string(),
            markdown: "# Title".to_string(),
        });
        assert_roundtrip(&sample_hovered_item());
        assert_roundtrip(&HostCapabilities {
            supports_front_surface_detection: true,
            supports_hover_resolution: true,
            supports_preview_window: true,
            supports_inline_editing: true,
            supports_multi_monitor_placement: true,
            supports_global_mouse_monitoring: true,
            supports_background_toggle: true,
            supports_paging: true,
        });
        assert_roundtrip(&sample_preview_request());
        assert_roundtrip(&preview_state);
        assert_roundtrip(&command);
        assert_roundtrip(&event);
        assert_roundtrip(&error);
    }

    #[test]
    fn screen_rect_contains_points() {
        let rect = ScreenRect::new(0.0, 0.0, 100.0, 60.0);

        assert!(rect.contains(&ScreenPoint::new(0.0, 0.0)));
        assert!(rect.contains(&ScreenPoint::new(100.0, 60.0)));
        assert!(!rect.contains(&ScreenPoint::new(101.0, 12.0)));
    }
}
