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
pub enum HoverResolutionScope {
    ExactItemUnderPointer,
    HoveredRowDescendant,
    NearbyCandidate,
    FirstVisibleItem,
}

impl HoverResolutionScope {
    pub fn supports_macos_parity(self) -> bool {
        matches!(
            self,
            Self::ExactItemUnderPointer | Self::HoveredRowDescendant
        )
    }
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

    pub fn is_absolute(&self) -> bool {
        Path::new(self.as_str()).is_absolute()
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

    pub fn distance_squared_to_point(&self, point: &ScreenPoint) -> f64 {
        let dx = if point.x < self.min_x() {
            self.min_x() - point.x
        } else if point.x > self.max_x() {
            point.x - self.max_x()
        } else {
            0.0
        };
        let dy = if point.y < self.min_y() {
            self.min_y() - point.y
        } else if point.y > self.max_y() {
            point.y - self.max_y()
        } else {
            0.0
        };

        dx * dx + dy * dy
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum CoordinateSpaceReference {
    DesktopSpace,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlacementBoundsReference {
    VisibleFrame,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackgroundToggleKey {
    Tab,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EditEntryReference {
    DoubleClickSmallestMatchingBlock,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FrontmostFileManagerReference {
    pub app_identifier: &'static str,
    pub surface_kind: FrontSurfaceKind,
    pub requires_strict_match: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HoverResolutionReference {
    pub surface_kind: FrontSurfaceKind,
    pub requires_actual_hovered_item: bool,
    pub supports_hovered_row_descendant: bool,
    pub rejects_nearby_candidates: bool,
    pub rejects_first_visible_fallbacks: bool,
    pub direct_path_attribute_names: [&'static str; 4],
    pub filename_fallback_uses_front_directory: bool,
    pub requires_absolute_path: bool,
    pub requires_existing_local_markdown_file: bool,
    pub requires_regular_file: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MultiMonitorReference {
    pub coordinate_space: CoordinateSpaceReference,
    pub placement_bounds: PlacementBoundsReference,
    pub prefer_containing_monitor: bool,
    pub fallback_to_nearest_monitor: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct PreviewGeometryReference {
    pub hover_trigger_ms: u64,
    pub width_tiers_px: [u32; 4],
    pub aspect_ratio: (u8, u8),
    pub edge_inset_px: u16,
    pub pointer_offset_px: u16,
    pub min_available_width_px: u16,
    pub min_available_height_px: u16,
    pub reposition_before_shrink: bool,
}

impl PreviewGeometryReference {
    pub fn aspect_ratio_value(self) -> f64 {
        self.aspect_ratio.0 as f64 / self.aspect_ratio.1 as f64
    }

    pub fn clamped_width_tier_index(self, index: isize) -> usize {
        let max_index = self.width_tiers_px.len().saturating_sub(1) as isize;
        index.clamp(0, max_index) as usize
    }

    pub fn width_px_for_index(self, index: usize) -> u32 {
        self.width_tiers_px[self.clamped_width_tier_index(index as isize)]
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InteractionReference {
    pub requires_frontmost_file_manager: bool,
    pub replaces_different_hovered_markdown: bool,
    pub suppresses_stationary_reopen: bool,
    pub preview_becomes_hot_on_open: bool,
    pub keeps_hot_surface_while_visible: bool,
    pub supports_scroll_wheel_and_touchpad: bool,
    pub supports_space_and_page_keys: bool,
    pub supports_background_toggle: bool,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct BackgroundToggleReference {
    pub trigger_key: BackgroundToggleKey,
    pub modes: [BackgroundMode; 2],
    pub requires_hot_surface: bool,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct PagingReference {
    pub requires_hot_surface: bool,
    pub scroll_inverts_delta_y: bool,
    pub precise_scroll_multiplier: f64,
    pub non_precise_scroll_multiplier: f64,
    pub page_inputs: [PageInput; 4],
    pub page_fraction: f64,
    pub overshoot_factor: f64,
    pub max_overshoot_px: f64,
    pub first_segment_ms: u16,
    pub settle_segment_ms: u16,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct EditModeReference {
    pub entry: EditEntryReference,
    pub locks_preview_replacement_until_save_or_cancel: bool,
    pub locks_preview_dismissal_until_save_or_cancel: bool,
    pub save_writes_back_to_source: bool,
    pub cancel_preserves_source: bool,
}

impl EditModeReference {
    pub fn blocks_preview_replacement(self) -> bool {
        self.locks_preview_replacement_until_save_or_cancel
    }

    pub fn blocks_preview_dismissal(self) -> bool {
        self.locks_preview_dismissal_until_save_or_cancel
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ClosePolicyReference {
    pub outside_click_closes_when_not_editing: bool,
    pub app_switch_closes_when_not_editing: bool,
    pub escape_closes_when_not_editing: bool,
    pub editing_blocks_non_forced_close: bool,
}

impl ClosePolicyReference {
    pub fn allows_non_forced_close(self, reason: CloseReason) -> bool {
        match reason {
            CloseReason::OutsideClick => self.outside_click_closes_when_not_editing,
            CloseReason::AppSwitch => self.app_switch_closes_when_not_editing,
            CloseReason::Escape => self.escape_closes_when_not_editing,
            CloseReason::ForceStop | CloseReason::FrontSurfaceLost => false,
        }
    }

    pub fn allows_non_forced_close_while_editing(self, reason: CloseReason) -> bool {
        if self.editing_blocks_non_forced_close {
            false
        } else {
            self.allows_non_forced_close(reason)
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HintChipReference {
    pub collapsed_into_single_chip: bool,
    pub width_label_template: &'static str,
    pub background_label: &'static str,
    pub paging_label: &'static str,
    pub background_icon: &'static str,
    pub paging_icon: &'static str,
}

impl HintChipReference {
    pub fn width_label(self, selected_width_tier_index: usize, total_tiers: usize) -> String {
        self.width_label_template
            .replace("{current}", &(selected_width_tier_index + 1).to_string())
            .replace("{total}", &total_tiers.to_string())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MathDelimiterReference {
    pub left: &'static str,
    pub right: &'static str,
    pub display: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingRuntimeReference {
    pub html_enabled: bool,
    pub linkify: bool,
    pub typographer: bool,
    pub syntax_highlight_uses_highlight_js: bool,
    pub syntax_highlight_falls_back_to_auto_detect: bool,
    pub supports_footnotes: bool,
    pub supports_task_lists: bool,
    pub task_list_wraps_label: bool,
    pub task_list_wraps_label_after_checkbox: bool,
    pub supports_mermaid: bool,
    pub mermaid_fence_info_string: &'static str,
    pub mermaid_security_level: &'static str,
    pub supports_math: bool,
    pub math_delimiters: [MathDelimiterReference; 4],
    pub html_blocks_passthrough: bool,
    pub wraps_top_level_blocks_with_source_mapping: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingTypographyReference {
    pub ui_font_family: &'static str,
    pub body_font_family: &'static str,
    pub code_font_family: &'static str,
    pub base_font_size_px: u16,
    pub heading_sizes_px: [u16; 6],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingThemeReference {
    pub white_page_bg: &'static str,
    pub black_page_bg: &'static str,
    pub white_text: &'static str,
    pub black_text: &'static str,
    pub white_code_bg: &'static str,
    pub black_code_bg: &'static str,
    pub white_editor_bg: &'static str,
    pub black_editor_bg: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingChromeReference {
    pub toolbar_eyebrow: &'static str,
    pub width_tooltip_template: &'static str,
    pub width_aria_label_template: &'static str,
    pub edit_locked_status_text: &'static str,
    pub saving_status_text: &'static str,
    pub save_failed_fallback_text: &'static str,
    pub inline_editor_source_line_template: &'static str,
    pub inline_editor_return_text: &'static str,
    pub save_label: &'static str,
    pub cancel_label: &'static str,
}

impl RenderingChromeReference {
    pub fn width_tooltip(
        self,
        selected_width_tier_index: usize,
        total_tiers: usize,
        width_px: u32,
    ) -> String {
        self.width_tooltip_template
            .replace("{current}", &(selected_width_tier_index + 1).to_string())
            .replace("{total}", &total_tiers.to_string())
            .replace("{width}", &width_px.to_string())
    }

    pub fn width_aria_label(
        self,
        selected_width_tier_index: usize,
        total_tiers: usize,
        width_px: u32,
    ) -> String {
        self.width_aria_label_template
            .replace("{current}", &(selected_width_tier_index + 1).to_string())
            .replace("{total}", &total_tiers.to_string())
            .replace("{width}", &width_px.to_string())
    }

    pub fn inline_editor_source_line_label(self, start_line: u32, end_line: u32) -> String {
        self.inline_editor_source_line_template
            .replace("{start}", &(start_line + 1).to_string())
            .replace("{end}", &end_line.to_string())
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingLayoutReference {
    pub render_root_padding_px: u16,
    pub toolbar_padding_top_px: u16,
    pub toolbar_padding_horizontal_px: u16,
    pub toolbar_padding_bottom_px: u16,
    pub inline_editor_width_percent: u8,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingReference {
    pub runtime: RenderingRuntimeReference,
    pub typography: RenderingTypographyReference,
    pub theme: RenderingThemeReference,
    pub chrome: RenderingChromeReference,
    pub layout: RenderingLayoutReference,
}

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct MacOsReferenceBehavior {
    pub reference_surface: &'static str,
    pub frontmost_file_manager: FrontmostFileManagerReference,
    pub hover_resolution: HoverResolutionReference,
    pub multi_monitor: MultiMonitorReference,
    pub preview_geometry: PreviewGeometryReference,
    pub background_modes: [BackgroundMode; 2],
    pub interaction: InteractionReference,
    pub background_toggle: BackgroundToggleReference,
    pub paging: PagingReference,
    pub edit_mode: EditModeReference,
    pub close_policy: ClosePolicyReference,
    pub hint_chip: HintChipReference,
    pub rendering: RenderingReference,
}

pub static MACOS_REFERENCE_BEHAVIOR: MacOsReferenceBehavior = MacOsReferenceBehavior {
    reference_surface: "apps/macos",
    frontmost_file_manager: FrontmostFileManagerReference {
        app_identifier: "com.apple.finder",
        surface_kind: FrontSurfaceKind::FinderListView,
        requires_strict_match: true,
    },
    hover_resolution: HoverResolutionReference {
        surface_kind: FrontSurfaceKind::FinderListView,
        requires_actual_hovered_item: true,
        supports_hovered_row_descendant: true,
        rejects_nearby_candidates: true,
        rejects_first_visible_fallbacks: true,
        direct_path_attribute_names: ["AXFilename", "AXPath", "AXDocument", "AXURL"],
        filename_fallback_uses_front_directory: true,
        requires_absolute_path: true,
        requires_existing_local_markdown_file: true,
        requires_regular_file: true,
    },
    multi_monitor: MultiMonitorReference {
        coordinate_space: CoordinateSpaceReference::DesktopSpace,
        placement_bounds: PlacementBoundsReference::VisibleFrame,
        prefer_containing_monitor: true,
        fallback_to_nearest_monitor: true,
    },
    preview_geometry: PreviewGeometryReference {
        hover_trigger_ms: 1_000,
        width_tiers_px: [560, 960, 1_440, 1_920],
        aspect_ratio: (4, 3),
        edge_inset_px: 12,
        pointer_offset_px: 18,
        min_available_width_px: 320,
        min_available_height_px: 240,
        reposition_before_shrink: true,
    },
    background_modes: [BackgroundMode::White, BackgroundMode::Black],
    interaction: InteractionReference {
        requires_frontmost_file_manager: true,
        replaces_different_hovered_markdown: true,
        suppresses_stationary_reopen: true,
        preview_becomes_hot_on_open: true,
        keeps_hot_surface_while_visible: true,
        supports_scroll_wheel_and_touchpad: true,
        supports_space_and_page_keys: true,
        supports_background_toggle: true,
    },
    background_toggle: BackgroundToggleReference {
        trigger_key: BackgroundToggleKey::Tab,
        modes: [BackgroundMode::White, BackgroundMode::Black],
        requires_hot_surface: true,
    },
    paging: PagingReference {
        requires_hot_surface: true,
        scroll_inverts_delta_y: true,
        precise_scroll_multiplier: 1.0,
        non_precise_scroll_multiplier: 10.0,
        page_inputs: [
            PageInput::Space,
            PageInput::ShiftSpace,
            PageInput::PageUp,
            PageInput::PageDown,
        ],
        page_fraction: 0.92,
        overshoot_factor: 0.06,
        max_overshoot_px: 34.0,
        first_segment_ms: 520,
        settle_segment_ms: 180,
    },
    edit_mode: EditModeReference {
        entry: EditEntryReference::DoubleClickSmallestMatchingBlock,
        locks_preview_replacement_until_save_or_cancel: true,
        locks_preview_dismissal_until_save_or_cancel: true,
        save_writes_back_to_source: true,
        cancel_preserves_source: true,
    },
    close_policy: ClosePolicyReference {
        outside_click_closes_when_not_editing: true,
        app_switch_closes_when_not_editing: true,
        escape_closes_when_not_editing: true,
        editing_blocks_non_forced_close: true,
    },
    hint_chip: HintChipReference {
        collapsed_into_single_chip: true,
        width_label_template: "← {current}/{total} →",
        background_label: "Tab",
        paging_label: "(⇧+) Space",
        background_icon: "◐",
        paging_icon: "⇵",
    },
    rendering: RenderingReference {
        runtime: RenderingRuntimeReference {
            html_enabled: true,
            linkify: true,
            typographer: true,
            syntax_highlight_uses_highlight_js: true,
            syntax_highlight_falls_back_to_auto_detect: true,
            supports_footnotes: true,
            supports_task_lists: true,
            task_list_wraps_label: true,
            task_list_wraps_label_after_checkbox: true,
            supports_mermaid: true,
            mermaid_fence_info_string: "mermaid",
            mermaid_security_level: "loose",
            supports_math: true,
            math_delimiters: [
                MathDelimiterReference {
                    left: "$$",
                    right: "$$",
                    display: true,
                },
                MathDelimiterReference {
                    left: "\\[",
                    right: "\\]",
                    display: true,
                },
                MathDelimiterReference {
                    left: "$",
                    right: "$",
                    display: false,
                },
                MathDelimiterReference {
                    left: "\\(",
                    right: "\\)",
                    display: false,
                },
            ],
            html_blocks_passthrough: true,
            wraps_top_level_blocks_with_source_mapping: true,
        },
        typography: RenderingTypographyReference {
            ui_font_family: "\"SF Pro Text\", \"Helvetica Neue\", system-ui, sans-serif",
            body_font_family: "\"Charter\", \"Iowan Old Style\", Georgia, serif",
            code_font_family: "\"SF Mono\", \"Menlo\", \"Monaco\", monospace",
            base_font_size_px: 14,
            heading_sizes_px: [25, 21, 18, 16, 15, 12],
        },
        theme: RenderingThemeReference {
            white_page_bg: "#ffffff",
            black_page_bg: "#000000",
            white_text: "#111111",
            black_text: "#f5f5f5",
            white_code_bg: "#f5f7fb",
            black_code_bg: "#0f0f10",
            white_editor_bg: "#fffdf8",
            black_editor_bg: "#121212",
        },
        chrome: RenderingChromeReference {
            toolbar_eyebrow: "FastMD Preview",
            width_tooltip_template: "{current}/{total} · {width}px",
            width_aria_label_template: "宽度档位 {current}/{total}，目标宽度 {width}px",
            edit_locked_status_text: "Edit mode is locked until you save or cancel.",
            saving_status_text: "Saving Markdown block back to disk…",
            save_failed_fallback_text: "Save failed.",
            inline_editor_source_line_template: "Editing source lines {start}-{end}",
            inline_editor_return_text: "Double-clicked block returns to raw Markdown.",
            save_label: "Save",
            cancel_label: "Cancel",
        },
        layout: RenderingLayoutReference {
            render_root_padding_px: 18,
            toolbar_padding_top_px: 14,
            toolbar_padding_horizontal_px: 18,
            toolbar_padding_bottom_px: 12,
            inline_editor_width_percent: 60,
        },
    },
};

pub static WINDOWS_EXPLORER_FRONTMOST_REFERENCE: FrontmostFileManagerReference =
    FrontmostFileManagerReference {
        app_identifier: "explorer.exe",
        surface_kind: FrontSurfaceKind::ExplorerListView,
        requires_strict_match: true,
    };

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MonitorMetadata {
    pub id: String,
    pub name: Option<String>,
    pub frame: ScreenRect,
    pub visible_frame: ScreenRect,
    pub scale_factor: f64,
    pub is_primary: bool,
}

impl MonitorMetadata {
    pub fn contains_point_in_visible_frame(&self, point: &ScreenPoint) -> bool {
        self.visible_frame.contains(point)
    }

    pub fn distance_squared_to_visible_frame(&self, point: &ScreenPoint) -> f64 {
        self.visible_frame.distance_squared_to_point(point)
    }
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
            && self.path.is_absolute()
            && self.path.is_markdown_file()
    }
}

impl HoverResolutionReference {
    pub fn accepts_scope(self, scope: HoverResolutionScope) -> bool {
        match scope {
            HoverResolutionScope::ExactItemUnderPointer => true,
            HoverResolutionScope::HoveredRowDescendant => self.supports_hovered_row_descendant,
            HoverResolutionScope::NearbyCandidate => !self.rejects_nearby_candidates,
            HoverResolutionScope::FirstVisibleItem => !self.rejects_first_visible_fallbacks,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct LoadedDocument {
    pub document: ResolvedDocument,
    pub encoding: String,
    pub markdown: String,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FrontSurfaceIdentity {
    pub native_window_id: String,
    pub owner_process_id: Option<u32>,
}

impl FrontSurfaceIdentity {
    pub fn new(native_window_id: impl Into<String>) -> Self {
        Self {
            native_window_id: native_window_id.into(),
            owner_process_id: None,
        }
    }

    pub fn with_process_id(mut self, owner_process_id: u32) -> Self {
        self.owner_process_id = Some(owner_process_id);
        self
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FrontSurface {
    pub platform_id: PlatformId,
    pub surface_kind: FrontSurfaceKind,
    pub app_identifier: String,
    pub window_title: Option<String>,
    pub directory: Option<DocumentPath>,
    pub stable_identity: Option<FrontSurfaceIdentity>,
    pub expected_host: bool,
}

impl FrontSurface {
    pub fn is_expected_host(&self) -> bool {
        self.expected_host
    }

    pub fn stable_identity(&self) -> Option<&FrontSurfaceIdentity> {
        self.stable_identity.as_ref()
    }

    pub fn has_stable_identity(&self) -> bool {
        self.stable_identity.is_some()
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
            stable_identity: Some(
                FrontSurfaceIdentity::new("finder-window-1").with_process_id(7_001),
            ),
            expected_host: true,
        }
    }

    fn sample_windows_front_surface(expected_host: bool) -> FrontSurface {
        FrontSurface {
            platform_id: PlatformId::WindowsExplorer,
            surface_kind: FrontSurfaceKind::ExplorerListView,
            app_identifier: "explorer.exe".to_string(),
            window_title: Some("Docs".to_string()),
            directory: Some(DocumentPath::from(r"C:\Users\example\Docs")),
            stable_identity: if expected_host {
                Some(FrontSurfaceIdentity::new("hwnd:0x10001").with_process_id(4_012))
            } else {
                None
            },
            expected_host,
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
        let relative = DocumentPath::from("notes.md");

        assert!(markdown.is_markdown_file());
        assert!(upper_case.is_markdown_file());
        assert!(!other.is_markdown_file());
        assert!(markdown.is_absolute());
        assert!(!relative.is_absolute());
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
        let relative = ResolvedDocument::new(
            "spec.md",
            "spec.md",
            DocumentOrigin::LocalFileSystem,
            DocumentKind::File,
        );

        assert!(sample_document().is_local_markdown_file());
        assert!(!remote.is_local_markdown_file());
        assert!(!directory.is_local_markdown_file());
        assert!(!relative.is_local_markdown_file());
    }

    #[test]
    fn page_inputs_match_macos_direction_contract() {
        assert_eq!(PageInput::Space.direction(), PageDirection::Forward);
        assert_eq!(PageInput::PageDown.direction(), PageDirection::Forward);
        assert_eq!(PageInput::ShiftSpace.direction(), PageDirection::Backward);
        assert_eq!(PageInput::PageUp.direction(), PageDirection::Backward);
    }

    #[test]
    fn macos_reference_behavior_tracks_layer5_contract_rules() {
        let reference = MACOS_REFERENCE_BEHAVIOR;

        assert_eq!(reference.reference_surface, "apps/macos");
        assert_eq!(
            reference.frontmost_file_manager.app_identifier,
            "com.apple.finder"
        );
        assert_eq!(
            reference.frontmost_file_manager.surface_kind,
            FrontSurfaceKind::FinderListView
        );
        assert!(reference.hover_resolution.requires_actual_hovered_item);
        assert!(reference.hover_resolution.supports_hovered_row_descendant);
        assert!(reference.hover_resolution.rejects_nearby_candidates);
        assert!(reference.hover_resolution.rejects_first_visible_fallbacks);
        assert_eq!(
            reference.hover_resolution.direct_path_attribute_names,
            ["AXFilename", "AXPath", "AXDocument", "AXURL"]
        );
        assert!(reference.hover_resolution.requires_absolute_path);
        assert!(reference.hover_resolution.requires_regular_file);
        assert_eq!(
            reference.multi_monitor.coordinate_space,
            CoordinateSpaceReference::DesktopSpace
        );
        assert_eq!(
            reference.multi_monitor.placement_bounds,
            PlacementBoundsReference::VisibleFrame
        );
        assert_eq!(
            reference.preview_geometry.width_tiers_px,
            [560, 960, 1_440, 1_920]
        );
        assert_eq!(reference.preview_geometry.aspect_ratio, (4, 3));
        assert!(reference.preview_geometry.reposition_before_shrink);
        assert!(reference.interaction.keeps_hot_surface_while_visible);
        assert_eq!(
            reference.background_toggle.trigger_key,
            BackgroundToggleKey::Tab
        );
        assert_eq!(
            reference.background_toggle.modes,
            [BackgroundMode::White, BackgroundMode::Black]
        );
        assert_eq!(reference.paging.page_inputs[0], PageInput::Space);
        assert_eq!(reference.paging.page_inputs[1], PageInput::ShiftSpace);
        assert_eq!(
            reference.edit_mode.entry,
            EditEntryReference::DoubleClickSmallestMatchingBlock
        );
        assert!(reference.edit_mode.blocks_preview_replacement());
        assert!(reference.edit_mode.blocks_preview_dismissal());
        assert!(reference
            .close_policy
            .allows_non_forced_close(CloseReason::OutsideClick));
        assert!(reference
            .close_policy
            .allows_non_forced_close(CloseReason::AppSwitch));
        assert!(reference
            .close_policy
            .allows_non_forced_close(CloseReason::Escape));
        assert!(!reference
            .close_policy
            .allows_non_forced_close_while_editing(CloseReason::OutsideClick));
        assert!(!reference
            .close_policy
            .allows_non_forced_close_while_editing(CloseReason::AppSwitch));
        assert!(!reference
            .close_policy
            .allows_non_forced_close_while_editing(CloseReason::Escape));
        assert!(reference.hint_chip.collapsed_into_single_chip);
        assert_eq!(reference.hint_chip.background_label, "Tab");
        assert_eq!(reference.hint_chip.paging_label, "(⇧+) Space");
        assert_eq!(reference.hint_chip.width_label(1, 4), "← 2/4 →");
    }

    #[test]
    fn hover_resolution_scope_contract_rejects_nearby_fallbacks() {
        let reference = MACOS_REFERENCE_BEHAVIOR.hover_resolution;

        assert!(reference.accepts_scope(HoverResolutionScope::ExactItemUnderPointer));
        assert!(reference.accepts_scope(HoverResolutionScope::HoveredRowDescendant));
        assert!(!reference.accepts_scope(HoverResolutionScope::NearbyCandidate));
        assert!(!reference.accepts_scope(HoverResolutionScope::FirstVisibleItem));
        assert!(HoverResolutionScope::ExactItemUnderPointer.supports_macos_parity());
        assert!(HoverResolutionScope::HoveredRowDescendant.supports_macos_parity());
        assert!(!HoverResolutionScope::NearbyCandidate.supports_macos_parity());
        assert!(!HoverResolutionScope::FirstVisibleItem.supports_macos_parity());
    }

    #[test]
    fn front_surface_identity_roundtrips_and_reports_presence() {
        let surface = sample_front_surface();

        assert!(surface.has_stable_identity());
        assert_eq!(
            surface
                .stable_identity()
                .expect("stable identity should be present")
                .native_window_id,
            "finder-window-1"
        );
        assert_roundtrip(&surface);
    }

    #[test]
    fn windows_frontmost_reference_requires_a_strict_explorer_match() {
        assert_eq!(
            WINDOWS_EXPLORER_FRONTMOST_REFERENCE.app_identifier,
            "explorer.exe"
        );
        assert_eq!(
            WINDOWS_EXPLORER_FRONTMOST_REFERENCE.surface_kind,
            FrontSurfaceKind::ExplorerListView
        );
        assert!(WINDOWS_EXPLORER_FRONTMOST_REFERENCE.requires_strict_match);
    }

    #[test]
    fn windows_front_surface_roundtrips_through_shared_contracts() {
        let surface = sample_windows_front_surface(true);

        assert!(surface.is_expected_host());
        assert!(surface.has_stable_identity());
        assert_eq!(
            surface
                .stable_identity()
                .expect("stable identity should be present")
                .native_window_id,
            "hwnd:0x10001"
        );
        assert_roundtrip(&surface);

        let rejected = sample_windows_front_surface(false);
        assert!(!rejected.is_expected_host());
        assert!(!rejected.has_stable_identity());
        assert_roundtrip(&rejected);
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
        assert_roundtrip(&sample_windows_front_surface(true));
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

    #[test]
    fn screen_rect_distance_squared_uses_the_nearest_edge() {
        let rect = ScreenRect::new(10.0, 20.0, 100.0, 60.0);

        assert_eq!(
            rect.distance_squared_to_point(&ScreenPoint::new(40.0, 40.0)),
            0.0
        );
        assert_eq!(
            rect.distance_squared_to_point(&ScreenPoint::new(4.0, 40.0)),
            36.0
        );
        assert_eq!(
            rect.distance_squared_to_point(&ScreenPoint::new(130.0, 100.0)),
            800.0
        );
    }

    #[test]
    fn monitor_metadata_uses_visible_frame_for_work_area_semantics() {
        let monitor = MonitorMetadata {
            id: "display-main".to_string(),
            name: Some("Studio Display".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 3024.0, 1964.0),
            visible_frame: ScreenRect::new(0.0, 25.0, 3024.0, 1910.0),
            scale_factor: 2.0,
            is_primary: true,
        };

        assert!(monitor.contains_point_in_visible_frame(&ScreenPoint::new(120.0, 120.0)));
        assert!(!monitor.contains_point_in_visible_frame(&ScreenPoint::new(120.0, 10.0)));
        assert_eq!(
            monitor.distance_squared_to_visible_frame(&ScreenPoint::new(120.0, 10.0)),
            225.0
        );
    }
}
