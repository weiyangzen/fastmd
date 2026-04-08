use std::{
    collections::BTreeMap,
    fs,
    path::{Path, PathBuf},
    sync::Mutex,
    thread,
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
};

use fastmd_platform_linux_nautilus::{
    DIAGNOSTIC_STATUS_EMITTED, DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE, DisplayServerKind,
    EDIT_LIFECYCLE_POLICY, EDIT_LIFECYCLE_RUNTIME_NOTE, FrontmostAppSnapshot,
    FrontmostSurfaceRejection, HoverCandidate, HoverResolutionScope, HoveredEntityKind,
    HoveredItemSnapshot, MONITOR_SELECTION_POLICY, MONITOR_SELECTION_RUNTIME_NOTE,
    Monitor as PlatformMonitor, MonitorLayout as PlatformMonitorLayout, PREVIEW_PLACEMENT_POLICY,
    PREVIEW_PLACEMENT_RUNTIME_NOTE, ScreenPoint as PlatformScreenPoint,
    ScreenRect as PlatformScreenRect, UbuntuPreviewFeatureCoverageSummary,
    UbuntuPreviewLoopValidationBundle, ValidationStatus, api_stack_for_display_server,
    classify_live_frontmost_gate, classify_live_hovered_item, crate_slice_validation_notes,
    display_server_label, frontmost_gate_pending_note, hovered_item_api_stack_for_display_server,
    hovered_item_pending_note, ubuntu_live_validation_checklist_items,
    ubuntu_parity_evidence_checklist_item, ubuntu_parity_evidence_pending_note,
    ubuntu_parity_evidence_required_display_servers,
    ubuntu_preview_feature_coverage_summary,
};
use fastmd_render::{MarkdownFeature, stage2_rendering_contract};
use serde::{Deserialize, Serialize};
use tauri::{
    AppHandle, Emitter, Manager, Monitor as TauriMonitor, PhysicalPosition, PhysicalRect,
    PhysicalSize, Position, Size, State, Url, WebviewWindow, WindowEvent,
};
use tauri_plugin_global_shortcut::Builder as GlobalShortcutBuilder;

const PREVIEW_WINDOW_LABEL: &str = "preview";
const SHELL_STATE_EVENT: &str = "fastmd://shell-state";
const HOST_CAPABILITIES_EVENT: &str = "fastmd://host-capabilities";
const CLOSE_REQUESTED_EVENT: &str = "fastmd://close-requested";
const WIDTH_TIERS: [u32; 4] = [560, 960, 1440, 1920];
const PREVIEW_ASPECT_RATIO: f64 = 4.0 / 3.0;
const PREVIEW_EDGE_INSET: f64 = 12.0;
const PREVIEW_POINTER_OFFSET: f64 = 18.0;
const HOVER_POLL_INTERVAL: Duration = Duration::from_millis(100);
const HOVER_TRIGGER_DELAY: Duration = Duration::from_secs(1);
const LINUX_HOVER_LIFECYCLE_STATUS_POLLING: &str = "polling";
const LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED: &str =
    "cross-session-review-required";
const LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_CAPTURED_AWAITING_REVIEW: &str =
    "cross-session-captured-awaiting-review";
const LINUX_HOVER_LIFECYCLE_NOTE: &str = "Linux hover lifecycle polls the desktop cursor, waits 1 second after the last pointer or hovered-target change, and only then opens or replaces the preview when Nautilus still resolves a Markdown file.";

#[derive(Clone, Copy, Serialize)]
#[serde(rename_all = "camelCase")]
enum BackgroundMode {
    White,
    Black,
}

impl BackgroundMode {
    fn toggled(self) -> Self {
        match self {
            Self::White => Self::Black,
            Self::Black => Self::White,
        }
    }
}

#[derive(Clone, Copy, Serialize, PartialEq, Eq, Debug)]
#[serde(rename_all = "camelCase")]
enum RuntimeMode {
    Desktop,
    Fallback,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct ShellStatePayload {
    document_title: String,
    markdown: String,
    content_base_url: Option<String>,
    source_document_path: Option<String>,
    width_tiers: [u32; 4],
    selected_width_tier_index: usize,
    background_mode: BackgroundMode,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct HostCapabilitiesPayload {
    platform_id: &'static str,
    runtime_mode: RuntimeMode,
    accessibility_permission: &'static str,
    frontmost_file_manager: &'static str,
    preview_window_positioning: bool,
    global_shortcut_registered: bool,
    close_on_blur_enabled: bool,
    can_persist_preview_edits: bool,
    hot_interaction_surface: Option<HotInteractionSurfacePayload>,
    preview_window_drag_surface: Option<PreviewWindowDragSurfacePayload>,
    shared_rendering_surface: Option<SharedRenderingSurfacePayload>,
    linux_probe_plans: Option<LinuxProbePlansPayload>,
    linux_preview_placement: Option<LinuxPreviewPlacementPayload>,
    linux_parity_coverage: Option<UbuntuPreviewFeatureCoverageSummary>,
    linux_preview_loop_validation: Option<UbuntuPreviewLoopValidationBundle>,
    linux_validation_evidence: Option<LinuxValidationEvidencePayload>,
    linux_runtime_diagnostics: Option<LinuxRuntimeDiagnosticsPayload>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BootstrapPayload {
    shell_state: ShellStatePayload,
    host_capabilities: HostCapabilitiesPayload,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct HotInteractionSurfacePayload {
    window_focus_strategy: &'static str,
    dom_focus_target: &'static str,
    pointer_scroll_routing: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct PreviewWindowDragSurfacePayload {
    strategy: &'static str,
    drag_handle_selector: &'static str,
    activation: &'static str,
    guardrail: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct SharedRenderingSurfacePayload {
    source: &'static str,
    macos_reference_renderer: &'static str,
    supported_features: Vec<String>,
    width_tiers_px: Vec<u32>,
    aspect_ratio: f64,
    render_pipeline: &'static str,
}

#[derive(Clone, Copy, Serialize, Deserialize, Debug, PartialEq)]
#[serde(rename_all = "camelCase")]
struct ScreenPoint {
    x: f64,
    y: f64,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct PreviewGeometryPayload {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
}

#[derive(Clone, Copy, Serialize)]
#[serde(rename_all = "camelCase")]
struct ScreenRectPayload {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct CloseRequestPayload {
    reason: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxProbePlansPayload {
    wayland_frontmost_api_stack: String,
    x11_frontmost_api_stack: String,
    wayland_hovered_item_api_stack: String,
    x11_hovered_item_api_stack: String,
    semantic_guardrail: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxPreviewPlacementPayload {
    monitor_work_area_source: &'static str,
    monitor_selection_policy: &'static str,
    coordinate_space: &'static str,
    aspect_ratio: &'static str,
    edge_inset_px: u32,
    pointer_offset_px: u32,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxValidationEvidencePayload {
    status: String,
    checklist_item: String,
    note: String,
    required_display_servers: Vec<String>,
    captured_display_servers: Vec<String>,
    missing_display_servers: Vec<String>,
    ready_display_server_reports: Vec<String>,
    latest_reports: Vec<LinuxValidationEvidenceReportPayload>,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct LinuxValidationEvidenceReportPayload {
    display_server: String,
    captured_at_unix_ms: u64,
    ready_to_close_display_server_report: bool,
    report_json_path: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxFrontmostGateDiagnosticPayload {
    status: &'static str,
    display_server: &'static str,
    backend: Option<String>,
    api_stack: String,
    observed_identifier: Option<String>,
    stable_surface_id: Option<String>,
    window_title: Option<String>,
    process_id: Option<u32>,
    is_open: Option<bool>,
    text_input_active: Option<bool>,
    text_input_role: Option<String>,
    text_input_name: Option<String>,
    inferred_blur_close_reason: Option<String>,
    rejection: Option<String>,
    detail: Option<String>,
    note: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxHoveredItemDiagnosticPayload {
    status: &'static str,
    display_server: &'static str,
    api_stack: String,
    backend: Option<String>,
    resolution_scope: Option<String>,
    entity_kind: Option<String>,
    item_name: Option<String>,
    path: Option<String>,
    path_source: Option<String>,
    visible_markdown_peer_count: Option<usize>,
    accepted: Option<bool>,
    rejection: Option<String>,
    detail: Option<String>,
    note: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxMonitorSelectionDiagnosticPayload {
    status: &'static str,
    selection_policy: &'static str,
    anchor: Option<ScreenPoint>,
    selected_monitor_id: Option<String>,
    used_nearest_fallback: Option<bool>,
    work_area: Option<ScreenRectPayload>,
    note: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxPreviewPlacementDiagnosticPayload {
    status: &'static str,
    policy: &'static str,
    requested_width: Option<u32>,
    applied_geometry: Option<PreviewGeometryPayload>,
    note: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxEditLifecycleDiagnosticPayload {
    status: &'static str,
    policy: &'static str,
    editing: bool,
    close_on_blur_enabled: bool,
    can_persist_preview_edits: bool,
    last_close_reason: Option<String>,
    note: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxHoverLifecycleDiagnosticPayload {
    status: &'static str,
    polling_interval_ms: u64,
    trigger_delay_ms: u64,
    last_anchor: Option<ScreenPoint>,
    observed_path: Option<String>,
    preview_visible: bool,
    preview_path: Option<String>,
    last_action: Option<String>,
    note: &'static str,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct LinuxRuntimeDiagnosticsPayload {
    display_server: &'static str,
    frontmost_gate: LinuxFrontmostGateDiagnosticPayload,
    hovered_item: LinuxHoveredItemDiagnosticPayload,
    monitor_selection: LinuxMonitorSelectionDiagnosticPayload,
    preview_placement: LinuxPreviewPlacementDiagnosticPayload,
    edit_lifecycle: LinuxEditLifecycleDiagnosticPayload,
    hover_lifecycle: LinuxHoverLifecycleDiagnosticPayload,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct LinuxValidationNotePayload {
    item: String,
    status: String,
    note: String,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct LinuxValidationSectionPayload {
    title: String,
    status: String,
    checklist_items: Vec<String>,
    details: Vec<String>,
}

#[derive(Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
struct LinuxValidationReportPayload {
    target: String,
    reference_surface: String,
    display_server: String,
    captured_at_unix_ms: u64,
    anchor: Option<ScreenPoint>,
    ready_to_close_display_server_report: bool,
    cross_session_parity_evidence_ready: bool,
    cross_session_parity_evidence_note: String,
    #[serde(default)]
    cross_session_required_display_servers: Vec<String>,
    #[serde(default)]
    cross_session_captured_display_servers: Vec<String>,
    #[serde(default)]
    cross_session_missing_display_servers: Vec<String>,
    #[serde(default)]
    cross_session_ready_display_server_reports: Vec<String>,
    ready_checklist_items: Vec<String>,
    blocked_checklist_items: Vec<String>,
    sections: Vec<LinuxValidationSectionPayload>,
    notes: Vec<LinuxValidationNotePayload>,
    markdown: String,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct DesktopShellValidationSnapshotPayload {
    captured_at_unix_ms: u64,
    shell_state: ShellStatePayload,
    host_capabilities: HostCapabilitiesPayload,
    linux_validation_report: Option<LinuxValidationReportPayload>,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct DesktopShellValidationArtifactExportPayload {
    captured_at_unix_ms: u64,
    output_directory: String,
    snapshot_markdown_path: String,
    linux_validation_report_markdown_path: Option<String>,
    linux_validation_report_json_path: Option<String>,
    display_server: Option<String>,
    linux_validation_evidence: Option<LinuxValidationEvidencePayload>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum LinuxValidationSectionStatus {
    Pass,
    Fail,
    NotCaptured,
}

impl LinuxValidationSectionStatus {
    fn label(self) -> &'static str {
        match self {
            Self::Pass => "pass",
            Self::Fail => "fail",
            Self::NotCaptured => "not-captured",
        }
    }

    fn is_pass(self) -> bool {
        matches!(self, Self::Pass)
    }
}

#[derive(Clone, Debug)]
struct LinuxValidationSection {
    title: &'static str,
    status: LinuxValidationSectionStatus,
    checklist_item: Option<String>,
    details: Vec<String>,
}

impl LinuxValidationSection {
    fn into_payload(self) -> LinuxValidationSectionPayload {
        LinuxValidationSectionPayload {
            title: self.title.to_owned(),
            status: self.status.label().to_owned(),
            checklist_items: self.checklist_item.into_iter().collect(),
            details: self.details,
        }
    }
}

#[derive(Clone)]
struct SelectedMonitorWorkArea {
    monitor_id: String,
    work_area: PlatformScreenRect,
    used_nearest_fallback: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct HoverObservationKey {
    cursor_x: i32,
    cursor_y: i32,
    gate_fingerprint: String,
    hover_fingerprint: String,
}

#[derive(Debug, Clone)]
struct LinuxHoverObservation {
    key: HoverObservationKey,
    anchor: ScreenPoint,
    observed_markdown_path: Option<String>,
}

#[derive(Debug, Clone)]
struct LinuxHoverRuntimeState {
    last_observation: Option<HoverObservationKey>,
    last_change_at: Option<Instant>,
    executed_observation: Option<HoverObservationKey>,
    preview_visible: bool,
}

impl Default for LinuxHoverRuntimeState {
    fn default() -> Self {
        Self {
            last_observation: None,
            last_change_at: None,
            executed_observation: None,
            preview_visible: false,
        }
    }
}

#[derive(Debug, Clone)]
enum HoverLifecycleAction {
    Open { path: String, anchor: ScreenPoint },
    Replace { path: String, anchor: ScreenPoint },
    SuppressSameItem,
}

#[derive(Debug, Clone)]
struct HoverLifecycleStep {
    observation_changed: bool,
    action: Option<HoverLifecycleAction>,
}

struct ShellBridgeState {
    shell_state: Mutex<ShellStatePayload>,
    host_capabilities: Mutex<HostCapabilitiesPayload>,
    is_editing: Mutex<bool>,
    last_anchor: Mutex<Option<ScreenPoint>>,
    linux_hover_runtime: Mutex<LinuxHoverRuntimeState>,
}

impl ShellBridgeState {
    fn new() -> Self {
        let shell_state = initial_shell_state();
        let host_capabilities = initial_host_capabilities(&shell_state);

        Self {
            shell_state: Mutex::new(shell_state),
            host_capabilities: Mutex::new(host_capabilities),
            is_editing: Mutex::new(false),
            last_anchor: Mutex::new(None),
            linux_hover_runtime: Mutex::new(LinuxHoverRuntimeState::default()),
        }
    }

    fn bootstrap_payload(&self) -> BootstrapPayload {
        BootstrapPayload {
            shell_state: self.snapshot_shell_state(),
            host_capabilities: self.snapshot_host_capabilities(),
        }
    }

    fn snapshot_shell_state(&self) -> ShellStatePayload {
        self.shell_state.lock().unwrap().clone()
    }

    fn snapshot_host_capabilities(&self) -> HostCapabilitiesPayload {
        self.host_capabilities.lock().unwrap().clone()
    }
}

fn initial_shell_state() -> ShellStatePayload {
    let source_document = bootstrap_source_document_path();
    let markdown = source_document
        .as_ref()
        .and_then(|path| fs::read_to_string(path).ok())
        .unwrap_or_else(|| include_str!("../../../../README.md").to_owned());
    let document_title = source_document
        .as_ref()
        .and_then(|path| file_name_label(path))
        .unwrap_or("README.md".to_owned());

    ShellStatePayload {
        document_title,
        markdown,
        content_base_url: source_document
            .as_deref()
            .and_then(content_base_url_for_source_document),
        source_document_path: source_document.as_deref().map(path_string),
        width_tiers: WIDTH_TIERS,
        selected_width_tier_index: 0,
        background_mode: BackgroundMode::White,
    }
}

fn initial_host_capabilities(shell_state: &ShellStatePayload) -> HostCapabilitiesPayload {
    let mut host_capabilities = HostCapabilitiesPayload {
        platform_id: detected_platform_id(),
        runtime_mode: RuntimeMode::Desktop,
        accessibility_permission: "unknown",
        frontmost_file_manager: "unknown",
        preview_window_positioning: true,
        global_shortcut_registered: true,
        close_on_blur_enabled: true,
        can_persist_preview_edits: false,
        hot_interaction_surface: hot_interaction_surface_payload(),
        preview_window_drag_surface: preview_window_drag_surface_payload(),
        shared_rendering_surface: shared_rendering_surface_payload(),
        linux_probe_plans: linux_probe_plans_payload(),
        linux_preview_placement: linux_preview_placement_payload(),
        linux_parity_coverage: linux_parity_coverage_payload(),
        linux_preview_loop_validation: linux_preview_loop_validation_payload(),
        linux_validation_evidence: linux_validation_evidence_payload(),
        linux_runtime_diagnostics: linux_runtime_diagnostics_payload(),
    };
    refresh_edit_persistence_capability(&mut host_capabilities, shell_state);
    refresh_linux_validation_evidence(&mut host_capabilities);
    refresh_linux_frontmost_gate_diagnostics(&mut host_capabilities);
    host_capabilities
}

fn detected_platform_id() -> &'static str {
    if cfg!(target_os = "macos") {
        "macos"
    } else if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "linux") {
        "ubuntu"
    } else {
        "shell"
    }
}

fn linux_probe_plans_payload() -> Option<LinuxProbePlansPayload> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    let wayland_probe_plan = fastmd_platform_linux_nautilus::backends::wayland::probe_plan();
    let x11_probe_plan = fastmd_platform_linux_nautilus::backends::x11::probe_plan();
    debug_assert_eq!(
        wayland_probe_plan.semantic_guardrail, x11_probe_plan.semantic_guardrail,
        "Wayland and X11 backend plans must preserve one shared FastMD semantic guardrail",
    );

    Some(LinuxProbePlansPayload {
        wayland_frontmost_api_stack: api_stack_for_display_server(DisplayServerKind::Wayland)
            .diagnostic_summary(),
        x11_frontmost_api_stack: api_stack_for_display_server(DisplayServerKind::X11)
            .diagnostic_summary(),
        wayland_hovered_item_api_stack: hovered_item_api_stack_for_display_server(
            DisplayServerKind::Wayland,
        )
        .diagnostic_summary(),
        x11_hovered_item_api_stack: hovered_item_api_stack_for_display_server(
            DisplayServerKind::X11,
        )
        .diagnostic_summary(),
        semantic_guardrail: wayland_probe_plan.semantic_guardrail,
    })
}

fn hot_interaction_surface_payload() -> Option<HotInteractionSurfacePayload> {
    if !matches!(detected_platform_id(), "macos" | "windows" | "ubuntu") {
        return None;
    }

    Some(HotInteractionSurfacePayload {
        window_focus_strategy: "tauri show+set_focus on reveal and global re-open",
        dom_focus_target: ".shell root with tabindex=-1 after shell renders",
        pointer_scroll_routing: "shared frontend wheel delta normalization routed into preview scroll",
    })
}

fn preview_window_drag_surface_payload() -> Option<PreviewWindowDragSurfacePayload> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    Some(PreviewWindowDragSurfacePayload {
        strategy: "shared toolbar mousedown -> Tauri WebviewWindow::start_dragging",
        drag_handle_selector: ".toolbar",
        activation: "primary-button mousedown on top chrome only",
        guardrail:
            "Ubuntu only advertises hidden top-chrome drag metadata so blur-close and edit-lock wiring stay unchanged while the preview window moves.",
    })
}

fn markdown_feature_label(feature: MarkdownFeature) -> &'static str {
    match feature {
        MarkdownFeature::Heading => "heading",
        MarkdownFeature::Paragraph => "paragraph",
        MarkdownFeature::Emphasis => "emphasis",
        MarkdownFeature::Strong => "strong",
        MarkdownFeature::FencedCode => "fenced-code",
        MarkdownFeature::SyntaxHighlightedCode => "syntax-highlighted-code",
        MarkdownFeature::Blockquote => "blockquote",
        MarkdownFeature::TaskList => "task-list",
        MarkdownFeature::Table => "table",
        MarkdownFeature::Mermaid => "mermaid",
        MarkdownFeature::Math => "math",
        MarkdownFeature::Image => "image",
        MarkdownFeature::Footnote => "footnote",
        MarkdownFeature::HtmlBlock => "html-block",
    }
}

fn shared_rendering_surface_payload() -> Option<SharedRenderingSurfacePayload> {
    if !matches!(
        detected_platform_id(),
        "macos" | "windows" | "ubuntu" | "shell"
    ) {
        return None;
    }

    let contract = stage2_rendering_contract(0);
    Some(SharedRenderingSurfacePayload {
        source: "fastmd-render::stage2_rendering_contract",
        macos_reference_renderer: "apps/macos/Sources/FastMD/MarkdownRenderer.swift",
        supported_features: contract
            .supported_features
            .into_iter()
            .map(markdown_feature_label)
            .map(ToOwned::to_owned)
            .collect(),
        width_tiers_px: contract.width_tiers_px,
        aspect_ratio: contract.aspect_ratio,
        render_pipeline: "offscreen-stage-then-atomic-swap",
    })
}

fn linux_preview_placement_payload() -> Option<LinuxPreviewPlacementPayload> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    Some(LinuxPreviewPlacementPayload {
        monitor_work_area_source: "tauri-runtime-wry linux monitor.work_area via GDK/GNOME workarea",
        monitor_selection_policy: MONITOR_SELECTION_POLICY,
        coordinate_space: "desktop-space physical pixels",
        aspect_ratio: "4:3",
        edge_inset_px: PREVIEW_EDGE_INSET as u32,
        pointer_offset_px: PREVIEW_POINTER_OFFSET as u32,
    })
}

fn linux_parity_coverage_payload() -> Option<UbuntuPreviewFeatureCoverageSummary> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    Some(ubuntu_preview_feature_coverage_summary())
}

fn linux_preview_loop_validation_payload() -> Option<UbuntuPreviewLoopValidationBundle> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    Some(fastmd_platform_linux_nautilus::ubuntu_preview_loop_validation_bundle())
}

fn required_linux_validation_display_servers() -> Vec<String> {
    ubuntu_parity_evidence_required_display_servers()
        .iter()
        .map(|display_server| display_server_label(Some(*display_server)).to_owned())
        .collect()
}

fn load_linux_validation_report_artifact(
    path: &Path,
) -> Option<LinuxValidationEvidenceReportPayload> {
    let report: LinuxValidationReportPayload =
        serde_json::from_str(&fs::read_to_string(path).ok()?).ok()?;
    let display_server = report.display_server.clone();

    Some(LinuxValidationEvidenceReportPayload {
        display_server,
        captured_at_unix_ms: report.captured_at_unix_ms,
        ready_to_close_display_server_report: report.ready_to_close_display_server_report,
        report_json_path: path_string(path),
    })
}

fn linux_validation_evidence_payload_for_directory(
    output_directory: &Path,
) -> LinuxValidationEvidencePayload {
    let required_display_servers = required_linux_validation_display_servers();
    let mut latest_reports_by_display_server: BTreeMap<String, LinuxValidationEvidenceReportPayload> =
        BTreeMap::new();

    if let Ok(entries) = fs::read_dir(output_directory) {
        for entry in entries.flatten() {
            let path = entry.path();
            let Some(file_name) = path.file_name().and_then(|value| value.to_str()) else {
                continue;
            };
            if !file_name.starts_with("ubuntu-validation-report-") || !file_name.ends_with(".json")
            {
                continue;
            }

            let Some(artifact_report) = load_linux_validation_report_artifact(&path) else {
                continue;
            };
            if !required_display_servers
                .iter()
                .any(|display_server| display_server == &artifact_report.display_server)
            {
                continue;
            }

            match latest_reports_by_display_server.get(&artifact_report.display_server) {
                Some(existing)
                    if existing.captured_at_unix_ms >= artifact_report.captured_at_unix_ms => {}
                _ => {
                    latest_reports_by_display_server
                        .insert(artifact_report.display_server.clone(), artifact_report);
                }
            }
        }
    }

    let latest_reports: Vec<_> = required_display_servers
        .iter()
        .filter_map(|display_server| latest_reports_by_display_server.remove(display_server))
        .collect();
    let captured_display_servers: Vec<_> = latest_reports
        .iter()
        .map(|report| report.display_server.clone())
        .collect();
    let ready_display_server_reports: Vec<_> = latest_reports
        .iter()
        .filter(|report| report.ready_to_close_display_server_report)
        .map(|report| report.display_server.clone())
        .collect();
    let missing_display_servers: Vec<_> = required_display_servers
        .iter()
        .filter(|display_server| {
            !captured_display_servers
                .iter()
                .any(|captured| captured == *display_server)
        })
        .cloned()
        .collect();

    let all_required_reports_captured =
        missing_display_servers.is_empty() && latest_reports.len() == required_display_servers.len();
    let all_required_reports_ready =
        all_required_reports_captured
            && ready_display_server_reports.len() == required_display_servers.len();
    let status = if all_required_reports_ready {
        LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_CAPTURED_AWAITING_REVIEW
    } else {
        LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED
    };

    let note = if all_required_reports_ready {
        format!(
            "Wayland and X11 live Ubuntu validation reports now exist under `{}` and both display-server reports are individually ready to close, but the umbrella Ubuntu parity-evidence checklist item must stay open until those real-machine captures are reviewed and explicitly signed off.",
            path_string(output_directory)
        )
    } else if all_required_reports_captured {
        format!(
            "Wayland and X11 live Ubuntu validation reports now exist under `{}`, but at least one display-server report is not yet individually ready to close. Keep the umbrella Ubuntu parity-evidence checklist item open until both display-server reports pass and reviewed real-machine sign-off exists.",
            path_string(output_directory)
        )
    } else {
        ubuntu_parity_evidence_pending_note().to_owned()
    };

    LinuxValidationEvidencePayload {
        status: status.to_owned(),
        checklist_item: ubuntu_parity_evidence_checklist_item().to_owned(),
        note,
        required_display_servers,
        captured_display_servers,
        missing_display_servers,
        ready_display_server_reports,
        latest_reports,
    }
}

fn linux_validation_evidence_payload() -> Option<LinuxValidationEvidencePayload> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    Some(linux_validation_evidence_payload_for_directory(
        &test_logs_output_directory(),
    ))
}

fn detected_linux_display_server() -> Option<DisplayServerKind> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    match std::env::var("XDG_SESSION_TYPE").ok().as_deref() {
        Some("wayland") => Some(DisplayServerKind::Wayland),
        Some("x11") => Some(DisplayServerKind::X11),
        _ if std::env::var_os("WAYLAND_DISPLAY").is_some() => Some(DisplayServerKind::Wayland),
        _ if std::env::var_os("DISPLAY").is_some() => Some(DisplayServerKind::X11),
        _ => None,
    }
}

fn active_frontmost_api_stack_summary(display_server: Option<DisplayServerKind>) -> String {
    match display_server {
        Some(display_server) => api_stack_for_display_server(display_server).diagnostic_summary(),
        None => format!(
            "session=unknown; wayland={} ; x11={}",
            api_stack_for_display_server(DisplayServerKind::Wayland).diagnostic_summary(),
            api_stack_for_display_server(DisplayServerKind::X11).diagnostic_summary(),
        ),
    }
}

fn active_hovered_item_api_stack_summary(display_server: Option<DisplayServerKind>) -> String {
    match display_server {
        Some(display_server) => {
            hovered_item_api_stack_for_display_server(display_server).diagnostic_summary()
        }
        None => format!(
            "session=unknown; wayland={} ; x11={}",
            hovered_item_api_stack_for_display_server(DisplayServerKind::Wayland)
                .diagnostic_summary(),
            hovered_item_api_stack_for_display_server(DisplayServerKind::X11).diagnostic_summary(),
        ),
    }
}

fn linux_runtime_diagnostics_payload() -> Option<LinuxRuntimeDiagnosticsPayload> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    let display_server = detected_linux_display_server();
    let display_server_label = display_server_label(display_server);

    Some(LinuxRuntimeDiagnosticsPayload {
        display_server: display_server_label,
        frontmost_gate: LinuxFrontmostGateDiagnosticPayload {
            status: DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE,
            display_server: display_server_label,
            backend: None,
            api_stack: active_frontmost_api_stack_summary(display_server),
            observed_identifier: None,
            stable_surface_id: None,
            window_title: None,
            process_id: None,
            is_open: None,
            text_input_active: None,
            text_input_role: None,
            text_input_name: None,
            inferred_blur_close_reason: None,
            rejection: None,
            detail: None,
            note: frontmost_gate_pending_note(display_server).to_owned(),
        },
        hovered_item: LinuxHoveredItemDiagnosticPayload {
            status: DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE,
            display_server: display_server_label,
            api_stack: active_hovered_item_api_stack_summary(display_server),
            backend: None,
            resolution_scope: None,
            entity_kind: None,
            item_name: None,
            path: None,
            path_source: None,
            visible_markdown_peer_count: None,
            accepted: None,
            rejection: None,
            detail: None,
            note: hovered_item_pending_note(display_server).to_owned(),
        },
        monitor_selection: LinuxMonitorSelectionDiagnosticPayload {
            status: DIAGNOSTIC_STATUS_EMITTED,
            selection_policy: MONITOR_SELECTION_POLICY,
            anchor: None,
            selected_monitor_id: None,
            used_nearest_fallback: None,
            work_area: None,
            note: MONITOR_SELECTION_RUNTIME_NOTE,
        },
        preview_placement: LinuxPreviewPlacementDiagnosticPayload {
            status: DIAGNOSTIC_STATUS_EMITTED,
            policy: PREVIEW_PLACEMENT_POLICY,
            requested_width: Some(WIDTH_TIERS[0]),
            applied_geometry: None,
            note: PREVIEW_PLACEMENT_RUNTIME_NOTE,
        },
        edit_lifecycle: LinuxEditLifecycleDiagnosticPayload {
            status: DIAGNOSTIC_STATUS_EMITTED,
            policy: EDIT_LIFECYCLE_POLICY,
            editing: false,
            close_on_blur_enabled: true,
            can_persist_preview_edits: false,
            last_close_reason: None,
            note: EDIT_LIFECYCLE_RUNTIME_NOTE,
        },
        hover_lifecycle: LinuxHoverLifecycleDiagnosticPayload {
            status: LINUX_HOVER_LIFECYCLE_STATUS_POLLING,
            polling_interval_ms: HOVER_POLL_INTERVAL.as_millis() as u64,
            trigger_delay_ms: HOVER_TRIGGER_DELAY.as_millis() as u64,
            last_anchor: None,
            observed_path: None,
            preview_visible: false,
            preview_path: None,
            last_action: None,
            note: LINUX_HOVER_LIFECYCLE_NOTE,
        },
    })
}

fn current_unix_ms() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_millis() as u64)
        .unwrap_or(0)
}

fn linux_validation_note_status_label(status: ValidationStatus) -> &'static str {
    match status {
        ValidationStatus::ImplementedInSlice => "implemented-in-slice",
        ValidationStatus::NeedsUbuntuHostValidation => "needs-ubuntu-host-validation",
        ValidationStatus::BlockedByLowerLayers => "blocked-by-lower-layers",
    }
}

fn linux_validation_display_server_kind(display_server: &str) -> Option<DisplayServerKind> {
    match display_server {
        "wayland" => Some(DisplayServerKind::Wayland),
        "x11" => Some(DisplayServerKind::X11),
        _ => None,
    }
}

fn linux_validation_target(host_capabilities: &HostCapabilitiesPayload) -> String {
    host_capabilities
        .linux_parity_coverage
        .as_ref()
        .map(|payload| payload.target.to_owned())
        .unwrap_or_else(|| "Ubuntu 24.04 + GNOME Files / Nautilus".to_owned())
}

fn linux_validation_reference_surface(host_capabilities: &HostCapabilitiesPayload) -> String {
    host_capabilities
        .linux_parity_coverage
        .as_ref()
        .map(|payload| payload.reference_surface.to_owned())
        .unwrap_or_else(|| "apps/macos".to_owned())
}

fn linux_validation_format_point(point: Option<ScreenPoint>) -> String {
    point
        .map(|point| format!("x={}, y={}", point.x, point.y))
        .unwrap_or_else(|| "not-captured".to_owned())
}

fn linux_validation_format_rect(rect: Option<&ScreenRectPayload>) -> String {
    rect.map(|rect| {
        format!(
            "x={}, y={}, width={}, height={}",
            rect.x, rect.y, rect.width, rect.height
        )
    })
    .unwrap_or_else(|| "not-captured".to_owned())
}

fn linux_validation_format_geometry(geometry: Option<&PreviewGeometryPayload>) -> String {
    geometry
        .map(|geometry| {
            format!(
                "x={}, y={}, width={}, height={}",
                geometry.x, geometry.y, geometry.width, geometry.height
            )
        })
        .unwrap_or_else(|| "not-captured".to_owned())
}

fn linux_validation_format_list(values: &[String]) -> String {
    if values.is_empty() {
        "none".to_owned()
    } else {
        values.join(", ")
    }
}

fn linux_validation_notes_payload() -> Vec<LinuxValidationNotePayload> {
    crate_slice_validation_notes()
        .into_iter()
        .map(|note| LinuxValidationNotePayload {
            item: note.item.to_owned(),
            status: linux_validation_note_status_label(note.status).to_owned(),
            note: note.note.to_owned(),
        })
        .collect()
}

fn build_linux_frontmost_validation_section(
    host_capabilities: &HostCapabilitiesPayload,
    display_server: DisplayServerKind,
) -> LinuxValidationSection {
    let checklist_item = ubuntu_live_validation_checklist_items(display_server)[0].to_owned();
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_ref() else {
        return LinuxValidationSection {
            title: "Frontmost Nautilus evidence",
            status: LinuxValidationSectionStatus::NotCaptured,
            checklist_item: Some(checklist_item),
            details: vec![
                "The shared desktop shell is not currently publishing Linux runtime diagnostics."
                    .to_owned(),
            ],
        };
    };
    let frontmost_gate = &diagnostics.frontmost_gate;
    let status = if frontmost_gate.status == DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE {
        LinuxValidationSectionStatus::NotCaptured
    } else if frontmost_gate.status == DIAGNOSTIC_STATUS_EMITTED
        && frontmost_gate.is_open == Some(true)
        && host_capabilities.frontmost_file_manager == "nautilus"
    {
        LinuxValidationSectionStatus::Pass
    } else {
        LinuxValidationSectionStatus::Fail
    };

    LinuxValidationSection {
        title: "Frontmost Nautilus evidence",
        status,
        checklist_item: Some(checklist_item),
        details: vec![
            format!("Display server: {}", frontmost_gate.display_server),
            format!(
                "Frontmost file manager: {}",
                host_capabilities.frontmost_file_manager
            ),
            format!(
                "Observed identifier: {}",
                frontmost_gate
                    .observed_identifier
                    .as_deref()
                    .unwrap_or("not-captured")
            ),
            format!(
                "Stable surface id: {}",
                frontmost_gate
                    .stable_surface_id
                    .as_deref()
                    .unwrap_or("not-captured")
            ),
            format!(
                "Gate open: {}",
                frontmost_gate
                    .is_open
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Rejection: {}",
                frontmost_gate.rejection.as_deref().unwrap_or("none")
            ),
            format!("API stack: {}", frontmost_gate.api_stack),
            format!(
                "Backend: {}",
                frontmost_gate.backend.as_deref().unwrap_or("not-captured")
            ),
            format!(
                "Detail: {}",
                frontmost_gate.detail.as_deref().unwrap_or("not-captured")
            ),
            format!("Note: {}", frontmost_gate.note),
        ],
    }
}

fn build_linux_hover_validation_section(
    host_capabilities: &HostCapabilitiesPayload,
    display_server: DisplayServerKind,
) -> LinuxValidationSection {
    let checklist_item = ubuntu_live_validation_checklist_items(display_server)[1].to_owned();
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_ref() else {
        return LinuxValidationSection {
            title: "Hovered Markdown evidence",
            status: LinuxValidationSectionStatus::NotCaptured,
            checklist_item: Some(checklist_item),
            details: vec![
                "The shared desktop shell is not currently publishing Linux runtime diagnostics."
                    .to_owned(),
            ],
        };
    };
    let hovered_item = &diagnostics.hovered_item;
    let accepted_scope = matches!(
        hovered_item.resolution_scope.as_deref(),
        Some("exact-item-under-pointer" | "hovered-row-descendant")
    );
    let accepted_markdown_path = hovered_item
        .path
        .as_deref()
        .is_some_and(|path| path.ends_with(".md"));
    let status = if hovered_item.status == DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE {
        LinuxValidationSectionStatus::NotCaptured
    } else if hovered_item.status == DIAGNOSTIC_STATUS_EMITTED
        && hovered_item.accepted == Some(true)
        && accepted_scope
        && accepted_markdown_path
    {
        LinuxValidationSectionStatus::Pass
    } else {
        LinuxValidationSectionStatus::Fail
    };

    LinuxValidationSection {
        title: "Hovered Markdown evidence",
        status,
        checklist_item: Some(checklist_item),
        details: vec![
            format!("Display server: {}", hovered_item.display_server),
            format!(
                "Resolution scope: {}",
                hovered_item
                    .resolution_scope
                    .as_deref()
                    .unwrap_or("not-captured")
            ),
            format!(
                "Accepted: {}",
                hovered_item
                    .accepted
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Item name: {}",
                hovered_item.item_name.as_deref().unwrap_or("not-captured")
            ),
            format!(
                "Path: {}",
                hovered_item.path.as_deref().unwrap_or("not-captured")
            ),
            format!(
                "Path source: {}",
                hovered_item
                    .path_source
                    .as_deref()
                    .unwrap_or("not-captured")
            ),
            format!(
                "Visible Markdown peers: {}",
                hovered_item
                    .visible_markdown_peer_count
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Rejection: {}",
                hovered_item.rejection.as_deref().unwrap_or("none")
            ),
            format!("API stack: {}", hovered_item.api_stack),
            format!(
                "Backend: {}",
                hovered_item.backend.as_deref().unwrap_or("not-captured")
            ),
            format!(
                "Detail: {}",
                hovered_item.detail.as_deref().unwrap_or("not-captured")
            ),
            format!("Note: {}", hovered_item.note),
        ],
    }
}

fn build_linux_monitor_validation_section(
    host_capabilities: &HostCapabilitiesPayload,
    display_server: DisplayServerKind,
) -> LinuxValidationSection {
    let checklist_item = ubuntu_live_validation_checklist_items(display_server)[2].to_owned();
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_ref() else {
        return LinuxValidationSection {
            title: "Monitor and coordinate evidence",
            status: LinuxValidationSectionStatus::NotCaptured,
            checklist_item: Some(checklist_item),
            details: vec![
                "The shared desktop shell is not currently publishing Linux runtime diagnostics."
                    .to_owned(),
            ],
        };
    };
    let monitor_selection = &diagnostics.monitor_selection;
    let preview_placement = &diagnostics.preview_placement;
    let status = if monitor_selection.selected_monitor_id.is_none()
        && monitor_selection.work_area.is_none()
        && preview_placement.applied_geometry.is_none()
    {
        LinuxValidationSectionStatus::NotCaptured
    } else if monitor_selection.status == DIAGNOSTIC_STATUS_EMITTED
        && monitor_selection.selected_monitor_id.is_some()
        && monitor_selection.work_area.is_some()
        && preview_placement.applied_geometry.is_some()
    {
        LinuxValidationSectionStatus::Pass
    } else {
        LinuxValidationSectionStatus::Fail
    };

    LinuxValidationSection {
        title: "Monitor and coordinate evidence",
        status,
        checklist_item: Some(checklist_item),
        details: vec![
            format!("Display server: {}", diagnostics.display_server),
            format!("Selection policy: {}", monitor_selection.selection_policy),
            format!(
                "Anchor: {}",
                linux_validation_format_point(monitor_selection.anchor)
            ),
            format!(
                "Selected monitor id: {}",
                monitor_selection
                    .selected_monitor_id
                    .as_deref()
                    .unwrap_or("not-captured")
            ),
            format!(
                "Used nearest fallback: {}",
                monitor_selection
                    .used_nearest_fallback
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Work area: {}",
                linux_validation_format_rect(monitor_selection.work_area.as_ref())
            ),
            format!(
                "Requested width: {}",
                preview_placement
                    .requested_width
                    .map(|value| value.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Applied geometry: {}",
                linux_validation_format_geometry(preview_placement.applied_geometry.as_ref())
            ),
            format!("Monitor note: {}", monitor_selection.note),
            format!("Placement note: {}", preview_placement.note),
        ],
    }
}

fn build_linux_automated_parity_section(
    host_capabilities: &HostCapabilitiesPayload,
) -> LinuxValidationSection {
    let parity_coverage = host_capabilities.linux_parity_coverage.as_ref();
    let preview_loop_validation = host_capabilities.linux_preview_loop_validation.as_ref();
    let status = match (parity_coverage, preview_loop_validation) {
        (Some(parity_coverage), Some(preview_loop_validation))
            if parity_coverage.matches_reference
                && parity_coverage.missing_features.is_empty()
                && preview_loop_validation.wayland.matches_reference
                && preview_loop_validation.wayland.missing_features.is_empty()
                && preview_loop_validation.x11.matches_reference
                && preview_loop_validation.x11.missing_features.is_empty() =>
        {
            LinuxValidationSectionStatus::Pass
        }
        (Some(_), Some(_)) => LinuxValidationSectionStatus::Fail,
        _ => LinuxValidationSectionStatus::NotCaptured,
    };

    LinuxValidationSection {
        title: "Automated macOS-reference parity coverage",
        status,
        checklist_item: None,
        details: vec![
            format!(
                "Feature coverage summary: {}",
                parity_coverage
                    .map(|coverage| format!(
                        "{}/{} reference features covered",
                        coverage.covered_feature_count, coverage.reference_feature_count
                    ))
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Feature gaps: {}",
                parity_coverage
                    .map(|coverage| format!("{:?}", coverage.missing_features))
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Wayland preview-loop parity: {}",
                preview_loop_validation
                    .map(|bundle| bundle.wayland.matches_reference.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "X11 preview-loop parity: {}",
                preview_loop_validation
                    .map(|bundle| bundle.x11.matches_reference.to_string())
                    .unwrap_or_else(|| "not-captured".to_owned())
            ),
            format!(
                "Wayland note: {}",
                preview_loop_validation
                    .map(|bundle| bundle.wayland.note)
                    .unwrap_or("not-captured")
            ),
            format!(
                "X11 note: {}",
                preview_loop_validation
                    .map(|bundle| bundle.x11.note)
                    .unwrap_or("not-captured")
            ),
        ],
    }
}

fn linux_validation_report_markdown(report: &LinuxValidationReportPayload) -> String {
    let implemented_notes = report
        .notes
        .iter()
        .filter(|note| note.status == "implemented-in-slice")
        .count();
    let pending_host_validation_notes = report
        .notes
        .iter()
        .filter(|note| note.status == "needs-ubuntu-host-validation")
        .count();
    let blocked_by_lower_layers_notes = report
        .notes
        .iter()
        .filter(|note| note.status == "blocked-by-lower-layers")
        .count();
    let mut lines = vec![
        "# Ubuntu 24.04 GNOME Files Validation Evidence Report".to_owned(),
        String::new(),
        format!("- Target: `{}`", report.target),
        format!("- Reference surface: `{}`", report.reference_surface),
        format!("- Display server: `{}`", report.display_server),
        format!("- Captured at unix ms: `{}`", report.captured_at_unix_ms),
        format!(
            "- Hover anchor: `{}`",
            linux_validation_format_point(report.anchor)
        ),
        format!(
            "- Active display-server report readiness: `{}`",
            if report.ready_to_close_display_server_report {
                "ready-to-close"
            } else {
                "not-ready-to-close"
            }
        ),
        format!(
            "- Cross-session Ubuntu parity-evidence readiness: `{}`",
            if report.cross_session_parity_evidence_ready {
                "ready-to-close"
            } else {
                "not-ready-to-close"
            }
        ),
        format!(
            "- Cross-session Ubuntu parity-evidence note: `{}`",
            report.cross_session_parity_evidence_note
        ),
        format!(
            "- Cross-session required display servers: `{}`",
            linux_validation_format_list(&report.cross_session_required_display_servers)
        ),
        format!(
            "- Cross-session captured display servers: `{}`",
            linux_validation_format_list(&report.cross_session_captured_display_servers)
        ),
        format!(
            "- Cross-session missing display servers: `{}`",
            linux_validation_format_list(&report.cross_session_missing_display_servers)
        ),
        format!(
            "- Cross-session ready display-server reports: `{}`",
            linux_validation_format_list(&report.cross_session_ready_display_server_reports)
        ),
        format!(
            "- Checklist items ready in this report: `{}`",
            report.ready_checklist_items.len()
        ),
        format!(
            "- Checklist items still blocked in this report: `{}`",
            report.blocked_checklist_items.len()
        ),
        format!(
            "- Validation notes implemented in slice: `{}`",
            implemented_notes
        ),
        format!(
            "- Validation notes still needing Ubuntu host evidence: `{}`",
            pending_host_validation_notes
        ),
        format!(
            "- Validation notes blocked by lower layers: `{}`",
            blocked_by_lower_layers_notes
        ),
        String::new(),
    ];

    for checklist_item in &report.ready_checklist_items {
        lines.push(format!("- Ready checklist item: {checklist_item}"));
    }
    for checklist_item in &report.blocked_checklist_items {
        lines.push(format!("- Blocked checklist item: {checklist_item}"));
    }
    if !report.sections.is_empty() {
        lines.push(String::new());
    }

    for section in &report.sections {
        lines.push(format!("## {}", section.title));
        lines.push(String::new());
        lines.push(format!("- Status: `{}`", section.status));
        for checklist_item in &section.checklist_items {
            lines.push(format!("- Checklist item: {checklist_item}"));
        }
        for detail in &section.details {
            lines.push(format!("- {detail}"));
        }
        lines.push(String::new());
    }

    let outstanding_notes: Vec<_> = report
        .notes
        .iter()
        .filter(|note| note.status != "implemented-in-slice")
        .collect();
    if !outstanding_notes.is_empty() {
        lines.push("## Outstanding validation notes".to_owned());
        lines.push(String::new());
        for note in outstanding_notes {
            lines.push(format!("- [{}] {}: {}", note.status, note.item, note.note));
        }
        lines.push(String::new());
    }

    lines.join("\n")
}

fn build_linux_validation_report_payload(
    host_capabilities: &HostCapabilitiesPayload,
    anchor: Option<ScreenPoint>,
) -> Result<LinuxValidationReportPayload, String> {
    let display_server = host_capabilities
        .linux_runtime_diagnostics
        .as_ref()
        .map(|diagnostics| diagnostics.display_server)
        .ok_or_else(|| {
            "Linux validation reports require Linux runtime diagnostics from the desktop shell."
                .to_owned()
        })?;
    let display_server_kind = linux_validation_display_server_kind(display_server).ok_or_else(|| {
        format!(
            "Linux validation reports require an active Wayland or X11 session, got `{display_server}`."
        )
    })?;

    let frontmost_section =
        build_linux_frontmost_validation_section(host_capabilities, display_server_kind);
    let hover_section =
        build_linux_hover_validation_section(host_capabilities, display_server_kind);
    let monitor_section =
        build_linux_monitor_validation_section(host_capabilities, display_server_kind);
    let automated_parity_section = build_linux_automated_parity_section(host_capabilities);

    let mut ready_checklist_items = Vec::new();
    let mut blocked_checklist_items = Vec::new();
    for section in [&frontmost_section, &hover_section, &monitor_section] {
        if let Some(checklist_item) = section.checklist_item.as_ref() {
            if section.status.is_pass() {
                ready_checklist_items.push(checklist_item.clone());
            } else {
                blocked_checklist_items.push(checklist_item.clone());
            }
        }
    }

    let ready_to_close_display_server_report = [
        frontmost_section.status,
        hover_section.status,
        monitor_section.status,
        automated_parity_section.status,
    ]
    .into_iter()
    .all(LinuxValidationSectionStatus::is_pass);
    let cross_session_parity_evidence_ready = false;
    let parity_checklist_item = ubuntu_parity_evidence_checklist_item().to_owned();
    let required_display_servers = host_capabilities
        .linux_validation_evidence
        .as_ref()
        .map(|payload| payload.required_display_servers.clone())
        .unwrap_or_else(required_linux_validation_display_servers);
    let captured_display_servers = host_capabilities
        .linux_validation_evidence
        .as_ref()
        .map(|payload| payload.captured_display_servers.clone())
        .unwrap_or_default();
    let missing_display_servers = host_capabilities
        .linux_validation_evidence
        .as_ref()
        .map(|payload| payload.missing_display_servers.clone())
        .unwrap_or_else(required_linux_validation_display_servers);
    let ready_display_server_reports = host_capabilities
        .linux_validation_evidence
        .as_ref()
        .map(|payload| payload.ready_display_server_reports.clone())
        .unwrap_or_default();
    let cross_session_parity_evidence_note = host_capabilities
        .linux_validation_evidence
        .as_ref()
        .map(|payload| payload.note.to_owned())
        .unwrap_or_else(|| ubuntu_parity_evidence_pending_note().to_owned());
    blocked_checklist_items.push(parity_checklist_item);

    let sections = vec![
        frontmost_section.into_payload(),
        hover_section.into_payload(),
        monitor_section.into_payload(),
        automated_parity_section.into_payload(),
    ];
    let notes = linux_validation_notes_payload();
    let mut report = LinuxValidationReportPayload {
        target: linux_validation_target(host_capabilities),
        reference_surface: linux_validation_reference_surface(host_capabilities),
        display_server: display_server.to_owned(),
        captured_at_unix_ms: current_unix_ms(),
        anchor,
        ready_to_close_display_server_report,
        cross_session_parity_evidence_ready,
        cross_session_parity_evidence_note,
        cross_session_required_display_servers: required_display_servers,
        cross_session_captured_display_servers: captured_display_servers,
        cross_session_missing_display_servers: missing_display_servers,
        cross_session_ready_display_server_reports: ready_display_server_reports,
        ready_checklist_items,
        blocked_checklist_items,
        sections,
        notes,
        markdown: String::new(),
    };
    report.markdown = linux_validation_report_markdown(&report);
    Ok(report)
}

fn build_desktop_shell_validation_snapshot_payload(
    shell_state: &ShellStatePayload,
    host_capabilities: &HostCapabilitiesPayload,
    anchor: Option<ScreenPoint>,
) -> DesktopShellValidationSnapshotPayload {
    DesktopShellValidationSnapshotPayload {
        captured_at_unix_ms: current_unix_ms(),
        shell_state: shell_state.clone(),
        host_capabilities: host_capabilities.clone(),
        linux_validation_report: build_linux_validation_report_payload(host_capabilities, anchor)
            .ok(),
    }
}

fn stage2_repo_root() -> PathBuf {
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../..");
    fs::canonicalize(&root).unwrap_or(root)
}

fn test_logs_output_directory() -> PathBuf {
    stage2_repo_root().join("Docs/Test_Logs")
}

fn validation_artifact_slug(value: &str) -> String {
    let mut slug = String::new();
    let mut last_was_separator = false;

    for character in value.chars().flat_map(char::to_lowercase) {
        if character.is_ascii_alphanumeric() {
            slug.push(character);
            last_was_separator = false;
        } else if !last_was_separator {
            slug.push('-');
            last_was_separator = true;
        }
    }

    let slug = slug.trim_matches('-');
    if slug.is_empty() {
        "capture".to_owned()
    } else {
        slug.to_owned()
    }
}

fn background_mode_label(mode: BackgroundMode) -> &'static str {
    match mode {
        BackgroundMode::White => "white",
        BackgroundMode::Black => "black",
    }
}

fn runtime_mode_label(mode: RuntimeMode) -> &'static str {
    match mode {
        RuntimeMode::Desktop => "desktop",
        RuntimeMode::Fallback => "fallback",
    }
}

fn write_markdown_artifact(path: &Path, markdown: &str) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| {
            format!(
                "Failed to create validation artifact directory {}: {error}",
                path_string(parent)
            )
        })?;
    }

    fs::write(path, markdown).map_err(|error| {
        format!(
            "Failed to write validation artifact {}: {error}",
            path_string(path)
        )
    })
}

fn write_json_artifact<T: Serialize>(path: &Path, value: &T) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).map_err(|error| {
            format!(
                "Failed to create validation artifact directory {}: {error}",
                path_string(parent)
            )
        })?;
    }

    let json = serde_json::to_string_pretty(value).map_err(|error| {
        format!(
            "Failed to serialize validation artifact {}: {error}",
            path_string(path)
        )
    })?;

    fs::write(path, json).map_err(|error| {
        format!(
            "Failed to write validation artifact {}: {error}",
            path_string(path)
        )
    })
}

fn desktop_shell_validation_snapshot_markdown(
    snapshot: &DesktopShellValidationSnapshotPayload,
    linux_validation_report_markdown_path: Option<&Path>,
) -> String {
    let selected_width = snapshot
        .shell_state
        .width_tiers
        .get(snapshot.shell_state.selected_width_tier_index)
        .copied()
        .unwrap_or(0);
    let linux_validation_report = snapshot.linux_validation_report.as_ref();
    let mut lines = vec![
        "# FastMD Desktop Shell Validation Snapshot".to_owned(),
        String::new(),
        format!("- Captured at unix ms: `{}`", snapshot.captured_at_unix_ms),
        format!("- Platform: `{}`", snapshot.host_capabilities.platform_id),
        format!(
            "- Runtime mode: `{}`",
            runtime_mode_label(snapshot.host_capabilities.runtime_mode)
        ),
        format!(
            "- Frontmost file manager: `{}`",
            snapshot.host_capabilities.frontmost_file_manager
        ),
        format!(
            "- Linux validation report captured: `{}`",
            if linux_validation_report.is_some() {
                "yes"
            } else {
                "no"
            }
        ),
    ];

    if let Some(path) = linux_validation_report_markdown_path {
        lines.push(format!(
            "- Companion Ubuntu validation report: `{}`",
            path_string(path)
        ));
    }

    lines.extend([
        String::new(),
        "## Shell State".to_owned(),
        String::new(),
        format!("- Document title: `{}`", snapshot.shell_state.document_title),
        format!(
            "- Source document path: `{}`",
            snapshot
                .shell_state
                .source_document_path
                .as_deref()
                .unwrap_or("none")
        ),
        format!(
            "- Content base URL: `{}`",
            snapshot
                .shell_state
                .content_base_url
                .as_deref()
                .unwrap_or("none")
        ),
        format!(
            "- Selected width tier: `{}`",
            snapshot.shell_state.selected_width_tier_index + 1
        ),
        format!("- Selected width in px: `{selected_width}`"),
        format!(
            "- Width tiers in px: `{}`",
            snapshot
                .shell_state
                .width_tiers
                .iter()
                .map(u32::to_string)
                .collect::<Vec<_>>()
                .join(", ")
        ),
        format!(
            "- Background mode: `{}`",
            background_mode_label(snapshot.shell_state.background_mode)
        ),
        String::new(),
        "## Host Capabilities".to_owned(),
        String::new(),
        format!(
            "- Accessibility permission: `{}`",
            snapshot.host_capabilities.accessibility_permission
        ),
        format!(
            "- Preview window positioning: `{}`",
            snapshot.host_capabilities.preview_window_positioning
        ),
        format!(
            "- Global shortcut registered: `{}`",
            snapshot.host_capabilities.global_shortcut_registered
        ),
        format!(
            "- Close on blur enabled: `{}`",
            snapshot.host_capabilities.close_on_blur_enabled
        ),
        format!(
            "- Can persist preview edits: `{}`",
            snapshot.host_capabilities.can_persist_preview_edits
        ),
    ]);

    if let Some(report) = linux_validation_report {
        lines.extend([
            String::new(),
            "## Ubuntu Validation Report Summary".to_owned(),
            String::new(),
            format!("- Display server: `{}`", report.display_server),
            format!(
                "- Active display-server report readiness: `{}`",
                if report.ready_to_close_display_server_report {
                    "ready-to-close"
                } else {
                    "not-ready-to-close"
                }
            ),
            format!(
                "- Cross-session Ubuntu parity-evidence readiness: `{}`",
                if report.cross_session_parity_evidence_ready {
                    "ready-to-close"
                } else {
                    "not-ready-to-close"
                }
            ),
            format!(
                "- Ready checklist items captured: `{}`",
                report.ready_checklist_items.len()
            ),
            format!(
                "- Blocked checklist items captured: `{}`",
                report.blocked_checklist_items.len()
            ),
            format!(
                "- Captured display servers in evidence cache: `{}`",
                linux_validation_format_list(&report.cross_session_captured_display_servers)
            ),
            format!(
                "- Missing display servers in evidence cache: `{}`",
                linux_validation_format_list(&report.cross_session_missing_display_servers)
            ),
            format!(
                "- Cross-session parity note: `{}`",
                report.cross_session_parity_evidence_note
            ),
        ]);
    }

    lines.push(String::new());
    lines.join("\n")
}

fn export_desktop_shell_validation_artifacts_to_directory(
    output_directory: &Path,
    snapshot: &DesktopShellValidationSnapshotPayload,
) -> Result<DesktopShellValidationArtifactExportPayload, String> {
    fs::create_dir_all(output_directory).map_err(|error| {
        format!(
            "Failed to create validation artifact directory {}: {error}",
            path_string(output_directory)
        )
    })?;

    let snapshot_context = snapshot
        .linux_validation_report
        .as_ref()
        .map(|report| report.display_server.as_str())
        .unwrap_or(snapshot.host_capabilities.platform_id);
    let snapshot_markdown_path = output_directory.join(format!(
        "desktop-shell-validation-snapshot-{}-{}.md",
        validation_artifact_slug(snapshot_context),
        snapshot.captured_at_unix_ms,
    ));

    let linux_validation_report_markdown_path =
        snapshot
            .linux_validation_report
            .as_ref()
            .map(|report| {
                output_directory.join(format!(
                    "ubuntu-validation-report-{}-{}.md",
                    validation_artifact_slug(&report.display_server),
                    report.captured_at_unix_ms,
                ))
            });
    let linux_validation_report_json_path = snapshot.linux_validation_report.as_ref().map(|report| {
        output_directory.join(format!(
            "ubuntu-validation-report-{}-{}.json",
            validation_artifact_slug(&report.display_server),
            report.captured_at_unix_ms,
        ))
    });

    if let (Some(report), Some(report_path)) = (
        snapshot.linux_validation_report.as_ref(),
        linux_validation_report_markdown_path.as_ref(),
    ) {
        write_markdown_artifact(report_path, &report.markdown)?;
    }
    if let (Some(report), Some(report_path)) = (
        snapshot.linux_validation_report.as_ref(),
        linux_validation_report_json_path.as_ref(),
    ) {
        write_json_artifact(report_path, report)?;
    }

    let snapshot_markdown = desktop_shell_validation_snapshot_markdown(
        snapshot,
        linux_validation_report_markdown_path.as_deref(),
    );
    write_markdown_artifact(&snapshot_markdown_path, &snapshot_markdown)?;
    let linux_validation_evidence = snapshot
        .linux_validation_report
        .as_ref()
        .map(|_| linux_validation_evidence_payload_for_directory(output_directory));

    Ok(DesktopShellValidationArtifactExportPayload {
        captured_at_unix_ms: snapshot.captured_at_unix_ms,
        output_directory: path_string(output_directory),
        snapshot_markdown_path: path_string(&snapshot_markdown_path),
        linux_validation_report_markdown_path: linux_validation_report_markdown_path
            .as_ref()
            .map(|path| path_string(path)),
        linux_validation_report_json_path: linux_validation_report_json_path
            .as_ref()
            .map(|path| path_string(path)),
        display_server: snapshot
            .linux_validation_report
            .as_ref()
            .map(|report| report.display_server.clone()),
        linux_validation_evidence,
    })
}

fn bootstrap_source_document_path() -> Option<PathBuf> {
    canonical_source_document_path(
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../README.md"),
    )
}

fn canonical_source_document_path(path: impl AsRef<Path>) -> Option<PathBuf> {
    let path = path.as_ref();
    if !path.is_absolute() {
        return None;
    }

    let canonical = fs::canonicalize(path).ok()?;
    let metadata = fs::metadata(&canonical).ok()?;
    if metadata.is_file() {
        Some(canonical)
    } else {
        None
    }
}

fn normalize_source_document_path(raw_path: &str) -> Result<String, String> {
    let trimmed = raw_path.trim();
    canonical_source_document_path(trimmed)
        .as_deref()
        .map(path_string)
        .ok_or_else(|| {
            format!("Attached source document path is not a readable local file: {trimmed}")
        })
}

fn attached_source_document_path(shell_state: &ShellStatePayload) -> Option<PathBuf> {
    shell_state
        .source_document_path
        .as_deref()
        .and_then(canonical_source_document_path)
}

fn can_persist_preview_edits(shell_state: &ShellStatePayload) -> bool {
    attached_source_document_path(shell_state)
        .and_then(|path| fs::metadata(path).ok())
        .is_some_and(|metadata| metadata.is_file() && !metadata.permissions().readonly())
}

fn content_base_url_for_source_document(path: &Path) -> Option<String> {
    Url::from_directory_path(path.parent()?)
        .ok()
        .map(|url| url.to_string())
}

fn file_name_label(path: &Path) -> Option<String> {
    path.file_name()
        .and_then(|value| value.to_str())
        .map(ToOwned::to_owned)
}

fn path_string(path: &Path) -> String {
    path.to_string_lossy().into_owned()
}

fn replace_preview_document_state(
    shell_state: &mut ShellStatePayload,
    markdown: String,
    content_base_url: Option<String>,
    source_document_path: Option<String>,
    document_title: Option<String>,
) -> Result<(), String> {
    let existing_source_document_path = shell_state.source_document_path.clone();
    let existing_content_base_url = shell_state.content_base_url.clone();
    let normalized_source_document_path = match source_document_path {
        Some(path) => Some(normalize_source_document_path(&path)?),
        None => existing_source_document_path,
    };

    shell_state.markdown = markdown;
    shell_state.source_document_path = normalized_source_document_path.clone();
    shell_state.content_base_url = match content_base_url {
        Some(content_base_url) => Some(content_base_url),
        None => normalized_source_document_path
            .as_deref()
            .and_then(|path| content_base_url_for_source_document(Path::new(path)))
            .or(existing_content_base_url),
    };

    if let Some(document_title) = document_title {
        shell_state.document_title = document_title;
    } else if let Some(source_document_path) = normalized_source_document_path.as_deref() {
        if let Some(label) = file_name_label(Path::new(source_document_path)) {
            shell_state.document_title = label;
        }
    }

    Ok(())
}

fn save_preview_markdown_to_attached_source(
    shell_state: &mut ShellStatePayload,
    markdown: &str,
) -> Result<(), String> {
    let source_document_path = attached_source_document_path(shell_state)
        .ok_or_else(|| "No current file is attached to the preview.".to_owned())?;

    fs::write(&source_document_path, markdown).map_err(|error| {
        format!(
            "Failed to save Markdown back to {}: {error}",
            source_document_path.display()
        )
    })?;

    shell_state.markdown = markdown.to_owned();
    shell_state.source_document_path = Some(path_string(&source_document_path));
    shell_state.content_base_url = content_base_url_for_source_document(&source_document_path);
    if let Some(label) = file_name_label(&source_document_path) {
        shell_state.document_title = label;
    }

    Ok(())
}

fn refresh_edit_persistence_capability(
    host_capabilities: &mut HostCapabilitiesPayload,
    shell_state: &ShellStatePayload,
) {
    let editing = host_capabilities
        .linux_runtime_diagnostics
        .as_ref()
        .map(|diagnostics| diagnostics.edit_lifecycle.editing)
        .unwrap_or(false);
    host_capabilities.can_persist_preview_edits = can_persist_preview_edits(shell_state);
    update_linux_edit_lifecycle_diagnostics(host_capabilities, editing, None);
}

fn refresh_linux_validation_evidence(host_capabilities: &mut HostCapabilitiesPayload) {
    if !cfg!(target_os = "linux") {
        host_capabilities.linux_validation_evidence = None;
        return;
    }

    host_capabilities.linux_validation_evidence = linux_validation_evidence_payload();
}

fn observed_frontmost_identifier(frontmost_app: &FrontmostAppSnapshot) -> Option<String> {
    frontmost_app
        .app_id
        .clone()
        .or(frontmost_app.desktop_entry.clone())
        .or(frontmost_app.window_class.clone())
        .or(frontmost_app.executable.clone())
}

fn linux_frontmost_live_note(display_server: DisplayServerKind) -> String {
    match display_server {
        DisplayServerKind::Wayland => {
            "Wayland frontmost-gate diagnostics now run against the live AT-SPI focus probe; Ubuntu validation evidence is still required before parity sign-off.".to_owned()
        }
        DisplayServerKind::X11 => {
            "X11 frontmost-gate diagnostics now run against the live AT-SPI plus _NET_ACTIVE_WINDOW probe path; Ubuntu validation evidence is still required before parity sign-off.".to_owned()
        }
    }
}

fn linux_frontmost_probe_failure_note(display_server: Option<DisplayServerKind>) -> String {
    match display_server {
        Some(DisplayServerKind::Wayland) => {
            "Wayland frontmost-gate diagnostics attempted the live AT-SPI focus probe, but FastMD fell back to generic blur-close handling because the host probe failed.".to_owned()
        }
        Some(DisplayServerKind::X11) => {
            "X11 frontmost-gate diagnostics attempted the live AT-SPI plus _NET_ACTIVE_WINDOW probe path, but FastMD fell back to generic blur-close handling because the host probe failed.".to_owned()
        }
        None => {
            "Linux frontmost-gate diagnostics could not run a live probe because the active display server is unresolved.".to_owned()
        }
    }
}

fn linux_hovered_item_live_note(display_server: DisplayServerKind) -> String {
    match display_server {
        DisplayServerKind::Wayland => {
            "Wayland hovered-item diagnostics now run against a live AT-SPI hit-test at the supplied hover anchor; Ubuntu validation evidence is still required before parity sign-off.".to_owned()
        }
        DisplayServerKind::X11 => {
            "X11 hovered-item diagnostics now run against a live AT-SPI hit-test at the supplied hover anchor; Ubuntu validation evidence is still required before parity sign-off.".to_owned()
        }
    }
}

fn linux_hovered_item_probe_failure_note(display_server: Option<DisplayServerKind>) -> String {
    match display_server {
        Some(DisplayServerKind::Wayland) => {
            "Wayland hovered-item diagnostics attempted the live AT-SPI hit-test probe, but FastMD could not classify a hovered Nautilus item from the supplied anchor.".to_owned()
        }
        Some(DisplayServerKind::X11) => {
            "X11 hovered-item diagnostics attempted the live AT-SPI hit-test probe, but FastMD could not classify a hovered Nautilus item from the supplied anchor.".to_owned()
        }
        None => {
            "Linux hovered-item diagnostics could not run a live probe because the active display server is unresolved.".to_owned()
        }
    }
}

fn hover_resolution_scope_label(scope: HoverResolutionScope) -> &'static str {
    match scope {
        HoverResolutionScope::ExactItemUnderPointer => "exact-item-under-pointer",
        HoverResolutionScope::HoveredRowDescendant => "hovered-row-descendant",
        HoverResolutionScope::NearbyCandidate => "nearby-candidate",
        HoverResolutionScope::FirstVisibleItem => "first-visible-item",
    }
}

fn hovered_entity_kind_label(kind: HoveredEntityKind) -> &'static str {
    match kind {
        HoveredEntityKind::File => "file",
        HoveredEntityKind::Directory => "directory",
        HoveredEntityKind::Unsupported => "unsupported",
    }
}

fn hovered_candidate_path(snapshot: &HoveredItemSnapshot) -> Option<String> {
    match &snapshot.candidate {
        HoverCandidate::LocalPath { path, .. } => Some(path_string(path)),
        HoverCandidate::UnsupportedItem { .. } => None,
    }
}

fn hover_observation_fingerprint(
    snapshot: &HoveredItemSnapshot,
    accepted_path: Option<&str>,
) -> String {
    let candidate = accepted_path
        .map(ToOwned::to_owned)
        .or_else(|| hovered_candidate_path(snapshot))
        .or_else(|| snapshot.item_name.clone())
        .unwrap_or_else(|| "none".to_owned());

    format!(
        "scope={};entity={};candidate={};accepted={};rejection={}",
        hover_resolution_scope_label(snapshot.resolution_scope),
        hovered_entity_kind_label(snapshot.entity_kind),
        candidate,
        accepted_path.is_some(),
        snapshot.item_name.as_deref().unwrap_or("none")
    )
}

fn frontmost_text_input_hover_fingerprint(frontmost_app: &FrontmostAppSnapshot) -> Option<String> {
    if !frontmost_app.focused_is_text_input {
        return None;
    }

    let role = frontmost_app
        .focused_role_name
        .as_deref()
        .unwrap_or("text-input");
    let name = frontmost_app.focused_name.as_deref().unwrap_or("unnamed");

    Some(format!(
        "hover=blocked:text-input-active:role={role}:name={name}"
    ))
}

fn collect_linux_hover_observation(anchor: ScreenPoint) -> LinuxHoverObservation {
    let rounded_x = anchor.x.round() as i32;
    let rounded_y = anchor.y.round() as i32;

    match classify_live_frontmost_gate() {
        Ok((_probe, gate)) if gate.is_open => {
            let gate_fingerprint = format!(
                "open:{}",
                gate.detected_surface
                    .as_ref()
                    .map(|surface| surface.stable_identity.native_surface_id.as_str())
                    .unwrap_or("unknown")
            );

            if let Some(hover_fingerprint) =
                frontmost_text_input_hover_fingerprint(&gate.frontmost_app)
            {
                return LinuxHoverObservation {
                    key: HoverObservationKey {
                        cursor_x: rounded_x,
                        cursor_y: rounded_y,
                        gate_fingerprint,
                        hover_fingerprint,
                    },
                    anchor,
                    observed_markdown_path: None,
                };
            }

            match classify_live_hovered_item(platform_screen_point(anchor)) {
                Ok(Some((_probe, outcome))) => {
                    let observed_markdown_path = outcome
                        .accepted
                        .as_ref()
                        .map(|accepted| path_string(accepted.path()));
                    let hover_fingerprint = hover_observation_fingerprint(
                        &outcome.snapshot,
                        observed_markdown_path.as_deref(),
                    );

                    LinuxHoverObservation {
                        key: HoverObservationKey {
                            cursor_x: rounded_x,
                            cursor_y: rounded_y,
                            gate_fingerprint,
                            hover_fingerprint,
                        },
                        anchor,
                        observed_markdown_path,
                    }
                }
                Ok(None) => LinuxHoverObservation {
                    key: HoverObservationKey {
                        cursor_x: rounded_x,
                        cursor_y: rounded_y,
                        gate_fingerprint,
                        hover_fingerprint: "hover=no-hit".to_owned(),
                    },
                    anchor,
                    observed_markdown_path: None,
                },
                Err(error) => LinuxHoverObservation {
                    key: HoverObservationKey {
                        cursor_x: rounded_x,
                        cursor_y: rounded_y,
                        gate_fingerprint,
                        hover_fingerprint: format!("hover=probe-failed:{error}"),
                    },
                    anchor,
                    observed_markdown_path: None,
                },
            }
        }
        Ok((_probe, gate)) => LinuxHoverObservation {
            key: HoverObservationKey {
                cursor_x: rounded_x,
                cursor_y: rounded_y,
                gate_fingerprint: format!(
                    "closed:{}",
                    gate.rejection
                        .as_ref()
                        .map(ToString::to_string)
                        .unwrap_or_else(|| "unknown".to_owned())
                ),
                hover_fingerprint: "hover=blocked".to_owned(),
            },
            anchor,
            observed_markdown_path: None,
        },
        Err(error) => LinuxHoverObservation {
            key: HoverObservationKey {
                cursor_x: rounded_x,
                cursor_y: rounded_y,
                gate_fingerprint: format!("gate=probe-failed:{error}"),
                hover_fingerprint: "hover=blocked".to_owned(),
            },
            anchor,
            observed_markdown_path: None,
        },
    }
}

fn linux_blur_close_reason(
    is_open: bool,
    rejection: Option<&FrontmostSurfaceRejection>,
) -> &'static str {
    if is_open {
        "outside-click"
    } else if matches!(
        rejection,
        Some(FrontmostSurfaceRejection::NonNautilusApp { .. })
    ) {
        "app-switch"
    } else {
        "focus-lost"
    }
}

fn refresh_linux_frontmost_gate_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
) -> Option<String> {
    if !cfg!(target_os = "linux") {
        return None;
    }

    let display_server = detected_linux_display_server();
    enum FrontmostGateRefresh {
        Live {
            frontmost_file_manager: &'static str,
            reason: String,
            diagnostics_display_server: &'static str,
            backend: String,
            api_stack: String,
            observed_identifier: Option<String>,
            stable_surface_id: Option<String>,
            window_title: Option<String>,
            process_id: Option<u32>,
            is_open: bool,
            text_input_active: bool,
            text_input_role: Option<String>,
            text_input_name: Option<String>,
            inferred_blur_close_reason: String,
            rejection: Option<String>,
            detail: String,
            note: String,
        },
        ProbeFailed {
            inferred_blur_close_reason: String,
            detail: String,
            note: String,
        },
    }

    let refresh = match classify_live_frontmost_gate() {
        Ok((probe, gate)) => FrontmostGateRefresh::Live {
            frontmost_file_manager: if gate.is_open { "nautilus" } else { "unknown" },
            reason: linux_blur_close_reason(gate.is_open, gate.rejection.as_ref()).to_owned(),
            diagnostics_display_server: display_server_label(Some(gate.session.display_server)),
            backend: probe.backend,
            api_stack: gate.api_stack.diagnostic_summary(),
            observed_identifier: gate
                .detected_surface
                .as_ref()
                .map(|surface| surface.observed_identifier.clone())
                .or_else(|| observed_frontmost_identifier(&gate.frontmost_app)),
            stable_surface_id: gate
                .detected_surface
                .as_ref()
                .map(|surface| surface.stable_identity.native_surface_id.clone())
                .or_else(|| gate.frontmost_app.stable_surface_id.clone()),
            window_title: gate.frontmost_app.window_title.clone(),
            process_id: gate.frontmost_app.process_id,
            is_open: gate.is_open,
            text_input_active: gate.frontmost_app.focused_is_text_input,
            text_input_role: gate.frontmost_app.focused_role_name.clone(),
            text_input_name: gate.frontmost_app.focused_name.clone(),
            inferred_blur_close_reason: linux_blur_close_reason(
                gate.is_open,
                gate.rejection.as_ref(),
            )
            .to_owned(),
            rejection: gate.rejection.as_ref().map(ToString::to_string),
            detail: if gate.is_open && gate.frontmost_app.focused_is_text_input {
                "Live Linux frontmost probing kept Nautilus as the foreground gate and detected an active text-input surface, so hover-driven preview open or replace stays suppressed.".to_owned()
            } else if gate.is_open {
                "Live Linux frontmost probing kept Nautilus as the foreground gate.".to_owned()
            } else {
                "Live Linux frontmost probing rejected the foreground surface before close-reason inference.".to_owned()
            },
            note: linux_frontmost_live_note(gate.session.display_server),
        },
        Err(error) => FrontmostGateRefresh::ProbeFailed {
            inferred_blur_close_reason: "focus-lost".to_owned(),
            detail: error.to_string(),
            note: linux_frontmost_probe_failure_note(display_server),
        },
    };

    match &refresh {
        FrontmostGateRefresh::Live {
            frontmost_file_manager,
            diagnostics_display_server,
            backend,
            api_stack,
            observed_identifier,
            stable_surface_id,
            window_title,
            process_id,
            is_open,
            text_input_active,
            text_input_role,
            text_input_name,
            inferred_blur_close_reason,
            rejection,
            detail,
            note,
            ..
        } => {
            host_capabilities.frontmost_file_manager = *frontmost_file_manager;
            let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
                return None;
            };
            diagnostics.display_server = *diagnostics_display_server;
            diagnostics.frontmost_gate.status = DIAGNOSTIC_STATUS_EMITTED;
            diagnostics.frontmost_gate.display_server = *diagnostics_display_server;
            diagnostics.frontmost_gate.backend = Some(backend.clone());
            diagnostics.frontmost_gate.api_stack = api_stack.clone();
            diagnostics.frontmost_gate.observed_identifier = observed_identifier.clone();
            diagnostics.frontmost_gate.stable_surface_id = stable_surface_id.clone();
            diagnostics.frontmost_gate.window_title = window_title.clone();
            diagnostics.frontmost_gate.process_id = *process_id;
            diagnostics.frontmost_gate.is_open = Some(*is_open);
            diagnostics.frontmost_gate.text_input_active = Some(*text_input_active);
            diagnostics.frontmost_gate.text_input_role = text_input_role.clone();
            diagnostics.frontmost_gate.text_input_name = text_input_name.clone();
            diagnostics.frontmost_gate.inferred_blur_close_reason =
                Some(inferred_blur_close_reason.clone());
            diagnostics.frontmost_gate.rejection = rejection.clone();
            diagnostics.frontmost_gate.detail = Some(detail.clone());
            diagnostics.frontmost_gate.note = note.clone();
        }
        FrontmostGateRefresh::ProbeFailed {
            inferred_blur_close_reason,
            detail,
            note,
        } => {
            host_capabilities.frontmost_file_manager = "unknown";
            let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
                return None;
            };
            diagnostics.display_server = display_server_label(display_server);
            diagnostics.frontmost_gate.status = "probe-failed";
            diagnostics.frontmost_gate.display_server = display_server_label(display_server);
            diagnostics.frontmost_gate.backend = None;
            diagnostics.frontmost_gate.api_stack =
                active_frontmost_api_stack_summary(display_server);
            diagnostics.frontmost_gate.observed_identifier = None;
            diagnostics.frontmost_gate.stable_surface_id = None;
            diagnostics.frontmost_gate.window_title = None;
            diagnostics.frontmost_gate.process_id = None;
            diagnostics.frontmost_gate.is_open = None;
            diagnostics.frontmost_gate.text_input_active = None;
            diagnostics.frontmost_gate.text_input_role = None;
            diagnostics.frontmost_gate.text_input_name = None;
            diagnostics.frontmost_gate.inferred_blur_close_reason =
                Some(inferred_blur_close_reason.clone());
            diagnostics.frontmost_gate.rejection = None;
            diagnostics.frontmost_gate.detail = Some(detail.clone());
            diagnostics.frontmost_gate.note = note.clone();
        }
    }

    match refresh {
        FrontmostGateRefresh::Live { reason, .. } => Some(reason),
        FrontmostGateRefresh::ProbeFailed { .. } => Some("focus-lost".to_owned()),
    }
}

fn refresh_linux_hovered_item_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
    anchor: Option<ScreenPoint>,
) {
    if !cfg!(target_os = "linux") {
        return;
    }

    let display_server = detected_linux_display_server();
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.display_server = display_server_label(display_server);
    diagnostics.hovered_item.display_server = display_server_label(display_server);

    let Some(anchor) = anchor else {
        diagnostics.hovered_item.status = DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE;
        diagnostics.hovered_item.backend = None;
        diagnostics.hovered_item.api_stack = active_hovered_item_api_stack_summary(display_server);
        diagnostics.hovered_item.resolution_scope = None;
        diagnostics.hovered_item.entity_kind = None;
        diagnostics.hovered_item.item_name = None;
        diagnostics.hovered_item.path = None;
        diagnostics.hovered_item.path_source = None;
        diagnostics.hovered_item.visible_markdown_peer_count = None;
        diagnostics.hovered_item.accepted = None;
        diagnostics.hovered_item.rejection = None;
        diagnostics.hovered_item.detail = None;
        diagnostics.hovered_item.note = hovered_item_pending_note(display_server).to_owned();
        return;
    };

    match classify_live_hovered_item(platform_screen_point(anchor)) {
        Ok(Some((probe, outcome))) => {
            let snapshot = &outcome.snapshot;
            let probe_display_server = probe.session.display_server;
            let probe_backend = probe.backend.clone();
            diagnostics.display_server = display_server_label(Some(probe_display_server));
            diagnostics.hovered_item.status = DIAGNOSTIC_STATUS_EMITTED;
            diagnostics.hovered_item.display_server =
                display_server_label(Some(probe_display_server));
            diagnostics.hovered_item.api_stack =
                hovered_item_api_stack_for_display_server(probe_display_server)
                    .diagnostic_summary();
            diagnostics.hovered_item.backend = Some(probe_backend);
            diagnostics.hovered_item.resolution_scope =
                Some(hover_resolution_scope_label(snapshot.resolution_scope).to_owned());
            diagnostics.hovered_item.entity_kind =
                Some(hovered_entity_kind_label(snapshot.entity_kind).to_owned());
            diagnostics.hovered_item.item_name = snapshot.item_name.clone();
            diagnostics.hovered_item.path = outcome
                .accepted
                .as_ref()
                .map(|accepted| path_string(accepted.path()))
                .or_else(|| hovered_candidate_path(snapshot));
            diagnostics.hovered_item.path_source = Some(snapshot.path_source.label().to_owned());
            diagnostics.hovered_item.visible_markdown_peer_count =
                snapshot.visible_markdown_peer_count;
            diagnostics.hovered_item.accepted = Some(outcome.accepted.is_some());
            diagnostics.hovered_item.rejection =
                outcome.rejection.as_ref().map(ToString::to_string);
            diagnostics.hovered_item.detail = Some(match outcome.accepted.as_ref() {
                Some(accepted) => format!(
                    "Live Linux hovered-item probing resolved {} through the shared markdown filter.",
                    accepted.path().display()
                ),
                None => "Live Linux hovered-item probing classified the AT-SPI hit-test result through the shared markdown filter and kept the rejection detail for parity review.".to_owned(),
            });
            diagnostics.hovered_item.note = linux_hovered_item_live_note(probe_display_server);
        }
        Ok(None) => {
            diagnostics.hovered_item.status = DIAGNOSTIC_STATUS_EMITTED;
            diagnostics.hovered_item.display_server = display_server_label(display_server);
            diagnostics.hovered_item.api_stack =
                active_hovered_item_api_stack_summary(display_server);
            diagnostics.hovered_item.backend =
                display_server.map(|display_server| match display_server {
                    DisplayServerKind::Wayland => "live-atspi-wayland-hit-test".to_owned(),
                    DisplayServerKind::X11 => "live-atspi-x11-hit-test".to_owned(),
                });
            diagnostics.hovered_item.resolution_scope = None;
            diagnostics.hovered_item.entity_kind = None;
            diagnostics.hovered_item.item_name = None;
            diagnostics.hovered_item.path = None;
            diagnostics.hovered_item.path_source = None;
            diagnostics.hovered_item.visible_markdown_peer_count = None;
            diagnostics.hovered_item.accepted = Some(false);
            diagnostics.hovered_item.rejection = None;
            diagnostics.hovered_item.detail = Some(
                "Live Linux hovered-item probing found no AT-SPI accessible under the supplied hover anchor."
                    .to_owned(),
            );
            diagnostics.hovered_item.note = linux_hovered_item_probe_failure_note(display_server);
        }
        Err(error) => {
            diagnostics.hovered_item.status = "probe-failed";
            diagnostics.hovered_item.display_server = display_server_label(display_server);
            diagnostics.hovered_item.api_stack =
                active_hovered_item_api_stack_summary(display_server);
            diagnostics.hovered_item.backend = None;
            diagnostics.hovered_item.resolution_scope = None;
            diagnostics.hovered_item.entity_kind = None;
            diagnostics.hovered_item.item_name = None;
            diagnostics.hovered_item.path = None;
            diagnostics.hovered_item.path_source = None;
            diagnostics.hovered_item.visible_markdown_peer_count = None;
            diagnostics.hovered_item.accepted = None;
            diagnostics.hovered_item.rejection = None;
            diagnostics.hovered_item.detail = Some(error.to_string());
            diagnostics.hovered_item.note = linux_hovered_item_probe_failure_note(display_server);
        }
    }
}

fn screen_rect_payload(rect: PlatformScreenRect) -> ScreenRectPayload {
    ScreenRectPayload {
        x: rect.x,
        y: rect.y,
        width: rect.width,
        height: rect.height,
    }
}

fn update_linux_monitor_selection_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
    anchor: ScreenPoint,
    selected: &SelectedMonitorWorkArea,
) {
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.monitor_selection.anchor = Some(anchor);
    diagnostics.monitor_selection.selected_monitor_id = Some(selected.monitor_id.clone());
    diagnostics.monitor_selection.used_nearest_fallback = Some(selected.used_nearest_fallback);
    diagnostics.monitor_selection.work_area = Some(screen_rect_payload(selected.work_area));
}

fn update_linux_preview_placement_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
    requested_width: u32,
    geometry: &PreviewGeometryPayload,
) {
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.preview_placement.requested_width = Some(requested_width);
    diagnostics.preview_placement.applied_geometry = Some(geometry.clone());
}

fn update_linux_edit_lifecycle_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
    editing: bool,
    last_close_reason: Option<String>,
) {
    let close_on_blur_enabled = host_capabilities.close_on_blur_enabled;
    let can_persist_preview_edits = host_capabilities.can_persist_preview_edits;
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.edit_lifecycle.editing = editing;
    diagnostics.edit_lifecycle.close_on_blur_enabled = close_on_blur_enabled;
    diagnostics.edit_lifecycle.can_persist_preview_edits = can_persist_preview_edits;
    if let Some(reason) = last_close_reason {
        diagnostics.edit_lifecycle.last_close_reason = Some(reason);
    }
}

fn update_linux_hover_lifecycle_diagnostics(
    host_capabilities: &mut HostCapabilitiesPayload,
    last_anchor: Option<ScreenPoint>,
    observed_path: Option<String>,
    preview_visible: bool,
    preview_path: Option<String>,
    last_action: Option<String>,
) {
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.hover_lifecycle.last_anchor = last_anchor;
    diagnostics.hover_lifecycle.observed_path = observed_path;
    diagnostics.hover_lifecycle.preview_visible = preview_visible;
    diagnostics.hover_lifecycle.preview_path = preview_path;
    diagnostics.hover_lifecycle.last_action = last_action;
}

fn current_preview_source_document_path(state: &ShellBridgeState) -> Option<String> {
    state
        .shell_state
        .lock()
        .unwrap()
        .source_document_path
        .clone()
}

fn set_preview_visibility(
    state: &ShellBridgeState,
    visible: bool,
    last_action: Option<String>,
    observed_path: Option<String>,
) {
    state.linux_hover_runtime.lock().unwrap().preview_visible = visible;

    let last_anchor = *state.last_anchor.lock().unwrap();
    let preview_path = if visible {
        current_preview_source_document_path(state)
    } else {
        None
    };

    let mut host_capabilities = state.host_capabilities.lock().unwrap();
    update_linux_hover_lifecycle_diagnostics(
        &mut host_capabilities,
        last_anchor,
        observed_path,
        visible,
        preview_path,
        last_action,
    );
}

fn advance_linux_hover_lifecycle(
    runtime: &mut LinuxHoverRuntimeState,
    observation: &LinuxHoverObservation,
    current_preview_path: Option<&str>,
    now: Instant,
) -> HoverLifecycleStep {
    if runtime.last_observation.as_ref() != Some(&observation.key) {
        runtime.last_observation = Some(observation.key.clone());
        runtime.last_change_at = Some(now);
        runtime.executed_observation = None;
        return HoverLifecycleStep {
            observation_changed: true,
            action: None,
        };
    }

    if runtime.executed_observation.as_ref() == Some(&observation.key) {
        return HoverLifecycleStep {
            observation_changed: false,
            action: None,
        };
    }

    let Some(last_change_at) = runtime.last_change_at else {
        runtime.last_change_at = Some(now);
        return HoverLifecycleStep {
            observation_changed: true,
            action: None,
        };
    };

    if now.duration_since(last_change_at) < HOVER_TRIGGER_DELAY {
        return HoverLifecycleStep {
            observation_changed: false,
            action: None,
        };
    }

    runtime.executed_observation = Some(observation.key.clone());
    let action = match observation.observed_markdown_path.as_deref() {
        Some(path) if runtime.preview_visible && current_preview_path == Some(path) => {
            Some(HoverLifecycleAction::SuppressSameItem)
        }
        Some(path) if runtime.preview_visible => Some(HoverLifecycleAction::Replace {
            path: path.to_owned(),
            anchor: observation.anchor,
        }),
        Some(path) => Some(HoverLifecycleAction::Open {
            path: path.to_owned(),
            anchor: observation.anchor,
        }),
        None => None,
    };

    HoverLifecycleStep {
        observation_changed: false,
        action,
    }
}

fn emit_shell_state(app: &AppHandle, state: &ShellBridgeState) -> Result<(), String> {
    app.emit(SHELL_STATE_EVENT, state.snapshot_shell_state())
        .map_err(|error| error.to_string())
}

fn emit_host_capabilities(app: &AppHandle, state: &ShellBridgeState) -> Result<(), String> {
    app.emit(HOST_CAPABILITIES_EVENT, state.snapshot_host_capabilities())
        .map_err(|error| error.to_string())
}

fn current_anchor_or_monitor_center(
    window: &WebviewWindow,
    state: &ShellBridgeState,
) -> Result<ScreenPoint, String> {
    if let Some(anchor) = *state.last_anchor.lock().unwrap() {
        return Ok(anchor);
    }

    let monitor = window
        .current_monitor()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| "No monitor is available for preview geometry.".to_owned())?;
    let work_area = *monitor.work_area();

    Ok(ScreenPoint {
        x: f64::from(work_area.position.x) + f64::from(work_area.size.width) / 2.0,
        y: f64::from(work_area.position.y) + f64::from(work_area.size.height) / 2.0,
    })
}

fn platform_screen_point(point: ScreenPoint) -> PlatformScreenPoint {
    PlatformScreenPoint {
        x: point.x,
        y: point.y,
    }
}

fn platform_screen_rect_from_tauri_rect(rect: PhysicalRect<i32, u32>) -> PlatformScreenRect {
    PlatformScreenRect {
        x: f64::from(rect.position.x),
        y: f64::from(rect.position.y),
        width: f64::from(rect.size.width),
        height: f64::from(rect.size.height),
    }
}

fn monitor_identity_key(monitor: &TauriMonitor) -> (i32, i32, u32, u32) {
    let position = monitor.position();
    let size = monitor.size();
    (position.x, position.y, size.width, size.height)
}

fn platform_monitor_layout_from_tauri(
    monitors: &[TauriMonitor],
    primary_identity: Option<(i32, i32, u32, u32)>,
) -> PlatformMonitorLayout {
    PlatformMonitorLayout {
        monitors: monitors
            .iter()
            .enumerate()
            .map(|(index, monitor)| {
                let full_frame = PlatformScreenRect {
                    x: f64::from(monitor.position().x),
                    y: f64::from(monitor.position().y),
                    width: f64::from(monitor.size().width),
                    height: f64::from(monitor.size().height),
                };
                PlatformMonitor {
                    id: format!("monitor-{index}"),
                    frame: full_frame,
                    work_area: platform_screen_rect_from_tauri_rect(*monitor.work_area()),
                    primary: primary_identity
                        .is_some_and(|identity| identity == monitor_identity_key(monitor)),
                }
            })
            .collect(),
    }
}

fn selected_work_area_for_anchor(
    layout: &PlatformMonitorLayout,
    anchor: ScreenPoint,
) -> Option<SelectedMonitorWorkArea> {
    let anchor_point = platform_screen_point(anchor);
    let used_nearest_fallback = !layout
        .monitors
        .iter()
        .any(|monitor| monitor.work_area.contains(anchor_point));

    layout
        .monitor_for_point(anchor_point)
        .map(|monitor| SelectedMonitorWorkArea {
            monitor_id: monitor.id.clone(),
            work_area: monitor.work_area,
            used_nearest_fallback,
        })
}

fn preview_work_area_for_anchor(
    window: &WebviewWindow,
    anchor: ScreenPoint,
) -> Result<SelectedMonitorWorkArea, String> {
    let monitors = window
        .available_monitors()
        .map_err(|error| error.to_string())?;
    if monitors.is_empty() {
        return Err("No monitor is available for preview geometry.".to_owned());
    }

    let primary_identity = window
        .primary_monitor()
        .map_err(|error| error.to_string())?
        .as_ref()
        .map(monitor_identity_key);
    let layout = platform_monitor_layout_from_tauri(&monitors, primary_identity);

    selected_work_area_for_anchor(&layout, anchor)
        .ok_or_else(|| "No monitor work area is available for preview geometry.".to_owned())
}

fn compute_preview_geometry(
    anchor: ScreenPoint,
    work_area: PlatformScreenRect,
    requested_width: u32,
) -> PreviewGeometryPayload {
    let min_x = work_area.x + PREVIEW_EDGE_INSET;
    let min_y = work_area.y + PREVIEW_EDGE_INSET;
    let available_width = (work_area.width - PREVIEW_EDGE_INSET * 2.0).max(320.0);
    let available_height = (work_area.height - PREVIEW_EDGE_INSET * 2.0).max(240.0);
    let max_fit_width = available_width.min(available_height * PREVIEW_ASPECT_RATIO);
    let max_fit_height = max_fit_width / PREVIEW_ASPECT_RATIO;

    let requested_width = requested_width as f64;
    let requested_height = requested_width / PREVIEW_ASPECT_RATIO;
    let width = requested_width.min(max_fit_width);
    let height = requested_height.min(max_fit_height);

    let max_x = work_area.x + work_area.width - width - PREVIEW_EDGE_INSET;
    let max_y = work_area.y + work_area.height - height - PREVIEW_EDGE_INSET;

    let mut origin_x = anchor.x + PREVIEW_POINTER_OFFSET;
    let mut origin_y = anchor.y - height - PREVIEW_POINTER_OFFSET;

    if origin_x > max_x {
        origin_x = anchor.x - width - PREVIEW_POINTER_OFFSET;
    }
    if origin_x < min_x {
        origin_x = min_x;
    }
    if origin_x > max_x {
        origin_x = max_x;
    }

    if origin_y < min_y {
        origin_y = anchor.y + PREVIEW_POINTER_OFFSET;
    }
    if origin_y > max_y {
        origin_y = max_y;
    }
    if origin_y < min_y {
        origin_y = min_y;
    }

    PreviewGeometryPayload {
        x: origin_x.round() as i32,
        y: origin_y.round() as i32,
        width: width.round() as u32,
        height: height.round() as u32,
    }
}

fn apply_preview_geometry_internal(
    window: &WebviewWindow,
    state: &ShellBridgeState,
    anchor: Option<ScreenPoint>,
) -> Result<PreviewGeometryPayload, String> {
    if let Some(anchor) = anchor {
        *state.last_anchor.lock().unwrap() = Some(anchor);
    }
    let remembered_hover_anchor = *state.last_anchor.lock().unwrap();
    let effective_anchor =
        remembered_hover_anchor.unwrap_or(current_anchor_or_monitor_center(window, state)?);
    let selected_work_area = preview_work_area_for_anchor(window, effective_anchor)?;

    let requested_width = {
        let shell_state = state.shell_state.lock().unwrap();
        shell_state.width_tiers[shell_state.selected_width_tier_index]
    };

    let geometry = compute_preview_geometry(
        effective_anchor,
        selected_work_area.work_area,
        requested_width,
    );

    window
        .set_size(Size::Physical(PhysicalSize::new(
            geometry.width,
            geometry.height,
        )))
        .map_err(|error| error.to_string())?;
    window
        .set_position(Position::Physical(PhysicalPosition::new(
            geometry.x, geometry.y,
        )))
        .map_err(|error| error.to_string())?;

    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        update_linux_monitor_selection_diagnostics(
            &mut host_capabilities,
            effective_anchor,
            &selected_work_area,
        );
        update_linux_preview_placement_diagnostics(
            &mut host_capabilities,
            requested_width,
            &geometry,
        );
        refresh_linux_hovered_item_diagnostics(&mut host_capabilities, remembered_hover_anchor);
    }

    Ok(geometry)
}

fn clear_linux_monitor_validation_snapshot(host_capabilities: &mut HostCapabilitiesPayload) {
    let Some(diagnostics) = host_capabilities.linux_runtime_diagnostics.as_mut() else {
        return;
    };

    diagnostics.monitor_selection.anchor = None;
    diagnostics.monitor_selection.selected_monitor_id = None;
    diagnostics.monitor_selection.used_nearest_fallback = None;
    diagnostics.monitor_selection.work_area = None;
    diagnostics.preview_placement.requested_width = None;
    diagnostics.preview_placement.applied_geometry = None;
}

fn refresh_linux_validation_snapshot(
    window: &WebviewWindow,
    state: &ShellBridgeState,
    anchor: Option<ScreenPoint>,
) -> Result<(HostCapabilitiesPayload, Option<ScreenPoint>), String> {
    if !cfg!(target_os = "linux") {
        return Err(
            "Linux validation reports are only available when the desktop shell is built for Linux."
                .to_owned(),
        );
    }

    if let Some(anchor) = anchor {
        *state.last_anchor.lock().unwrap() = Some(anchor);
    }
    let remembered_anchor = *state.last_anchor.lock().unwrap();
    let requested_width = {
        let shell_state = state.shell_state.lock().unwrap();
        shell_state.width_tiers[shell_state.selected_width_tier_index]
    };

    let snapshot = {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        refresh_linux_validation_evidence(&mut host_capabilities);
        refresh_linux_frontmost_gate_diagnostics(&mut host_capabilities);
        refresh_linux_hovered_item_diagnostics(&mut host_capabilities, remembered_anchor);

        if let Some(effective_anchor) = remembered_anchor {
            let selected_work_area = preview_work_area_for_anchor(window, effective_anchor)?;
            let geometry = compute_preview_geometry(
                effective_anchor,
                selected_work_area.work_area,
                requested_width,
            );
            update_linux_monitor_selection_diagnostics(
                &mut host_capabilities,
                effective_anchor,
                &selected_work_area,
            );
            update_linux_preview_placement_diagnostics(
                &mut host_capabilities,
                requested_width,
                &geometry,
            );
        } else {
            clear_linux_monitor_validation_snapshot(&mut host_capabilities);
        }

        host_capabilities.clone()
    };

    Ok((snapshot, remembered_anchor))
}

fn capture_desktop_shell_validation_snapshot_internal(
    app: &AppHandle,
    window: &WebviewWindow,
    state: &ShellBridgeState,
    anchor: Option<ScreenPoint>,
) -> Result<DesktopShellValidationSnapshotPayload, String> {
    let (host_capabilities, remembered_anchor) = if cfg!(target_os = "linux") {
        let (host_capabilities, remembered_anchor) =
            refresh_linux_validation_snapshot(window, state, anchor)?;
        emit_host_capabilities(app, state)?;
        (host_capabilities, remembered_anchor)
    } else {
        let remembered_anchor = if let Some(anchor) = anchor {
            *state.last_anchor.lock().unwrap() = Some(anchor);
            Some(anchor)
        } else {
            *state.last_anchor.lock().unwrap()
        };
        let host_capabilities = state.host_capabilities.lock().unwrap().clone();
        (host_capabilities, remembered_anchor)
    };
    let shell_state = state.shell_state.lock().unwrap().clone();

    emit_shell_state(app, state)?;

    Ok(build_desktop_shell_validation_snapshot_payload(
        &shell_state,
        &host_capabilities,
        remembered_anchor,
    ))
}

fn reveal_preview_window(window: &WebviewWindow, state: &ShellBridgeState) -> Result<(), String> {
    let _ = apply_preview_geometry_internal(window, state, None)?;
    window.show().map_err(|error| error.to_string())?;
    window.set_focus().map_err(|error| error.to_string())
}

fn apply_hovered_markdown_document(
    app: &AppHandle,
    window: &WebviewWindow,
    state: &ShellBridgeState,
    path: &str,
    anchor: ScreenPoint,
    action_label: &str,
) -> Result<(), String> {
    let path = normalize_source_document_path(path)?;
    let markdown = fs::read_to_string(&path)
        .map_err(|error| format!("Failed to read hovered Markdown from {path}: {error}"))?;
    let title = file_name_label(Path::new(&path));

    {
        let mut shell_state = state.shell_state.lock().unwrap();
        replace_preview_document_state(
            &mut shell_state,
            markdown,
            None,
            Some(path.clone()),
            title,
        )?;
        let shell_state_snapshot = shell_state.clone();
        drop(shell_state);

        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        refresh_edit_persistence_capability(&mut host_capabilities, &shell_state_snapshot);
    }

    *state.last_anchor.lock().unwrap() = Some(anchor);
    set_preview_visibility(
        state,
        true,
        Some(action_label.to_owned()),
        Some(path.clone()),
    );
    reveal_preview_window(window, state)?;
    emit_shell_state(app, state)?;
    emit_host_capabilities(app, state)
}

fn start_linux_hover_worker(app: AppHandle) {
    if !cfg!(target_os = "linux") {
        return;
    }

    thread::spawn(move || {
        loop {
            thread::sleep(HOVER_POLL_INTERVAL);

            let Some(state) = app.try_state::<ShellBridgeState>() else {
                break;
            };

            let anchor = match app.cursor_position() {
                Ok(position) => ScreenPoint {
                    x: position.x,
                    y: position.y,
                },
                Err(_) => continue,
            };
            let observation = collect_linux_hover_observation(anchor);
            let now = Instant::now();
            let current_preview_path = current_preview_source_document_path(&state);

            let step = {
                let mut runtime = state.linux_hover_runtime.lock().unwrap();
                advance_linux_hover_lifecycle(
                    &mut runtime,
                    &observation,
                    current_preview_path.as_deref(),
                    now,
                )
            };

            if step.observation_changed || step.action.is_some() {
                let preview_visible = state.linux_hover_runtime.lock().unwrap().preview_visible;
                let preview_path = if preview_visible {
                    current_preview_source_document_path(&state)
                } else {
                    None
                };
                {
                    let mut host_capabilities = state.host_capabilities.lock().unwrap();
                    let last_action = match &step.action {
                        Some(HoverLifecycleAction::Open { .. }) => Some("opened".to_owned()),
                        Some(HoverLifecycleAction::Replace { .. }) => Some("replaced".to_owned()),
                        Some(HoverLifecycleAction::SuppressSameItem) => {
                            Some("suppressed-same-item".to_owned())
                        }
                        None => None,
                    };
                    update_linux_hover_lifecycle_diagnostics(
                        &mut host_capabilities,
                        Some(observation.anchor),
                        observation.observed_markdown_path.clone(),
                        preview_visible,
                        preview_path,
                        last_action,
                    );
                }
                let _ = emit_host_capabilities(&app, &state);
            }

            let Some(action) = step.action else {
                continue;
            };
            let Some(app_state) = app.try_state::<ShellBridgeState>() else {
                continue;
            };
            if *app_state.is_editing.lock().unwrap() {
                continue;
            }

            match action {
                HoverLifecycleAction::Open { path, anchor } => {
                    let app_handle = app.clone();
                    let _ = app.run_on_main_thread(move || {
                        let Some(window) = app_handle.get_webview_window(PREVIEW_WINDOW_LABEL)
                        else {
                            return;
                        };
                        let Some(state) = app_handle.try_state::<ShellBridgeState>() else {
                            return;
                        };
                        let _ = apply_hovered_markdown_document(
                            &app_handle,
                            &window,
                            &state,
                            &path,
                            anchor,
                            "opened",
                        );
                    });
                }
                HoverLifecycleAction::Replace { path, anchor } => {
                    let app_handle = app.clone();
                    let _ = app.run_on_main_thread(move || {
                        let Some(window) = app_handle.get_webview_window(PREVIEW_WINDOW_LABEL)
                        else {
                            return;
                        };
                        let Some(state) = app_handle.try_state::<ShellBridgeState>() else {
                            return;
                        };
                        let _ = apply_hovered_markdown_document(
                            &app_handle,
                            &window,
                            &state,
                            &path,
                            anchor,
                            "replaced",
                        );
                    });
                }
                HoverLifecycleAction::SuppressSameItem => {}
            }
        }
    });
}

#[tauri::command]
fn bootstrap_shell(state: State<'_, ShellBridgeState>) -> BootstrapPayload {
    state.bootstrap_payload()
}

#[tauri::command]
fn set_editing_state(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
    editing: bool,
) -> Result<(), String> {
    *state.is_editing.lock().unwrap() = editing;
    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        host_capabilities.close_on_blur_enabled = !editing;
        update_linux_edit_lifecycle_diagnostics(&mut host_capabilities, editing, None);
        refresh_linux_frontmost_gate_diagnostics(&mut host_capabilities);
    }
    emit_host_capabilities(&app, &state)
}

#[tauri::command]
fn adjust_width_tier(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    delta: i32,
) -> Result<ShellStatePayload, String> {
    {
        let mut shell_state = state.shell_state.lock().unwrap();
        let current = shell_state.selected_width_tier_index as i32;
        let next = (current + delta).clamp(0, shell_state.width_tiers.len() as i32 - 1);
        shell_state.selected_width_tier_index = next as usize;
    }
    let _ = apply_preview_geometry_internal(&window, &state, None)?;
    emit_shell_state(&app, &state)?;
    emit_host_capabilities(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn toggle_background_mode(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
) -> Result<ShellStatePayload, String> {
    {
        let mut shell_state = state.shell_state.lock().unwrap();
        shell_state.background_mode = shell_state.background_mode.toggled();
    }
    emit_shell_state(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn replace_preview_markdown(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
    markdown: String,
    content_base_url: Option<String>,
    source_document_path: Option<String>,
    document_title: Option<String>,
) -> Result<ShellStatePayload, String> {
    let shell_state_snapshot = {
        let mut shell_state = state.shell_state.lock().unwrap();
        replace_preview_document_state(
            &mut shell_state,
            markdown,
            content_base_url,
            source_document_path,
            document_title,
        )?;
        shell_state.clone()
    };
    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        refresh_edit_persistence_capability(&mut host_capabilities, &shell_state_snapshot);
    }
    emit_shell_state(&app, &state)?;
    emit_host_capabilities(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn save_preview_markdown(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
    markdown: String,
) -> Result<ShellStatePayload, String> {
    let shell_state_snapshot = {
        let mut shell_state = state.shell_state.lock().unwrap();
        save_preview_markdown_to_attached_source(&mut shell_state, &markdown)?;
        shell_state.clone()
    };
    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        refresh_edit_persistence_capability(&mut host_capabilities, &shell_state_snapshot);
    }
    emit_shell_state(&app, &state)?;
    emit_host_capabilities(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn request_preview_close(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    reason: String,
) -> Result<(), String> {
    if *state.is_editing.lock().unwrap() {
        return Ok(());
    }
    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        update_linux_edit_lifecycle_diagnostics(
            &mut host_capabilities,
            false,
            Some(reason.clone()),
        );
    }
    set_preview_visibility(&state, false, Some(format!("closed:{reason}")), None);
    emit_host_capabilities(&app, &state)?;
    window.hide().map_err(|error| error.to_string())?;
    app.emit(
        CLOSE_REQUESTED_EVENT,
        CloseRequestPayload {
            reason: reason.clone(),
        },
    )
    .map_err(|error| error.to_string())
}

#[tauri::command]
fn apply_preview_geometry(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    anchor: Option<ScreenPoint>,
) -> Result<PreviewGeometryPayload, String> {
    let geometry = apply_preview_geometry_internal(&window, &state, anchor)?;
    emit_host_capabilities(&app, &state)?;
    Ok(geometry)
}

#[tauri::command]
fn capture_linux_validation_report(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    anchor: Option<ScreenPoint>,
) -> Result<LinuxValidationReportPayload, String> {
    let (host_capabilities, remembered_anchor) =
        refresh_linux_validation_snapshot(&window, &state, anchor)?;
    emit_host_capabilities(&app, &state)?;
    build_linux_validation_report_payload(&host_capabilities, remembered_anchor)
}

#[tauri::command]
fn capture_desktop_shell_validation_snapshot(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    anchor: Option<ScreenPoint>,
) -> Result<DesktopShellValidationSnapshotPayload, String> {
    capture_desktop_shell_validation_snapshot_internal(&app, &window, &state, anchor)
}

#[tauri::command]
fn export_desktop_shell_validation_artifacts(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    anchor: Option<ScreenPoint>,
) -> Result<DesktopShellValidationArtifactExportPayload, String> {
    let snapshot =
        capture_desktop_shell_validation_snapshot_internal(&app, &window, &state, anchor)?;
    let export = export_desktop_shell_validation_artifacts_to_directory(
        &test_logs_output_directory(),
        &snapshot,
    )?;
    if cfg!(target_os = "linux") {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        refresh_linux_validation_evidence(&mut host_capabilities);
        drop(host_capabilities);
        emit_host_capabilities(&app, &state)?;
    }
    Ok(export)
}

#[tauri::command]
fn reveal_preview(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
) -> Result<(), String> {
    reveal_preview_window(&window, &state)?;
    set_preview_visibility(
        &state,
        true,
        Some("revealed".to_owned()),
        current_preview_source_document_path(&state),
    );
    emit_shell_state(&app, &state)?;
    emit_host_capabilities(&app, &state)
}

#[tauri::command]
fn start_preview_window_drag(window: WebviewWindow) -> Result<(), String> {
    if !cfg!(target_os = "linux") {
        return Ok(());
    }

    window.start_dragging().map_err(|error| error.to_string())
}

fn main() {
    let shell_state = ShellBridgeState::new();
    let global_shortcut_plugin = GlobalShortcutBuilder::new()
        .with_shortcut("CmdOrCtrl+Shift+P")
        .expect("failed to register the FastMD preview re-open shortcut")
        .with_handler(|app, _, _| {
            if let Some(window) = app.get_webview_window(PREVIEW_WINDOW_LABEL) {
                if let Some(state) = app.try_state::<ShellBridgeState>() {
                    let _ = reveal_preview_window(&window, &state);
                    set_preview_visibility(
                        &state,
                        true,
                        Some("revealed".to_owned()),
                        current_preview_source_document_path(&state),
                    );
                    let _ = emit_shell_state(app, &state);
                    let _ = emit_host_capabilities(app, &state);
                }
            }
        })
        .build();

    tauri::Builder::default()
        .manage(shell_state)
        .plugin(global_shortcut_plugin)
        .invoke_handler(tauri::generate_handler![
            bootstrap_shell,
            set_editing_state,
            adjust_width_tier,
            toggle_background_mode,
            replace_preview_markdown,
            save_preview_markdown,
            request_preview_close,
            apply_preview_geometry,
            capture_linux_validation_report,
            capture_desktop_shell_validation_snapshot,
            export_desktop_shell_validation_artifacts,
            reveal_preview,
            start_preview_window_drag,
        ])
        .on_window_event(|window, event| {
            if window.label() != PREVIEW_WINDOW_LABEL {
                return;
            }

            if let WindowEvent::Focused(false) = event {
                let Some(state) = window.app_handle().try_state::<ShellBridgeState>() else {
                    return;
                };
                let should_close = {
                    let host_capabilities = state.host_capabilities.lock().unwrap();
                    host_capabilities.close_on_blur_enabled
                };
                if !should_close {
                    return;
                }
                let reason = {
                    let mut host_capabilities = state.host_capabilities.lock().unwrap();
                    refresh_linux_frontmost_gate_diagnostics(&mut host_capabilities)
                        .unwrap_or_else(|| "focus-lost".to_owned())
                };
                {
                    let mut host_capabilities = state.host_capabilities.lock().unwrap();
                    update_linux_edit_lifecycle_diagnostics(
                        &mut host_capabilities,
                        false,
                        Some(reason.clone()),
                    );
                }
                set_preview_visibility(&state, false, Some(format!("closed:{reason}")), None);
                let _ = emit_host_capabilities(window.app_handle(), &state);
                let _ = window.hide();
                let _ = window
                    .app_handle()
                    .emit(CLOSE_REQUESTED_EVENT, CloseRequestPayload { reason });
            }
        })
        .setup(|app| {
            let window = app
                .get_webview_window(PREVIEW_WINDOW_LABEL)
                .ok_or_else(|| std::io::Error::other("The preview window is not configured."))?;
            let state = app.state::<ShellBridgeState>();
            if cfg!(target_os = "linux") {
                window.hide().map_err(std::io::Error::other)?;
                set_preview_visibility(&state, false, None, None);
                start_linux_hover_worker(app.handle().clone());
            } else {
                reveal_preview_window(&window, &state).map_err(std::io::Error::other)?;
                set_preview_visibility(
                    &state,
                    true,
                    Some("revealed".to_owned()),
                    current_preview_source_document_path(&state),
                );
            }
            emit_shell_state(app.handle(), &state).map_err(std::io::Error::other)?;
            emit_host_capabilities(app.handle(), &state).map_err(std::io::Error::other)?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("failed to run the FastMD desktop Tauri shell");
}

#[cfg(test)]
mod tests {
    use std::time::{SystemTime, UNIX_EPOCH};

    use super::*;

    #[test]
    fn width_tiers_match_the_macos_reference_values() {
        assert_eq!(WIDTH_TIERS, [560, 960, 1440, 1920]);
    }

    #[test]
    fn tauri_shell_bootstraps_reference_width_tiers() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(shell_state.snapshot_shell_state().width_tiers, WIDTH_TIERS);
    }

    #[test]
    fn tauri_shell_bootstraps_in_desktop_runtime_mode() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state.snapshot_host_capabilities().runtime_mode,
            RuntimeMode::Desktop
        );
    }

    #[test]
    fn linux_probe_plans_are_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_probe_plans
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_preview_placement_metadata_is_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_preview_placement
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_preview_window_drag_surface_metadata_is_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();
        let drag_surface = shell_state.snapshot_host_capabilities().preview_window_drag_surface;

        assert_eq!(drag_surface.is_some(), cfg!(target_os = "linux"));
        if let Some(drag_surface) = drag_surface {
            assert_eq!(
                drag_surface.strategy,
                "shared toolbar mousedown -> Tauri WebviewWindow::start_dragging"
            );
            assert_eq!(drag_surface.drag_handle_selector, ".toolbar");
            assert_eq!(
                drag_surface.activation,
                "primary-button mousedown on top chrome only"
            );
        }
    }

    #[test]
    fn linux_parity_coverage_is_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_parity_coverage
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_runtime_diagnostics_are_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_runtime_diagnostics
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_preview_loop_validation_is_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_preview_loop_validation
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_validation_evidence_is_only_advertised_on_linux_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .linux_validation_evidence
                .is_some(),
            cfg!(target_os = "linux")
        );
    }

    #[test]
    fn linux_parity_coverage_payload_tracks_the_macos_reference_feature_list() {
        let payload = linux_parity_coverage_payload();

        if cfg!(target_os = "linux") {
            let payload = payload.expect("linux parity coverage should exist on Linux targets");
            assert!(payload.matches_reference);
            assert_eq!(payload.target, "Ubuntu 24.04 + GNOME Files / Nautilus");
            assert_eq!(payload.reference_surface, "apps/macos");
            assert_eq!(
                payload.covered_feature_count,
                payload.reference_feature_count
            );
            assert!(payload.missing_features.is_empty());
            assert!(payload.feature_lanes.iter().any(|entry| {
                entry.feature
                    == "Resolve the actual hovered Markdown item instead of a nearby or first-visible candidate"
                    && entry.lanes.iter().any(|lane| lane == "ubuntu-adapter")
            }));
            assert!(payload.feature_lanes.iter().any(|entry| {
                entry.feature
                    == "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy"
                    && entry.lanes.iter().any(|lane| lane == "shared-render")
            }));
        } else {
            assert!(payload.is_none());
        }
    }

    #[test]
    fn linux_preview_loop_validation_payload_tracks_wayland_and_x11_reference_coverage() {
        let payload = linux_preview_loop_validation_payload();

        if cfg!(target_os = "linux") {
            let payload =
                payload.expect("linux preview-loop validation should exist on Linux targets");
            assert_eq!(payload.wayland.display_server, "wayland");
            assert_eq!(payload.x11.display_server, "x11");
            assert_eq!(
                payload.wayland.validation_mode,
                "automated-shared-preview-loop"
            );
            assert_eq!(payload.x11.validation_mode, "automated-shared-preview-loop");
            assert!(payload.wayland.matches_reference);
            assert!(payload.x11.matches_reference);
            assert!(payload.wayland.missing_features.is_empty());
            assert!(payload.x11.missing_features.is_empty());
            assert_eq!(
                payload.wayland.covered_feature_count,
                payload.wayland.reference_feature_count
            );
            assert_eq!(
                payload.x11.covered_feature_count,
                payload.x11.reference_feature_count
            );
        } else {
            assert!(payload.is_none());
        }
    }

    #[test]
    fn linux_validation_evidence_payload_requires_cross_session_review() {
        let payload = linux_validation_evidence_payload();

        if cfg!(target_os = "linux") {
            let payload =
                payload.expect("linux validation evidence metadata should exist on Linux targets");
            assert!(matches!(
                payload.status.as_str(),
                LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED
                    | LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_CAPTURED_AWAITING_REVIEW
            ));
            assert_eq!(
                payload.checklist_item,
                "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above"
            );
            assert!(payload.note.contains("Wayland and X11"));
            assert_eq!(payload.required_display_servers, vec!["wayland", "x11"]);
        } else {
            assert!(payload.is_none());
        }
    }

    #[test]
    fn linux_validation_evidence_payload_for_directory_starts_with_missing_wayland_and_x11() {
        let output_directory = temp_file_path("validation-evidence-empty");

        let payload = linux_validation_evidence_payload_for_directory(&output_directory);

        assert_eq!(
            payload.status,
            LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED
        );
        assert_eq!(payload.required_display_servers, vec!["wayland", "x11"]);
        assert!(payload.captured_display_servers.is_empty());
        assert_eq!(payload.missing_display_servers, vec!["wayland", "x11"]);
        assert!(payload.ready_display_server_reports.is_empty());
        assert!(payload.latest_reports.is_empty());

        cleanup_dir(&output_directory);
    }

    #[test]
    fn linux_probe_plans_payload_advertises_one_shared_wayland_x11_semantic_guardrail() {
        let payload = linux_probe_plans_payload();

        if cfg!(target_os = "linux") {
            let payload = payload.expect("linux probe plans should exist on Linux targets");
            assert_eq!(
                payload.semantic_guardrail,
                "Match macOS product semantics exactly; the display server changes host probing only."
            );
            assert!(payload.wayland_frontmost_api_stack.contains("AT-SPI"));
            assert!(
                payload
                    .x11_frontmost_api_stack
                    .contains("_NET_ACTIVE_WINDOW")
            );
        } else {
            assert!(payload.is_none());
        }
    }

    #[test]
    fn linux_blur_reason_uses_outside_click_for_an_open_nautilus_gate() {
        assert_eq!(linux_blur_close_reason(true, None), "outside-click");
    }

    #[test]
    fn linux_blur_reason_uses_app_switch_when_the_foreground_is_not_nautilus() {
        assert_eq!(
            linux_blur_close_reason(
                false,
                Some(&FrontmostSurfaceRejection::NonNautilusApp {
                    app_id: Some("org.gnome.Terminal".to_owned()),
                    desktop_entry: None,
                    window_class: None,
                    executable: Some("gnome-terminal".to_owned()),
                }),
            ),
            "app-switch"
        );
    }

    #[test]
    fn linux_blur_reason_falls_back_when_a_stable_surface_id_is_missing() {
        assert_eq!(
            linux_blur_close_reason(
                false,
                Some(&FrontmostSurfaceRejection::MissingStableSurfaceId {
                    display_server: DisplayServerKind::Wayland,
                }),
            ),
            "focus-lost"
        );
    }

    #[test]
    fn frontmost_text_input_hover_fingerprint_blocks_rename_surfaces() {
        let fingerprint = frontmost_text_input_hover_fingerprint(&FrontmostAppSnapshot {
            app_id: Some("org.gnome.Nautilus".to_owned()),
            desktop_entry: Some("org.gnome.Nautilus.desktop".to_owned()),
            window_class: None,
            executable: Some("nautilus".to_owned()),
            window_title: Some("Docs".to_owned()),
            process_id: Some(4201),
            stable_surface_id: Some("atspi:wayland:pid=4201:name=Docs".to_owned()),
            focused_role_name: Some("entry".to_owned()),
            focused_name: Some("Report.md".to_owned()),
            focused_is_text_input: true,
        });

        assert_eq!(
            fingerprint.as_deref(),
            Some("hover=blocked:text-input-active:role=entry:name=Report.md")
        );
    }

    #[test]
    fn hover_lifecycle_waits_one_second_before_opening_a_markdown_preview() {
        let mut runtime = LinuxHoverRuntimeState::default();
        let observation = hover_observation(240, 320, Some("/tmp/hovered.md"));
        let start = Instant::now();

        let first = advance_linux_hover_lifecycle(&mut runtime, &observation, None, start);
        assert!(first.observation_changed);
        assert!(first.action.is_none());

        let before_delay = advance_linux_hover_lifecycle(
            &mut runtime,
            &observation,
            None,
            start + Duration::from_millis(900),
        );
        assert!(before_delay.action.is_none());

        let after_delay = advance_linux_hover_lifecycle(
            &mut runtime,
            &observation,
            None,
            start + HOVER_TRIGGER_DELAY,
        );
        match after_delay.action {
            Some(HoverLifecycleAction::Open { path, anchor }) => {
                assert_eq!(path, "/tmp/hovered.md");
                assert_eq!(anchor.x, 240.0);
                assert_eq!(anchor.y, 320.0);
            }
            other => panic!("expected open action after debounce, got {other:?}"),
        }
    }

    #[test]
    fn hover_lifecycle_replaces_visible_preview_when_the_hovered_path_changes() {
        let mut runtime = LinuxHoverRuntimeState {
            preview_visible: true,
            ..LinuxHoverRuntimeState::default()
        };
        let first = hover_observation(100, 100, Some("/tmp/first.md"));
        let second = hover_observation(140, 180, Some("/tmp/second.md"));
        let start = Instant::now();

        let _ = advance_linux_hover_lifecycle(&mut runtime, &first, Some("/tmp/first.md"), start);
        let _ = advance_linux_hover_lifecycle(
            &mut runtime,
            &first,
            Some("/tmp/first.md"),
            start + HOVER_TRIGGER_DELAY,
        );
        let changed = advance_linux_hover_lifecycle(
            &mut runtime,
            &second,
            Some("/tmp/first.md"),
            start + HOVER_TRIGGER_DELAY + Duration::from_millis(10),
        );
        assert!(changed.observation_changed);

        let replaced = advance_linux_hover_lifecycle(
            &mut runtime,
            &second,
            Some("/tmp/first.md"),
            start + HOVER_TRIGGER_DELAY * 2 + Duration::from_millis(10),
        );
        match replaced.action {
            Some(HoverLifecycleAction::Replace { path, anchor }) => {
                assert_eq!(path, "/tmp/second.md");
                assert_eq!(anchor.x, 140.0);
                assert_eq!(anchor.y, 180.0);
            }
            other => panic!("expected replace action after debounce, got {other:?}"),
        }
    }

    #[test]
    fn hover_lifecycle_suppresses_reopen_for_the_same_visible_markdown_file() {
        let mut runtime = LinuxHoverRuntimeState {
            preview_visible: true,
            ..LinuxHoverRuntimeState::default()
        };
        let observation = hover_observation(400, 220, Some("/tmp/same.md"));
        let start = Instant::now();

        let _ =
            advance_linux_hover_lifecycle(&mut runtime, &observation, Some("/tmp/same.md"), start);
        let suppressed = advance_linux_hover_lifecycle(
            &mut runtime,
            &observation,
            Some("/tmp/same.md"),
            start + HOVER_TRIGGER_DELAY,
        );

        assert!(matches!(
            suppressed.action,
            Some(HoverLifecycleAction::SuppressSameItem)
        ));
    }

    #[test]
    fn hover_lifecycle_does_not_open_without_a_resolved_markdown_path() {
        let mut runtime = LinuxHoverRuntimeState::default();
        let observation = hover_observation(90, 120, None);
        let start = Instant::now();

        let _ = advance_linux_hover_lifecycle(&mut runtime, &observation, None, start);
        let after_delay = advance_linux_hover_lifecycle(
            &mut runtime,
            &observation,
            None,
            start + HOVER_TRIGGER_DELAY,
        );

        assert!(after_delay.action.is_none());
    }

    #[test]
    fn hot_interaction_surface_metadata_is_advertised_on_supported_desktop_targets() {
        let shell_state = ShellBridgeState::new();

        assert_eq!(
            shell_state
                .snapshot_host_capabilities()
                .hot_interaction_surface
                .is_some(),
            matches!(detected_platform_id(), "macos" | "windows" | "ubuntu")
        );
    }

    #[test]
    fn shared_rendering_surface_payload_tracks_the_macos_pinned_stage2_contract() {
        let payload = shared_rendering_surface_payload().expect("render surface payload");

        assert_eq!(payload.source, "fastmd-render::stage2_rendering_contract");
        assert_eq!(
            payload.macos_reference_renderer,
            "apps/macos/Sources/FastMD/MarkdownRenderer.swift"
        );
        assert_eq!(payload.width_tiers_px, vec![560, 960, 1440, 1920]);
        assert_eq!(payload.aspect_ratio, PREVIEW_ASPECT_RATIO);
        assert!(payload.supported_features.contains(&"mermaid".to_owned()));
        assert!(payload.supported_features.contains(&"math".to_owned()));
        assert!(
            payload
                .supported_features
                .contains(&"html-block".to_owned())
        );
    }

    #[test]
    fn shell_monitor_selection_prefers_containing_work_area_then_nearest() {
        let layout = PlatformMonitorLayout {
            monitors: vec![
                PlatformMonitor {
                    id: "primary".to_owned(),
                    frame: PlatformScreenRect {
                        x: 0.0,
                        y: 0.0,
                        width: 1920.0,
                        height: 1080.0,
                    },
                    work_area: PlatformScreenRect {
                        x: 0.0,
                        y: 0.0,
                        width: 1920.0,
                        height: 1040.0,
                    },
                    primary: true,
                },
                PlatformMonitor {
                    id: "secondary".to_owned(),
                    frame: PlatformScreenRect {
                        x: 1920.0,
                        y: 0.0,
                        width: 2560.0,
                        height: 1440.0,
                    },
                    work_area: PlatformScreenRect {
                        x: 1920.0,
                        y: 0.0,
                        width: 2560.0,
                        height: 1400.0,
                    },
                    primary: false,
                },
            ],
        };

        let containing = selected_work_area_for_anchor(
            &layout,
            ScreenPoint {
                x: 2200.0,
                y: 300.0,
            },
        )
        .unwrap();
        assert_eq!(containing.monitor_id, "secondary");
        assert!(!containing.used_nearest_fallback);
        assert_eq!(containing.work_area.x, 1920.0);
        assert_eq!(containing.work_area.width, 2560.0);

        let nearest = selected_work_area_for_anchor(
            &layout,
            ScreenPoint {
                x: 5000.0,
                y: 5000.0,
            },
        )
        .unwrap();
        assert_eq!(nearest.monitor_id, "secondary");
        assert!(nearest.used_nearest_fallback);
        assert_eq!(nearest.work_area.x, 1920.0);
        assert_eq!(nearest.work_area.width, 2560.0);
    }

    #[test]
    fn preview_geometry_repositions_before_shrinking_when_requested_tier_still_fits() {
        let geometry = compute_preview_geometry(
            ScreenPoint { x: 980.0, y: 500.0 },
            PlatformScreenRect {
                x: 0.0,
                y: 0.0,
                width: 1200.0,
                height: 900.0,
            },
            960,
        );

        assert_eq!(geometry.width, 960);
        assert_eq!(geometry.height, 720);
        assert_eq!(geometry.x, 2);
        assert_eq!(geometry.y, 168);
    }

    #[test]
    fn preview_geometry_shrinks_only_when_requested_tier_exceeds_work_area_capacity() {
        let geometry = compute_preview_geometry(
            ScreenPoint { x: 320.0, y: 240.0 },
            PlatformScreenRect {
                x: 0.0,
                y: 0.0,
                width: 700.0,
                height: 500.0,
            },
            960,
        );

        assert_eq!(geometry.width, 635);
        assert_eq!(geometry.height, 476);
        assert_eq!(geometry.x, 12);
        assert_eq!(geometry.y, 12);
    }

    #[test]
    fn bootstrap_shell_attaches_the_repo_readme_when_available() {
        let shell_state = initial_shell_state();

        assert_eq!(shell_state.document_title, "README.md");
        assert_eq!(
            shell_state.source_document_path.is_some(),
            bootstrap_source_document_path().is_some()
        );
        assert_eq!(
            shell_state.content_base_url.is_some(),
            shell_state.source_document_path.is_some()
        );
    }

    #[test]
    fn replace_preview_document_state_keeps_attached_source_metadata_when_only_markdown_changes() {
        let path = temp_file_path("replace-source.md");
        fs::write(&path, "# before\n").unwrap();

        let mut shell_state = ShellStatePayload {
            document_title: "replace-source.md".to_owned(),
            markdown: "# before\n".to_owned(),
            content_base_url: content_base_url_for_source_document(&path),
            source_document_path: Some(path_string(&path)),
            width_tiers: WIDTH_TIERS,
            selected_width_tier_index: 0,
            background_mode: BackgroundMode::White,
        };

        replace_preview_document_state(&mut shell_state, "# after\n".to_owned(), None, None, None)
            .unwrap();

        assert_eq!(shell_state.markdown, "# after\n");
        assert_eq!(shell_state.source_document_path, Some(path_string(&path)));
        assert_eq!(
            shell_state.content_base_url,
            content_base_url_for_source_document(&path)
        );

        cleanup_path(&path);
    }

    #[test]
    fn save_preview_markdown_writes_back_to_the_attached_source_file() {
        let path = temp_file_path("attached-save.md");
        fs::write(&path, "# before\n").unwrap();

        let mut shell_state = ShellStatePayload {
            document_title: "attached-save.md".to_owned(),
            markdown: "# before\n".to_owned(),
            content_base_url: None,
            source_document_path: Some(path_string(&path)),
            width_tiers: WIDTH_TIERS,
            selected_width_tier_index: 0,
            background_mode: BackgroundMode::White,
        };

        save_preview_markdown_to_attached_source(&mut shell_state, "# after\n").unwrap();

        assert_eq!(fs::read_to_string(&path).unwrap(), "# after\n");
        assert_eq!(shell_state.markdown, "# after\n");
        assert_eq!(shell_state.source_document_path, Some(path_string(&path)));
        assert_eq!(
            shell_state.content_base_url,
            content_base_url_for_source_document(&path)
        );

        cleanup_path(&path);
    }

    #[test]
    fn refresh_edit_persistence_capability_tracks_attached_source_writability() {
        let path = temp_file_path("edit-persist.md");
        fs::write(&path, "# attached\n").unwrap();

        let shell_state = ShellStatePayload {
            document_title: "edit-persist.md".to_owned(),
            markdown: "# attached\n".to_owned(),
            content_base_url: content_base_url_for_source_document(&path),
            source_document_path: Some(path_string(&path)),
            width_tiers: WIDTH_TIERS,
            selected_width_tier_index: 0,
            background_mode: BackgroundMode::White,
        };
        let mut host_capabilities = initial_host_capabilities(&shell_state);
        host_capabilities.close_on_blur_enabled = false;
        update_linux_edit_lifecycle_diagnostics(&mut host_capabilities, true, None);

        refresh_edit_persistence_capability(&mut host_capabilities, &shell_state);

        assert!(host_capabilities.can_persist_preview_edits);
        assert_eq!(
            host_capabilities
                .linux_runtime_diagnostics
                .as_ref()
                .map(|diagnostics| diagnostics.edit_lifecycle.editing),
            Some(true)
        );
        assert_eq!(
            host_capabilities
                .linux_runtime_diagnostics
                .as_ref()
                .map(|diagnostics| diagnostics.edit_lifecycle.close_on_blur_enabled),
            Some(false)
        );

        cleanup_path(&path);
    }

    #[test]
    fn linux_validation_report_marks_wayland_items_ready_when_live_shell_evidence_passes() {
        let host_capabilities = linux_validation_host_capabilities("wayland");

        let report = build_linux_validation_report_payload(
            &host_capabilities,
            Some(ScreenPoint { x: 240.0, y: 180.0 }),
        )
        .expect("validation report");

        assert_eq!(report.display_server, "wayland");
        assert!(report.ready_to_close_display_server_report);
        assert!(!report.cross_session_parity_evidence_ready);
        assert!(
            report
                .cross_session_parity_evidence_note
                .contains("Wayland and X11")
        );
        assert_eq!(
            report.cross_session_required_display_servers,
            vec!["wayland", "x11"]
        );
        assert!(report.cross_session_captured_display_servers.is_empty());
        assert_eq!(
            report.cross_session_missing_display_servers,
            vec!["wayland", "x11"]
        );
        assert!(report.ready_checklist_items.iter().any(|item| {
            item == "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session"
        }));
        assert!(report.ready_checklist_items.iter().any(|item| {
            item == "Validate exact hovered-item resolution on a real Ubuntu 24.04 Wayland session"
        }));
        assert!(report.ready_checklist_items.iter().any(|item| {
            item == "Validate monitor selection and coordinate handling on a real Ubuntu 24.04 Wayland session"
        }));
        assert!(report.blocked_checklist_items.iter().any(|item| {
            item == "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above"
        }));
        assert_eq!(report.blocked_checklist_items.len(), 1);
        assert!(
            report
                .markdown
                .contains("Active display-server report readiness: `ready-to-close`")
        );
        assert!(
            report
                .markdown
                .contains("Cross-session Ubuntu parity-evidence readiness: `not-ready-to-close`")
        );
        assert!(
            report
                .markdown
                .contains("Cross-session missing display servers: `wayland, x11`")
        );
    }

    #[test]
    fn linux_validation_report_keeps_hover_and_parity_items_blocked_without_live_hover_evidence() {
        let mut host_capabilities = linux_validation_host_capabilities("x11");
        let diagnostics = host_capabilities
            .linux_runtime_diagnostics
            .as_mut()
            .expect("linux runtime diagnostics");
        diagnostics.hovered_item.status = DIAGNOSTIC_STATUS_PENDING_LIVE_PROBE;
        diagnostics.hovered_item.accepted = None;
        diagnostics.hovered_item.path = None;
        diagnostics.hovered_item.resolution_scope = None;
        diagnostics.hovered_item.detail = None;

        let report = build_linux_validation_report_payload(&host_capabilities, None)
            .expect("validation report");

        assert_eq!(report.display_server, "x11");
        assert!(!report.ready_to_close_display_server_report);
        assert!(!report.cross_session_parity_evidence_ready);
        assert!(report.ready_checklist_items.iter().any(|item| {
            item == "Validate frontmost Nautilus detection on a real Ubuntu 24.04 X11 session"
        }));
        assert!(report.blocked_checklist_items.iter().any(|item| {
            item == "Validate exact hovered-item resolution on a real Ubuntu 24.04 X11 session"
        }));
        assert!(report.blocked_checklist_items.iter().any(|item| {
            item == "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above"
        }));
        assert!(
            report
                .markdown
                .contains("Cross-session Ubuntu parity-evidence readiness: `not-ready-to-close`")
        );
    }

    #[test]
    fn desktop_shell_validation_snapshot_embeds_shell_host_and_linux_report_state() {
        let shell_state = initial_shell_state();
        let host_capabilities = linux_validation_host_capabilities("wayland");

        let snapshot = build_desktop_shell_validation_snapshot_payload(
            &shell_state,
            &host_capabilities,
            Some(ScreenPoint { x: 240.0, y: 180.0 }),
        );

        assert!(snapshot.captured_at_unix_ms > 0);
        assert_eq!(snapshot.shell_state.document_title, shell_state.document_title);
        assert_eq!(
            snapshot.host_capabilities.platform_id,
            host_capabilities.platform_id
        );
        assert_eq!(
            snapshot
                .linux_validation_report
                .as_ref()
                .map(|report| report.display_server.as_str()),
            Some("wayland")
        );
    }

    #[test]
    fn desktop_shell_validation_snapshot_keeps_linux_report_optional_for_non_linux_shells() {
        let shell_state = initial_shell_state();
        let host_capabilities = initial_host_capabilities(&shell_state);

        let snapshot =
            build_desktop_shell_validation_snapshot_payload(&shell_state, &host_capabilities, None);

        assert!(snapshot.captured_at_unix_ms > 0);
        assert_eq!(snapshot.shell_state.document_title, shell_state.document_title);
        assert_eq!(
            snapshot.host_capabilities.platform_id,
            host_capabilities.platform_id
        );
        assert!(snapshot.linux_validation_report.is_none());
    }

    #[test]
    fn export_desktop_shell_validation_artifacts_writes_snapshot_report_markdown_and_report_json() {
        let shell_state = initial_shell_state();
        let host_capabilities = linux_validation_host_capabilities("wayland");
        let snapshot = build_desktop_shell_validation_snapshot_payload(
            &shell_state,
            &host_capabilities,
            Some(ScreenPoint { x: 240.0, y: 180.0 }),
        );
        let output_directory = temp_file_path("validation-artifacts");

        let export = export_desktop_shell_validation_artifacts_to_directory(
            &output_directory,
            &snapshot,
        )
        .expect("validation artifacts should export");

        assert_eq!(export.output_directory, path_string(&output_directory));
        assert_eq!(export.display_server.as_deref(), Some("wayland"));
        assert!(Path::new(&export.snapshot_markdown_path).exists());
        assert!(
            Path::new(
                export
                    .linux_validation_report_markdown_path
                    .as_deref()
                    .expect("linux validation report path")
            )
            .exists()
        );
        assert!(
            Path::new(
                export
                    .linux_validation_report_json_path
                    .as_deref()
                    .expect("linux validation report json path")
            )
            .exists()
        );
        assert_eq!(
            export
                .linux_validation_evidence
                .as_ref()
                .map(|payload| payload.captured_display_servers.clone()),
            Some(vec!["wayland".to_owned()])
        );
        assert_eq!(
            export
                .linux_validation_evidence
                .as_ref()
                .map(|payload| payload.missing_display_servers.clone()),
            Some(vec!["x11".to_owned()])
        );

        let snapshot_markdown = fs::read_to_string(&export.snapshot_markdown_path)
            .expect("snapshot markdown should be readable");
        assert!(snapshot_markdown.contains("# FastMD Desktop Shell Validation Snapshot"));
        assert!(snapshot_markdown.contains("Companion Ubuntu validation report"));
        assert!(snapshot_markdown.contains("Runtime mode: `desktop`"));

        let report_markdown = fs::read_to_string(
            export
                .linux_validation_report_markdown_path
                .as_deref()
                .expect("linux validation report path"),
        )
        .expect("report markdown should be readable");
        assert!(report_markdown.contains("# Ubuntu 24.04 GNOME Files Validation Evidence Report"));
        assert!(report_markdown.contains("Display server: `wayland`"));

        cleanup_dir(&output_directory);
    }

    #[test]
    fn export_desktop_shell_validation_artifacts_tracks_cross_session_wayland_and_x11_capture_progress()
    {
        let shell_state = initial_shell_state();
        let output_directory = temp_file_path("validation-evidence-summary");

        let wayland_snapshot = build_desktop_shell_validation_snapshot_payload(
            &shell_state,
            &linux_validation_host_capabilities("wayland"),
            Some(ScreenPoint { x: 240.0, y: 180.0 }),
        );
        let wayland_export = export_desktop_shell_validation_artifacts_to_directory(
            &output_directory,
            &wayland_snapshot,
        )
        .expect("wayland validation artifacts should export");
        assert_eq!(
            wayland_export
                .linux_validation_evidence
                .as_ref()
                .map(|payload| payload.status.clone()),
            Some(LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED.to_owned())
        );
        assert_eq!(
            wayland_export
                .linux_validation_evidence
                .as_ref()
                .map(|payload| payload.captured_display_servers.clone()),
            Some(vec!["wayland".to_owned()])
        );

        let x11_snapshot = build_desktop_shell_validation_snapshot_payload(
            &shell_state,
            &linux_validation_host_capabilities("x11"),
            Some(ScreenPoint { x: 240.0, y: 180.0 }),
        );
        let x11_export = export_desktop_shell_validation_artifacts_to_directory(
            &output_directory,
            &x11_snapshot,
        )
        .expect("x11 validation artifacts should export");
        let linux_validation_evidence = x11_export
            .linux_validation_evidence
            .expect("cross-session linux validation evidence");

        assert_eq!(
            linux_validation_evidence.status,
            LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_CAPTURED_AWAITING_REVIEW
        );
        assert_eq!(
            linux_validation_evidence.captured_display_servers,
            vec!["wayland".to_owned(), "x11".to_owned()]
        );
        assert!(linux_validation_evidence.missing_display_servers.is_empty());
        assert_eq!(
            linux_validation_evidence.ready_display_server_reports,
            vec!["wayland".to_owned(), "x11".to_owned()]
        );
        assert_eq!(linux_validation_evidence.latest_reports.len(), 2);
        assert!(
            linux_validation_evidence
                .note
                .contains("reviewed and explicitly signed off")
        );

        cleanup_dir(&output_directory);
    }

    fn temp_file_path(name: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_nanos();
        std::env::temp_dir().join(format!("fastmd-desktop-tauri-{nonce}-{name}"))
    }

    fn cleanup_path(path: &Path) {
        let _ = fs::remove_file(path);
    }

    fn cleanup_dir(path: &Path) {
        let _ = fs::remove_dir_all(path);
    }

    fn linux_validation_host_capabilities(display_server: &str) -> HostCapabilitiesPayload {
        HostCapabilitiesPayload {
            platform_id: "ubuntu",
            runtime_mode: RuntimeMode::Desktop,
            accessibility_permission: "unknown",
            frontmost_file_manager: "nautilus",
            preview_window_positioning: true,
            global_shortcut_registered: true,
            close_on_blur_enabled: true,
            can_persist_preview_edits: true,
            hot_interaction_surface: hot_interaction_surface_payload(),
            shared_rendering_surface: shared_rendering_surface_payload(),
            linux_probe_plans: None,
            linux_preview_placement: None,
            linux_parity_coverage: Some(UbuntuPreviewFeatureCoverageSummary {
                target: "Ubuntu 24.04 + GNOME Files / Nautilus",
                reference_surface: "apps/macos",
                matches_reference: true,
                covered_feature_count: 20,
                reference_feature_count: 20,
                missing_features: Vec::new(),
                feature_lanes: Vec::new(),
            }),
            linux_preview_loop_validation: Some(UbuntuPreviewLoopValidationBundle {
                wayland: fastmd_platform_linux_nautilus::ubuntu_preview_loop_validation_summary(
                    DisplayServerKind::Wayland,
                ),
                x11: fastmd_platform_linux_nautilus::ubuntu_preview_loop_validation_summary(
                    DisplayServerKind::X11,
                ),
            }),
            linux_validation_evidence: Some(LinuxValidationEvidencePayload {
                status: LINUX_VALIDATION_EVIDENCE_STATUS_CROSS_SESSION_REVIEW_REQUIRED.to_owned(),
                checklist_item: ubuntu_parity_evidence_checklist_item().to_owned(),
                note: ubuntu_parity_evidence_pending_note().to_owned(),
                required_display_servers: vec!["wayland".to_owned(), "x11".to_owned()],
                captured_display_servers: Vec::new(),
                missing_display_servers: vec!["wayland".to_owned(), "x11".to_owned()],
                ready_display_server_reports: Vec::new(),
                latest_reports: Vec::new(),
            }),
            linux_runtime_diagnostics: Some(LinuxRuntimeDiagnosticsPayload {
                display_server: if display_server == "x11" {
                    "x11"
                } else {
                    "wayland"
                },
                frontmost_gate: LinuxFrontmostGateDiagnosticPayload {
                    status: DIAGNOSTIC_STATUS_EMITTED,
                    display_server: if display_server == "x11" {
                        "x11"
                    } else {
                        "wayland"
                    },
                    backend: Some(if display_server == "x11" {
                        "live-atspi+xprop-x11".to_owned()
                    } else {
                        "live-atspi-wayland".to_owned()
                    }),
                    api_stack: "focus=AT-SPI focused accessible".to_owned(),
                    observed_identifier: Some("org.gnome.Nautilus".to_owned()),
                    stable_surface_id: Some("nautilus-surface-1".to_owned()),
                    window_title: Some("Docs".to_owned()),
                    process_id: Some(4242),
                    is_open: Some(true),
                    text_input_active: Some(false),
                    text_input_role: None,
                    text_input_name: None,
                    inferred_blur_close_reason: Some("outside-click".to_owned()),
                    rejection: None,
                    detail: Some(
                        "Live Linux frontmost probing kept Nautilus as the foreground gate."
                            .to_owned(),
                    ),
                    note: "Live frontmost note".to_owned(),
                },
                hovered_item: LinuxHoveredItemDiagnosticPayload {
                    status: DIAGNOSTIC_STATUS_EMITTED,
                    display_server: if display_server == "x11" {
                        "x11"
                    } else {
                        "wayland"
                    },
                    api_stack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)".to_owned(),
                    backend: Some(if display_server == "x11" {
                        "live-atspi-x11-hit-test".to_owned()
                    } else {
                        "live-atspi-wayland-hit-test".to_owned()
                    }),
                    resolution_scope: Some("exact-item-under-pointer".to_owned()),
                    entity_kind: Some("file".to_owned()),
                    item_name: Some("demo.md".to_owned()),
                    path: Some("/home/demo/demo.md".to_owned()),
                    path_source: Some("direct-path".to_owned()),
                    visible_markdown_peer_count: Some(4),
                    accepted: Some(true),
                    rejection: None,
                    detail: Some(
                        "Live Linux hovered-item probing resolved /home/demo/demo.md through the shared markdown filter."
                            .to_owned(),
                    ),
                    note: "Live hovered-item note".to_owned(),
                },
                monitor_selection: LinuxMonitorSelectionDiagnosticPayload {
                    status: DIAGNOSTIC_STATUS_EMITTED,
                    selection_policy: MONITOR_SELECTION_POLICY,
                    anchor: Some(ScreenPoint { x: 240.0, y: 180.0 }),
                    selected_monitor_id: Some("monitor-1".to_owned()),
                    used_nearest_fallback: Some(false),
                    work_area: Some(ScreenRectPayload {
                        x: 0.0,
                        y: 0.0,
                        width: 1920.0,
                        height: 1040.0,
                    }),
                    note: MONITOR_SELECTION_RUNTIME_NOTE,
                },
                preview_placement: LinuxPreviewPlacementDiagnosticPayload {
                    status: DIAGNOSTIC_STATUS_EMITTED,
                    policy: PREVIEW_PLACEMENT_POLICY,
                    requested_width: Some(960),
                    applied_geometry: Some(PreviewGeometryPayload {
                        x: 300,
                        y: 120,
                        width: 960,
                        height: 720,
                    }),
                    note: PREVIEW_PLACEMENT_RUNTIME_NOTE,
                },
                edit_lifecycle: LinuxEditLifecycleDiagnosticPayload {
                    status: DIAGNOSTIC_STATUS_EMITTED,
                    policy: EDIT_LIFECYCLE_POLICY,
                    editing: false,
                    close_on_blur_enabled: true,
                    can_persist_preview_edits: true,
                    last_close_reason: Some("outside-click".to_owned()),
                    note: EDIT_LIFECYCLE_RUNTIME_NOTE,
                },
                hover_lifecycle: LinuxHoverLifecycleDiagnosticPayload {
                    status: LINUX_HOVER_LIFECYCLE_STATUS_POLLING,
                    polling_interval_ms: HOVER_POLL_INTERVAL.as_millis() as u64,
                    trigger_delay_ms: HOVER_TRIGGER_DELAY.as_millis() as u64,
                    last_anchor: Some(ScreenPoint { x: 240.0, y: 180.0 }),
                    observed_path: Some("/home/demo/demo.md".to_owned()),
                    preview_visible: true,
                    preview_path: Some("/home/demo/demo.md".to_owned()),
                    last_action: Some("opened:/home/demo/demo.md".to_owned()),
                    note: LINUX_HOVER_LIFECYCLE_NOTE,
                },
            }),
        }
    }

    fn hover_observation(
        x: i32,
        y: i32,
        observed_markdown_path: Option<&str>,
    ) -> LinuxHoverObservation {
        let observed_markdown_path = observed_markdown_path.map(ToOwned::to_owned);
        let hover_fingerprint = observed_markdown_path
            .clone()
            .unwrap_or_else(|| "hover=none".to_owned());

        LinuxHoverObservation {
            key: HoverObservationKey {
                cursor_x: x,
                cursor_y: y,
                gate_fingerprint: "open:nautilus-surface".to_owned(),
                hover_fingerprint,
            },
            anchor: ScreenPoint {
                x: f64::from(x),
                y: f64::from(y),
            },
            observed_markdown_path,
        }
    }
}
