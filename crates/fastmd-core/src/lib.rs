use std::cmp::Ordering;

use fastmd_contracts::{
    AppEvent, CloseReason, EditingPhase, FrontSurface, HoveredItem, MonitorMetadata, PageInput,
    PagingMotion, PreviewState, PreviewWindowRequest, ResolvedDocument, ScreenPoint, ScreenRect,
    MACOS_REFERENCE_BEHAVIOR,
};
use fastmd_render::{find_smallest_matching_block, BlockMapping};

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

        vec![AppEvent::EditSessionChanged {
            editing: self.state.editing.clone(),
        }]
    }

    pub fn save_edit(&mut self, replacement_markdown: String) -> Vec<AppEvent> {
        if self.state.editing.phase != EditingPhase::Active {
            return Vec::new();
        }

        let Some(document) = self.state.current_document.clone() else {
            return Vec::new();
        };

        self.state.editing.phase = EditingPhase::Saving;
        self.state.editing.draft_markdown = Some(replacement_markdown.clone());

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

        vec![AppEvent::EditSessionChanged {
            editing: self.state.editing.clone(),
        }]
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
        BackgroundMode, DocumentKind, DocumentOrigin, DocumentPath, EditingPhase,
        FrontSurfaceIdentity, FrontSurfaceKind, PlatformId,
    };
    use fastmd_render::BlockKind;

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
        let selected = select_monitor_for_anchor(
            &[right.clone(), left.clone()],
            &ScreenPoint::new(-240.0, 640.0),
        )
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

        let save_requested = engine.save_edit("updated markdown".to_string());
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
        engine.save_edit("final markdown".to_string());
        let completed = engine.complete_save(true);
        match &completed[0] {
            AppEvent::EditSessionChanged { editing } => {
                assert_eq!(editing.phase, EditingPhase::Inactive);
                assert_eq!(editing.draft_markdown, None);
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }
}
