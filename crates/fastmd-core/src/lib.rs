use std::cmp::Ordering;

use fastmd_contracts::{
    AppCommand, AppEvent, CloseReason, EditingPhase, FrontSurface, HintChipContract, HoveredItem,
    MacOsPreviewFeature, MonitorMetadata, PageInput, PagingMotion, PreviewFeatureCoverageLane,
    PreviewFeatureCoverageRecord, PreviewState, PreviewWindowRequest, ResolvedDocument,
    RuntimeDiagnostic, ScreenPoint, ScreenRect, MACOS_REFERENCE_BEHAVIOR,
};
use fastmd_render::{find_block_for_editing_state, find_smallest_matching_block, BlockMapping};

#[derive(Debug, Clone)]
pub struct CoreEngine {
    state: PreviewState,
    last_monitor: Option<MonitorMetadata>,
}

impl Default for CoreEngine {
    fn default() -> Self {
        Self::new()
    }
}

impl CoreEngine {
    pub fn new() -> Self {
        let mut state = PreviewState::default();
        state.hover.hover_trigger_ms = MACOS_REFERENCE_BEHAVIOR.preview_geometry.hover_trigger_ms;
        Self {
            state,
            last_monitor: None,
        }
    }

    pub fn state(&self) -> &PreviewState {
        &self.state
    }

    pub fn dispatch_command(
        &mut self,
        command: AppCommand,
        blocks: &[BlockMapping],
    ) -> Vec<AppEvent> {
        match command {
            AppCommand::ObserveHover {
                at_ms,
                front_surface,
                hovered_item,
                monitor,
            } => self.observe_hover(at_ms, front_surface, hovered_item, monitor),
            AppCommand::SetInteractionHot { hot } => {
                self.set_interaction_hot(hot);
                Vec::new()
            }
            AppCommand::AdjustWidthTier { delta, monitor } => {
                self.adjust_width_tier(delta, monitor)
            }
            AppCommand::ToggleBackgroundMode => self.toggle_background_mode(),
            AppCommand::ScrollPreview {
                raw_delta_y,
                precise,
            } => self.handle_scroll_input(raw_delta_y, precise),
            AppCommand::PagePreview { input } => self.handle_page_input(input),
            AppCommand::OutsideClick => self.outside_click(),
            AppCommand::FrontSurfaceChanged { front_surface } => {
                self.front_surface_changed(front_surface)
            }
            AppCommand::Escape => self.escape_pressed(),
            AppCommand::RequestEdit { target_line } => self.begin_edit_at_line(target_line, blocks),
            AppCommand::SaveEdit {
                replacement_markdown,
                replacement_source,
            } => self.save_edit(replacement_markdown, replacement_source),
            AppCommand::CompleteSave {
                success,
                persisted_markdown: _,
                message: _,
            } => self.complete_save(success),
            AppCommand::CancelEdit => self.cancel_edit(),
            AppCommand::ReportRuntimeDiagnostics { diagnostics } => {
                self.report_runtime_diagnostics(diagnostics)
            }
        }
    }

    pub fn observe_hover(
        &mut self,
        at_ms: u64,
        front_surface: FrontSurface,
        hovered_item: Option<HoveredItem>,
        monitor: Option<MonitorMetadata>,
    ) -> Vec<AppEvent> {
        if let Some(monitor) = monitor {
            self.last_monitor = Some(monitor);
        }

        if !front_surface.is_expected_host() {
            self.clear_pending_hover();
            return self.hide_preview(CloseReason::AppSwitch);
        }

        if self.state.editing.phase.is_locked() {
            self.clear_pending_hover();
            return Vec::new();
        }

        let Some(item) = hovered_item else {
            self.clear_pending_hover();
            return Vec::new();
        };

        if !item.document.is_local_markdown_file() {
            self.clear_pending_hover();
            return Vec::new();
        }

        if self.state.visibility.visible
            && self.state.current_document.as_ref() == Some(&item.document)
        {
            self.clear_pending_hover();
            return Vec::new();
        }

        match &self.state.hover.pending {
            Some(pending) if pending.document == item.document => {
                let Some(started_at_ms) = self.state.hover.candidate_started_at_ms else {
                    self.state.hover.candidate_started_at_ms = Some(at_ms);
                    return Vec::new();
                };

                if at_ms.saturating_sub(started_at_ms) < self.state.hover.hover_trigger_ms {
                    return Vec::new();
                }

                let Some(request) =
                    self.build_preview_request(item.document.clone(), item.screen_point.clone())
                else {
                    return Vec::new();
                };

                self.state.current_document = Some(item.document);
                self.state.visibility.visible = true;
                self.state.visibility.last_request = Some(request.clone());
                self.state.interaction_hot = true;
                self.state.last_close_reason = None;
                self.clear_pending_hover();

                vec![AppEvent::PreviewWindowRequested { request }]
            }
            _ => {
                self.state.hover.pending = Some(item);
                self.state.hover.candidate_started_at_ms = Some(at_ms);
                Vec::new()
            }
        }
    }

    pub fn set_interaction_hot(&mut self, hot: bool) {
        self.state.interaction_hot = hot;
        if let Some(request) = &mut self.state.visibility.last_request {
            request.interaction_hot = hot;
        }
    }

    pub fn adjust_width_tier(
        &mut self,
        delta: i8,
        monitor: Option<MonitorMetadata>,
    ) -> Vec<AppEvent> {
        if let Some(monitor) = monitor {
            self.last_monitor = Some(monitor);
        }

        if !self.can_consume_hot_interaction() {
            return Vec::new();
        }

        let current = self.state.selected_width_tier_index as isize;
        let next = MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .clamped_width_tier_index(current + delta as isize);
        if next == self.state.selected_width_tier_index {
            return Vec::new();
        }

        self.state.selected_width_tier_index = next;
        let mut events = vec![AppEvent::WidthTierChanged {
            selected_width_tier_index: next,
            requested_width_px: MACOS_REFERENCE_BEHAVIOR
                .preview_geometry
                .width_px_for_index(next),
        }];

        if let (Some(document), Some(anchor)) =
            (self.state.current_document.clone(), self.last_anchor())
        {
            if let Some(request) = self.build_preview_request(document, anchor) {
                self.state.visibility.last_request = Some(request.clone());
                events.push(AppEvent::PreviewWindowRequested { request });
            }
        }

        events
    }

    pub fn toggle_background_mode(&mut self) -> Vec<AppEvent> {
        if !self.can_consume_hot_interaction() {
            return Vec::new();
        }

        self.state.background_mode = self.state.background_mode.opposite();
        if let Some(request) = &mut self.state.visibility.last_request {
            request.background_mode = self.state.background_mode;
        }

        vec![AppEvent::BackgroundModeChanged {
            background_mode: self.state.background_mode,
        }]
    }

    pub fn handle_scroll_input(&mut self, raw_delta_y: f64, precise: bool) -> Vec<AppEvent> {
        if !self.can_consume_hot_interaction() {
            return Vec::new();
        }

        let delta_y = normalized_scroll_delta(raw_delta_y, precise);
        if delta_y.abs() <= 0.01 {
            return Vec::new();
        }

        self.state.paging.last_scroll_delta_y = Some(delta_y);
        vec![AppEvent::ScrollApplied { delta_y }]
    }

    pub fn handle_page_input(&mut self, input: PageInput) -> Vec<AppEvent> {
        if !self.can_consume_hot_interaction() {
            return Vec::new();
        }

        let motion = sticky_page_motion(input);
        self.state.paging.last_motion = Some(motion.clone());
        vec![AppEvent::PageMotionRequested { motion }]
    }

    pub fn outside_click(&mut self) -> Vec<AppEvent> {
        self.hide_preview(CloseReason::OutsideClick)
    }

    pub fn front_surface_changed(&mut self, front_surface: FrontSurface) -> Vec<AppEvent> {
        if front_surface.is_expected_host() {
            return Vec::new();
        }

        self.hide_preview(CloseReason::AppSwitch)
    }

    pub fn escape_pressed(&mut self) -> Vec<AppEvent> {
        self.hide_preview(CloseReason::Escape)
    }

    pub fn begin_edit_at_line(
        &mut self,
        target_line: u32,
        blocks: &[BlockMapping],
    ) -> Vec<AppEvent> {
        if !self.state.visibility.visible || self.state.editing.phase.is_locked() {
            return Vec::new();
        }

        let Some(block) = find_smallest_matching_block(blocks, target_line) else {
            return Vec::new();
        };

        self.state.editing.phase = EditingPhase::Active;
        self.state.editing.target_start_line = Some(block.start_line);
        self.state.editing.target_end_line = Some(block.end_line);
        self.state.editing.draft_markdown = None;
        self.state.editing.draft_source = None;

        vec![AppEvent::EditSessionChanged {
            editing: self.state.editing.clone(),
        }]
    }

    pub fn save_edit(
        &mut self,
        replacement_markdown: String,
        replacement_source: String,
    ) -> Vec<AppEvent> {
        if self.state.editing.phase != EditingPhase::Active {
            return Vec::new();
        }

        let Some(document) = self.state.current_document.clone() else {
            return Vec::new();
        };

        self.state.editing.phase = EditingPhase::Saving;
        self.state.editing.draft_markdown = Some(replacement_markdown.clone());
        self.state.editing.draft_source = Some(replacement_source);

        vec![AppEvent::MarkdownSaveRequested {
            document,
            replacement_markdown,
        }]
    }

    pub fn complete_save(&mut self, success: bool) -> Vec<AppEvent> {
        if self.state.editing.phase != EditingPhase::Saving {
            return Vec::new();
        }

        if success {
            self.state.editing.phase = EditingPhase::Inactive;
            self.state.editing.target_start_line = None;
            self.state.editing.target_end_line = None;
            self.state.editing.draft_markdown = None;
            self.state.editing.draft_source = None;
        } else {
            self.state.editing.phase = EditingPhase::Active;
        }

        vec![AppEvent::EditSessionChanged {
            editing: self.state.editing.clone(),
        }]
    }

    pub fn cancel_edit(&mut self) -> Vec<AppEvent> {
        if self.state.editing.phase != EditingPhase::Active {
            return Vec::new();
        }

        self.state.editing.phase = EditingPhase::Inactive;
        self.state.editing.target_start_line = None;
        self.state.editing.target_end_line = None;
        self.state.editing.draft_markdown = None;
        self.state.editing.draft_source = None;

        vec![AppEvent::EditSessionChanged {
            editing: self.state.editing.clone(),
        }]
    }

    pub fn report_runtime_diagnostics(
        &mut self,
        diagnostics: Vec<RuntimeDiagnostic>,
    ) -> Vec<AppEvent> {
        if diagnostics.is_empty() {
            return Vec::new();
        }

        vec![AppEvent::RuntimeDiagnosticsReported { diagnostics }]
    }

    fn can_consume_hot_interaction(&self) -> bool {
        self.state.visibility.visible
            && self.state.interaction_hot
            && !self.state.editing.phase.is_locked()
    }

    fn hide_preview(&mut self, reason: CloseReason) -> Vec<AppEvent> {
        if !self.state.visibility.visible || self.state.editing.phase.is_locked() {
            return Vec::new();
        }

        self.state.current_document = None;
        self.state.visibility.visible = false;
        self.state.visibility.last_request = None;
        self.state.interaction_hot = false;
        self.state.last_close_reason = Some(reason);
        self.clear_pending_hover();

        vec![AppEvent::PreviewWindowHidden { reason }]
    }

    fn clear_pending_hover(&mut self) {
        self.state.hover.pending = None;
        self.state.hover.candidate_started_at_ms = None;
    }

    fn build_preview_request(
        &self,
        document: ResolvedDocument,
        anchor: ScreenPoint,
    ) -> Option<PreviewWindowRequest> {
        let monitor = self.last_monitor.as_ref()?;
        let requested_width_px = MACOS_REFERENCE_BEHAVIOR
            .preview_geometry
            .width_px_for_index(self.state.selected_width_tier_index);
        let frame = preview_frame_for_anchor(&anchor, &monitor.visible_frame, requested_width_px);

        Some(PreviewWindowRequest {
            title: document.display_name.clone(),
            document,
            anchor,
            frame,
            selected_width_tier_index: self.state.selected_width_tier_index,
            requested_width_px,
            background_mode: self.state.background_mode,
            interaction_hot: self.state.interaction_hot || !self.state.visibility.visible,
            monitor_id: Some(monitor.id.clone()),
        })
    }

    fn last_anchor(&self) -> Option<ScreenPoint> {
        self.state
            .visibility
            .last_request
            .as_ref()
            .map(|request| request.anchor.clone())
    }

    pub fn editing_block(&self, blocks: &[BlockMapping]) -> Option<BlockMapping> {
        find_block_for_editing_state(blocks, &self.state.editing)
    }
}

pub fn normalized_scroll_delta(raw_delta_y: f64, precise: bool) -> f64 {
    let paging = MACOS_REFERENCE_BEHAVIOR.paging;
    let multiplier = if precise {
        paging.precise_scroll_multiplier
    } else {
        paging.non_precise_scroll_multiplier
    };
    let direction = if paging.scroll_inverts_delta_y {
        -1.0
    } else {
        1.0
    };

    direction * raw_delta_y * multiplier
}

pub fn sticky_page_motion(input: PageInput) -> PagingMotion {
    let paging = MACOS_REFERENCE_BEHAVIOR.paging;
    PagingMotion {
        direction: input.direction(),
        page_fraction: paging.page_fraction,
        overshoot_factor: paging.overshoot_factor,
        max_overshoot_px: paging.max_overshoot_px,
        first_segment_ms: paging.first_segment_ms,
        settle_segment_ms: paging.settle_segment_ms,
    }
}

pub fn select_monitor_for_anchor<'a>(
    monitors: &'a [MonitorMetadata],
    anchor: &ScreenPoint,
) -> Option<&'a MonitorMetadata> {
    monitors
        .iter()
        .min_by(|lhs, rhs| compare_monitors_for_anchor(lhs, rhs, anchor))
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MonitorSelectionMode {
    ContainingVisibleFrame,
    NearestVisibleFrameFallback,
}

impl MonitorSelectionMode {
    pub fn label(self) -> &'static str {
        match self {
            Self::ContainingVisibleFrame => "containing visible frame",
            Self::NearestVisibleFrameFallback => "nearest visible frame fallback",
        }
    }
}

pub fn monitor_selection_mode(
    selected_monitor: &MonitorMetadata,
    anchor: &ScreenPoint,
) -> MonitorSelectionMode {
    if selected_monitor.contains_point_in_visible_frame(anchor) {
        MonitorSelectionMode::ContainingVisibleFrame
    } else {
        MonitorSelectionMode::NearestVisibleFrameFallback
    }
}

pub fn selected_monitor_matches_reference(
    monitors: &[MonitorMetadata],
    anchor: &ScreenPoint,
    selected_monitor: &MonitorMetadata,
) -> bool {
    select_monitor_for_anchor(monitors, anchor)
        .map(|expected| expected == selected_monitor)
        .unwrap_or(false)
}

pub fn shared_core_preview_feature_coverage() -> &'static [MacOsPreviewFeature] {
    &[
        MacOsPreviewFeature::FrontmostFileManagerGating,
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
        MacOsPreviewFeature::EditSaveCancelAndLock,
        MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape,
    ]
}

const SHARED_CORE_PREVIEW_FEATURE_COVERAGE_RECORDS: [PreviewFeatureCoverageRecord; 14] = [
    PreviewFeatureCoverageRecord::new(
        MacOsPreviewFeature::FrontmostFileManagerGating,
        PreviewFeatureCoverageLane::SharedCore,
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
        PreviewFeatureCoverageLane::SharedCore,
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
        MacOsPreviewFeature::EditSaveCancelAndLock,
        PreviewFeatureCoverageLane::SharedCore,
    ),
    PreviewFeatureCoverageRecord::new(
        MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape,
        PreviewFeatureCoverageLane::SharedCore,
    ),
];

pub fn shared_core_preview_feature_coverage_records() -> &'static [PreviewFeatureCoverageRecord] {
    &SHARED_CORE_PREVIEW_FEATURE_COVERAGE_RECORDS
}

pub fn shared_core_hint_chip_contract(state: &PreviewState) -> HintChipContract {
    state.hint_chip_contract()
}

fn compare_monitors_for_anchor(
    lhs: &MonitorMetadata,
    rhs: &MonitorMetadata,
    anchor: &ScreenPoint,
) -> Ordering {
    let lhs_contains = lhs.contains_point_in_visible_frame(anchor);
    let rhs_contains = rhs.contains_point_in_visible_frame(anchor);
    if lhs_contains != rhs_contains {
        return if lhs_contains {
            Ordering::Less
        } else {
            Ordering::Greater
        };
    }

    let lhs_distance = lhs.distance_squared_to_visible_frame(anchor);
    let rhs_distance = rhs.distance_squared_to_visible_frame(anchor);
    match lhs_distance
        .partial_cmp(&rhs_distance)
        .unwrap_or(Ordering::Equal)
    {
        Ordering::Equal => {}
        ordering => return ordering,
    }

    if lhs.is_primary != rhs.is_primary {
        return if lhs.is_primary {
            Ordering::Less
        } else {
            Ordering::Greater
        };
    }

    lhs.id.cmp(&rhs.id)
}

pub fn preview_frame_for_anchor(
    anchor: &ScreenPoint,
    visible_frame: &ScreenRect,
    requested_width_px: u32,
) -> ScreenRect {
    let geometry = MACOS_REFERENCE_BEHAVIOR.preview_geometry;
    let aspect_ratio = geometry.aspect_ratio_value();
    let edge_inset = geometry.edge_inset_px as f64;
    let pointer_offset = geometry.pointer_offset_px as f64;
    let min_available_width = geometry.min_available_width_px as f64;
    let min_available_height = geometry.min_available_height_px as f64;
    let available_width = (visible_frame.width - edge_inset * 2.0).max(min_available_width);
    let available_height = (visible_frame.height - edge_inset * 2.0).max(min_available_height);
    let max_fit_width = available_width.min(available_height * aspect_ratio);
    let max_fit_height = max_fit_width / aspect_ratio;

    let requested_width = requested_width_px as f64;
    let requested_height = requested_width / aspect_ratio;
    let width = requested_width.min(max_fit_width);
    let height = requested_height.min(max_fit_height);

    let min_x = visible_frame.min_x() + edge_inset;
    let max_x = visible_frame.max_x() - width - edge_inset;
    let min_y = visible_frame.min_y() + edge_inset;
    let max_y = visible_frame.max_y() - height - edge_inset;

    let mut origin_x = anchor.x + pointer_offset;
    let mut origin_y = anchor.y - height - pointer_offset;

    if origin_x > max_x {
        origin_x = anchor.x - width - pointer_offset;
    }
    if origin_x < min_x {
        origin_x = min_x;
    }
    if origin_x > max_x {
        origin_x = max_x;
    }

    if origin_y < min_y {
        origin_y = anchor.y + pointer_offset;
    }
    if origin_y > max_y {
        origin_y = max_y;
    }
    if origin_y < min_y {
        origin_y = min_y;
    }

    ScreenRect::new(origin_x, origin_y, width, height)
}

#[cfg(test)]
mod tests {
    use super::*;
    use fastmd_contracts::{
        preview_feature_gaps_against_reference, AppCommand, BackgroundMode, DocumentKind,
        DocumentOrigin, DocumentPath, EditingPhase, FrontSurfaceIdentity, FrontSurfaceKind,
        MacOsPreviewFeature, PageDirection, PlatformId, PreviewFeatureCoverageLane,
    };
    use fastmd_render::BlockKind;
    use std::collections::BTreeSet;

    fn finder_surface(expected_host: bool, native_window_id: &str) -> FrontSurface {
        FrontSurface {
            platform_id: PlatformId::MacosFinder,
            surface_kind: FrontSurfaceKind::FinderListView,
            app_identifier: "com.apple.finder".to_string(),
            window_title: Some("Docs".to_string()),
            directory: Some(DocumentPath::from("/Users/example/Docs")),
            stable_identity: Some(
                FrontSurfaceIdentity::new(native_window_id).with_process_id(7_001),
            ),
            expected_host,
        }
    }

    fn explorer_surface(expected_host: bool, native_window_id: &str) -> FrontSurface {
        FrontSurface {
            platform_id: PlatformId::WindowsExplorer,
            surface_kind: FrontSurfaceKind::ExplorerListView,
            app_identifier: "explorer.exe".to_string(),
            window_title: Some("Docs".to_string()),
            directory: Some(DocumentPath::from(r"C:\Users\example\Docs")),
            stable_identity: if expected_host {
                Some(FrontSurfaceIdentity::new(native_window_id).with_process_id(4_012))
            } else {
                None
            },
            expected_host,
        }
    }

    fn monitor() -> MonitorMetadata {
        MonitorMetadata {
            id: "display-main".to_string(),
            name: Some("Studio Display".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 3024.0, 1964.0),
            visible_frame: ScreenRect::new(0.0, 25.0, 3024.0, 1910.0),
            scale_factor: 2.0,
            is_primary: true,
        }
    }

    fn resolved_markdown(path: &str) -> ResolvedDocument {
        ResolvedDocument::new(
            path,
            path.rsplit('/').next().unwrap_or(path),
            DocumentOrigin::LocalFileSystem,
            DocumentKind::File,
        )
    }

    fn hovered_markdown(path: &str, x: f64, y: f64) -> HoveredItem {
        HoveredItem {
            document: resolved_markdown(path),
            screen_point: ScreenPoint::new(x, y),
            element_description: "Finder row subtree direct path".to_string(),
        }
    }

    fn hovered_non_markdown() -> HoveredItem {
        HoveredItem {
            document: ResolvedDocument::new(
                "/Users/example/Docs/spec.txt",
                "spec.txt",
                DocumentOrigin::LocalFileSystem,
                DocumentKind::File,
            ),
            screen_point: ScreenPoint::new(240.0, 620.0),
            element_description: "Finder row subtree direct path".to_string(),
        }
    }

    fn hovered_directory() -> HoveredItem {
        HoveredItem {
            document: ResolvedDocument::new(
                "/Users/example/Docs/spec.md",
                "spec.md",
                DocumentOrigin::LocalFileSystem,
                DocumentKind::Directory,
            ),
            screen_point: ScreenPoint::new(240.0, 620.0),
            element_description: "Finder row subtree direct path".to_string(),
        }
    }

    fn hovered_relative_markdown() -> HoveredItem {
        HoveredItem {
            document: ResolvedDocument::new(
                "spec.md",
                "spec.md",
                DocumentOrigin::LocalFileSystem,
                DocumentKind::File,
            ),
            screen_point: ScreenPoint::new(240.0, 620.0),
            element_description: "Finder row subtree direct path".to_string(),
        }
    }

    fn block_mappings() -> Vec<BlockMapping> {
        vec![
            BlockMapping {
                block_id: 0,
                kind: BlockKind::Paragraph,
                start_line: 0,
                end_line: 8,
            },
            BlockMapping {
                block_id: 1,
                kind: BlockKind::Blockquote,
                start_line: 2,
                end_line: 6,
            },
            BlockMapping {
                block_id: 2,
                kind: BlockKind::Paragraph,
                start_line: 3,
                end_line: 5,
            },
        ]
    }

    #[test]
    fn hover_requires_one_second_before_preview_opens() {
        let mut engine = CoreEngine::new();

        assert!(engine
            .observe_hover(
                0,
                finder_surface(true, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
                Some(monitor()),
            )
            .is_empty());
        assert!(!engine.state().visibility.visible);

        assert!(engine
            .observe_hover(
                999,
                finder_surface(true, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
                None,
            )
            .is_empty());

        let events = engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(events.len(), 1);
        assert!(engine.state().visibility.visible);
        assert_eq!(engine.state().selected_width_tier_index, 0);
        match &events[0] {
            AppEvent::PreviewWindowRequested { request } => {
                let expected_aspect_ratio = MACOS_REFERENCE_BEHAVIOR
                    .preview_geometry
                    .aspect_ratio_value();
                assert_eq!(request.title, "a.md");
                assert_eq!(request.requested_width_px, 560);
                assert!(
                    (request.frame.width / request.frame.height - expected_aspect_ratio).abs()
                        < 0.0001
                );
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn shared_core_hover_open_semantics_apply_to_windows_explorer_surfaces() {
        let mut engine = CoreEngine::new();

        assert!(engine
            .observe_hover(
                0,
                explorer_surface(true, "hwnd:0x10001"),
                Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
                Some(monitor()),
            )
            .is_empty());

        let events = engine.observe_hover(
            1_000,
            explorer_surface(true, "hwnd:0x10001"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(events.len(), 1);
        assert!(engine.state().visibility.visible);
        assert_eq!(
            engine
                .state()
                .current_document
                .as_ref()
                .map(|document| document.display_name.as_str()),
            Some("a.md")
        );
    }

    #[test]
    fn shared_core_preview_feature_coverage_stays_locked_to_macos_semantics() {
        let features: BTreeSet<_> = shared_core_preview_feature_coverage()
            .iter()
            .copied()
            .collect();

        assert_eq!(features.len(), 14);
        assert!(features.contains(&MacOsPreviewFeature::FrontmostFileManagerGating));
        assert!(features.contains(&MacOsPreviewFeature::HoverOpensAfterOneSecond));
        assert!(features.contains(&MacOsPreviewFeature::WidthTierModel));
        assert!(features.contains(&MacOsPreviewFeature::CompactHintChipChrome));
        assert!(features.contains(&MacOsPreviewFeature::EditSaveCancelAndLock));
        assert!(features.contains(&MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape));
    }

    #[test]
    fn shared_core_preview_feature_coverage_only_leaves_render_and_host_boundary_items() {
        let gaps: BTreeSet<_> =
            preview_feature_gaps_against_reference(&[shared_core_preview_feature_coverage()])
                .into_iter()
                .collect();
        let expected: BTreeSet<_> = [
            MacOsPreviewFeature::ExactHoveredMarkdownResolution,
            MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
            MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
            MacOsPreviewFeature::InlineBlockEditEntryAndSourceMapping,
            MacOsPreviewFeature::MarkdownRenderingSurface,
            MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
        ]
        .into_iter()
        .collect();

        assert_eq!(gaps, expected);
    }

    #[test]
    fn shared_core_preview_feature_coverage_records_stay_tagged_to_the_core_lane() {
        let records = shared_core_preview_feature_coverage_records();
        let recorded_features: BTreeSet<_> = records.iter().map(|record| record.feature).collect();
        let plain_features: BTreeSet<_> = shared_core_preview_feature_coverage()
            .iter()
            .copied()
            .collect();

        assert_eq!(records.len(), 14);
        assert_eq!(recorded_features, plain_features);
        assert!(records
            .iter()
            .all(|record| { record.lane == PreviewFeatureCoverageLane::SharedCore }));
        assert!(records
            .iter()
            .any(|record| { record.feature == MacOsPreviewFeature::HoverOpensAfterOneSecond }));
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::ClosePolicyOutsideClickAppSwitchEscape
        }));
    }

    #[test]
    fn different_hovered_markdown_replaces_current_preview_after_pause() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert!(engine
            .observe_hover(
                1_500,
                finder_surface(true, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/b.md", 220.0, 700.0)),
                None,
            )
            .is_empty());

        let events = engine.observe_hover(
            2_500,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/b.md", 220.0, 700.0)),
            None,
        );

        assert_eq!(
            engine
                .state()
                .current_document
                .as_ref()
                .map(|doc| doc.display_name.as_str()),
            Some("b.md")
        );
        assert_eq!(events.len(), 1);
    }

    #[test]
    fn same_item_does_not_reopen_while_stationary() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        let repeated = engine.observe_hover(
            4_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert!(repeated.is_empty());
    }

    #[test]
    fn frontmost_file_manager_gating_and_local_md_only_acceptance_are_enforced() {
        let mut engine = CoreEngine::new();

        assert!(engine
            .observe_hover(
                0,
                finder_surface(false, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
                Some(monitor()),
            )
            .is_empty());
        assert!(!engine.state().visibility.visible);

        assert!(engine
            .observe_hover(
                0,
                finder_surface(true, "finder-window-1"),
                Some(hovered_non_markdown()),
                Some(monitor())
            )
            .is_empty());
        assert!(engine
            .observe_hover(
                0,
                finder_surface(true, "finder-window-1"),
                Some(hovered_directory()),
                Some(monitor())
            )
            .is_empty());
        assert!(engine
            .observe_hover(
                0,
                finder_surface(true, "finder-window-1"),
                Some(hovered_relative_markdown()),
                Some(monitor())
            )
            .is_empty());

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        let hidden = engine.front_surface_changed(finder_surface(false, "finder-window-1"));
        assert_eq!(
            hidden,
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::AppSwitch,
            }]
        );
    }

    #[test]
    fn shared_core_keeps_preview_open_while_the_expected_host_remains_frontmost() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        let unchanged = engine.front_surface_changed(finder_surface(true, "finder-window-2"));

        assert!(unchanged.is_empty());
        assert!(engine.state().visibility.visible);
    }

    #[test]
    fn preview_frame_uses_four_tiers_four_by_three_and_repositions_before_shrinking() {
        let wide_visible_frame = ScreenRect::new(0.0, 25.0, 2_200.0, 1_200.0);
        let frame =
            preview_frame_for_anchor(&ScreenPoint::new(2_150.0, 600.0), &wide_visible_frame, 960);
        assert_eq!(frame.width, 960.0);
        assert_eq!(frame.height, 720.0);
        assert!(frame.x < 2_150.0);

        let cramped_visible_frame = ScreenRect::new(0.0, 25.0, 1_000.0, 800.0);
        let cramped = preview_frame_for_anchor(
            &ScreenPoint::new(500.0, 400.0),
            &cramped_visible_frame,
            1_920,
        );
        assert!(cramped.width < 1_920.0);
        assert!(
            (cramped.width / cramped.height
                - MACOS_REFERENCE_BEHAVIOR
                    .preview_geometry
                    .aspect_ratio_value())
            .abs()
                < 0.0001
        );
    }

    #[test]
    fn monitor_selection_prefers_the_work_area_containing_the_pointer() {
        let left = MonitorMetadata {
            id: "display-left".to_string(),
            name: Some("Left".to_string()),
            frame: ScreenRect::new(-1_920.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(-1_920.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: false,
        };
        let right = MonitorMetadata {
            id: "display-right".to_string(),
            name: Some("Right".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: true,
        };
        let monitors = [right.clone(), left.clone()];
        let selected = select_monitor_for_anchor(&monitors, &ScreenPoint::new(-240.0, 640.0))
            .expect("left monitor should contain the anchor");

        assert_eq!(selected.id, left.id);
    }

    #[test]
    fn monitor_selection_falls_back_to_the_nearest_work_area() {
        let left = MonitorMetadata {
            id: "display-left".to_string(),
            name: Some("Left".to_string()),
            frame: ScreenRect::new(-1_920.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(-1_920.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: false,
        };
        let right = MonitorMetadata {
            id: "display-right".to_string(),
            name: Some("Right".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: true,
        };
        let monitors = [left.clone(), right.clone()];

        let left_fallback = select_monitor_for_anchor(&monitors, &ScreenPoint::new(-10.0, 10.0))
            .expect("the nearest visible frame should be selected");
        assert_eq!(left_fallback.id, left.id);

        let right_fallback = select_monitor_for_anchor(&monitors, &ScreenPoint::new(10.0, 10.0))
            .expect("the nearest visible frame should be selected");
        assert_eq!(right_fallback.id, right.id);
    }

    #[test]
    fn monitor_selection_mode_reports_containing_vs_fallback_paths() {
        let right = MonitorMetadata {
            id: "display-right".to_string(),
            name: Some("Right".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: true,
        };

        assert_eq!(
            monitor_selection_mode(&right, &ScreenPoint::new(240.0, 640.0)),
            MonitorSelectionMode::ContainingVisibleFrame
        );
        assert_eq!(
            monitor_selection_mode(&right, &ScreenPoint::new(-10.0, 10.0)),
            MonitorSelectionMode::NearestVisibleFrameFallback
        );
        assert_eq!(
            MonitorSelectionMode::ContainingVisibleFrame.label(),
            "containing visible frame"
        );
        assert_eq!(
            MonitorSelectionMode::NearestVisibleFrameFallback.label(),
            "nearest visible frame fallback"
        );
    }

    #[test]
    fn selected_monitor_match_validation_reuses_shared_core_selection_rule() {
        let left = MonitorMetadata {
            id: "display-left".to_string(),
            name: Some("Left".to_string()),
            frame: ScreenRect::new(-1_920.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(-1_920.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: false,
        };
        let right = MonitorMetadata {
            id: "display-right".to_string(),
            name: Some("Right".to_string()),
            frame: ScreenRect::new(0.0, 0.0, 1_920.0, 1_080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1_920.0, 1_040.0),
            scale_factor: 1.0,
            is_primary: true,
        };
        let monitors = [left.clone(), right.clone()];
        let cursor = ScreenPoint::new(-240.0, 640.0);

        assert!(selected_monitor_matches_reference(
            &monitors, &cursor, &left
        ));
        assert!(!selected_monitor_matches_reference(
            &monitors, &cursor, &right
        ));
    }

    #[test]
    fn width_changes_background_toggles_and_hot_surface_gating_match_reference() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        engine.set_interaction_hot(false);
        assert!(engine.adjust_width_tier(1, None).is_empty());
        assert!(engine.toggle_background_mode().is_empty());

        engine.set_interaction_hot(true);
        let width_events = engine.adjust_width_tier(1, None);
        assert_eq!(engine.state().selected_width_tier_index, 1);
        assert_eq!(
            width_events[0],
            AppEvent::WidthTierChanged {
                selected_width_tier_index: 1,
                requested_width_px: 960,
            }
        );

        let background_events = engine.toggle_background_mode();
        assert_eq!(engine.state().background_mode, BackgroundMode::Black);
        assert_eq!(
            background_events,
            vec![AppEvent::BackgroundModeChanged {
                background_mode: BackgroundMode::Black,
            }]
        );
    }

    #[test]
    fn shared_core_hint_chip_contract_tracks_selected_width_tier_and_macos_copy() {
        let mut engine = CoreEngine::new();

        assert_eq!(
            shared_core_hint_chip_contract(engine.state()).width_label,
            "← 1/4 →"
        );
        assert_eq!(
            shared_core_hint_chip_contract(engine.state()).background_label,
            "Tab"
        );
        assert_eq!(
            shared_core_hint_chip_contract(engine.state()).paging_label,
            "(⇧+) Space"
        );

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );
        engine.set_interaction_hot(true);
        let width_events = engine.adjust_width_tier(2, None);

        assert!(matches!(
            width_events.as_slice(),
            [
                AppEvent::WidthTierChanged {
                    selected_width_tier_index: 2,
                    requested_width_px: 1_440,
                },
                AppEvent::PreviewWindowRequested { .. }
            ]
        ));
        assert_eq!(
            shared_core_hint_chip_contract(engine.state()).width_label,
            "← 3/4 →"
        );
    }

    #[test]
    fn windows_reference_preview_opens_hot_and_accepts_keyboard_and_scroll_without_rehover() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            explorer_surface(true, "hwnd:0x10001"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        let opened = engine.observe_hover(
            1_000,
            explorer_surface(true, "hwnd:0x10001"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert!(matches!(
            opened.as_slice(),
            [AppEvent::PreviewWindowRequested { .. }]
        ));
        assert!(engine.state().interaction_hot);

        assert_eq!(
            engine.dispatch_command(AppCommand::ToggleBackgroundMode, &[]),
            vec![AppEvent::BackgroundModeChanged {
                background_mode: BackgroundMode::Black,
            }]
        );
        assert_eq!(
            engine.dispatch_command(
                AppCommand::ScrollPreview {
                    raw_delta_y: -8.4,
                    precise: false,
                },
                &[],
            ),
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );

        let paging = engine.dispatch_command(
            AppCommand::PagePreview {
                input: PageInput::PageDown,
            },
            &[],
        );
        match paging.as_slice() {
            [AppEvent::PageMotionRequested { motion }] => {
                assert_eq!(motion.direction, PageDirection::Forward);
                assert_eq!(motion.page_fraction, 0.92);
                assert_eq!(motion.overshoot_factor, 0.06);
                assert_eq!(motion.max_overshoot_px, 34.0);
                assert_eq!(motion.first_segment_ms, 520);
                assert_eq!(motion.settle_segment_ms, 180);
            }
            other => panic!("unexpected paging events: {other:?}"),
        }
    }

    #[test]
    fn app_command_dispatch_routes_shared_width_paging_and_close_contracts() {
        let mut engine = CoreEngine::new();

        let initial_hover = AppCommand::ObserveHover {
            at_ms: 0,
            front_surface: finder_surface(true, "finder-window-1"),
            hovered_item: Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            monitor: Some(monitor()),
        };
        let committed_hover = AppCommand::ObserveHover {
            at_ms: 1_000,
            front_surface: finder_surface(true, "finder-window-1"),
            hovered_item: Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            monitor: None,
        };

        assert!(engine.dispatch_command(initial_hover, &[]).is_empty());
        let opened = engine.dispatch_command(committed_hover, &[]);
        assert!(matches!(
            opened.as_slice(),
            [AppEvent::PreviewWindowRequested { .. }]
        ));

        engine.dispatch_command(AppCommand::SetInteractionHot { hot: false }, &[]);
        assert!(engine
            .dispatch_command(
                AppCommand::AdjustWidthTier {
                    delta: 1,
                    monitor: None,
                },
                &[],
            )
            .is_empty());

        engine.dispatch_command(AppCommand::SetInteractionHot { hot: true }, &[]);
        let width_events = engine.dispatch_command(
            AppCommand::AdjustWidthTier {
                delta: 1,
                monitor: None,
            },
            &[],
        );
        assert_eq!(
            width_events[0],
            AppEvent::WidthTierChanged {
                selected_width_tier_index: 1,
                requested_width_px: 960,
            }
        );
        assert!(matches!(
            width_events[1],
            AppEvent::PreviewWindowRequested { .. }
        ));

        assert_eq!(
            engine.dispatch_command(AppCommand::ToggleBackgroundMode, &[]),
            vec![AppEvent::BackgroundModeChanged {
                background_mode: BackgroundMode::Black,
            }]
        );
        assert_eq!(
            engine.dispatch_command(
                AppCommand::ScrollPreview {
                    raw_delta_y: -84.0,
                    precise: true,
                },
                &[],
            ),
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );

        let paging = engine.dispatch_command(
            AppCommand::PagePreview {
                input: PageInput::PageDown,
            },
            &[],
        );
        match paging.as_slice() {
            [AppEvent::PageMotionRequested { motion }] => {
                assert_eq!(motion.direction, PageDirection::Forward);
                assert_eq!(motion.page_fraction, 0.92);
                assert_eq!(motion.overshoot_factor, 0.06);
                assert_eq!(motion.max_overshoot_px, 34.0);
                assert_eq!(motion.first_segment_ms, 520);
                assert_eq!(motion.settle_segment_ms, 180);
            }
            other => panic!("unexpected paging events: {other:?}"),
        }

        assert_eq!(
            engine.dispatch_command(AppCommand::Escape, &[]),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
    }

    #[test]
    fn scroll_and_paging_match_current_macos_motion_constants() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );
        engine.set_interaction_hot(true);

        let precise_scroll = engine.handle_scroll_input(-84.0, true);
        assert_eq!(
            precise_scroll,
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );

        let wheel_scroll = engine.handle_scroll_input(-8.4, false);
        assert_eq!(
            wheel_scroll,
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );

        let page_events = engine.handle_page_input(PageInput::Space);
        match &page_events[0] {
            AppEvent::PageMotionRequested { motion } => {
                assert_eq!(motion.direction, fastmd_contracts::PageDirection::Forward);
                assert_eq!(
                    motion.page_fraction,
                    MACOS_REFERENCE_BEHAVIOR.paging.page_fraction
                );
                assert_eq!(
                    motion.overshoot_factor,
                    MACOS_REFERENCE_BEHAVIOR.paging.overshoot_factor
                );
                assert_eq!(
                    motion.max_overshoot_px,
                    MACOS_REFERENCE_BEHAVIOR.paging.max_overshoot_px
                );
                assert_eq!(
                    motion.first_segment_ms,
                    MACOS_REFERENCE_BEHAVIOR.paging.first_segment_ms
                );
                assert_eq!(
                    motion.settle_segment_ms,
                    MACOS_REFERENCE_BEHAVIOR.paging.settle_segment_ms
                );
            }
            other => panic!("unexpected event: {other:?}"),
        }

        let backward = engine.handle_page_input(PageInput::ShiftSpace);
        match &backward[0] {
            AppEvent::PageMotionRequested { motion } => {
                assert_eq!(motion.direction, fastmd_contracts::PageDirection::Backward);
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn macos_reference_edit_mode_lock_blocks_replacement_and_dismissal_until_unlocked() {
        let mut engine = CoreEngine::new();

        assert!(MACOS_REFERENCE_BEHAVIOR
            .edit_mode
            .blocks_preview_replacement());
        assert!(MACOS_REFERENCE_BEHAVIOR
            .edit_mode
            .blocks_preview_dismissal());

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        let edit_events = engine.begin_edit_at_line(4, &block_mappings());
        assert_eq!(edit_events.len(), 1);
        assert_eq!(engine.state().editing.phase, EditingPhase::Active);

        let replacement_attempt = engine.observe_hover(
            4_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/b.md", 220.0, 740.0)),
            None,
        );
        assert!(replacement_attempt.is_empty());
        assert_eq!(
            engine
                .state()
                .current_document
                .as_ref()
                .map(|document| document.display_name.as_str()),
            Some("a.md")
        );

        assert!(engine.outside_click().is_empty());
        assert!(engine
            .front_surface_changed(finder_surface(false, "finder-window-1"))
            .is_empty());
        assert!(engine.escape_pressed().is_empty());
        assert!(engine.state().visibility.visible);

        let cancel_events = engine.cancel_edit();
        assert_eq!(cancel_events.len(), 1);
        assert_eq!(engine.state().editing.phase, EditingPhase::Inactive);

        assert_eq!(
            engine.escape_pressed(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
    }

    #[test]
    fn macos_reference_close_policy_matches_preview_panel_behavior_when_not_editing() {
        let mut engine = CoreEngine::new();

        assert!(MACOS_REFERENCE_BEHAVIOR
            .close_policy
            .allows_non_forced_close(CloseReason::OutsideClick));
        assert!(MACOS_REFERENCE_BEHAVIOR
            .close_policy
            .allows_non_forced_close(CloseReason::AppSwitch));
        assert!(MACOS_REFERENCE_BEHAVIOR
            .close_policy
            .allows_non_forced_close(CloseReason::Escape));

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(
            engine.outside_click(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::OutsideClick,
            }]
        );
        assert_eq!(
            engine.state().last_close_reason,
            Some(CloseReason::OutsideClick)
        );

        engine.observe_hover(
            2_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            3_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(
            engine.front_surface_changed(finder_surface(false, "finder-window-1")),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::AppSwitch,
            }]
        );
        assert_eq!(
            engine.state().last_close_reason,
            Some(CloseReason::AppSwitch)
        );

        engine.observe_hover(
            4_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            5_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(
            engine.escape_pressed(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
        assert_eq!(engine.state().last_close_reason, Some(CloseReason::Escape));
    }

    #[test]
    fn close_policies_follow_outside_click_app_switch_and_escape_unless_edit_locked() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        assert_eq!(
            engine.outside_click(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::OutsideClick,
            }]
        );

        engine.observe_hover(
            2_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            3_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        engine.begin_edit_at_line(4, &block_mappings());
        assert!(engine.outside_click().is_empty());
        assert!(engine
            .front_surface_changed(finder_surface(false, "finder-window-1"))
            .is_empty());
        assert!(engine.escape_pressed().is_empty());

        engine.cancel_edit();
        assert_eq!(
            engine.escape_pressed(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
    }

    #[test]
    fn edit_mode_selects_smallest_block_and_save_cancel_semantics_lock_replacement() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        let edit_events = engine.begin_edit_at_line(4, &block_mappings());
        match &edit_events[0] {
            AppEvent::EditSessionChanged { editing } => {
                assert_eq!(editing.phase, EditingPhase::Active);
                assert_eq!(editing.target_start_line, Some(3));
                assert_eq!(editing.target_end_line, Some(5));
            }
            other => panic!("unexpected event: {other:?}"),
        }

        assert!(engine
            .observe_hover(
                4_000,
                finder_surface(true, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/b.md", 220.0, 740.0)),
                None,
            )
            .is_empty());

        let save_requested =
            engine.save_edit("updated markdown".to_string(), "updated block".to_string());
        match &save_requested[0] {
            AppEvent::MarkdownSaveRequested {
                document,
                replacement_markdown,
            } => {
                assert_eq!(document.display_name, "a.md");
                assert_eq!(replacement_markdown, "updated markdown");
            }
            other => panic!("unexpected event: {other:?}"),
        }
        assert_eq!(engine.state().editing.phase, EditingPhase::Saving);
        assert!(engine.cancel_edit().is_empty());

        let failed_save = engine.complete_save(false);
        match &failed_save[0] {
            AppEvent::EditSessionChanged { editing } => {
                assert_eq!(editing.phase, EditingPhase::Active);
                assert_eq!(editing.draft_markdown.as_deref(), Some("updated markdown"));
                assert_eq!(editing.draft_source.as_deref(), Some("updated block"));
            }
            other => panic!("unexpected event: {other:?}"),
        }

        let canceled = engine.cancel_edit();
        match &canceled[0] {
            AppEvent::EditSessionChanged { editing } => {
                assert_eq!(editing.phase, EditingPhase::Inactive);
            }
            other => panic!("unexpected event: {other:?}"),
        }

        engine.begin_edit_at_line(4, &block_mappings());
        engine.save_edit("final markdown".to_string(), "final block".to_string());
        let completed = engine.complete_save(true);
        match &completed[0] {
            AppEvent::EditSessionChanged { editing } => {
                assert_eq!(editing.phase, EditingPhase::Inactive);
                assert_eq!(editing.draft_markdown, None);
                assert_eq!(editing.draft_source, None);
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn saving_edit_mode_keeps_preview_locked_until_the_save_completes() {
        let mut engine = CoreEngine::new();

        engine.observe_hover(
            0,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            Some(monitor()),
        );
        engine.observe_hover(
            1_000,
            finder_surface(true, "finder-window-1"),
            Some(hovered_markdown("/Users/example/Docs/a.md", 180.0, 780.0)),
            None,
        );

        engine.begin_edit_at_line(4, &block_mappings());
        engine.save_edit("updated markdown".to_string(), "updated block".to_string());
        assert_eq!(engine.state().editing.phase, EditingPhase::Saving);
        assert_eq!(
            engine.state().editing.draft_source.as_deref(),
            Some("updated block")
        );
        assert_eq!(
            engine
                .editing_block(&block_mappings())
                .map(|block| block.block_id),
            Some(2)
        );

        assert!(engine
            .observe_hover(
                4_000,
                finder_surface(true, "finder-window-1"),
                Some(hovered_markdown("/Users/example/Docs/b.md", 220.0, 740.0)),
                None,
            )
            .is_empty());
        assert!(engine.outside_click().is_empty());
        assert!(engine
            .front_surface_changed(finder_surface(false, "finder-window-1"))
            .is_empty());
        assert!(engine.escape_pressed().is_empty());

        let completed = engine.complete_save(true);
        assert!(matches!(
            completed.as_slice(),
            [AppEvent::EditSessionChanged { .. }]
        ));
        assert_eq!(
            engine.escape_pressed(),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
    }

    #[test]
    fn runtime_diagnostics_flow_through_the_shared_command_event_bridge() {
        let mut engine = CoreEngine::new();
        let diagnostics = vec![RuntimeDiagnostic::new(
            fastmd_contracts::PlatformId::WindowsExplorer,
            fastmd_contracts::RuntimeDiagnosticLevel::Info,
            fastmd_contracts::RuntimeDiagnosticCategory::FrontmostGating,
            "Explorer frontmost gating accepted the foreground surface",
        )
        .at_ms(1_500)
        .with_detail("window_class", "CabinetWClass")];

        assert_eq!(
            engine.dispatch_command(
                AppCommand::ReportRuntimeDiagnostics {
                    diagnostics: diagnostics.clone(),
                },
                &[],
            ),
            vec![AppEvent::RuntimeDiagnosticsReported { diagnostics }]
        );
    }
}
