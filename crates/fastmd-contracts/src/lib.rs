use std::collections::{BTreeMap, BTreeSet};
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

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ValidationCaptureProvenance {
    RealHostSession,
    ValidationFixture,
    Synthetic,
}

impl ValidationCaptureProvenance {
    pub fn label(self) -> &'static str {
        match self {
            Self::RealHostSession => "real-host-session",
            Self::ValidationFixture => "validation-fixture",
            Self::Synthetic => "synthetic",
        }
    }

    pub fn satisfies_real_machine_evidence(self) -> bool {
        matches!(self, Self::RealHostSession)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ValidationHostEnvironment {
    pub platform_id: PlatformId,
    pub operating_system: String,
    pub operating_system_version: Option<String>,
    pub operating_system_build: Option<String>,
    pub file_manager: Option<String>,
    pub host_name: Option<String>,
    pub architecture: Option<String>,
    pub captured_at_utc: Option<String>,
}

impl ValidationHostEnvironment {
    pub fn operating_system_label(&self) -> String {
        let mut label = self.operating_system.clone();

        if let Some(version) = self
            .operating_system_version
            .as_deref()
            .filter(|value| !value.trim().is_empty())
        {
            label.push(' ');
            label.push_str(version);
        }

        if let Some(build) = self
            .operating_system_build
            .as_deref()
            .filter(|value| !value.trim().is_empty())
        {
            label.push_str(" (build ");
            label.push_str(build);
            label.push(')');
        }

        label
    }

    pub fn target_label(&self) -> String {
        match self
            .file_manager
            .as_deref()
            .filter(|value| !value.trim().is_empty())
        {
            Some(file_manager) => format!("{} + {}", self.operating_system_label(), file_manager),
            None => self.operating_system_label(),
        }
    }

    pub fn operating_system_matches(&self, expected_substring: &str) -> bool {
        let expected = expected_substring.trim();
        !expected.is_empty()
            && self
                .operating_system_label()
                .to_ascii_lowercase()
                .contains(&expected.to_ascii_lowercase())
    }

    pub fn file_manager_matches(&self, expected: &str) -> bool {
        let expected = expected.trim();
        !expected.is_empty()
            && self
                .file_manager
                .as_deref()
                .map(str::trim)
                .is_some_and(|value| value.eq_ignore_ascii_case(expected))
    }

    pub fn matches_target(
        &self,
        platform_id: PlatformId,
        operating_system_substring: &str,
        file_manager: Option<&str>,
    ) -> bool {
        self.platform_id == platform_id
            && self.operating_system_matches(operating_system_substring)
            && file_manager
                .map(|expected| self.file_manager_matches(expected))
                .unwrap_or(true)
    }
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

impl From<String> for DocumentPath {
    fn from(value: String) -> Self {
        Self::new(value)
    }
}

impl From<DocumentPath> for String {
    fn from(value: DocumentPath) -> Self {
        value.0
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

    pub fn has_positive_area(&self) -> bool {
        self.width > 0.0 && self.height > 0.0
    }

    pub fn contains(&self, point: &ScreenPoint) -> bool {
        point.x >= self.min_x()
            && point.x <= self.max_x()
            && point.y >= self.min_y()
            && point.y <= self.max_y()
    }

    pub fn contains_rect(&self, other: &ScreenRect) -> bool {
        other.min_x() >= self.min_x()
            && other.max_x() <= self.max_x()
            && other.min_y() >= self.min_y()
            && other.max_y() <= self.max_y()
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

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct HintChipContract {
    pub width_label: String,
    pub background_label: String,
    pub paging_label: String,
    pub background_icon: String,
    pub paging_icon: String,
}

impl HintChipReference {
    pub fn width_label(self, selected_width_tier_index: usize, total_tiers: usize) -> String {
        self.width_label_template
            .replace("{current}", &(selected_width_tier_index + 1).to_string())
            .replace("{total}", &total_tiers.to_string())
    }

    pub fn contract(
        self,
        selected_width_tier_index: usize,
        total_tiers: usize,
    ) -> HintChipContract {
        HintChipContract {
            width_label: self.width_label(selected_width_tier_index, total_tiers),
            background_label: self.background_label.to_string(),
            paging_label: self.paging_label.to_string(),
            background_icon: self.background_icon.to_string(),
            paging_icon: self.paging_icon.to_string(),
        }
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
pub struct HintChipVisualReference {
    pub chip_gap_css: &'static str,
    pub chip_padding_css: &'static str,
    pub chip_border_radius_css: &'static str,
    pub chip_border_css: &'static str,
    pub chip_background_css: &'static str,
    pub desktop_justify_content_css: &'static str,
    pub mobile_justify_content_css: &'static str,
    pub item_gap_css: &'static str,
    pub item_font_size_css: &'static str,
    pub width_font_weight: u16,
    pub width_letter_spacing_css: &'static str,
    pub width_font_variant_numeric_css: &'static str,
    pub icon_size_px: u8,
    pub icon_border_css: &'static str,
    pub icon_font_size_css: &'static str,
    pub separator_size_px: u8,
    pub separator_background_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HeadingRenderingReference {
    pub margin_css: &'static str,
    pub line_height_css: &'static str,
    pub letter_spacing_css: &'static str,
    pub h6_text_transform: &'static str,
    pub h6_letter_spacing_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ParagraphRenderingReference {
    pub margin_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct BlockquoteRenderingReference {
    pub margin_css: &'static str,
    pub padding_css: &'static str,
    pub border_left_css: &'static str,
    pub color_css: &'static str,
    pub background_css: &'static str,
    pub border_radius_css: &'static str,
    pub nested_margin_top_css: &'static str,
    pub nested_background_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MermaidRenderingReference {
    pub overflow_x_css: &'static str,
    pub margin_css: &'static str,
    pub padding_css: &'static str,
    pub border_radius_css: &'static str,
    pub border_css: &'static str,
    pub background_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FootnoteRenderingReference {
    pub margin_top_css: &'static str,
    pub padding_top_css: &'static str,
    pub border_top_css: &'static str,
    pub color_css: &'static str,
    pub font_size_css: &'static str,
    pub paragraph_margin_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct HtmlBlockRenderingReference {
    pub details_margin_css: &'static str,
    pub details_border_css: &'static str,
    pub details_border_radius_css: &'static str,
    pub details_background_css: &'static str,
    pub summary_font_family_css: &'static str,
    pub summary_font_weight: u16,
    pub summary_padding_css: &'static str,
    pub summary_background_css: &'static str,
    pub body_padding_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TaskListRenderingReference {
    pub item_list_style_css: &'static str,
    pub item_margin_left_css: &'static str,
    pub checkbox_margin_right_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct TableRenderingReference {
    pub width_css: &'static str,
    pub border_collapse_css: &'static str,
    pub margin_css: &'static str,
    pub font_family_css: &'static str,
    pub font_size_css: &'static str,
    pub border_radius_css: &'static str,
    pub border_css: &'static str,
    pub box_shadow_css: &'static str,
    pub header_background_css: &'static str,
    pub cell_padding_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InlineMarkupRenderingReference {
    pub emphasis_html_tag: &'static str,
    pub strong_html_tag: &'static str,
    pub strong_emphasis_html_snippet: &'static str,
    pub strong_font_weight: u16,
    pub strong_uses_ui_font_family: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct FencedCodeRenderingReference {
    pub pre_margin_css: &'static str,
    pub pre_padding_css: &'static str,
    pub pre_border_radius_css: &'static str,
    pub pre_overflow_x_css: &'static str,
    pub code_font_size_css: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SyntaxHighlightingRenderingReference {
    pub highlight_theme_asset: &'static str,
    pub highlighter_symbol: &'static str,
    pub language_guard_api: &'static str,
    pub highlight_api: &'static str,
    pub auto_detect_api: &'static str,
    pub escape_fallback_api: &'static str,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingCodeReference {
    pub fenced_block: FencedCodeRenderingReference,
    pub syntax_highlighting: SyntaxHighlightingRenderingReference,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingTextReference {
    pub heading: HeadingRenderingReference,
    pub paragraph: ParagraphRenderingReference,
    pub blockquote: BlockquoteRenderingReference,
    pub task_list: TaskListRenderingReference,
    pub inline_markup: InlineMarkupRenderingReference,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RenderingReference {
    pub runtime: RenderingRuntimeReference,
    pub typography: RenderingTypographyReference,
    pub theme: RenderingThemeReference,
    pub chrome: RenderingChromeReference,
    pub layout: RenderingLayoutReference,
    pub hint_chip_visual: HintChipVisualReference,
    pub code: RenderingCodeReference,
    pub mermaid: MermaidRenderingReference,
    pub footnote: FootnoteRenderingReference,
    pub html_block: HtmlBlockRenderingReference,
    pub table: TableRenderingReference,
    pub text: RenderingTextReference,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum MacOsPreviewFeature {
    FrontmostFileManagerGating,
    ExactHoveredMarkdownResolution,
    AcceptedLocalMarkdownFilesOnly,
    MonitorSelectionAndCoordinateTranslation,
    HoverOpensAfterOneSecond,
    DifferentDocumentReplacesCurrentPreview,
    StationaryHoveredItemDoesNotReopen,
    SameDocumentPointerMotionKeepsPreview,
    WidthTierModel,
    PreviewPlacementRepositionBeforeShrink,
    CompactHintChipChrome,
    HotInteractionSurface,
    BackgroundToggleTab,
    ScrollWheelAndTouchpad,
    PagingKeysAndStickyMotion,
    InlineBlockEditEntryAndSourceMapping,
    EditSaveCancelAndLock,
    ClosePolicyOutsideClickAppSwitchEscape,
    MarkdownRenderingSurface,
    RuntimeDiagnosticsCoverage,
}

impl MacOsPreviewFeature {
    pub fn blueprint_label(self) -> &'static str {
        match self {
            Self::FrontmostFileManagerGating => {
                "Ensure preview opening is blocked while the foreground surface is not Finder / Explorer / Nautilus"
            }
            Self::ExactHoveredMarkdownResolution => {
                "Resolve the actual hovered Markdown item instead of a nearby or first-visible candidate"
            }
            Self::AcceptedLocalMarkdownFilesOnly => {
                "Reject non-Markdown files, directories, stale paths, and unsupported entities before preview open"
            }
            Self::MonitorSelectionAndCoordinateTranslation => {
                "Preserve macOS-equivalent monitor selection and desktop-space coordinate translation"
            }
            Self::HoverOpensAfterOneSecond => {
                "Open preview after a 1-second hover debounce"
            }
            Self::DifferentDocumentReplacesCurrentPreview => {
                "Replace the current preview only when a different hovered Markdown document resolves"
            }
            Self::StationaryHoveredItemDoesNotReopen => {
                "Do not repeatedly reopen the same preview while the pointer stays stationary"
            }
            Self::SameDocumentPointerMotionKeepsPreview => {
                "Do not dismiss the preview when pointer motion stays on the same resolved document"
            }
            Self::WidthTierModel => {
                "Preserve the macOS four-tier width model of 560 / 960 / 1440 / 1920"
            }
            Self::PreviewPlacementRepositionBeforeShrink => {
                "Preserve the shared 4:3 placement policy and reposition before shrink"
            }
            Self::CompactHintChipChrome => {
                "Keep the preview chrome collapsed into the same compact top-right hint chip"
            }
            Self::HotInteractionSurface => {
                "Keep the preview hot immediately after open without forcing a re-hover"
            }
            Self::BackgroundToggleTab => {
                "Toggle the same white/black background modes with Tab"
            }
            Self::ScrollWheelAndTouchpad => {
                "Apply the same mouse-wheel and touchpad scrolling semantics"
            }
            Self::PagingKeysAndStickyMotion => {
                "Apply the same (Shift+) Space / Page Up / Page Down paging inputs and sticky motion"
            }
            Self::InlineBlockEditEntryAndSourceMapping => {
                "Enter inline editing from the smallest matching block and preserve block-to-source mapping"
            }
            Self::EditSaveCancelAndLock => {
                "Preserve macOS save/cancel behavior and edit-mode lock semantics"
            }
            Self::ClosePolicyOutsideClickAppSwitchEscape => {
                "Preserve macOS close-on-outside-click, app-switch, and Escape semantics"
            }
            Self::MarkdownRenderingSurface => {
                "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy"
            }
            Self::RuntimeDiagnosticsCoverage => {
                "Emit structured runtime diagnostics for host gating, hover resolution, placement, and edit lifecycle"
            }
        }
    }

    pub fn real_host_evidence_requirements(self) -> &'static [RealHostEvidenceRequirement] {
        match self {
            Self::FrontmostFileManagerGating => {
                &FRONTMOST_FILE_MANAGER_REAL_HOST_EVIDENCE_REQUIREMENTS
            }
            Self::ExactHoveredMarkdownResolution | Self::AcceptedLocalMarkdownFilesOnly => {
                &EXACT_HOVERED_MARKDOWN_REAL_HOST_EVIDENCE_REQUIREMENTS
            }
            Self::MonitorSelectionAndCoordinateTranslation
            | Self::WidthTierModel
            | Self::PreviewPlacementRepositionBeforeShrink => {
                &MONITOR_SELECTION_REAL_HOST_EVIDENCE_REQUIREMENTS
            }
            Self::HoverOpensAfterOneSecond
            | Self::DifferentDocumentReplacesCurrentPreview
            | Self::StationaryHoveredItemDoesNotReopen
            | Self::SameDocumentPointerMotionKeepsPreview
            | Self::CompactHintChipChrome
            | Self::HotInteractionSurface
            | Self::BackgroundToggleTab
            | Self::ScrollWheelAndTouchpad
            | Self::PagingKeysAndStickyMotion
            | Self::InlineBlockEditEntryAndSourceMapping
            | Self::EditSaveCancelAndLock
            | Self::ClosePolicyOutsideClickAppSwitchEscape
            | Self::MarkdownRenderingSurface
            | Self::RuntimeDiagnosticsCoverage => &NO_REAL_HOST_EVIDENCE_REQUIREMENTS,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum PreviewFeatureCoverageLane {
    SharedCore,
    SharedRender,
    WindowsAdapter,
}

impl PreviewFeatureCoverageLane {
    pub fn label(self) -> &'static str {
        match self {
            Self::SharedCore => "shared-core",
            Self::SharedRender => "shared-render",
            Self::WindowsAdapter => "windows-adapter",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RealHostEvidenceRequirement {
    FrontmostFileManagerDetection,
    ExactHoveredMarkdownResolution,
    MonitorSelectionAndCoordinateTranslation,
}

impl RealHostEvidenceRequirement {
    pub fn label(self) -> &'static str {
        match self {
            Self::FrontmostFileManagerDetection => "frontmost-file-manager-detection",
            Self::ExactHoveredMarkdownResolution => "exact-hovered-markdown-resolution",
            Self::MonitorSelectionAndCoordinateTranslation => {
                "monitor-selection-and-coordinate-translation"
            }
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum ValidationRequirementStatus {
    Pass,
    Fail,
    NotCaptured,
}

impl ValidationRequirementStatus {
    pub fn label(self) -> &'static str {
        match self {
            Self::Pass => "pass",
            Self::Fail => "fail",
            Self::NotCaptured => "not-captured",
        }
    }

    pub fn is_pass(self) -> bool {
        matches!(self, Self::Pass)
    }
}

const FRONTMOST_FILE_MANAGER_REAL_HOST_EVIDENCE_REQUIREMENTS: [RealHostEvidenceRequirement; 1] =
    [RealHostEvidenceRequirement::FrontmostFileManagerDetection];
const EXACT_HOVERED_MARKDOWN_REAL_HOST_EVIDENCE_REQUIREMENTS: [RealHostEvidenceRequirement; 1] =
    [RealHostEvidenceRequirement::ExactHoveredMarkdownResolution];
const MONITOR_SELECTION_REAL_HOST_EVIDENCE_REQUIREMENTS: [RealHostEvidenceRequirement; 1] =
    [RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation];
const NO_REAL_HOST_EVIDENCE_REQUIREMENTS: [RealHostEvidenceRequirement; 0] = [];

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct PreviewFeatureCoverageRecord {
    pub feature: MacOsPreviewFeature,
    pub lane: PreviewFeatureCoverageLane,
}

impl PreviewFeatureCoverageRecord {
    pub const fn new(feature: MacOsPreviewFeature, lane: PreviewFeatureCoverageLane) -> Self {
        Self { feature, lane }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct PreviewFeatureValidationStatus {
    pub feature: MacOsPreviewFeature,
    pub automated_lanes: Vec<PreviewFeatureCoverageLane>,
    pub real_host_requirements: Vec<RealHostEvidenceRequirement>,
    pub blocking_real_host_requirements: Vec<RealHostEvidenceRequirement>,
}

impl PreviewFeatureValidationStatus {
    pub fn automated_coverage_present(&self) -> bool {
        !self.automated_lanes.is_empty()
    }

    pub fn automated_status_label(&self) -> &'static str {
        if self.automated_coverage_present() {
            "covered"
        } else {
            "missing"
        }
    }

    pub fn is_ready_for_closure(&self) -> bool {
        self.automated_coverage_present() && self.blocking_real_host_requirements.is_empty()
    }

    pub fn parity_readiness_label(&self) -> &'static str {
        if self.is_ready_for_closure() {
            "ready"
        } else {
            "blocked"
        }
    }
}

pub static MACOS_PREVIEW_FEATURE_LIST: [MacOsPreviewFeature; 20] = [
    MacOsPreviewFeature::FrontmostFileManagerGating,
    MacOsPreviewFeature::ExactHoveredMarkdownResolution,
    MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
    MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
    MacOsPreviewFeature::HoverOpensAfterOneSecond,
    MacOsPreviewFeature::DifferentDocumentReplacesCurrentPreview,
    MacOsPreviewFeature::StationaryHoveredItemDoesNotReopen,
    MacOsPreviewFeature::SameDocumentPointerMotionKeepsPreview,
    MacOsPreviewFeature::WidthTierModel,
    MacOsPreviewFeature::PreviewPlacementRepositionBeforeShrink,
    MacOsPreviewFeature::CompactHintChipChrome,
    MacOsPreviewFeature::HotInteractionSurface,
    MacOsPreviewFeature::BackgroundToggleTab,
    MacOsPreviewFeature::ScrollWheelAndTouchpad,
    MacOsPreviewFeature::PagingKeysAndStickyMotion,
    MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping,
    MacOsPreviewFeature::EditSaveCancelAndLock,
    MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape,
    MacOsPreviewFeature::MarkdownRenderingSurface,
    MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
];

pub fn shared_hint_chip_contract(selected_width_tier_index: usize) -> HintChipContract {
    MACOS_REFERENCE_BEHAVIOR.hint_chip.contract(
        selected_width_tier_index,
        MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_tiers_px
            .len(),
    )
}

pub fn macos_preview_feature_list() -> &'static [MacOsPreviewFeature] {
    &MACOS_PREVIEW_FEATURE_LIST
}

pub fn merged_preview_feature_coverage(
    feature_sets: &[&[MacOsPreviewFeature]],
) -> Vec<MacOsPreviewFeature> {
    let mut features = BTreeSet::new();
    for feature_set in feature_sets {
        features.extend(feature_set.iter().copied());
    }

    features.into_iter().collect()
}

pub fn merged_preview_feature_coverage_records(
    record_sets: &[&[PreviewFeatureCoverageRecord]],
) -> Vec<PreviewFeatureCoverageRecord> {
    let mut records = BTreeSet::new();
    for record_set in record_sets {
        records.extend(record_set.iter().copied());
    }

    records.into_iter().collect()
}

pub fn preview_feature_coverage_from_records(
    records: &[PreviewFeatureCoverageRecord],
) -> Vec<MacOsPreviewFeature> {
    let mut features = BTreeSet::new();
    for record in records {
        features.insert(record.feature);
    }

    features.into_iter().collect()
}

pub fn preview_feature_coverage_lanes(
    records: &[PreviewFeatureCoverageRecord],
    feature: MacOsPreviewFeature,
) -> Vec<PreviewFeatureCoverageLane> {
    let mut lanes = BTreeSet::new();
    for record in records {
        if record.feature == feature {
            lanes.insert(record.lane);
        }
    }

    lanes.into_iter().collect()
}

pub fn preview_feature_real_host_evidence_requirements(
    features: &[MacOsPreviewFeature],
) -> Vec<RealHostEvidenceRequirement> {
    let mut requirements = BTreeSet::new();
    for feature in features {
        requirements.extend(feature.real_host_evidence_requirements().iter().copied());
    }

    requirements.into_iter().collect()
}

pub fn preview_feature_coverage_record_gaps_against_reference(
    record_sets: &[&[PreviewFeatureCoverageRecord]],
) -> Vec<MacOsPreviewFeature> {
    let merged_records = merged_preview_feature_coverage_records(record_sets);
    let covered: BTreeSet<_> = preview_feature_coverage_from_records(&merged_records)
        .into_iter()
        .collect();

    macos_preview_feature_list()
        .iter()
        .copied()
        .filter(|feature| !covered.contains(feature))
        .collect()
}

pub fn preview_feature_coverage_records_match_reference(
    record_sets: &[&[PreviewFeatureCoverageRecord]],
) -> bool {
    preview_feature_coverage_record_gaps_against_reference(record_sets).is_empty()
}

pub fn preview_feature_validation_statuses(
    record_sets: &[&[PreviewFeatureCoverageRecord]],
    requirement_statuses: &[(RealHostEvidenceRequirement, ValidationRequirementStatus)],
) -> Vec<PreviewFeatureValidationStatus> {
    let merged_records = merged_preview_feature_coverage_records(record_sets);
    let requirement_statuses: BTreeMap<_, _> = requirement_statuses.iter().copied().collect();

    macos_preview_feature_list()
        .iter()
        .copied()
        .map(|feature| {
            let automated_lanes = preview_feature_coverage_lanes(&merged_records, feature);
            let real_host_requirements = feature.real_host_evidence_requirements().to_vec();
            let blocking_real_host_requirements = real_host_requirements
                .iter()
                .copied()
                .filter(|requirement| {
                    !requirement_statuses
                        .get(requirement)
                        .copied()
                        .unwrap_or(ValidationRequirementStatus::NotCaptured)
                        .is_pass()
                })
                .collect();

            PreviewFeatureValidationStatus {
                feature,
                automated_lanes,
                real_host_requirements,
                blocking_real_host_requirements,
            }
        })
        .collect()
}

pub fn preview_feature_gaps_against_reference(
    feature_sets: &[&[MacOsPreviewFeature]],
) -> Vec<MacOsPreviewFeature> {
    let covered: BTreeSet<_> = merged_preview_feature_coverage(feature_sets)
        .into_iter()
        .collect();

    macos_preview_feature_list()
        .iter()
        .copied()
        .filter(|feature| !covered.contains(feature))
        .collect()
}

pub fn preview_feature_coverage_matches_reference(feature_sets: &[&[MacOsPreviewFeature]]) -> bool {
    preview_feature_gaps_against_reference(feature_sets).is_empty()
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
        hint_chip_visual: HintChipVisualReference {
            chip_gap_css: "6px 10px",
            chip_padding_css: "7px 11px",
            chip_border_radius_css: "999px",
            chip_border_css: "1px solid var(--border)",
            chip_background_css: "color-mix(in srgb, var(--surface) 94%, transparent)",
            desktop_justify_content_css: "flex-end",
            mobile_justify_content_css: "flex-start",
            item_gap_css: "6px",
            item_font_size_css: "0.74rem",
            width_font_weight: 700,
            width_letter_spacing_css: "0.01em",
            width_font_variant_numeric_css: "tabular-nums",
            icon_size_px: 18,
            icon_border_css: "1px solid var(--border)",
            icon_font_size_css: "0.68rem",
            separator_size_px: 4,
            separator_background_css: "color-mix(in srgb, var(--muted) 42%, transparent)",
        },
        code: RenderingCodeReference {
            fenced_block: FencedCodeRenderingReference {
                pre_margin_css: "0.95rem 0",
                pre_padding_css: "14px 16px",
                pre_border_radius_css: "14px",
                pre_overflow_x_css: "auto",
                code_font_size_css: "0.88em",
            },
            syntax_highlighting: SyntaxHighlightingRenderingReference {
                highlight_theme_asset: "highlight.js/styles/github.css",
                highlighter_symbol: "hljs",
                language_guard_api: "getLanguage",
                highlight_api: "highlight",
                auto_detect_api: "highlightAuto",
                escape_fallback_api: "escapeHtml",
            },
        },
        mermaid: MermaidRenderingReference {
            overflow_x_css: "auto",
            margin_css: "1rem 0",
            padding_css: "16px",
            border_radius_css: "16px",
            border_css: "1px solid var(--border)",
            background_css: "color-mix(in srgb, var(--surface) 92%, transparent)",
        },
        footnote: FootnoteRenderingReference {
            margin_top_css: "2rem",
            padding_top_css: "1rem",
            border_top_css: "1px solid var(--border)",
            color_css: "var(--muted)",
            font_size_css: "0.86rem",
            paragraph_margin_css: "0.35rem 0",
        },
        html_block: HtmlBlockRenderingReference {
            details_margin_css: "1rem 0",
            details_border_css: "1px solid var(--border)",
            details_border_radius_css: "12px",
            details_background_css: "color-mix(in srgb, var(--surface) 96%, transparent)",
            summary_font_family_css: "var(--font-ui)",
            summary_font_weight: 700,
            summary_padding_css: "12px 14px",
            summary_background_css: "color-mix(in srgb, var(--accent-soft) 30%, transparent)",
            body_padding_css: "0 14px 14px",
        },
        table: TableRenderingReference {
            width_css: "100%",
            border_collapse_css: "collapse",
            margin_css: "1rem 0",
            font_family_css: "var(--font-ui)",
            font_size_css: "0.96rem",
            border_radius_css: "12px",
            border_css: "1px solid var(--border)",
            box_shadow_css: "0 8px 18px rgba(15, 23, 42, 0.06)",
            header_background_css: "color-mix(in srgb, var(--accent-soft) 42%, var(--surface))",
            cell_padding_css: "11px 12px",
        },
        text: RenderingTextReference {
            heading: HeadingRenderingReference {
                margin_css: "1.05em 0 0.45em",
                line_height_css: "1.18",
                letter_spacing_css: "-0.02em",
                h6_text_transform: "uppercase",
                h6_letter_spacing_css: "0.08em",
            },
            paragraph: ParagraphRenderingReference {
                margin_css: "0.7em 0",
            },
            blockquote: BlockquoteRenderingReference {
                margin_css: "0.95rem 0",
                padding_css: "0.24rem 0 0.24rem 1rem",
                border_left_css: "4px solid var(--quote)",
                color_css: "color-mix(in srgb, var(--text) 88%, var(--muted))",
                background_css: "color-mix(in srgb, var(--accent-soft) 20%, transparent)",
                border_radius_css: "0 10px 10px 0",
                nested_margin_top_css: "0.8rem",
                nested_background_css: "transparent",
            },
            task_list: TaskListRenderingReference {
                item_list_style_css: "none",
                item_margin_left_css: "-1.25rem",
                checkbox_margin_right_css: "0.55rem",
            },
            inline_markup: InlineMarkupRenderingReference {
                emphasis_html_tag: "em",
                strong_html_tag: "strong",
                strong_emphasis_html_snippet: "<strong><em>$1</em></strong>",
                strong_font_weight: 700,
                strong_uses_ui_font_family: true,
            },
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

    pub fn has_positive_frame_area(&self) -> bool {
        self.frame.has_positive_area() && self.visible_frame.has_positive_area()
    }

    pub fn visible_frame_within_frame(&self) -> bool {
        self.frame.contains_rect(&self.visible_frame)
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
    #[serde(default)]
    pub warmed_document: Option<LoadedDocument>,
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
    pub draft_source: Option<String>,
}

impl EditingState {
    pub fn target_line_range(&self) -> Option<std::ops::Range<u32>> {
        match (self.target_start_line, self.target_end_line) {
            (Some(start), Some(end)) if end > start => Some(start..end),
            _ => None,
        }
    }

    pub fn has_target_range(&self) -> bool {
        self.target_line_range().is_some()
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RuntimeDiagnosticLevel {
    Info,
    Warning,
    Error,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum RuntimeDiagnosticCategory {
    FrontmostGating,
    HoveredItemResolution,
    MonitorSelection,
    PreviewPlacement,
    EditLifecycle,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct RuntimeDiagnostic {
    pub platform: PlatformId,
    pub level: RuntimeDiagnosticLevel,
    pub category: RuntimeDiagnosticCategory,
    pub at_ms: Option<u64>,
    pub summary: String,
    pub details: BTreeMap<String, String>,
}

impl RuntimeDiagnostic {
    pub fn new(
        platform: PlatformId,
        level: RuntimeDiagnosticLevel,
        category: RuntimeDiagnosticCategory,
        summary: impl Into<String>,
    ) -> Self {
        Self {
            platform,
            level,
            category,
            at_ms: None,
            summary: summary.into(),
            details: BTreeMap::new(),
        }
    }

    pub fn at_ms(mut self, at_ms: u64) -> Self {
        self.at_ms = Some(at_ms);
        self
    }

    pub fn with_detail(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.details.insert(key.into(), value.into());
        self
    }
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
                draft_source: None,
            },
            last_close_reason: None,
            selected_width_tier_index: 0,
            background_mode: BackgroundMode::White,
            interaction_hot: false,
        }
    }
}

impl PreviewState {
    pub fn hint_chip_contract(&self) -> HintChipContract {
        shared_hint_chip_contract(self.selected_width_tier_index)
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
        replacement_source: String,
    },
    CompleteSave {
        success: bool,
        persisted_markdown: Option<String>,
        message: Option<String>,
    },
    CancelEdit,
    ReportRuntimeDiagnostics {
        diagnostics: Vec<RuntimeDiagnostic>,
    },
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
    RuntimeDiagnosticsReported {
        diagnostics: Vec<RuntimeDiagnostic>,
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
    use std::collections::BTreeSet;

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
            warmed_document: Some(LoadedDocument {
                document: sample_document(),
                encoding: "utf-8".to_string(),
                markdown: "# Title".to_string(),
            }),
        }
    }

    fn sample_editing_state() -> EditingState {
        EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(4),
            target_end_line: Some(9),
            draft_markdown: Some("updated".to_string()),
            draft_source: Some("updated block".to_string()),
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
    fn editing_state_exposes_only_valid_target_ranges() {
        let editing = sample_editing_state();
        assert_eq!(editing.target_line_range(), Some(4..9));
        assert!(editing.has_target_range());

        let missing_end = EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(4),
            target_end_line: None,
            draft_markdown: None,
            draft_source: None,
        };
        assert_eq!(missing_end.target_line_range(), None);
        assert!(!missing_end.has_target_range());

        let inverted = EditingState {
            phase: EditingPhase::Active,
            target_start_line: Some(9),
            target_end_line: Some(4),
            draft_markdown: None,
            draft_source: None,
        };
        assert_eq!(inverted.target_line_range(), None);
        assert!(!inverted.has_target_range());
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
    fn hint_chip_and_post_open_input_contracts_stay_locked_to_macos_reference() {
        let reference = MACOS_REFERENCE_BEHAVIOR;

        assert!(reference.hint_chip.collapsed_into_single_chip);
        assert_eq!(reference.hint_chip.background_icon, "◐");
        assert_eq!(reference.hint_chip.paging_icon, "⇵");
        assert!(reference.interaction.preview_becomes_hot_on_open);
        assert!(reference.interaction.keeps_hot_surface_while_visible);
        assert!(reference.interaction.supports_background_toggle);
        assert!(reference.interaction.supports_scroll_wheel_and_touchpad);
        assert!(reference.interaction.supports_space_and_page_keys);
        assert!(reference.background_toggle.requires_hot_surface);
        assert!(reference.paging.requires_hot_surface);
    }

    #[test]
    fn macos_reference_behavior_exposes_fenced_code_and_syntax_highlighting_parity_details() {
        let rendering = MACOS_REFERENCE_BEHAVIOR.rendering;

        assert_eq!(rendering.code.fenced_block.pre_margin_css, "0.95rem 0");
        assert_eq!(rendering.code.fenced_block.pre_padding_css, "14px 16px");
        assert_eq!(rendering.code.fenced_block.pre_border_radius_css, "14px");
        assert_eq!(rendering.code.fenced_block.pre_overflow_x_css, "auto");
        assert_eq!(rendering.code.fenced_block.code_font_size_css, "0.88em");
        assert_eq!(
            rendering.code.syntax_highlighting.highlight_theme_asset,
            "highlight.js/styles/github.css"
        );
        assert_eq!(
            rendering.code.syntax_highlighting.highlighter_symbol,
            "hljs"
        );
        assert_eq!(
            rendering.code.syntax_highlighting.language_guard_api,
            "getLanguage"
        );
        assert_eq!(
            rendering.code.syntax_highlighting.highlight_api,
            "highlight"
        );
        assert_eq!(
            rendering.code.syntax_highlighting.auto_detect_api,
            "highlightAuto"
        );
        assert_eq!(
            rendering.code.syntax_highlighting.escape_fallback_api,
            "escapeHtml"
        );
        assert!(rendering.runtime.syntax_highlight_uses_highlight_js);
        assert!(rendering.runtime.syntax_highlight_falls_back_to_auto_detect);
    }

    #[test]
    fn macos_reference_behavior_exposes_table_rendering_parity_details() {
        let table = MACOS_REFERENCE_BEHAVIOR.rendering.table;

        assert_eq!(table.width_css, "100%");
        assert_eq!(table.border_collapse_css, "collapse");
        assert_eq!(table.margin_css, "1rem 0");
        assert_eq!(table.font_family_css, "var(--font-ui)");
        assert_eq!(table.font_size_css, "0.96rem");
        assert_eq!(table.border_radius_css, "12px");
        assert_eq!(table.border_css, "1px solid var(--border)");
        assert_eq!(table.box_shadow_css, "0 8px 18px rgba(15, 23, 42, 0.06)");
        assert_eq!(
            table.header_background_css,
            "color-mix(in srgb, var(--accent-soft) 42%, var(--surface))"
        );
        assert_eq!(table.cell_padding_css, "11px 12px");
    }

    #[test]
    fn macos_reference_behavior_exposes_blockquote_rendering_parity_details() {
        let blockquote = MACOS_REFERENCE_BEHAVIOR.rendering.text.blockquote;

        assert_eq!(blockquote.margin_css, "0.95rem 0");
        assert_eq!(blockquote.padding_css, "0.24rem 0 0.24rem 1rem");
        assert_eq!(blockquote.border_left_css, "4px solid var(--quote)");
        assert_eq!(
            blockquote.color_css,
            "color-mix(in srgb, var(--text) 88%, var(--muted))"
        );
        assert_eq!(
            blockquote.background_css,
            "color-mix(in srgb, var(--accent-soft) 20%, transparent)"
        );
        assert_eq!(blockquote.border_radius_css, "0 10px 10px 0");
        assert_eq!(blockquote.nested_margin_top_css, "0.8rem");
        assert_eq!(blockquote.nested_background_css, "transparent");
    }

    #[test]
    fn macos_reference_behavior_exposes_mermaid_rendering_parity_details() {
        let mermaid = MACOS_REFERENCE_BEHAVIOR.rendering.mermaid;
        let runtime = MACOS_REFERENCE_BEHAVIOR.rendering.runtime;

        assert!(runtime.supports_mermaid);
        assert_eq!(runtime.mermaid_fence_info_string, "mermaid");
        assert_eq!(runtime.mermaid_security_level, "loose");
        assert_eq!(mermaid.overflow_x_css, "auto");
        assert_eq!(mermaid.margin_css, "1rem 0");
        assert_eq!(mermaid.padding_css, "16px");
        assert_eq!(mermaid.border_radius_css, "16px");
        assert_eq!(mermaid.border_css, "1px solid var(--border)");
        assert_eq!(
            mermaid.background_css,
            "color-mix(in srgb, var(--surface) 92%, transparent)"
        );
    }

    #[test]
    fn macos_reference_behavior_exposes_footnote_rendering_parity_details() {
        let footnote = MACOS_REFERENCE_BEHAVIOR.rendering.footnote;
        let runtime = MACOS_REFERENCE_BEHAVIOR.rendering.runtime;

        assert!(runtime.supports_footnotes);
        assert_eq!(footnote.margin_top_css, "2rem");
        assert_eq!(footnote.padding_top_css, "1rem");
        assert_eq!(footnote.border_top_css, "1px solid var(--border)");
        assert_eq!(footnote.color_css, "var(--muted)");
        assert_eq!(footnote.font_size_css, "0.86rem");
        assert_eq!(footnote.paragraph_margin_css, "0.35rem 0");
    }

    #[test]
    fn macos_reference_behavior_exposes_html_block_rendering_parity_details() {
        let html_block = MACOS_REFERENCE_BEHAVIOR.rendering.html_block;
        let runtime = MACOS_REFERENCE_BEHAVIOR.rendering.runtime;

        assert!(runtime.html_enabled);
        assert!(runtime.html_blocks_passthrough);
        assert_eq!(html_block.details_margin_css, "1rem 0");
        assert_eq!(html_block.details_border_css, "1px solid var(--border)");
        assert_eq!(html_block.details_border_radius_css, "12px");
        assert_eq!(
            html_block.details_background_css,
            "color-mix(in srgb, var(--surface) 96%, transparent)"
        );
        assert_eq!(html_block.summary_font_family_css, "var(--font-ui)");
        assert_eq!(html_block.summary_font_weight, 700);
        assert_eq!(html_block.summary_padding_css, "12px 14px");
        assert_eq!(
            html_block.summary_background_css,
            "color-mix(in srgb, var(--accent-soft) 30%, transparent)"
        );
        assert_eq!(html_block.body_padding_css, "0 14px 14px");
    }

    #[test]
    fn macos_reference_behavior_exposes_hint_chip_visual_parity_details() {
        let hint_chip = MACOS_REFERENCE_BEHAVIOR.rendering.hint_chip_visual;

        assert_eq!(hint_chip.chip_gap_css, "6px 10px");
        assert_eq!(hint_chip.chip_padding_css, "7px 11px");
        assert_eq!(hint_chip.chip_border_radius_css, "999px");
        assert_eq!(hint_chip.chip_border_css, "1px solid var(--border)");
        assert_eq!(
            hint_chip.chip_background_css,
            "color-mix(in srgb, var(--surface) 94%, transparent)"
        );
        assert_eq!(hint_chip.desktop_justify_content_css, "flex-end");
        assert_eq!(hint_chip.mobile_justify_content_css, "flex-start");
        assert_eq!(hint_chip.item_gap_css, "6px");
        assert_eq!(hint_chip.item_font_size_css, "0.74rem");
        assert_eq!(hint_chip.width_font_weight, 700);
        assert_eq!(hint_chip.width_letter_spacing_css, "0.01em");
        assert_eq!(hint_chip.width_font_variant_numeric_css, "tabular-nums");
        assert_eq!(hint_chip.icon_size_px, 18);
        assert_eq!(hint_chip.icon_border_css, "1px solid var(--border)");
        assert_eq!(hint_chip.icon_font_size_css, "0.68rem");
        assert_eq!(hint_chip.separator_size_px, 4);
        assert_eq!(
            hint_chip.separator_background_css,
            "color-mix(in srgb, var(--muted) 42%, transparent)"
        );
    }

    #[test]
    fn shared_hint_chip_contract_round_trips_the_macos_reference_copy() {
        let contract = shared_hint_chip_contract(1);

        assert_eq!(
            contract,
            HintChipContract {
                width_label: "← 2/4 →".to_string(),
                background_label: "Tab".to_string(),
                paging_label: "(⇧+) Space".to_string(),
                background_icon: "◐".to_string(),
                paging_icon: "⇵".to_string(),
            }
        );
        assert_roundtrip(&contract);
    }

    #[test]
    fn preview_state_exposes_hint_chip_contract_from_selected_width_tier() {
        let state = PreviewState {
            selected_width_tier_index: 2,
            ..PreviewState::default()
        };

        assert_eq!(state.hint_chip_contract(), shared_hint_chip_contract(2));
        assert_eq!(state.hint_chip_contract().width_label, "← 3/4 →");
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
    fn macos_preview_feature_list_stays_explicit_and_unique() {
        let features = macos_preview_feature_list();
        let unique: BTreeSet<_> = features.iter().copied().collect();

        assert_eq!(features.len(), 20);
        assert_eq!(unique.len(), features.len());
        assert!(unique.contains(&MacOsPreviewFeature::FrontmostFileManagerGating));
        assert!(unique.contains(&MacOsPreviewFeature::CompactHintChipChrome));
        assert!(unique.contains(&MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping));
        assert!(unique.contains(&MacOsPreviewFeature::MarkdownRenderingSurface));
        assert!(unique.contains(&MacOsPreviewFeature::RuntimeDiagnosticsCoverage));
        assert_eq!(
            MacOsPreviewFeature::HoverOpensAfterOneSecond.blueprint_label(),
            "Open preview after a 1-second hover debounce"
        );
    }

    #[test]
    fn preview_feature_coverage_helpers_deduplicate_and_report_reference_gaps() {
        let merged = merged_preview_feature_coverage(&[
            &[
                MacOsPreviewFeature::HoverOpensAfterOneSecond,
                MacOsPreviewFeature::WidthTierModel,
            ],
            &[
                MacOsPreviewFeature::WidthTierModel,
                MacOsPreviewFeature::CompactHintChipChrome,
            ],
        ]);
        let merged_set: BTreeSet<_> = merged.iter().copied().collect();

        assert_eq!(merged.len(), 3);
        assert_eq!(merged_set.len(), 3);
        assert!(merged_set.contains(&MacOsPreviewFeature::HoverOpensAfterOneSecond));
        assert!(merged_set.contains(&MacOsPreviewFeature::WidthTierModel));
        assert!(merged_set.contains(&MacOsPreviewFeature::CompactHintChipChrome));

        let gaps = preview_feature_gaps_against_reference(&[&[
            MacOsPreviewFeature::HoverOpensAfterOneSecond,
            MacOsPreviewFeature::WidthTierModel,
        ]]);
        assert!(gaps.contains(&MacOsPreviewFeature::CompactHintChipChrome));
        assert!(gaps.contains(&MacOsPreviewFeature::RuntimeDiagnosticsCoverage));
        assert!(!preview_feature_coverage_matches_reference(&[&[
            MacOsPreviewFeature::HoverOpensAfterOneSecond,
            MacOsPreviewFeature::WidthTierModel,
        ]]));
        assert!(preview_feature_coverage_matches_reference(&[
            macos_preview_feature_list()
        ]));
    }

    #[test]
    fn preview_feature_coverage_record_helpers_keep_feature_lane_pairs_explicit() {
        let records = merged_preview_feature_coverage_records(&[
            &[
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::HoverOpensAfterOneSecond,
                    PreviewFeatureCoverageLane::SharedCore,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::WidthTierModel,
                    PreviewFeatureCoverageLane::SharedCore,
                ),
            ],
            &[
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::WidthTierModel,
                    PreviewFeatureCoverageLane::SharedCore,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::WidthTierModel,
                    PreviewFeatureCoverageLane::WindowsAdapter,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::CompactHintChipChrome,
                    PreviewFeatureCoverageLane::SharedRender,
                ),
            ],
        ]);

        assert_eq!(records.len(), 4);
        assert_eq!(
            preview_feature_coverage_from_records(&records),
            vec![
                MacOsPreviewFeature::HoverOpensAfterOneSecond,
                MacOsPreviewFeature::WidthTierModel,
                MacOsPreviewFeature::CompactHintChipChrome,
            ]
        );
        assert_eq!(
            preview_feature_coverage_lanes(&records, MacOsPreviewFeature::WidthTierModel),
            vec![
                PreviewFeatureCoverageLane::SharedCore,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ]
        );
        assert!(
            preview_feature_coverage_record_gaps_against_reference(&[&records])
                .contains(&MacOsPreviewFeature::RuntimeDiagnosticsCoverage)
        );
        assert!(!preview_feature_coverage_records_match_reference(&[
            &records
        ]));
        assert!(preview_feature_coverage_records_match_reference(&[&[
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::FrontmostFileManagerGating,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::ExactHoveredMarkdownResolution,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::HoverOpensAfterOneSecond,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::DifferentDocumentReplacesCurrentPreview,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::StationaryHoveredItemDoesNotReopen,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::SameDocumentPointerMotionKeepsPreview,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::WidthTierModel,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::PreviewPlacementRepositionBeforeShrink,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::CompactHintChipChrome,
                PreviewFeatureCoverageLane::SharedRender,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::HotInteractionSurface,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::BackgroundToggleTab,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::ScrollWheelAndTouchpad,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::PagingKeysAndStickyMotion,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::EditSaveCancelAndLock,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape,
                PreviewFeatureCoverageLane::SharedCore,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::MarkdownRenderingSurface,
                PreviewFeatureCoverageLane::SharedRender,
            ),
            PreviewFeatureCoverageRecord::new(
                MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
                PreviewFeatureCoverageLane::WindowsAdapter,
            ),
        ]]));
        assert_eq!(
            PreviewFeatureCoverageLane::SharedRender.label(),
            "shared-render"
        );
    }

    #[test]
    fn preview_feature_real_host_evidence_requirements_stay_explicit() {
        assert_eq!(
            MacOsPreviewFeature::FrontmostFileManagerGating.real_host_evidence_requirements(),
            &[RealHostEvidenceRequirement::FrontmostFileManagerDetection]
        );
        assert_eq!(
            MacOsPreviewFeature::ExactHoveredMarkdownResolution.real_host_evidence_requirements(),
            &[RealHostEvidenceRequirement::ExactHoveredMarkdownResolution]
        );
        assert_eq!(
            MacOsPreviewFeature::WidthTierModel.real_host_evidence_requirements(),
            &[RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation]
        );
        assert!(MacOsPreviewFeature::MarkdownRenderingSurface
            .real_host_evidence_requirements()
            .is_empty());
        assert_eq!(
            preview_feature_real_host_evidence_requirements(&[
                MacOsPreviewFeature::ExactHoveredMarkdownResolution,
                MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
                MacOsPreviewFeature::WidthTierModel,
            ]),
            vec![
                RealHostEvidenceRequirement::ExactHoveredMarkdownResolution,
                RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation,
            ]
        );
        assert_eq!(
            RealHostEvidenceRequirement::FrontmostFileManagerDetection.label(),
            "frontmost-file-manager-detection"
        );
    }

    #[test]
    fn preview_feature_validation_statuses_merge_automated_and_real_host_states() {
        let statuses = preview_feature_validation_statuses(
            &[&[
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::FrontmostFileManagerGating,
                    PreviewFeatureCoverageLane::WindowsAdapter,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::HoverOpensAfterOneSecond,
                    PreviewFeatureCoverageLane::SharedCore,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::WidthTierModel,
                    PreviewFeatureCoverageLane::SharedCore,
                ),
                PreviewFeatureCoverageRecord::new(
                    MacOsPreviewFeature::MarkdownRenderingSurface,
                    PreviewFeatureCoverageLane::SharedRender,
                ),
            ]],
            &[
                (
                    RealHostEvidenceRequirement::FrontmostFileManagerDetection,
                    ValidationRequirementStatus::Pass,
                ),
                (
                    RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation,
                    ValidationRequirementStatus::NotCaptured,
                ),
            ],
        );

        let frontmost = statuses
            .iter()
            .find(|status| status.feature == MacOsPreviewFeature::FrontmostFileManagerGating)
            .expect("frontmost status should be present");
        assert_eq!(frontmost.automated_status_label(), "covered");
        assert_eq!(frontmost.parity_readiness_label(), "ready");
        assert!(frontmost.blocking_real_host_requirements.is_empty());

        let hover_open = statuses
            .iter()
            .find(|status| status.feature == MacOsPreviewFeature::HoverOpensAfterOneSecond)
            .expect("hover-open status should be present");
        assert_eq!(hover_open.automated_status_label(), "covered");
        assert_eq!(hover_open.parity_readiness_label(), "ready");
        assert!(hover_open.real_host_requirements.is_empty());

        let width_tier = statuses
            .iter()
            .find(|status| status.feature == MacOsPreviewFeature::WidthTierModel)
            .expect("width-tier status should be present");
        assert_eq!(width_tier.automated_status_label(), "covered");
        assert_eq!(width_tier.parity_readiness_label(), "blocked");
        assert_eq!(
            width_tier.blocking_real_host_requirements,
            vec![RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation]
        );

        let exact_hover = statuses
            .iter()
            .find(|status| status.feature == MacOsPreviewFeature::ExactHoveredMarkdownResolution)
            .expect("exact-hover status should be present");
        assert_eq!(exact_hover.automated_status_label(), "missing");
        assert_eq!(exact_hover.parity_readiness_label(), "blocked");
        assert_eq!(
            exact_hover.blocking_real_host_requirements,
            vec![RealHostEvidenceRequirement::ExactHoveredMarkdownResolution]
        );

        assert_eq!(ValidationRequirementStatus::Fail.label(), "fail");
        assert!(ValidationRequirementStatus::Pass.is_pass());
        assert!(!ValidationRequirementStatus::NotCaptured.is_pass());
    }

    #[test]
    fn validation_capture_provenance_only_accepts_real_host_sessions_for_evidence_closure() {
        assert!(ValidationCaptureProvenance::RealHostSession.satisfies_real_machine_evidence());
        assert_eq!(
            ValidationCaptureProvenance::RealHostSession.label(),
            "real-host-session"
        );
        assert!(!ValidationCaptureProvenance::ValidationFixture.satisfies_real_machine_evidence());
        assert_eq!(
            ValidationCaptureProvenance::ValidationFixture.label(),
            "validation-fixture"
        );
        assert!(!ValidationCaptureProvenance::Synthetic.satisfies_real_machine_evidence());
        assert_eq!(ValidationCaptureProvenance::Synthetic.label(), "synthetic");
    }

    #[test]
    fn validation_host_environment_formats_a_target_label() {
        let environment = ValidationHostEnvironment {
            platform_id: PlatformId::WindowsExplorer,
            operating_system: "Windows 11".to_string(),
            operating_system_version: Some("24H2".to_string()),
            operating_system_build: Some("26100".to_string()),
            file_manager: Some("Explorer".to_string()),
            host_name: Some("FASTMD-WIN11".to_string()),
            architecture: Some("x64".to_string()),
            captured_at_utc: Some("2026-04-08T09:14:00Z".to_string()),
        };

        assert_eq!(
            environment.operating_system_label(),
            "Windows 11 24H2 (build 26100)"
        );
        assert_eq!(
            environment.target_label(),
            "Windows 11 24H2 (build 26100) + Explorer"
        );
        assert!(environment.operating_system_matches("Windows 11"));
        assert!(environment.file_manager_matches("explorer"));
        assert!(environment.matches_target(
            PlatformId::WindowsExplorer,
            "Windows 11",
            Some("Explorer"),
        ));
        assert!(!environment.matches_target(
            PlatformId::WindowsExplorer,
            "Windows 10",
            Some("Explorer"),
        ));
        assert!(!environment.matches_target(
            PlatformId::WindowsExplorer,
            "Windows 11",
            Some("Finder"),
        ));
        assert!(!environment.matches_target(
            PlatformId::MacosFinder,
            "Windows 11",
            Some("Explorer"),
        ));
        assert_roundtrip(&environment);
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
        let diagnostic = RuntimeDiagnostic::new(
            PlatformId::WindowsExplorer,
            RuntimeDiagnosticLevel::Info,
            RuntimeDiagnosticCategory::PreviewPlacement,
            "Windows preview placement requested a shared-core frame",
        )
        .at_ms(1_500)
        .with_detail("monitor_id", "primary")
        .with_detail("requested_width_px", "960");
        let command = AppCommand::ObserveHover {
            at_ms: 1_500,
            front_surface: sample_front_surface(),
            hovered_item: Some(sample_hovered_item()),
            monitor: Some(sample_monitor()),
        };
        let width_command = AppCommand::AdjustWidthTier {
            delta: 1,
            monitor: Some(sample_monitor()),
        };
        let event = AppEvent::PreviewWindowRequested {
            request: sample_preview_request(),
        };
        let width_event = AppEvent::WidthTierChanged {
            selected_width_tier_index: 1,
            requested_width_px: 960,
        };
        let close_event = AppEvent::PreviewWindowHidden {
            reason: CloseReason::Escape,
        };
        let diagnostics_command = AppCommand::ReportRuntimeDiagnostics {
            diagnostics: vec![diagnostic.clone()],
        };
        let diagnostics_event = AppEvent::RuntimeDiagnosticsReported {
            diagnostics: vec![diagnostic],
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
        assert_roundtrip(&width_command);
        assert_roundtrip(&event);
        assert_roundtrip(&width_event);
        assert_roundtrip(&close_event);
        assert_roundtrip(&diagnostics_command);
        assert_roundtrip(&diagnostics_event);
        assert_roundtrip(&ValidationHostEnvironment {
            platform_id: PlatformId::WindowsExplorer,
            operating_system: "Windows 11".to_string(),
            operating_system_version: Some("24H2".to_string()),
            operating_system_build: Some("26100".to_string()),
            file_manager: Some("Explorer".to_string()),
            host_name: Some("FASTMD-WIN11".to_string()),
            architecture: Some("x64".to_string()),
            captured_at_utc: Some("2026-04-08T09:14:00Z".to_string()),
        });
        assert_roundtrip(&error);
    }

    #[test]
    fn preview_window_request_defaults_warmed_document_when_legacy_payloads_omit_it() {
        let encoded = serde_json::json!({
            "document": {
                "path": "/Users/example/Notes/spec.md",
                "display_name": "spec.md",
                "origin": "local-file-system",
                "kind": "file"
            },
            "title": "spec.md",
            "anchor": {
                "x": 120.0,
                "y": 340.0
            },
            "frame": {
                "x": 64.0,
                "y": 96.0,
                "width": 960.0,
                "height": 720.0
            },
            "selected_width_tier_index": 1,
            "requested_width_px": 960,
            "background_mode": "white",
            "interaction_hot": true,
            "monitor_id": "display-main"
        });

        let decoded: PreviewWindowRequest =
            serde_json::from_value(encoded).expect("legacy request payload should deserialize");

        assert!(decoded.warmed_document.is_none());
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
        assert!(monitor.has_positive_frame_area());
        assert!(monitor.visible_frame_within_frame());
        assert!(monitor.frame.has_positive_area());
        assert!(monitor.frame.contains_rect(&monitor.visible_frame));
    }
}
