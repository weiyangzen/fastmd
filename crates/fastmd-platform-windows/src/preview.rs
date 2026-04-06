use std::fmt;

use fastmd_contracts::{
    AppEvent, DocumentKind, DocumentOrigin, HoverResolutionScope, HoveredItem, PreviewState,
    ResolvedDocument, ScreenPoint,
};
use fastmd_core::CoreEngine;

use crate::{
    AcceptedMarkdownPath, AdapterError, CoordinateProbeError, ExplorerAdapter, FrontmostProbeError,
    FrontmostSurfaceProbe, HoverProbeError, HoveredItemProbeOutcome, WindowsCoordinateTranslation,
};

/// Windows-specific preview loop wiring that feeds Explorer host signals into
/// the shared FastMD core without changing product semantics.
#[derive(Debug, Default)]
pub struct WindowsPreviewLoop {
    adapter: ExplorerAdapter,
    engine: CoreEngine,
}

/// Errors surfaced while translating Windows host probes into shared-core
/// preview events.
#[derive(Debug)]
pub enum PreviewLoopError {
    Adapter(AdapterError),
    FrontmostProbe(FrontmostProbeError),
    HoverProbe(HoverProbeError),
    CoordinateProbe(CoordinateProbeError),
    MissingRequiredProbeOutput { probe: &'static str },
}

impl fmt::Display for PreviewLoopError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Adapter(error) => write!(f, "{error}"),
            Self::FrontmostProbe(error) => write!(f, "{error}"),
            Self::HoverProbe(error) => write!(f, "{error}"),
            Self::CoordinateProbe(error) => write!(f, "{error}"),
            Self::MissingRequiredProbeOutput { probe } => write!(
                f,
                "missing required Windows {probe} probe output while Explorer is frontmost"
            ),
        }
    }
}

impl std::error::Error for PreviewLoopError {}

impl WindowsPreviewLoop {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn state(&self) -> &PreviewState {
        self.engine.state()
    }

    /// Polls the live Windows host and forwards the resulting Explorer facts
    /// into the shared core.
    pub fn poll_host_state(&mut self, at_ms: u64) -> Result<Vec<AppEvent>, PreviewLoopError> {
        let frontmost = self
            .adapter
            .probe_frontmost_surface()
            .map_err(PreviewLoopError::Adapter)?;

        if !frontmost.allowed {
            return Ok(self
                .engine
                .observe_hover(at_ms, frontmost.observed_surface, None, None));
        }

        let translation = self
            .adapter
            .translate_coordinates(ScreenPoint::new(0.0, 0.0))
            .map_err(PreviewLoopError::Adapter)?;
        let front_surface = frontmost
            .detected_surface
            .as_ref()
            .expect("allowed Explorer frontmost probe should carry the accepted surface")
            .clone();
        let hover = self
            .adapter
            .resolve_hovered_item(&front_surface, translation.cursor.clone())
            .map_err(PreviewLoopError::Adapter)?;

        Ok(self.observe_classified_state(at_ms, frontmost, hover, translation))
    }

    /// Test-friendly entrypoint that accepts already-captured probe outputs so
    /// this lane can validate the Windows host-to-core wiring off Windows.
    pub fn observe_probe_outputs(
        &mut self,
        at_ms: u64,
        frontmost_raw: &str,
        hover_raw: Option<&str>,
        coordinate_raw: Option<&str>,
    ) -> Result<Vec<AppEvent>, PreviewLoopError> {
        let frontmost = self
            .adapter
            .classify_frontmost_surface_from_probe_output(frontmost_raw)
            .map_err(PreviewLoopError::FrontmostProbe)?;

        if !frontmost.allowed {
            return Ok(self
                .engine
                .observe_hover(at_ms, frontmost.observed_surface, None, None));
        }

        let hover_raw =
            hover_raw.ok_or(PreviewLoopError::MissingRequiredProbeOutput { probe: "hover" })?;
        let coordinate_raw =
            coordinate_raw.ok_or(PreviewLoopError::MissingRequiredProbeOutput {
                probe: "coordinate",
            })?;

        let hover = self
            .adapter
            .classify_hovered_item_from_probe_output(hover_raw)
            .map_err(PreviewLoopError::HoverProbe)?;
        let translation = self
            .adapter
            .classify_coordinate_translation_from_probe_output(coordinate_raw)
            .map_err(PreviewLoopError::CoordinateProbe)?;

        Ok(self.observe_classified_state(at_ms, frontmost, hover, translation))
    }

    fn observe_classified_state(
        &mut self,
        at_ms: u64,
        frontmost: FrontmostSurfaceProbe,
        hover: HoveredItemProbeOutcome,
        translation: WindowsCoordinateTranslation,
    ) -> Vec<AppEvent> {
        let hovered_item = hover
            .accepted
            .as_ref()
            .map(|accepted| hovered_item_from_probe(accepted, &hover, &translation));

        self.engine.observe_hover(
            at_ms,
            frontmost.observed_surface,
            hovered_item,
            Some(translation.selected_monitor),
        )
    }
}

fn hovered_item_from_probe(
    accepted: &AcceptedMarkdownPath,
    hover: &HoveredItemProbeOutcome,
    translation: &WindowsCoordinateTranslation,
) -> HoveredItem {
    HoveredItem {
        document: resolved_document_from_accepted(accepted),
        screen_point: translation.cursor.clone(),
        element_description: hovered_item_description(hover),
    }
}

fn resolved_document_from_accepted(accepted: &AcceptedMarkdownPath) -> ResolvedDocument {
    let path = accepted.path();
    let display_name = path
        .file_name()
        .and_then(|value| value.to_str())
        .map(ToOwned::to_owned)
        .unwrap_or_else(|| path.display().to_string());

    ResolvedDocument::new(
        path.display().to_string(),
        display_name,
        DocumentOrigin::LocalFileSystem,
        DocumentKind::File,
    )
}

fn hovered_item_description(hover: &HoveredItemProbeOutcome) -> String {
    let snapshot = &hover.snapshot;
    let element_name = snapshot
        .element_name
        .as_deref()
        .map(|name| format!(" ({name})"))
        .unwrap_or_default();

    format!(
        "Windows Explorer {} via {}{}",
        hover_scope_label(snapshot.resolution_scope),
        snapshot.backend,
        element_name
    )
}

fn hover_scope_label(scope: HoverResolutionScope) -> &'static str {
    match scope {
        HoverResolutionScope::ExactItemUnderPointer => "exact-item-under-pointer",
        HoverResolutionScope::HoveredRowDescendant => "hovered-row-descendant",
        HoverResolutionScope::NearbyCandidate => "nearby-candidate",
        HoverResolutionScope::FirstVisibleItem => "first-visible-item",
    }
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use fastmd_contracts::{AppEvent, CloseReason};
    use serde_json::json;

    use super::WindowsPreviewLoop;

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
                "fastmd-platform-windows-preview-{nonce}-{}",
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

    fn explorer_frontmost_json() -> String {
        json!({
            "foreground_window_id": "hwnd:0x10001",
            "process_id": 4012,
            "process_image_name": r"C:\Windows\explorer.exe",
            "window_class": "CabinetWClass",
            "window_title": "Docs",
            "directory": r"C:\Users\example\Docs",
            "shell_window_id": "hwnd:0x10001"
        })
        .to_string()
    }

    fn non_explorer_frontmost_json() -> String {
        json!({
            "foreground_window_id": "hwnd:0x10002",
            "process_id": 777,
            "process_image_name": r"C:\Windows\System32\notepad.exe",
            "window_class": "Notepad",
            "window_title": "notes.txt",
            "shell_window_id": null
        })
        .to_string()
    }

    fn hovered_item_json(path: &Path, scope: &str) -> String {
        json!({
            "resolution_scope": scope,
            "backend": "uiautomation-element-from-point+shell-parse-name",
            "path": path.display().to_string(),
            "element_name": path.file_name().and_then(|name| name.to_str()).unwrap_or("notes.md"),
            "shell_window_id": "hwnd:0x10001"
        })
        .to_string()
    }

    fn coordinate_json(cursor_x: f64, cursor_y: f64) -> String {
        json!({
            "cursor": {
                "x": cursor_x,
                "y": cursor_y
            },
            "virtual_desktop": {
                "x": 0.0,
                "y": 0.0,
                "width": 1920.0,
                "height": 1080.0
            },
            "monitors": [
                {
                    "id": "primary",
                    "name": "Primary",
                    "is_primary": true,
                    "scale_factor": 1.0,
                    "frame": {
                        "x": 0.0,
                        "y": 0.0,
                        "width": 1920.0,
                        "height": 1080.0
                    },
                    "working_area": {
                        "x": 0.0,
                        "y": 0.0,
                        "width": 1920.0,
                        "height": 1040.0
                    }
                }
            ]
        })
        .to_string()
    }

    #[test]
    fn opens_preview_after_one_second_hover_with_windows_probe_inputs() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        assert!(
            preview
                .observe_probe_outputs(
                    0,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                    Some(&coordinate_json(320.0, 180.0)),
                )
                .expect("probe outputs should classify")
                .is_empty()
        );

        let events = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert_eq!(events.len(), 1);
        match &events[0] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(request.document.display_name, "notes.md");
                assert_eq!(request.requested_width_px, 560);
                assert_eq!(request.monitor_id.as_deref(), Some("primary"));
                assert!(request.interaction_hot);
            }
            other => panic!("unexpected event: {other:?}"),
        }
        assert!(preview.state().visibility.visible);
    }

    #[test]
    fn blocks_preview_opening_while_frontmost_surface_is_not_explorer() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        let events = preview
            .observe_probe_outputs(
                1_000,
                &non_explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert!(events.is_empty());
        assert!(!preview.state().visibility.visible);
    }

    #[test]
    fn keeps_same_hovered_markdown_from_reopening_while_stationary() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let repeated = preview
            .observe_probe_outputs(
                4_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert!(repeated.is_empty());
        assert_eq!(
            preview
                .state()
                .current_document
                .as_ref()
                .map(|document| document.display_name.as_str()),
            Some("notes.md")
        );
    }

    #[test]
    fn replaces_preview_only_after_the_resolved_markdown_document_changes() {
        let fixture = TempFixture::new();
        let first = fixture.write_file("a.md", "# first");
        let second = fixture.write_file("b.md", "# second");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&first, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&first, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert!(
            preview
                .observe_probe_outputs(
                    1_500,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                    Some(&coordinate_json(420.0, 220.0)),
                )
                .expect("probe outputs should classify")
                .is_empty()
        );

        let replacement = preview
            .observe_probe_outputs(
                2_500,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                Some(&coordinate_json(420.0, 220.0)),
            )
            .expect("probe outputs should classify");

        assert_eq!(replacement.len(), 1);
        match &replacement[0] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(request.document.display_name, "b.md");
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn ordinary_pointer_motion_on_the_same_document_does_not_dismiss_preview() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let unchanged = preview
            .observe_probe_outputs(
                4_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(500.0, 260.0)),
            )
            .expect("probe outputs should classify");

        assert!(unchanged.is_empty());
        assert!(preview.state().visibility.visible);
        assert_eq!(preview.state().last_close_reason, None);
    }

    #[test]
    fn explorer_loss_hides_an_open_preview_via_shared_core_app_switch_semantics() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let hidden = preview
            .observe_probe_outputs(1_500, &non_explorer_frontmost_json(), None, None)
            .expect("frontmost probe should classify");

        assert_eq!(
            hidden,
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::AppSwitch,
            }]
        );
        assert!(!preview.state().visibility.visible);
    }
}
