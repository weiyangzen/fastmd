use std::{collections::BTreeMap, fmt, fs, path::Path};

use fastmd_contracts::{
    merged_preview_feature_coverage, merged_preview_feature_coverage_records, AppCommand, AppEvent,
    DocumentKind, DocumentOrigin, HoverResolutionScope, HoveredItem, LoadedDocument,
    MacOsPreviewFeature, PlatformId, PreviewFeatureCoverageLane, PreviewFeatureCoverageRecord,
    PreviewState, PreviewWindowRequest, ResolvedDocument, RuntimeDiagnostic,
    RuntimeDiagnosticCategory, RuntimeDiagnosticLevel, ScreenPoint,
};
use fastmd_core::{
    shared_core_preview_feature_coverage, shared_core_preview_feature_coverage_records, CoreEngine,
};
use fastmd_render::{
    apply_inline_edit_to_markdown, build_inline_editor_model_for_editing_state,
    preview_model_from_loaded_document, shared_render_preview_feature_coverage,
    shared_render_preview_feature_coverage_records, BlockMapping, InlineEditorModel, PreviewModel,
};

use crate::{
    AcceptedMarkdownPath, AdapterError, CoordinateProbeError, ExplorerAdapter, FrontmostProbeError,
    FrontmostSurfaceProbe, HoverProbeError, HoveredItemProbeOutcome, WindowsCoordinateTranslation,
};

/// Windows-specific preview loop wiring that feeds Explorer host signals into
/// the shared FastMD core without changing product semantics.
#[derive(Debug, Clone)]
struct WarmedPreviewEntry {
    loaded_document: LoadedDocument,
    preview_model: PreviewModel,
}

#[derive(Debug, Default)]
pub struct WindowsPreviewLoop {
    adapter: ExplorerAdapter,
    engine: CoreEngine,
    warmed_previews: BTreeMap<String, WarmedPreviewEntry>,
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

    pub fn pending_warmed_document(&self) -> Option<&LoadedDocument> {
        let document = self.engine.pending_hovered_document()?;
        self.warmed_previews
            .get(document.path.as_str())
            .map(|entry| &entry.loaded_document)
    }

    pub fn pending_warmed_preview_model(&self) -> Option<&PreviewModel> {
        let document = self.engine.pending_hovered_document()?;
        self.warmed_previews
            .get(document.path.as_str())
            .map(|entry| &entry.preview_model)
    }

    pub fn current_warmed_preview_model(&self) -> Option<&PreviewModel> {
        let document = self.engine.state().current_document.as_ref()?;
        self.warmed_previews
            .get(document.path.as_str())
            .map(|entry| &entry.preview_model)
    }

    pub fn dispatch_command(
        &mut self,
        command: AppCommand,
        blocks: &[BlockMapping],
    ) -> Vec<AppEvent> {
        self.dispatch_command_with_runtime_diagnostics(command, blocks, Vec::new())
    }

    pub fn request_edit_at_line(
        &mut self,
        target_line: u32,
        markdown: &str,
        blocks: &[BlockMapping],
    ) -> Option<InlineEditorModel> {
        let events = self.dispatch_command(AppCommand::RequestEdit { target_line }, blocks);
        let product_events = non_diagnostic_event_refs(&events);
        if product_events.len() != 1
            || !matches!(product_events[0], &AppEvent::EditSessionChanged { .. })
        {
            return None;
        }

        self.inline_editor(markdown, blocks)
    }

    pub fn inline_editor(
        &self,
        markdown: &str,
        blocks: &[BlockMapping],
    ) -> Option<InlineEditorModel> {
        build_inline_editor_model_for_editing_state(markdown, blocks, &self.engine.state().editing)
    }

    pub fn save_current_edit(
        &mut self,
        markdown: &str,
        replacement_source: &str,
        blocks: &[BlockMapping],
    ) -> Option<(String, Vec<AppEvent>)> {
        let block = self.engine.editing_block(blocks)?;
        let replacement_markdown =
            apply_inline_edit_to_markdown(markdown, &block, replacement_source)?;
        let events = self.dispatch_command(
            AppCommand::SaveEdit {
                replacement_markdown: replacement_markdown.clone(),
                replacement_source: replacement_source.replace("\r\n", "\n"),
            },
            blocks,
        );
        if events.is_empty() {
            return None;
        }

        Some((replacement_markdown, events))
    }

    pub fn cancel_edit_session(&mut self) -> Vec<AppEvent> {
        self.dispatch_command(AppCommand::CancelEdit, &[])
    }

    pub fn complete_save(
        &mut self,
        success: bool,
        persisted_markdown: Option<String>,
        message: Option<String>,
    ) -> Vec<AppEvent> {
        let warmed_document = if success {
            self.engine
                .state()
                .current_document
                .clone()
                .zip(persisted_markdown.clone())
                .map(|(document, markdown)| LoadedDocument {
                    document,
                    encoding: "utf-8".to_string(),
                    markdown,
                })
        } else {
            None
        };
        let events = self.dispatch_command(
            AppCommand::CompleteSave {
                success,
                persisted_markdown,
                message,
            },
            &[],
        );
        if let Some(loaded_document) = warmed_document {
            self.store_warmed_document(loaded_document);
        }
        events
    }

    /// Polls the live Windows host and forwards the resulting Explorer facts
    /// into the shared core.
    pub fn poll_host_state(&mut self, at_ms: u64) -> Result<Vec<AppEvent>, PreviewLoopError> {
        let frontmost = self
            .adapter
            .probe_frontmost_surface()
            .map_err(PreviewLoopError::Adapter)?;

        if !frontmost.allowed {
            return Ok(self.observe_frontmost_probe(at_ms, frontmost));
        }

        if frontmost.observed_surface.blocks_hover_preview() {
            return Ok(self.observe_frontmost_probe(at_ms, frontmost));
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
            return Ok(self.observe_frontmost_probe(at_ms, frontmost));
        }

        if frontmost.observed_surface.blocks_hover_preview() {
            return Ok(self.observe_frontmost_probe(at_ms, frontmost));
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
        let front_surface = frontmost.observed_surface.clone();
        let selected_monitor = translation.selected_monitor.clone();
        let additional_diagnostics = vec![
            frontmost_runtime_diagnostic(at_ms, &frontmost),
            hover_runtime_diagnostic(at_ms, &hover),
            monitor_selection_runtime_diagnostic(at_ms, &translation),
        ];

        self.dispatch_command_with_runtime_diagnostics(
            AppCommand::ObserveHover {
                at_ms,
                front_surface,
                hovered_item,
                monitor: Some(selected_monitor),
            },
            &[],
            additional_diagnostics,
        )
    }

    fn observe_frontmost_probe(
        &mut self,
        at_ms: u64,
        frontmost: FrontmostSurfaceProbe,
    ) -> Vec<AppEvent> {
        let front_surface = frontmost.observed_surface.clone();
        self.dispatch_command_with_runtime_diagnostics(
            AppCommand::ObserveHover {
                at_ms,
                front_surface,
                hovered_item: None,
                monitor: None,
            },
            &[],
            vec![frontmost_runtime_diagnostic(at_ms, &frontmost)],
        )
    }

    fn dispatch_command_with_runtime_diagnostics(
        &mut self,
        command: AppCommand,
        blocks: &[BlockMapping],
        mut additional_diagnostics: Vec<RuntimeDiagnostic>,
    ) -> Vec<AppEvent> {
        let previous_pending_document = self.engine.pending_hovered_document().cloned();
        let mut events = self.engine.dispatch_command(command.clone(), blocks);
        self.warm_pending_hover_candidate(previous_pending_document.as_ref());
        self.refresh_warmed_preview_models();
        self.attach_warmed_documents_to_preview_requests(&mut events);
        additional_diagnostics.extend(runtime_diagnostics_for_command(&command, &events));

        if additional_diagnostics.is_empty() {
            return events;
        }

        events.extend(self.engine.dispatch_command(
            AppCommand::ReportRuntimeDiagnostics {
                diagnostics: additional_diagnostics,
            },
            &[],
        ));
        events
    }

    fn warm_pending_hover_candidate(
        &mut self,
        previous_pending_document: Option<&ResolvedDocument>,
    ) {
        let Some(document) = self.engine.pending_hovered_document().cloned() else {
            return;
        };

        if previous_pending_document == Some(&document)
            && self.warmed_previews.contains_key(document.path.as_str())
        {
            return;
        }

        let _ = self.load_document_from_disk(&document);
    }

    fn load_document_from_disk(&mut self, document: &ResolvedDocument) -> Option<()> {
        let markdown = fs::read_to_string(Path::new(document.path.as_str())).ok()?;
        self.store_warmed_document(LoadedDocument {
            document: document.clone(),
            encoding: "utf-8".to_string(),
            markdown,
        });
        Some(())
    }

    fn store_warmed_document(&mut self, loaded_document: LoadedDocument) {
        let preview_model = preview_model_from_loaded_document(
            &loaded_document,
            self.engine.state().selected_width_tier_index,
            self.engine.state().background_mode,
        );
        let key = loaded_document.document.path.as_str().to_string();
        self.warmed_previews.insert(
            key,
            WarmedPreviewEntry {
                loaded_document,
                preview_model,
            },
        );
    }

    fn refresh_warmed_preview_models(&mut self) {
        let selected_width_tier_index = self.engine.state().selected_width_tier_index;
        let background_mode = self.engine.state().background_mode;

        for entry in self.warmed_previews.values_mut() {
            entry.preview_model = preview_model_from_loaded_document(
                &entry.loaded_document,
                selected_width_tier_index,
                background_mode,
            );
        }
    }

    fn attach_warmed_documents_to_preview_requests(&self, events: &mut [AppEvent]) {
        for event in events {
            if let AppEvent::PreviewWindowRequested { request } = event {
                request.warmed_document = self
                    .warmed_previews
                    .get(request.document.path.as_str())
                    .map(|entry| entry.loaded_document.clone());
            }
        }
    }
}

pub fn windows_adapter_preview_feature_coverage() -> &'static [MacOsPreviewFeature] {
    &[
        MacOsPreviewFeature::FrontmostFileManagerGating,
        MacOsPreviewFeature::ExactHoveredMarkdownResolution,
        MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
        MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
        MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
    ]
}

const WINDOWS_ADAPTER_PREVIEW_FEATURE_COVERAGE_RECORDS: [PreviewFeatureCoverageRecord; 5] = [
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
        MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
        PreviewFeatureCoverageLane::WindowsAdapter,
    ),
];

pub fn windows_adapter_preview_feature_coverage_records() -> &'static [PreviewFeatureCoverageRecord]
{
    &WINDOWS_ADAPTER_PREVIEW_FEATURE_COVERAGE_RECORDS
}

pub fn windows_preview_loop_feature_coverage() -> Vec<MacOsPreviewFeature> {
    merged_preview_feature_coverage(&[
        shared_core_preview_feature_coverage(),
        shared_render_preview_feature_coverage(),
        windows_adapter_preview_feature_coverage(),
    ])
}

pub fn windows_preview_loop_feature_coverage_records() -> Vec<PreviewFeatureCoverageRecord> {
    merged_preview_feature_coverage_records(&[
        shared_core_preview_feature_coverage_records(),
        shared_render_preview_feature_coverage_records(),
        windows_adapter_preview_feature_coverage_records(),
    ])
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
    let presentation_mode = snapshot.presentation_mode.label();
    let view_mode = snapshot
        .explorer_view_mode
        .map(|mode| format!(", {}", mode.label()))
        .unwrap_or_default();

    format!(
        "Windows Explorer {} / {}{} via {}{}",
        hover_scope_label(snapshot.resolution_scope),
        presentation_mode,
        view_mode,
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

fn non_diagnostic_event_refs(events: &[AppEvent]) -> Vec<&AppEvent> {
    events
        .iter()
        .filter(|event| !matches!(event, AppEvent::RuntimeDiagnosticsReported { .. }))
        .collect()
}

fn runtime_diagnostics_for_command(
    command: &AppCommand,
    events: &[AppEvent],
) -> Vec<RuntimeDiagnostic> {
    let mut diagnostics = Vec::new();

    for event in non_diagnostic_event_refs(events) {
        match (command, event) {
            (
                AppCommand::ObserveHover { at_ms, .. },
                AppEvent::PreviewWindowRequested { request },
            ) => diagnostics.push(preview_placement_runtime_diagnostic(
                Some(*at_ms),
                "Windows preview placement opened a preview through the shared 4:3 geometry policy",
                request,
            )),
            (
                AppCommand::AdjustWidthTier { .. },
                AppEvent::PreviewWindowRequested { request },
            ) => diagnostics.push(preview_placement_runtime_diagnostic(
                None,
                "Windows preview placement recomputed the preview frame after a width-tier change",
                request,
            )),
            (
                AppCommand::RequestEdit { target_line },
                AppEvent::EditSessionChanged { editing },
            ) => diagnostics.push(
                RuntimeDiagnostic::new(
                    PlatformId::WindowsExplorer,
                    RuntimeDiagnosticLevel::Info,
                    RuntimeDiagnosticCategory::EditLifecycle,
                    "Windows edit lifecycle entered inline edit mode through the shared smallest-block rule",
                )
                .with_detail("target_line", target_line.to_string())
                .with_detail(
                    "target_start_line",
                    editing
                        .target_start_line
                        .map(|line| line.to_string())
                        .unwrap_or_else(|| "none".to_string()),
                )
                .with_detail(
                    "target_end_line",
                    editing
                        .target_end_line
                        .map(|line| line.to_string())
                        .unwrap_or_else(|| "none".to_string()),
                ),
            ),
            (
                AppCommand::SaveEdit {
                    replacement_source, ..
                },
                AppEvent::MarkdownSaveRequested { document, .. },
            ) => diagnostics.push(
                RuntimeDiagnostic::new(
                    PlatformId::WindowsExplorer,
                    RuntimeDiagnosticLevel::Info,
                    RuntimeDiagnosticCategory::EditLifecycle,
                    "Windows edit lifecycle requested a Markdown save through the shared save contract",
                )
                .with_detail("document_path", document.path.clone())
                .with_detail(
                    "replacement_line_count",
                    replacement_source.lines().count().to_string(),
                ),
            ),
            (
                AppCommand::CompleteSave {
                    success, message, ..
                },
                AppEvent::EditSessionChanged { editing },
            ) => {
                let level = if *success {
                    RuntimeDiagnosticLevel::Info
                } else {
                    RuntimeDiagnosticLevel::Error
                };
                let summary = if *success {
                    "Windows edit lifecycle completed a save and unlocked edit mode"
                } else {
                    "Windows edit lifecycle reported a failed save and restored the active draft"
                };
                let mut diagnostic = RuntimeDiagnostic::new(
                    PlatformId::WindowsExplorer,
                    level,
                    RuntimeDiagnosticCategory::EditLifecycle,
                    summary,
                )
                .with_detail("editing_phase", format!("{:?}", editing.phase));
                if let Some(message) = message.as_deref() {
                    diagnostic = diagnostic.with_detail("message", message.to_string());
                }
                diagnostics.push(diagnostic);
            }
            (AppCommand::CancelEdit, AppEvent::EditSessionChanged { editing }) => diagnostics
                .push(
                    RuntimeDiagnostic::new(
                        PlatformId::WindowsExplorer,
                        RuntimeDiagnosticLevel::Info,
                        RuntimeDiagnosticCategory::EditLifecycle,
                        "Windows edit lifecycle cancelled the active inline edit session",
                    )
                    .with_detail("editing_phase", format!("{:?}", editing.phase)),
                ),
            _ => {}
        }
    }

    diagnostics
}

fn preview_placement_runtime_diagnostic(
    at_ms: Option<u64>,
    summary: &'static str,
    request: &PreviewWindowRequest,
) -> RuntimeDiagnostic {
    let mut diagnostic = RuntimeDiagnostic::new(
        PlatformId::WindowsExplorer,
        RuntimeDiagnosticLevel::Info,
        RuntimeDiagnosticCategory::PreviewPlacement,
        summary,
    )
    .with_detail("document_path", request.document.path.clone())
    .with_detail(
        "monitor_id",
        request
            .monitor_id
            .clone()
            .unwrap_or_else(|| "none".to_string()),
    )
    .with_detail(
        "selected_width_tier_index",
        request.selected_width_tier_index.to_string(),
    )
    .with_detail("requested_width_px", request.requested_width_px.to_string())
    .with_detail("frame_x", format!("{:.1}", request.frame.x))
    .with_detail("frame_y", format!("{:.1}", request.frame.y))
    .with_detail("frame_width", format!("{:.1}", request.frame.width))
    .with_detail("frame_height", format!("{:.1}", request.frame.height))
    .with_detail("warmed_document", request.is_prewarmed().to_string());

    if let Some(line_count) = request.warmed_markdown_line_count() {
        diagnostic = diagnostic.with_detail("warmed_markdown_line_count", line_count.to_string());
    }

    if let Some(at_ms) = at_ms {
        diagnostic = diagnostic.at_ms(at_ms);
    }

    diagnostic
}

fn frontmost_runtime_diagnostic(
    at_ms: u64,
    frontmost: &FrontmostSurfaceProbe,
) -> RuntimeDiagnostic {
    let mut diagnostic = RuntimeDiagnostic::new(
        PlatformId::WindowsExplorer,
        if frontmost.allowed {
            RuntimeDiagnosticLevel::Info
        } else {
            RuntimeDiagnosticLevel::Warning
        },
        RuntimeDiagnosticCategory::FrontmostGating,
        if frontmost.allowed && frontmost.observed_surface.has_focused_text_input() {
            "Explorer frontmost gating accepted the current foreground surface and suspended hover preview while Explorer edits text"
        } else if frontmost.allowed {
            "Explorer frontmost gating accepted the current foreground surface"
        } else {
            "Explorer frontmost gating rejected the current foreground surface"
        },
    )
    .at_ms(at_ms)
    .with_detail(
        "observed_app_identifier",
        frontmost.observed_surface.app_identifier.clone(),
    )
    .with_detail(
        "observed_surface_kind",
        format!("{:?}", frontmost.observed_surface.surface_kind),
    )
    .with_detail("expected_host", frontmost.allowed.to_string())
    .with_detail(
        "focused_text_input_active",
        frontmost
            .observed_surface
            .has_focused_text_input()
            .to_string(),
    )
    .with_detail("notes", frontmost.notes.to_string());

    if let Some(identity) = frontmost.observed_surface.stable_identity() {
        diagnostic = diagnostic
            .with_detail("native_window_id", identity.native_window_id.clone())
            .with_detail(
                "process_id",
                identity
                    .owner_process_id
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "none".to_string()),
            );
    }
    if let Some(role_name) = frontmost
        .observed_surface
        .focused_text_input
        .role_name
        .as_deref()
    {
        diagnostic = diagnostic.with_detail("focused_text_input_role", role_name.to_string());
    }
    if let Some(element_name) = frontmost
        .observed_surface
        .focused_text_input
        .element_name
        .as_deref()
    {
        diagnostic = diagnostic.with_detail("focused_text_input_name", element_name.to_string());
    }
    if let Some(rejection) = &frontmost.rejection {
        diagnostic = diagnostic.with_detail("rejection", rejection.to_string());
    }

    diagnostic
}

fn hover_runtime_diagnostic(at_ms: u64, hover: &HoveredItemProbeOutcome) -> RuntimeDiagnostic {
    let mut diagnostic = RuntimeDiagnostic::new(
        PlatformId::WindowsExplorer,
        if hover.accepted.is_some() {
            RuntimeDiagnosticLevel::Info
        } else {
            RuntimeDiagnosticLevel::Warning
        },
        RuntimeDiagnosticCategory::HoveredItemResolution,
        if hover.accepted.is_some() {
            "Windows hovered-item resolution accepted the actual hovered Markdown target"
        } else {
            "Windows hovered-item resolution rejected the current hover target before preview open"
        },
    )
    .at_ms(at_ms)
    .with_detail(
        "resolution_scope",
        hover_scope_label(hover.snapshot.resolution_scope).to_string(),
    )
    .with_detail(
        "presentation_mode",
        hover.snapshot.presentation_mode.label().to_string(),
    )
    .with_detail("backend", hover.snapshot.backend.clone())
    .with_detail("notes", hover.notes.to_string());

    if let Some(element_name) = hover.snapshot.element_name.as_deref() {
        diagnostic = diagnostic.with_detail("element_name", element_name.to_string());
    }
    if let Some(view_mode) = hover.snapshot.explorer_view_mode {
        diagnostic = diagnostic.with_detail(
            "explorer_view_mode",
            format!("{} ({})", view_mode.label(), view_mode.code()),
        );
    }
    if let Some(path) = hover
        .accepted
        .as_ref()
        .map(|accepted| accepted.path().display().to_string())
    {
        diagnostic = diagnostic.with_detail("accepted_path", path);
    }
    if let Some(rejection) = &hover.rejection {
        diagnostic = diagnostic.with_detail("rejection", rejection.to_string());
    }

    diagnostic
}

fn monitor_selection_runtime_diagnostic(
    at_ms: u64,
    translation: &WindowsCoordinateTranslation,
) -> RuntimeDiagnostic {
    RuntimeDiagnostic::new(
        PlatformId::WindowsExplorer,
        RuntimeDiagnosticLevel::Info,
        RuntimeDiagnosticCategory::MonitorSelection,
        "Windows monitor selection classified the pointer into the shared desktop-space model",
    )
    .at_ms(at_ms)
    .with_detail("cursor_x", format!("{:.1}", translation.cursor.x))
    .with_detail("cursor_y", format!("{:.1}", translation.cursor.y))
    .with_detail(
        "selected_monitor_id",
        translation.selected_monitor.id.clone(),
    )
    .with_detail("monitor_count", translation.monitors.len().to_string())
    .with_detail(
        "contains_cursor",
        translation
            .selected_monitor
            .contains_point_in_visible_frame(&translation.cursor)
            .to_string(),
    )
    .with_detail("notes", translation.notes.to_string())
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeSet;
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use fastmd_contracts::{
        macos_preview_feature_list, preview_feature_coverage_record_gaps_against_reference,
        AppCommand, AppEvent, BackgroundMode, CloseReason, EditingPhase, MacOsPreviewFeature,
        PageDirection, PageInput, PreviewFeatureCoverageLane, RuntimeDiagnostic,
        RuntimeDiagnosticCategory, MACOS_REFERENCE_BEHAVIOR,
    };
    use fastmd_render::{BlockKind, BlockMapping};
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
        explorer_frontmost_json_with_text_input(None)
    }

    fn explorer_frontmost_json_with_text_input(focused_text_input: Option<(&str, &str)>) -> String {
        let (focused_is_text_input, focused_role_name, focused_name) = match focused_text_input {
            Some((role_name, focused_name)) => (true, Some(role_name), Some(focused_name)),
            None => (false, None, None),
        };

        json!({
            "foreground_window_id": "hwnd:0x10001",
            "process_id": 4012,
            "process_image_name": r"C:\Windows\explorer.exe",
            "window_class": "CabinetWClass",
            "window_title": "Docs",
            "directory": r"C:\Users\example\Docs",
            "shell_window_id": "hwnd:0x10001",
            "focused_is_text_input": focused_is_text_input,
            "focused_role_name": focused_role_name,
            "focused_name": focused_name
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
        hovered_item_json_with_mode(path, scope, "list", 4)
    }

    fn hovered_item_json_with_mode(
        path: &Path,
        scope: &str,
        presentation_mode: &str,
        view_mode_code: i32,
    ) -> String {
        json!({
            "resolution_scope": scope,
            "presentation_mode": presentation_mode,
            "backend": "uiautomation-element-from-point+shell-parse-name",
            "path": path.display().to_string(),
            "element_name": path.file_name().and_then(|name| name.to_str()).unwrap_or("notes.md"),
            "shell_window_id": "hwnd:0x10001",
            "view_mode_code": view_mode_code
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

    fn coordinate_json_for_visible_frame(
        cursor_x: f64,
        shared_cursor_y: f64,
        width: f64,
        height: f64,
    ) -> String {
        json!({
            "cursor": {
                "x": cursor_x,
                "y": height - shared_cursor_y
            },
            "virtual_desktop": {
                "x": 0.0,
                "y": 0.0,
                "width": width,
                "height": height
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
                        "width": width,
                        "height": height
                    },
                    "working_area": {
                        "x": 0.0,
                        "y": 0.0,
                        "width": width,
                        "height": height
                    }
                }
            ]
        })
        .to_string()
    }

    fn product_events(events: &[AppEvent]) -> Vec<AppEvent> {
        events
            .iter()
            .filter(|event| !matches!(event, AppEvent::RuntimeDiagnosticsReported { .. }))
            .cloned()
            .collect()
    }

    fn reported_diagnostics(events: &[AppEvent]) -> Vec<RuntimeDiagnostic> {
        events
            .iter()
            .flat_map(|event| match event {
                AppEvent::RuntimeDiagnosticsReported { diagnostics } => diagnostics.clone(),
                _ => Vec::new(),
            })
            .collect()
    }

    fn open_visible_preview(preview: &mut WindowsPreviewLoop, path: &Path) {
        assert!(product_events(
            &preview
                .observe_probe_outputs(
                    0,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(path, "exact-item-under-pointer")),
                    Some(&coordinate_json(320.0, 180.0)),
                )
                .expect("probe outputs should classify"),
        )
        .is_empty());

        let opened = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert!(matches!(
            product_events(&opened).as_slice(),
            [AppEvent::PreviewWindowRequested { .. }]
        ));
        assert!(preview.state().visibility.visible);
    }

    fn edit_markdown() -> &'static str {
        "line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8\nline 9\nline 10"
    }

    fn edit_block_mappings() -> Vec<BlockMapping> {
        vec![
            BlockMapping {
                block_id: 0,
                kind: BlockKind::Paragraph,
                start_line: 0,
                end_line: 10,
            },
            BlockMapping {
                block_id: 1,
                kind: BlockKind::Blockquote,
                start_line: 2,
                end_line: 8,
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
    fn opens_preview_after_one_second_hover_with_windows_probe_inputs() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        assert!(product_events(
            &preview
                .observe_probe_outputs(
                    0,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                    Some(&coordinate_json(320.0, 180.0)),
                )
                .expect("probe outputs should classify"),
        )
        .is_empty());

        let events = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let product_events = product_events(&events);
        assert_eq!(product_events.len(), 1);
        match &product_events[0] {
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
    fn warms_hovered_markdown_during_debounce_and_attaches_it_on_open() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello\n\nbody");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json_with_mode(
                    &path,
                    "exact-item-under-pointer",
                    "non-list",
                    6,
                )),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        assert_eq!(
            preview
                .pending_warmed_document()
                .map(|document| document.markdown.as_str()),
            Some("# hello\n\nbody")
        );
        assert_eq!(
            preview
                .pending_warmed_preview_model()
                .map(|model| model.chrome.selected_width_tier_index),
            Some(0)
        );

        let events = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json_with_mode(
                    &path,
                    "exact-item-under-pointer",
                    "non-list",
                    6,
                )),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let product_events = product_events(&events);
        assert_eq!(product_events.len(), 1);
        match &product_events[0] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(
                    request
                        .warmed_document
                        .as_ref()
                        .map(|document| document.markdown.as_str()),
                    Some("# hello\n\nbody")
                );
            }
            other => panic!("unexpected event: {other:?}"),
        }

        assert_eq!(
            preview
                .current_warmed_preview_model()
                .map(|model| model.document.title.as_str()),
            Some("notes.md")
        );
    }

    #[test]
    fn emits_runtime_diagnostics_for_frontmost_hover_monitor_and_preview_placement() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json_with_mode(
                    &path,
                    "exact-item-under-pointer",
                    "non-list",
                    6,
                )),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let events = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json_with_mode(
                    &path,
                    "exact-item-under-pointer",
                    "non-list",
                    6,
                )),
                Some(&coordinate_json(320.0, 180.0)),
            )
            .expect("probe outputs should classify");

        let diagnostics = reported_diagnostics(&events);
        let categories: Vec<_> = diagnostics
            .iter()
            .map(|diagnostic| diagnostic.category)
            .collect();

        assert!(categories.contains(&RuntimeDiagnosticCategory::FrontmostGating));
        assert!(categories.contains(&RuntimeDiagnosticCategory::HoveredItemResolution));
        assert!(categories.contains(&RuntimeDiagnosticCategory::MonitorSelection));
        assert!(categories.contains(&RuntimeDiagnosticCategory::PreviewPlacement));
        assert!(diagnostics.iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::HoveredItemResolution
                && diagnostic
                    .details
                    .get("presentation_mode")
                    .map(|value| value.as_str())
                    == Some("non-list")
        }));
        assert!(diagnostics.iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::HoveredItemResolution
                && diagnostic
                    .details
                    .get("explorer_view_mode")
                    .map(|value| value.as_str())
                    == Some("tile (6)")
        }));
        assert!(diagnostics.iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::PreviewPlacement
                && diagnostic
                    .details
                    .get("requested_width_px")
                    .map(|value| value.as_str())
                    == Some("560")
        }));
        assert!(diagnostics.iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::PreviewPlacement
                && diagnostic
                    .details
                    .get("warmed_document")
                    .map(|value| value.as_str())
                    == Some("true")
        }));
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

        assert!(product_events(&events).is_empty());
        assert!(!preview.state().visibility.visible);
    }

    #[test]
    fn explorer_text_input_suppresses_hover_open_without_requiring_hover_or_coordinate_probes() {
        let mut preview = WindowsPreviewLoop::new();

        let events = preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json_with_text_input(Some(("ControlType.Edit", "Report.md"))),
                None,
                None,
            )
            .expect("text-input frontmost probe should classify without hover data");

        assert!(product_events(&events).is_empty());
        assert!(!preview.state().visibility.visible);

        let diagnostics = reported_diagnostics(&events);
        assert!(diagnostics.iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::FrontmostGating
                && diagnostic
                    .details
                    .get("focused_text_input_active")
                    .map(|value| value.as_str())
                    == Some("true")
        }));
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

        assert!(product_events(&repeated).is_empty());
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

        assert!(product_events(
            &preview
                .observe_probe_outputs(
                    1_500,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                    Some(&coordinate_json(420.0, 220.0)),
                )
                .expect("probe outputs should classify"),
        )
        .is_empty());

        let replacement = preview
            .observe_probe_outputs(
                2_500,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                Some(&coordinate_json(420.0, 220.0)),
            )
            .expect("probe outputs should classify");

        let product_events = product_events(&replacement);
        assert_eq!(product_events.len(), 1);
        match &product_events[0] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(request.document.display_name, "b.md");
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn explorer_text_input_blocks_hover_replacement_without_hiding_the_current_preview() {
        let fixture = TempFixture::new();
        let first = fixture.write_file("a.md", "# first");
        let second = fixture.write_file("b.md", "# second");
        let mut preview = WindowsPreviewLoop::new();

        open_visible_preview(&mut preview, &first);

        let events = preview
            .observe_probe_outputs(
                2_000,
                &explorer_frontmost_json_with_text_input(Some(("ControlType.Edit", "Rename"))),
                None,
                None,
            )
            .expect("text-input frontmost probe should classify without hover data");

        assert!(product_events(&events).is_empty());
        assert!(preview.state().visibility.visible);
        assert_eq!(
            preview
                .state()
                .current_document
                .as_ref()
                .map(|document| document.display_name.as_str()),
            Some("a.md")
        );

        assert!(product_events(
            &preview
                .observe_probe_outputs(
                    2_500,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                    Some(&coordinate_json(420.0, 220.0)),
                )
                .expect("replacement hover should start a fresh debounce"),
        )
        .is_empty());

        let replacement = preview
            .observe_probe_outputs(
                3_500,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&second, "exact-item-under-pointer")),
                Some(&coordinate_json(420.0, 220.0)),
            )
            .expect("replacement hover should classify");

        assert!(matches!(
            product_events(&replacement).as_slice(),
            [AppEvent::PreviewWindowRequested { .. }]
        ));
        assert_eq!(
            preview
                .state()
                .current_document
                .as_ref()
                .map(|document| document.display_name.as_str()),
            Some("b.md")
        );
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

        assert!(product_events(&unchanged).is_empty());
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
            product_events(&hidden),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::AppSwitch,
            }]
        );
        assert!(!preview.state().visibility.visible);
    }

    #[test]
    fn preview_opens_hot_so_windows_tab_toggle_needs_no_rehover() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        open_visible_preview(&mut preview, &path);

        assert!(preview.state().interaction_hot);
        let events = preview.dispatch_command(AppCommand::ToggleBackgroundMode, &[]);
        assert_eq!(
            events,
            vec![AppEvent::BackgroundModeChanged {
                background_mode: BackgroundMode::Black,
            }]
        );
        assert_eq!(preview.state().background_mode, BackgroundMode::Black);
        assert_eq!(
            preview
                .state()
                .visibility
                .last_request
                .as_ref()
                .map(|request| request.background_mode),
            Some(BackgroundMode::Black)
        );
    }

    #[test]
    fn scroll_and_paging_commands_match_macos_without_rehover_inside_preview() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        open_visible_preview(&mut preview, &path);

        assert_eq!(
            preview.dispatch_command(
                AppCommand::ScrollPreview {
                    raw_delta_y: -84.0,
                    precise: true,
                },
                &[],
            ),
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );
        assert_eq!(
            preview.dispatch_command(
                AppCommand::ScrollPreview {
                    raw_delta_y: -8.4,
                    precise: false,
                },
                &[],
            ),
            vec![AppEvent::ScrollApplied { delta_y: 84.0 }]
        );

        for (input, direction) in [
            (PageInput::Space, PageDirection::Forward),
            (PageInput::PageDown, PageDirection::Forward),
            (PageInput::ShiftSpace, PageDirection::Backward),
            (PageInput::PageUp, PageDirection::Backward),
        ] {
            let events = preview.dispatch_command(AppCommand::PagePreview { input }, &[]);
            match events.as_slice() {
                [AppEvent::PageMotionRequested { motion }] => {
                    assert_eq!(motion.direction, direction);
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
                other => panic!("unexpected paging events: {other:?}"),
            }
        }
    }

    #[test]
    fn outside_click_and_escape_close_match_macos_on_windows() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");

        let mut outside_click_preview = WindowsPreviewLoop::new();
        open_visible_preview(&mut outside_click_preview, &path);
        assert_eq!(
            outside_click_preview.dispatch_command(AppCommand::OutsideClick, &[]),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::OutsideClick,
            }]
        );
        assert!(!outside_click_preview.state().visibility.visible);

        let mut escape_preview = WindowsPreviewLoop::new();
        open_visible_preview(&mut escape_preview, &path);
        assert_eq!(
            escape_preview.dispatch_command(AppCommand::Escape, &[]),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
        assert!(!escape_preview.state().visibility.visible);
    }

    #[test]
    fn inline_edit_entry_uses_smallest_block_and_maps_original_source_on_windows() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", edit_markdown());
        let mut preview = WindowsPreviewLoop::new();
        let blocks = edit_block_mappings();

        open_visible_preview(&mut preview, &path);

        let editor = preview
            .request_edit_at_line(4, edit_markdown(), &blocks)
            .expect("inline editor should open");

        assert_eq!(editor.block.block_id, 2);
        assert_eq!(editor.block.start_line, 3);
        assert_eq!(editor.block.end_line, 5);
        assert_eq!(editor.original_source, "line 4\nline 5");
        assert_eq!(editor.editable_source, "line 4\nline 5");
        assert_eq!(editor.source_line_label, "Editing source lines 4-5");
        assert_eq!(preview.state().editing.phase, EditingPhase::Active);
    }

    #[test]
    fn save_and_failed_save_preserve_the_current_editor_source_on_windows() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", edit_markdown());
        let mut preview = WindowsPreviewLoop::new();
        let blocks = edit_block_mappings();

        open_visible_preview(&mut preview, &path);
        preview
            .request_edit_at_line(4, edit_markdown(), &blocks)
            .expect("inline editor should open");

        let (replacement_markdown, save_events) = preview
            .save_current_edit(edit_markdown(), "updated\r\nblock", &blocks)
            .expect("save request should be emitted");

        assert_eq!(
            replacement_markdown,
            "line 1\nline 2\nline 3\nupdated\nblock\nline 6\nline 7\nline 8\nline 9\nline 10"
        );
        match product_events(&save_events).as_slice() {
            [AppEvent::MarkdownSaveRequested {
                document,
                replacement_markdown: emitted_markdown,
            }] => {
                assert_eq!(document.display_name, "notes.md");
                assert_eq!(emitted_markdown, &replacement_markdown);
            }
            other => panic!("unexpected save events: {other:?}"),
        }
        assert_eq!(preview.state().editing.phase, EditingPhase::Saving);
        assert_eq!(
            preview.state().editing.draft_source.as_deref(),
            Some("updated\nblock")
        );

        let failed = preview.complete_save(false, None, Some("disk full".to_string()));
        match product_events(&failed).as_slice() {
            [AppEvent::EditSessionChanged { editing }] => {
                assert_eq!(editing.phase, EditingPhase::Active);
                assert_eq!(
                    editing.draft_markdown.as_deref(),
                    Some(replacement_markdown.as_str())
                );
                assert_eq!(editing.draft_source.as_deref(), Some("updated\nblock"));
            }
            other => panic!("unexpected failed-save events: {other:?}"),
        }

        let editor = preview
            .inline_editor(edit_markdown(), &blocks)
            .expect("inline editor should stay open after a failed save");
        assert_eq!(editor.original_source, "line 4\nline 5");
        assert_eq!(editor.editable_source, "updated\nblock");

        let canceled = preview.cancel_edit_session();
        match product_events(&canceled).as_slice() {
            [AppEvent::EditSessionChanged { editing }] => {
                assert_eq!(editing.phase, EditingPhase::Inactive);
                assert_eq!(editing.draft_markdown, None);
                assert_eq!(editing.draft_source, None);
            }
            other => panic!("unexpected cancel events: {other:?}"),
        }
    }

    #[test]
    fn emits_runtime_diagnostics_for_the_windows_edit_lifecycle() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", edit_markdown());
        let mut preview = WindowsPreviewLoop::new();
        let blocks = edit_block_mappings();

        open_visible_preview(&mut preview, &path);

        let edit_events =
            preview.dispatch_command(AppCommand::RequestEdit { target_line: 4 }, &blocks);
        assert!(reported_diagnostics(&edit_events).iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::EditLifecycle
                && diagnostic.summary.contains("entered inline edit mode")
        }));

        let (_, save_events) = preview
            .save_current_edit(edit_markdown(), "updated block", &blocks)
            .expect("save request should be emitted");
        assert!(reported_diagnostics(&save_events).iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::EditLifecycle
                && diagnostic.summary.contains("requested a Markdown save")
        }));

        let failed = preview.complete_save(false, None, Some("disk full".to_string()));
        assert!(reported_diagnostics(&failed).iter().any(|diagnostic| {
            diagnostic.category == RuntimeDiagnosticCategory::EditLifecycle
                && diagnostic.level == fastmd_contracts::RuntimeDiagnosticLevel::Error
                && diagnostic.summary.contains("failed save")
        }));
    }

    #[test]
    fn edit_mode_lock_blocks_replacement_and_close_until_cancel_or_successful_save() {
        let fixture = TempFixture::new();
        let current = fixture.write_file("notes.md", edit_markdown());
        let other = fixture.write_file("other.md", "# other");
        let mut preview = WindowsPreviewLoop::new();
        let blocks = edit_block_mappings();

        open_visible_preview(&mut preview, &current);
        preview
            .request_edit_at_line(4, edit_markdown(), &blocks)
            .expect("inline editor should open");

        assert!(
            product_events(&preview.dispatch_command(AppCommand::OutsideClick, &[])).is_empty()
        );
        assert!(product_events(&preview.dispatch_command(AppCommand::Escape, &[])).is_empty());
        assert!(product_events(
            &preview
                .observe_probe_outputs(4_000, &non_explorer_frontmost_json(), None, None,)
                .expect("frontmost probe should classify"),
        )
        .is_empty());
        assert!(product_events(
            &preview
                .observe_probe_outputs(
                    4_000,
                    &explorer_frontmost_json(),
                    Some(&hovered_item_json(&other, "exact-item-under-pointer")),
                    Some(&coordinate_json(420.0, 220.0)),
                )
                .expect("probe outputs should classify"),
        )
        .is_empty());

        let (persisted_markdown, _) = preview
            .save_current_edit(edit_markdown(), "updated block", &blocks)
            .expect("save request should be emitted");
        assert!(
            product_events(&preview.dispatch_command(AppCommand::OutsideClick, &[])).is_empty()
        );
        assert!(product_events(&preview.dispatch_command(AppCommand::Escape, &[])).is_empty());

        preview.complete_save(true, Some(persisted_markdown), None);
        assert_eq!(
            product_events(&preview.dispatch_command(AppCommand::Escape, &[])),
            vec![AppEvent::PreviewWindowHidden {
                reason: CloseReason::Escape,
            }]
        );
    }

    #[test]
    fn width_tier_command_uses_the_same_windows_width_model_and_repositions_before_shrinking() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json_for_visible_frame(
                    2_150.0, 600.0, 2_200.0, 1_200.0,
                )),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json_for_visible_frame(
                    2_150.0, 600.0, 2_200.0, 1_200.0,
                )),
            )
            .expect("probe outputs should classify");

        let events = preview.dispatch_command(
            AppCommand::AdjustWidthTier {
                delta: 1,
                monitor: None,
            },
            &[],
        );

        let product_events = product_events(&events);
        assert_eq!(
            product_events[0],
            AppEvent::WidthTierChanged {
                selected_width_tier_index: 1,
                requested_width_px: 960,
            }
        );
        match &product_events[1] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(request.selected_width_tier_index, 1);
                assert_eq!(request.requested_width_px, 960);
                assert_eq!(request.frame.width, 960.0);
                assert_eq!(request.frame.height, 720.0);
                assert!(request.frame.x < 2_150.0);
            }
            other => panic!("unexpected event: {other:?}"),
        }
        assert_eq!(
            preview
                .current_warmed_preview_model()
                .map(|model| model.chrome.selected_width_tier_index),
            Some(1)
        );
    }

    #[test]
    fn width_tier_command_only_shrinks_when_the_requested_four_by_three_size_cannot_fit() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hello");
        let mut preview = WindowsPreviewLoop::new();

        preview
            .observe_probe_outputs(
                0,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json_for_visible_frame(
                    500.0, 400.0, 1_000.0, 800.0,
                )),
            )
            .expect("probe outputs should classify");
        preview
            .observe_probe_outputs(
                1_000,
                &explorer_frontmost_json(),
                Some(&hovered_item_json(&path, "exact-item-under-pointer")),
                Some(&coordinate_json_for_visible_frame(
                    500.0, 400.0, 1_000.0, 800.0,
                )),
            )
            .expect("probe outputs should classify");

        let events = preview.dispatch_command(
            AppCommand::AdjustWidthTier {
                delta: 3,
                monitor: None,
            },
            &[],
        );

        let product_events = product_events(&events);
        assert_eq!(
            product_events[0],
            AppEvent::WidthTierChanged {
                selected_width_tier_index: 3,
                requested_width_px: 1_920,
            }
        );
        match &product_events[1] {
            AppEvent::PreviewWindowRequested { request } => {
                assert_eq!(request.selected_width_tier_index, 3);
                assert_eq!(request.requested_width_px, 1_920);
                assert_eq!(request.frame.width, 976.0);
                assert_eq!(request.frame.height, 732.0);
                assert!((request.frame.width / request.frame.height - (4.0 / 3.0)).abs() < 0.0001);
            }
            other => panic!("unexpected event: {other:?}"),
        }
    }

    #[test]
    fn windows_preview_loop_feature_coverage_keeps_top_chrome_drag_explicitly_uncovered() {
        let expected: BTreeSet<_> = [MacOsPreviewFeature::PreviewWindowTopChromeDrag]
            .into_iter()
            .collect();
        let actual: BTreeSet<_> = preview_feature_coverage_record_gaps_against_reference(&[
            &super::windows_preview_loop_feature_coverage_records(),
        ])
        .into_iter()
        .collect();

        assert_eq!(actual, expected);
        assert!(
            macos_preview_feature_list().contains(&MacOsPreviewFeature::PreviewWindowTopChromeDrag)
        );
        assert!(!super::windows_preview_loop_feature_coverage()
            .into_iter()
            .any(|feature| feature == MacOsPreviewFeature::PreviewWindowTopChromeDrag));
    }

    #[test]
    fn windows_preview_loop_feature_coverage_records_keep_shared_and_adapter_lanes_visible() {
        let records = super::windows_preview_loop_feature_coverage_records();
        let recorded_features: BTreeSet<_> = records.iter().map(|record| record.feature).collect();
        let plain_features: BTreeSet<_> = super::windows_preview_loop_feature_coverage()
            .into_iter()
            .collect();

        assert_eq!(recorded_features, plain_features);
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::HoverOpensAfterOneSecond
                && record.lane == PreviewFeatureCoverageLane::SharedCore
        }));
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::MarkdownRenderingSurface
                && record.lane == PreviewFeatureCoverageLane::SharedRender
        }));
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::ExactHoveredMarkdownResolution
                && record.lane == PreviewFeatureCoverageLane::WindowsAdapter
        }));
    }
}
