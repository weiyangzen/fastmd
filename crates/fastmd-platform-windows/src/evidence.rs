use std::collections::BTreeSet;
#[cfg(target_os = "windows")]
use std::io::Write;
#[cfg(target_os = "windows")]
use std::process::{Command, Stdio};

use fastmd_contracts::{
    macos_preview_feature_list, preview_feature_coverage_from_records,
    preview_feature_coverage_record_gaps_against_reference,
    preview_feature_coverage_records_match_reference,
    preview_feature_real_host_evidence_requirements, preview_feature_validation_statuses,
    MacOsPreviewFeature, PlatformId, PreviewFeatureCoverageLane, RealHostEvidenceRequirement,
    ScreenPoint, ValidationCaptureProvenance, ValidationHostEnvironment,
    ValidationRequirementStatus,
};
use fastmd_core::{
    monitor_selection_mode, select_monitor_for_anchor, selected_monitor_matches_reference,
};
#[cfg(target_os = "windows")]
use serde::Deserialize;

use crate::{
    windows_preview_loop_feature_coverage_records, FrontmostSurfaceProbe, HoveredItemProbeOutcome,
    WindowsCoordinateTranslation, MACOS_REFERENCE_BEHAVIOR,
};
#[cfg(target_os = "windows")]
use crate::{AdapterError, ExplorerAdapter};

const FRONTMOST_CHECKLIST_ITEMS: [&str; 1] =
    ["Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"];
const HOVER_CHECKLIST_ITEMS: [&str; 1] =
    ["Record validation evidence for exact hovered-item resolution on a real Windows 11 machine"];
const COORDINATE_CHECKLIST_ITEMS: [&str; 1] = [
    "Record validation evidence for multi-monitor coordinate handling on a real Windows 11 machine",
];
const PARITY_CHECKLIST_ITEMS: [&str; 1] = [
    "Record Windows-specific validation evidence proving one-to-one parity with macOS for each feature above",
];
const WINDOWS_VALIDATION_REPORT_TARGET: &str = "Windows 11 + Explorer only";
const WINDOWS_VALIDATION_REQUIRED_OPERATING_SYSTEM: &str = "Windows 11";
const WINDOWS_VALIDATION_REQUIRED_FILE_MANAGER: &str = "Explorer";
#[cfg(target_os = "windows")]
const WINDOWS_VALIDATION_ENVIRONMENT_SCRIPT: &str = r#"
$os = Get-CimInstance Win32_OperatingSystem

[pscustomobject]@{
    operating_system = if ($os.Caption) { [string]$os.Caption } else { "Windows" }
    operating_system_version = if ($os.Version) { [string]$os.Version } else { $null }
    operating_system_build = if ($os.BuildNumber) { [string]$os.BuildNumber } else { $null }
    file_manager = "Explorer"
    host_name = if ($env:COMPUTERNAME) { [string]$env:COMPUTERNAME } else { $null }
    architecture = if ($os.OSArchitecture) { [string]$os.OSArchitecture } else { $null }
    captured_at_utc = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Compress
"#;

#[cfg(target_os = "windows")]
#[derive(Debug, Deserialize)]
struct ValidationEnvironmentPayload {
    operating_system: String,
    #[serde(default)]
    operating_system_version: Option<String>,
    #[serde(default)]
    operating_system_build: Option<String>,
    #[serde(default)]
    file_manager: Option<String>,
    #[serde(default)]
    host_name: Option<String>,
    #[serde(default)]
    architecture: Option<String>,
    #[serde(default)]
    captured_at_utc: Option<String>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum EvidenceSectionStatus {
    Pass,
    Fail,
    NotCaptured,
}

impl EvidenceSectionStatus {
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

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ValidationEvidenceSection {
    pub title: &'static str,
    pub status: EvidenceSectionStatus,
    pub checklist_items: &'static [&'static str],
    pub details: Vec<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WindowsValidationEvidenceReport {
    pub target: &'static str,
    pub reference_surface: &'static str,
    pub environment: ValidationHostEnvironment,
    pub provenance: ValidationCaptureProvenance,
    pub sections: Vec<ValidationEvidenceSection>,
}

impl WindowsValidationEvidenceReport {
    pub fn is_ready_to_close_all_mapped_items(&self) -> bool {
        self.sections.iter().all(|section| section.status.is_pass())
    }

    pub fn checklist_items_ready_for_closure(&self) -> Vec<&'static str> {
        let mut checklist_items = BTreeSet::new();
        for section in &self.sections {
            if section.status.is_pass() {
                checklist_items.extend(section.checklist_items.iter().copied());
            }
        }

        checklist_items.into_iter().collect()
    }

    pub fn checklist_items_still_blocked(&self) -> Vec<&'static str> {
        let mut checklist_items = BTreeSet::new();
        for section in &self.sections {
            if !section.status.is_pass() {
                checklist_items.extend(section.checklist_items.iter().copied());
            }
        }

        checklist_items.into_iter().collect()
    }

    pub fn to_markdown(&self) -> String {
        let ready_items = self.checklist_items_ready_for_closure();
        let blocked_items = self.checklist_items_still_blocked();
        let mut lines = vec![
            "# Windows 11 Explorer Validation Evidence Report".to_string(),
            String::new(),
            format!("- Target: `{}`", self.target),
            format!("- Reference surface: `{}`", self.reference_surface),
            format!(
                "- Platform id: `{}`",
                platform_id_label(self.environment.platform_id)
            ),
            format!("- Live host target: `{}`", self.environment.target_label()),
            format!(
                "- Captured at (UTC): `{}`",
                option_label(self.environment.captured_at_utc.as_deref())
            ),
            format!(
                "- Host machine: `{}`",
                option_label(self.environment.host_name.as_deref())
            ),
            format!(
                "- Host architecture: `{}`",
                option_label(self.environment.architecture.as_deref())
            ),
            format!("- Evidence provenance: `{}`", self.provenance.label()),
            format!(
                "- Layer 6 closure readiness: `{}`",
                if self.is_ready_to_close_all_mapped_items() {
                    "ready-to-close"
                } else {
                    "not-ready-to-close"
                }
            ),
            format!(
                "- Checklist items ready for closure: `{}`",
                ready_items.len()
            ),
            format!("- Checklist items still blocked: `{}`", blocked_items.len()),
            String::new(),
        ];

        for checklist_item in ready_items {
            lines.push(format!("- Ready checklist item: {checklist_item}"));
        }
        for checklist_item in blocked_items {
            lines.push(format!("- Blocked checklist item: {checklist_item}"));
        }
        if !self.sections.is_empty() {
            lines.push(String::new());
        }

        for section in &self.sections {
            lines.push(format!("## {}", section.title));
            lines.push(String::new());
            lines.push(format!("- Status: `{}`", section.status.label()));
            for checklist_item in section.checklist_items {
                lines.push(format!("- Checklist item: {checklist_item}"));
            }
            for detail in &section.details {
                lines.push(format!("- {detail}"));
            }
            lines.push(String::new());
        }

        lines.join("\n")
    }
}

pub fn build_windows_validation_evidence_report(
    environment: ValidationHostEnvironment,
    provenance: ValidationCaptureProvenance,
    frontmost: &FrontmostSurfaceProbe,
    hover: Option<&HoveredItemProbeOutcome>,
    translation: &WindowsCoordinateTranslation,
) -> WindowsValidationEvidenceReport {
    let frontmost_section = build_frontmost_section(&environment, provenance, frontmost);
    let hover_section = build_hover_section(&environment, provenance, frontmost, hover);
    let coordinate_section = build_coordinate_section(&environment, provenance, translation);
    let feature_coverage_section =
        build_feature_coverage_section(&frontmost_section, &hover_section, &coordinate_section);

    WindowsValidationEvidenceReport {
        target: WINDOWS_VALIDATION_REPORT_TARGET,
        reference_surface: MACOS_REFERENCE_BEHAVIOR.reference_surface,
        environment,
        provenance,
        sections: vec![
            frontmost_section,
            hover_section,
            coordinate_section,
            feature_coverage_section,
        ],
    }
}

#[cfg(target_os = "windows")]
pub fn capture_live_windows_validation_evidence_report(
) -> Result<WindowsValidationEvidenceReport, AdapterError> {
    let adapter = ExplorerAdapter::new();
    let environment = probe_windows_validation_environment().map_err(|message| {
        AdapterError::HostProbeFailed {
            api: crate::HostApi::ValidationEvidenceCapture,
            parity_requirement:
                "Windows validation evidence capture requires explicit live host metadata",
            message,
        }
    })?;
    let translation = adapter.translate_coordinates(ScreenPoint::new(0.0, 0.0))?;
    let frontmost = adapter.probe_frontmost_surface()?;
    let hover = match frontmost.detected_surface.as_ref() {
        Some(surface) => Some(adapter.resolve_hovered_item(surface, translation.cursor.clone())?),
        None => None,
    };

    Ok(build_windows_validation_evidence_report(
        environment,
        ValidationCaptureProvenance::RealHostSession,
        &frontmost,
        hover.as_ref(),
        &translation,
    ))
}

fn build_frontmost_section(
    environment: &ValidationHostEnvironment,
    provenance: ValidationCaptureProvenance,
    frontmost: &FrontmostSurfaceProbe,
) -> ValidationEvidenceSection {
    let mut details = vec![
        format!(
            "Observed app identifier: `{}`",
            frontmost.observed_surface.app_identifier
        ),
        format!(
            "Observed surface kind: `{}`",
            front_surface_kind_label(frontmost.observed_surface.surface_kind)
        ),
    ];

    if let Some(window_title) = frontmost.observed_surface.window_title.as_deref() {
        details.push(format!("Window title: `{window_title}`"));
    }

    if let Some(directory) = frontmost.observed_surface.directory.as_ref() {
        details.push(format!("Explorer directory: `{}`", directory.as_str()));
    }

    if let Some(identity) = frontmost.observed_surface.stable_identity() {
        details.push(format!(
            "Stable Explorer surface identity: `{}`",
            identity.native_window_id
        ));
    }

    if let Some(detected_surface) = frontmost.detected_surface.as_ref() {
        details.push(format!(
            "Classifier accepted Explorer surface: `{}`",
            detected_surface.is_expected_host()
        ));
    }

    if let Some(rejection) = frontmost.rejection.as_ref() {
        details.push(format!("Classifier rejection: {rejection}"));
    }

    details.push(frontmost.notes.to_string());
    append_target_mismatch_note(&mut details, environment);
    append_non_live_capture_note(&mut details, provenance);

    ValidationEvidenceSection {
        title: "Frontmost Explorer Detection",
        status: evidence_status_for_probe(environment, provenance, frontmost.allowed),
        checklist_items: &FRONTMOST_CHECKLIST_ITEMS,
        details,
    }
}

fn build_hover_section(
    environment: &ValidationHostEnvironment,
    provenance: ValidationCaptureProvenance,
    frontmost: &FrontmostSurfaceProbe,
    hover: Option<&HoveredItemProbeOutcome>,
) -> ValidationEvidenceSection {
    let Some(hover) = hover else {
        let mut details = vec![
            if frontmost.allowed {
                "Hover evidence was not captured even though Explorer was accepted as the frontmost surface.".to_string()
            } else {
                "Hover evidence was not captured because the current frontmost surface was not accepted as Explorer.".to_string()
            },
            "Run this capture again with Explorer frontmost and the pointer resting on a local `.md` item.".to_string(),
        ];
        append_target_mismatch_note(&mut details, environment);
        append_non_live_capture_note(&mut details, provenance);

        return ValidationEvidenceSection {
            title: "Exact Hovered-Item Resolution",
            status: EvidenceSectionStatus::NotCaptured,
            checklist_items: &HOVER_CHECKLIST_ITEMS,
            details,
        };
    };

    let mut details = vec![
        format!(
            "Resolution scope: `{}`",
            hover_scope_label(hover.snapshot.resolution_scope)
        ),
        format!(
            "Presentation mode: `{}`",
            hover.snapshot.presentation_mode.label()
        ),
        format!("Backend: `{}`", hover.snapshot.backend),
    ];

    if let Some(view_mode) = hover.snapshot.explorer_view_mode {
        details.push(format!(
            "Explorer view mode: `{} ({})`",
            view_mode.label(),
            view_mode.code()
        ));
    }

    if let Some(element_name) = hover.snapshot.element_name.as_deref() {
        details.push(format!(
            "Resolved UI Automation element name: `{element_name}`"
        ));
    }

    if let Some(shell_window_id) = hover.snapshot.shell_window_id.as_deref() {
        details.push(format!("Matched Explorer shell HWND: `{shell_window_id}`"));
    }

    if let Some(accepted) = hover.accepted.as_ref() {
        details.push(format!(
            "Accepted Markdown path: `{}`",
            accepted.path().display()
        ));
        details.push(format!("Accepted source: `{:?}`", accepted.source()));
        details.push(
            "The shared Windows Markdown filter accepted the live Explorer path, which means the path was absolute, existed at probe time, resolved to a regular file, and ended in `.md`.".to_string(),
        );
    }

    if let Some(rejection) = hover.rejection.as_ref() {
        details.push(format!("Parity-gate rejection: {rejection}"));
    }

    details.push(hover.notes.to_string());
    append_target_mismatch_note(&mut details, environment);
    append_non_live_capture_note(&mut details, provenance);

    ValidationEvidenceSection {
        title: "Exact Hovered-Item Resolution",
        status: evidence_status_for_probe(
            environment,
            provenance,
            hover.accepted.is_some() && hover.rejection.is_none(),
        ),
        checklist_items: &HOVER_CHECKLIST_ITEMS,
        details,
    }
}

fn build_coordinate_section(
    environment: &ValidationHostEnvironment,
    provenance: ValidationCaptureProvenance,
    translation: &WindowsCoordinateTranslation,
) -> ValidationEvidenceSection {
    let assessment = assess_coordinate_translation(translation);
    let selected_monitor_name = translation
        .selected_monitor
        .name
        .as_deref()
        .unwrap_or(translation.selected_monitor.id.as_str());

    let mut details = vec![
        format!(
            "Cursor in shared desktop space: `{}`",
            format_point(&translation.cursor)
        ),
        format!("Translated monitor count: `{}`", translation.monitors.len()),
        format!("Selected monitor: `{}`", selected_monitor_name),
        format!("Selection mode: `{}`", assessment.selection_mode_label),
        format!(
            "Selected monitor frame: `{}`",
            format_rect(&translation.selected_monitor.frame)
        ),
        format!(
            "Selected monitor visible frame: `{}`",
            format_rect(&translation.selected_monitor.visible_frame)
        ),
        format!(
            "Selected monitor matches shared-core placement rule: `{}`",
            assessment.matches_shared_core_selection
        ),
        format!(
            "All monitor frames are non-empty: `{}`",
            assessment.all_monitors_have_positive_area
        ),
        format!(
            "All visible frames stay within their enclosing monitor frame: `{}`",
            assessment.all_visible_frames_within_bounds
        ),
        translation.notes.to_string(),
    ];
    if let Some(expected_monitor_name) = assessment.expected_monitor_name.as_deref() {
        details.push(format!(
            "Shared-core expected monitor: `{}`",
            expected_monitor_name
        ));
    } else {
        details.push("Shared-core expected monitor: `unavailable`".to_string());
    }
    if let Some(expected_selection_mode) = assessment.expected_selection_mode_label.as_deref() {
        details.push(format!(
            "Shared-core expected selection mode: `{}`",
            expected_selection_mode
        ));
    }
    for reason in &assessment.failure_reasons {
        details.push(reason.clone());
    }
    for monitor in &translation.monitors {
        let monitor_name = monitor.name.as_deref().unwrap_or(monitor.id.as_str());
        details.push(format!(
            "Monitor `{monitor_name}`: frame `{}`, visible frame `{}`, primary `{}`",
            format_rect(&monitor.frame),
            format_rect(&monitor.visible_frame),
            monitor.is_primary
        ));
    }
    append_target_mismatch_note(&mut details, environment);
    append_non_live_capture_note(&mut details, provenance);

    ValidationEvidenceSection {
        title: "Multi-Monitor Coordinate Handling",
        status: evidence_status_for_probe(
            environment,
            provenance,
            assessment.is_parity_compliant(),
        ),
        checklist_items: &COORDINATE_CHECKLIST_ITEMS,
        details,
    }
}

fn build_feature_coverage_section(
    frontmost_section: &ValidationEvidenceSection,
    hover_section: &ValidationEvidenceSection,
    coordinate_section: &ValidationEvidenceSection,
) -> ValidationEvidenceSection {
    let prerequisite_sections = [frontmost_section, hover_section, coordinate_section];
    let coverage_records = windows_preview_loop_feature_coverage_records();
    let covered_features = preview_feature_coverage_from_records(&coverage_records);
    let matches_reference = preview_feature_coverage_records_match_reference(&[&coverage_records]);
    let requirement_statuses =
        real_host_requirement_statuses(frontmost_section, hover_section, coordinate_section);
    let feature_statuses =
        preview_feature_validation_statuses(&[&coverage_records], &requirement_statuses);
    let ready_feature_count = feature_statuses
        .iter()
        .filter(|status| status.is_ready_for_closure())
        .count();
    let blocking_sections: Vec<_> = prerequisite_sections
        .iter()
        .filter(|section| !section.status.is_pass())
        .map(|section| format!("{} ({})", section.title, section.status.label()))
        .collect();

    let mut details = vec![format!(
        "Automated preview-loop parity coverage: `{}/{}` macOS reference features.",
        covered_features.len(),
        macos_preview_feature_list().len()
    )];
    let real_host_requirements =
        preview_feature_real_host_evidence_requirements(macos_preview_feature_list());
    details.push(format!(
        "Real-host evidence requirements referenced by the macOS feature list: `{}`.",
        real_host_requirement_label_list(&real_host_requirements)
    ));
    details.push(format!(
        "Reference features ready for Layer 6 evidence closure: `{}/{}`.",
        ready_feature_count,
        feature_statuses.len()
    ));
    details.push(format!(
        "Reference features still blocked by automated or live-host evidence: `{}`.",
        feature_statuses.len().saturating_sub(ready_feature_count)
    ));

    if matches_reference {
        details.push(
            "Shared contracts, shared core, shared render, and the Windows preview loop cover the full macOS reference feature list in automated validation.".to_string(),
        );
    } else {
        let missing = preview_feature_coverage_record_gaps_against_reference(&[&coverage_records]);
        details.push(format!(
            "Missing automated feature coverage: {}.",
            feature_label_list(&missing)
        ));
    }

    if matches_reference && blocking_sections.is_empty() {
        details.push(
            "All real-machine evidence sections passed, so the remaining Windows parity-evidence checklist item is ready for review without relying on automated coverage alone.".to_string(),
        );
    } else if matches_reference {
        details.push(format!(
            "Automated coverage matches the macOS reference list, but the parity-evidence checklist item stays blocked until these real-machine sections pass: {}.",
            blocking_sections.join("; ")
        ));
    }

    for feature_status in &feature_statuses {
        let real_host_requirements = feature_status.real_host_requirements.as_slice();
        details.push(format!(
            "Reference feature `{}`: automated lanes `{}`; automated status `{}`; parity readiness `{}`; real-host evidence `{}`",
            feature_status.feature.blueprint_label(),
            coverage_lane_label_list(&feature_status.automated_lanes),
            feature_status.automated_status_label(),
            feature_status.parity_readiness_label(),
            real_host_requirement_status_label_list(
                real_host_requirements,
                frontmost_section,
                hover_section,
                coordinate_section,
            ),
        ));
        if !feature_status.blocking_real_host_requirements.is_empty() {
            details.push(format!(
                "Reference feature `{}` blockers: `{}`",
                feature_status.feature.blueprint_label(),
                real_host_requirement_label_list(&feature_status.blocking_real_host_requirements),
            ));
        }
    }

    ValidationEvidenceSection {
        title: "Automated macOS-Parity Feature Coverage",
        status: if !matches_reference {
            EvidenceSectionStatus::Fail
        } else if blocking_sections.is_empty() {
            EvidenceSectionStatus::Pass
        } else {
            EvidenceSectionStatus::NotCaptured
        },
        checklist_items: &PARITY_CHECKLIST_ITEMS,
        details,
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct CoordinateEvidenceAssessment {
    selection_mode_label: &'static str,
    expected_selection_mode_label: Option<&'static str>,
    expected_monitor_name: Option<String>,
    matches_shared_core_selection: bool,
    all_monitors_have_positive_area: bool,
    all_visible_frames_within_bounds: bool,
    failure_reasons: Vec<String>,
}

impl CoordinateEvidenceAssessment {
    fn is_parity_compliant(&self) -> bool {
        self.matches_shared_core_selection
            && self.all_monitors_have_positive_area
            && self.all_visible_frames_within_bounds
    }
}

fn assess_coordinate_translation(
    translation: &WindowsCoordinateTranslation,
) -> CoordinateEvidenceAssessment {
    let expected_monitor = select_monitor_for_anchor(&translation.monitors, &translation.cursor);
    let matches_shared_core_selection = selected_monitor_matches_reference(
        &translation.monitors,
        &translation.cursor,
        &translation.selected_monitor,
    );
    let all_monitors_have_positive_area = translation
        .monitors
        .iter()
        .all(|monitor| monitor.has_positive_frame_area());
    let all_visible_frames_within_bounds = translation
        .monitors
        .iter()
        .all(|monitor| monitor.visible_frame_within_frame());
    let mut failure_reasons = Vec::new();

    if !matches_shared_core_selection {
        match expected_monitor {
            Some(expected_monitor) => failure_reasons.push(format!(
                "Selected monitor `{}` does not match the shared-core expectation `{}` for cursor `{}`.",
                monitor_name(&translation.selected_monitor),
                monitor_name(expected_monitor),
                format_point(&translation.cursor),
            )),
            None => failure_reasons.push(
                "Shared-core monitor selection did not produce an expected monitor for the translated cursor."
                    .to_string(),
            ),
        }
    }

    for monitor in &translation.monitors {
        if !monitor.has_positive_frame_area() {
            failure_reasons.push(format!(
                "Monitor `{}` has a non-positive frame or visible frame, so the capture is not usable for placement validation.",
                monitor_name(monitor),
            ));
        }
        if !monitor.visible_frame_within_frame() {
            failure_reasons.push(format!(
                "Monitor `{}` exposes a visible frame outside its enclosing monitor frame, so the capture is not parity-compliant.",
                monitor_name(monitor),
            ));
        }
    }

    CoordinateEvidenceAssessment {
        selection_mode_label: monitor_selection_mode(
            &translation.selected_monitor,
            &translation.cursor,
        )
        .label(),
        expected_selection_mode_label: expected_monitor
            .map(|monitor| monitor_selection_mode(monitor, &translation.cursor).label()),
        expected_monitor_name: expected_monitor.map(|monitor| monitor_name(monitor).to_string()),
        matches_shared_core_selection,
        all_monitors_have_positive_area,
        all_visible_frames_within_bounds,
        failure_reasons,
    }
}

#[cfg(target_os = "windows")]
fn probe_windows_validation_environment() -> Result<ValidationHostEnvironment, String> {
    let mut child = Command::new("powershell.exe")
        .arg("-NoProfile")
        .arg("-NonInteractive")
        .arg("-Command")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| format!("failed to launch validation environment probe: {error}"))?;

    {
        let Some(mut stdin) = child.stdin.take() else {
            return Err(
                "PowerShell stdin was not available for the validation environment probe."
                    .to_string(),
            );
        };

        stdin
            .write_all(WINDOWS_VALIDATION_ENVIRONMENT_SCRIPT.as_bytes())
            .and_then(|_| stdin.flush())
            .map_err(|error| {
                format!("failed to write validation environment probe script: {error}")
            })?;
    }

    let output = child
        .wait_with_output()
        .map_err(|error| format!("failed to wait for validation environment probe: {error}"))?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(if stderr.is_empty() {
            format!(
                "validation environment probe exited with status {:?} without stderr output",
                output.status.code()
            )
        } else {
            format!(
                "validation environment probe exited with status {:?}: {stderr}",
                output.status.code()
            )
        });
    }

    parse_windows_validation_environment(&String::from_utf8_lossy(&output.stdout))
}

#[cfg(target_os = "windows")]
fn parse_windows_validation_environment(
    raw_output: &str,
) -> Result<ValidationHostEnvironment, String> {
    let trimmed_output = raw_output.trim().trim_start_matches('\u{feff}').trim();
    if trimmed_output.is_empty() {
        return Err("validation environment probe returned no JSON output".to_string());
    }

    let payload: ValidationEnvironmentPayload = serde_json::from_str(trimmed_output)
        .map_err(|error| format!("validation environment probe returned invalid JSON: {error}"))?;

    let operating_system = payload.operating_system.trim();
    if operating_system.is_empty() {
        return Err(
            "validation environment probe did not include an operating system name".to_string(),
        );
    }

    Ok(ValidationHostEnvironment {
        platform_id: PlatformId::WindowsExplorer,
        operating_system: operating_system.to_string(),
        operating_system_version: normalize_optional_string(payload.operating_system_version),
        operating_system_build: normalize_optional_string(payload.operating_system_build),
        file_manager: normalize_optional_string(payload.file_manager)
            .or_else(|| Some("Explorer".to_string())),
        host_name: normalize_optional_string(payload.host_name),
        architecture: normalize_optional_string(payload.architecture),
        captured_at_utc: normalize_optional_string(payload.captured_at_utc),
    })
}

fn hover_scope_label(scope: fastmd_contracts::HoverResolutionScope) -> &'static str {
    match scope {
        fastmd_contracts::HoverResolutionScope::ExactItemUnderPointer => "exact-item-under-pointer",
        fastmd_contracts::HoverResolutionScope::HoveredRowDescendant => "hovered-row-descendant",
        fastmd_contracts::HoverResolutionScope::NearbyCandidate => "nearby-candidate",
        fastmd_contracts::HoverResolutionScope::FirstVisibleItem => "first-visible-item",
    }
}

fn front_surface_kind_label(kind: fastmd_contracts::FrontSurfaceKind) -> &'static str {
    match kind {
        fastmd_contracts::FrontSurfaceKind::FinderListView => "finder-list-view",
        fastmd_contracts::FrontSurfaceKind::ExplorerListView => "explorer-list-view",
        fastmd_contracts::FrontSurfaceKind::GnomeFilesListView => "gnome-files-list-view",
        fastmd_contracts::FrontSurfaceKind::Other => "other",
    }
}

fn platform_id_label(platform_id: PlatformId) -> &'static str {
    match platform_id {
        PlatformId::MacosFinder => "macos-finder",
        PlatformId::WindowsExplorer => "windows-explorer",
        PlatformId::UbuntuGnomeFiles => "ubuntu-gnome-files",
    }
}

fn format_point(point: &ScreenPoint) -> String {
    format!("x={:.1}, y={:.1}", point.x, point.y)
}

fn format_rect(rect: &fastmd_contracts::ScreenRect) -> String {
    format!(
        "x={:.1}, y={:.1}, width={:.1}, height={:.1}",
        rect.x, rect.y, rect.width, rect.height
    )
}

fn monitor_name(monitor: &fastmd_contracts::MonitorMetadata) -> &str {
    monitor.name.as_deref().unwrap_or(monitor.id.as_str())
}

fn feature_label_list(features: &[MacOsPreviewFeature]) -> String {
    features
        .iter()
        .map(|feature| feature.blueprint_label())
        .collect::<Vec<_>>()
        .join("; ")
}

fn coverage_lane_label_list(lanes: &[PreviewFeatureCoverageLane]) -> String {
    if lanes.is_empty() {
        return "none".to_string();
    }

    lanes
        .iter()
        .map(|lane| lane.label())
        .collect::<Vec<_>>()
        .join(", ")
}

fn real_host_requirement_label_list(requirements: &[RealHostEvidenceRequirement]) -> String {
    if requirements.is_empty() {
        return "none".to_string();
    }

    requirements
        .iter()
        .map(|requirement| requirement.label())
        .collect::<Vec<_>>()
        .join(", ")
}

fn real_host_requirement_status_label_list(
    requirements: &[RealHostEvidenceRequirement],
    frontmost_section: &ValidationEvidenceSection,
    hover_section: &ValidationEvidenceSection,
    coordinate_section: &ValidationEvidenceSection,
) -> String {
    if requirements.is_empty() {
        return "not required beyond automated parity coverage".to_string();
    }

    requirements
        .iter()
        .map(|requirement| {
            format!(
                "{} ({})",
                requirement.label(),
                real_host_requirement_status(
                    *requirement,
                    frontmost_section,
                    hover_section,
                    coordinate_section,
                )
                .label(),
            )
        })
        .collect::<Vec<_>>()
        .join(", ")
}

fn real_host_requirement_status(
    requirement: RealHostEvidenceRequirement,
    frontmost_section: &ValidationEvidenceSection,
    hover_section: &ValidationEvidenceSection,
    coordinate_section: &ValidationEvidenceSection,
) -> ValidationRequirementStatus {
    match requirement {
        RealHostEvidenceRequirement::FrontmostFileManagerDetection => {
            validation_requirement_status(frontmost_section.status)
        }
        RealHostEvidenceRequirement::ExactHoveredMarkdownResolution => {
            validation_requirement_status(hover_section.status)
        }
        RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation => {
            validation_requirement_status(coordinate_section.status)
        }
    }
}

fn real_host_requirement_statuses(
    frontmost_section: &ValidationEvidenceSection,
    hover_section: &ValidationEvidenceSection,
    coordinate_section: &ValidationEvidenceSection,
) -> [(RealHostEvidenceRequirement, ValidationRequirementStatus); 3] {
    [
        (
            RealHostEvidenceRequirement::FrontmostFileManagerDetection,
            validation_requirement_status(frontmost_section.status),
        ),
        (
            RealHostEvidenceRequirement::ExactHoveredMarkdownResolution,
            validation_requirement_status(hover_section.status),
        ),
        (
            RealHostEvidenceRequirement::MonitorSelectionAndCoordinateTranslation,
            validation_requirement_status(coordinate_section.status),
        ),
    ]
}

fn validation_requirement_status(status: EvidenceSectionStatus) -> ValidationRequirementStatus {
    match status {
        EvidenceSectionStatus::Pass => ValidationRequirementStatus::Pass,
        EvidenceSectionStatus::Fail => ValidationRequirementStatus::Fail,
        EvidenceSectionStatus::NotCaptured => ValidationRequirementStatus::NotCaptured,
    }
}

#[cfg(target_os = "windows")]
fn normalize_optional_string(value: Option<String>) -> Option<String> {
    value.and_then(|value| {
        let trimmed = value.trim();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed.to_string())
        }
    })
}

fn option_label(value: Option<&str>) -> &str {
    value
        .filter(|value| !value.trim().is_empty())
        .unwrap_or("unknown")
}

fn environment_matches_windows_target(environment: &ValidationHostEnvironment) -> bool {
    environment.matches_target(
        PlatformId::WindowsExplorer,
        WINDOWS_VALIDATION_REQUIRED_OPERATING_SYSTEM,
        Some(WINDOWS_VALIDATION_REQUIRED_FILE_MANAGER),
    )
}

fn evidence_status_for_probe(
    environment: &ValidationHostEnvironment,
    provenance: ValidationCaptureProvenance,
    pass_condition: bool,
) -> EvidenceSectionStatus {
    if !provenance.satisfies_real_machine_evidence() {
        EvidenceSectionStatus::NotCaptured
    } else if !environment_matches_windows_target(environment) {
        EvidenceSectionStatus::Fail
    } else if pass_condition {
        EvidenceSectionStatus::Pass
    } else {
        EvidenceSectionStatus::Fail
    }
}

fn append_target_mismatch_note(details: &mut Vec<String>, environment: &ValidationHostEnvironment) {
    if environment_matches_windows_target(environment) {
        return;
    }

    details.push(format!(
        "Captured host environment `{}` on platform `{}` does not satisfy the Layer 6 target `{}`.",
        environment.target_label(),
        platform_id_label(environment.platform_id),
        WINDOWS_VALIDATION_REPORT_TARGET,
    ));
}

fn append_non_live_capture_note(
    details: &mut Vec<String>,
    provenance: ValidationCaptureProvenance,
) {
    if provenance.satisfies_real_machine_evidence() {
        return;
    }

    details.push(format!(
        "Capture provenance `{}` does not satisfy the blueprint requirement for evidence gathered on a real Windows 11 machine with Explorer frontmost, so this section remains `not-captured` even if the probe data looks parity-compliant.",
        provenance.label()
    ));
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use fastmd_contracts::{
        FrontSurfaceKind, HoverResolutionScope, MonitorMetadata, PlatformId, ScreenPoint,
        ScreenRect, ValidationCaptureProvenance, ValidationHostEnvironment,
    };

    use super::{
        build_windows_validation_evidence_report, EvidenceSectionStatus,
        WindowsValidationEvidenceReport,
    };
    use crate::{
        ExplorerAdapter, FrontmostWindowSnapshot, HoverCandidate, HoverCandidateSource,
        HoveredExplorerItemSnapshot, WindowsCoordinateTranslation, WINDOWS_COORDINATE_API_STACK,
    };

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
                "fastmd-platform-windows-evidence-{nonce}-{}",
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

    fn sample_translation() -> WindowsCoordinateTranslation {
        let selected_monitor = MonitorMetadata {
            id: String::from(r"\\.\DISPLAY1"),
            name: Some(String::from("Primary monitor")),
            frame: ScreenRect::new(0.0, 0.0, 1920.0, 1080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1920.0, 1040.0),
            scale_factor: 1.0,
            is_primary: true,
        };

        WindowsCoordinateTranslation {
            cursor: ScreenPoint::new(420.0, 420.0),
            monitors: vec![selected_monitor.clone()],
            selected_monitor,
            api_stack: &WINDOWS_COORDINATE_API_STACK,
            notes: "Windows monitor bounds and work areas are translated into the shared desktop-space model, then the containing visible frame is preferred before falling back to the nearest visible frame.",
        }
    }

    fn sample_environment() -> ValidationHostEnvironment {
        ValidationHostEnvironment {
            platform_id: PlatformId::WindowsExplorer,
            operating_system: "Windows 11 Pro".to_string(),
            operating_system_version: Some("24H2".to_string()),
            operating_system_build: Some("26100".to_string()),
            file_manager: Some("Explorer".to_string()),
            host_name: Some("FASTMD-WIN11".to_string()),
            architecture: Some("64-bit".to_string()),
            captured_at_utc: Some("2026-04-08T09:14:00Z".to_string()),
        }
    }

    fn parity_compliant_report(
        provenance: ValidationCaptureProvenance,
    ) -> WindowsValidationEvidenceReport {
        let fixture = TempFixture::new();
        let markdown_path = fixture.write_file("hovered.md", "# hovered\n");
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10001",
                4242,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_window_title("Docs")
            .with_directory(r"C:\Users\alice\Docs")
            .with_shell_window_id("hwnd:0x10001"),
        );
        let hover = adapter.classify_hovered_item(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: markdown_path,
                source: HoverCandidateSource::ValidationFixture,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            presentation_mode: fastmd_contracts::HoveredPresentationMode::NonList,
            backend: "uiautomation-element-from-point+shell-parse-name".to_string(),
            element_name: Some("hovered.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
            explorer_view_mode: Some(crate::hover::WindowsExplorerViewMode::Tile),
        });

        build_windows_validation_evidence_report(
            sample_environment(),
            provenance,
            &frontmost,
            Some(&hover),
            &sample_translation(),
        )
    }

    fn translation_with_mismatched_selected_monitor() -> WindowsCoordinateTranslation {
        let left = MonitorMetadata {
            id: String::from(r"\\.\DISPLAY_LEFT"),
            name: Some(String::from("Left monitor")),
            frame: ScreenRect::new(-1920.0, 0.0, 1920.0, 1080.0),
            visible_frame: ScreenRect::new(-1920.0, 40.0, 1920.0, 1040.0),
            scale_factor: 1.0,
            is_primary: false,
        };
        let right = MonitorMetadata {
            id: String::from(r"\\.\DISPLAY_RIGHT"),
            name: Some(String::from("Right monitor")),
            frame: ScreenRect::new(0.0, 0.0, 1920.0, 1080.0),
            visible_frame: ScreenRect::new(0.0, 40.0, 1920.0, 1040.0),
            scale_factor: 1.0,
            is_primary: true,
        };

        WindowsCoordinateTranslation {
            cursor: ScreenPoint::new(-240.0, 640.0),
            monitors: vec![left, right.clone()],
            selected_monitor: right,
            api_stack: &WINDOWS_COORDINATE_API_STACK,
            notes: "Windows monitor bounds and work areas are translated into the shared desktop-space model, then the containing visible frame is preferred before falling back to the nearest visible frame.",
        }
    }

    #[test]
    fn report_keeps_real_machine_sections_blocked_for_validation_fixtures() {
        let report = parity_compliant_report(ValidationCaptureProvenance::ValidationFixture);

        assert_eq!(report.sections.len(), 4);
        assert_eq!(
            report.sections[0].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert_eq!(
            report.sections[1].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert_eq!(
            report.sections[2].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Fail);
    }

    #[test]
    fn report_keeps_parity_section_failed_while_automated_feature_gaps_remain() {
        let report = parity_compliant_report(ValidationCaptureProvenance::RealHostSession);

        assert_eq!(report.sections.len(), 4);
        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[1].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[2].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Fail);
        assert!(report
            .to_markdown()
            .contains("Missing automated feature coverage:"));
    }

    #[test]
    fn report_fails_real_machine_sections_when_host_target_is_not_windows_11_explorer() {
        let fixture = TempFixture::new();
        let markdown_path = fixture.write_file("hovered.md", "# hovered\n");
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10001",
                4242,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_window_title("Docs")
            .with_directory(r"C:\Users\alice\Docs")
            .with_shell_window_id("hwnd:0x10001"),
        );
        let hover = adapter.classify_hovered_item(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: markdown_path,
                source: HoverCandidateSource::ValidationFixture,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            presentation_mode: fastmd_contracts::HoveredPresentationMode::NonList,
            backend: "uiautomation-element-from-point+shell-parse-name".to_string(),
            element_name: Some("hovered.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
            explorer_view_mode: Some(crate::hover::WindowsExplorerViewMode::Tile),
        });
        let mut environment = sample_environment();
        environment.operating_system = "Windows 10 Pro".to_string();

        let report = build_windows_validation_evidence_report(
            environment,
            ValidationCaptureProvenance::RealHostSession,
            &frontmost,
            Some(&hover),
            &sample_translation(),
        );

        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Fail);
        assert_eq!(report.sections[1].status, EvidenceSectionStatus::Fail);
        assert_eq!(report.sections[2].status, EvidenceSectionStatus::Fail);
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Fail);
        assert!(report
            .to_markdown()
            .contains("does not satisfy the Layer 6 target `Windows 11 + Explorer only`."));
    }

    #[test]
    fn report_marks_hover_section_not_captured_when_explorer_is_not_frontmost() {
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(FrontmostWindowSnapshot::new(
            "hwnd:0x20002",
            999,
            r"C:\Windows\System32\notepad.exe",
            "Notepad",
        ));
        let report = build_windows_validation_evidence_report(
            sample_environment(),
            ValidationCaptureProvenance::RealHostSession,
            &frontmost,
            None,
            &sample_translation(),
        );

        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Fail);
        assert_eq!(
            report.sections[1].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Fail);
        assert!(report.to_markdown().contains(
            "Hover evidence was not captured because the current frontmost surface was not accepted as Explorer."
        ));
    }

    #[test]
    fn report_fails_coordinate_section_when_selected_monitor_does_not_match_shared_core_rule() {
        let fixture = TempFixture::new();
        let markdown_path = fixture.write_file("hovered.md", "# hovered\n");
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10001",
                4242,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_window_title("Docs")
            .with_directory(r"C:\Users\alice\Docs")
            .with_shell_window_id("hwnd:0x10001"),
        );
        let hover = adapter.classify_hovered_item(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: markdown_path,
                source: HoverCandidateSource::ValidationFixture,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            presentation_mode: fastmd_contracts::HoveredPresentationMode::NonList,
            backend: "uiautomation-element-from-point+shell-parse-name".to_string(),
            element_name: Some("hovered.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
            explorer_view_mode: Some(crate::hover::WindowsExplorerViewMode::Tile),
        });

        let report = build_windows_validation_evidence_report(
            sample_environment(),
            ValidationCaptureProvenance::RealHostSession,
            &frontmost,
            Some(&hover),
            &translation_with_mismatched_selected_monitor(),
        );

        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[1].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[2].status, EvidenceSectionStatus::Fail);
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Fail);
        assert!(report
            .to_markdown()
            .contains("Selected monitor matches shared-core placement rule: `false`"));
        assert!(report
            .to_markdown()
            .contains("does not match the shared-core expectation `Left monitor`"));
    }

    #[test]
    fn markdown_report_includes_real_machine_capture_command_outputs_and_feature_labels() {
        let report = parity_compliant_report(ValidationCaptureProvenance::RealHostSession);
        let markdown = report.to_markdown();

        assert!(markdown.contains("# Windows 11 Explorer Validation Evidence Report"));
        assert!(markdown.contains("## Frontmost Explorer Detection"));
        assert!(markdown.contains("## Exact Hovered-Item Resolution"));
        assert!(markdown.contains("## Multi-Monitor Coordinate Handling"));
        assert!(markdown.contains("## Automated macOS-Parity Feature Coverage"));
        assert!(markdown.contains("- Evidence provenance: `real-host-session`"));
        assert!(markdown.contains("- Platform id: `windows-explorer`"));
        assert!(
            markdown.contains("- Live host target: `Windows 11 Pro 24H2 (build 26100) + Explorer`")
        );
        assert!(markdown.contains("- Captured at (UTC): `2026-04-08T09:14:00Z`"));
        assert!(markdown.contains("- Host machine: `FASTMD-WIN11`"));
        assert!(markdown.contains("- Host architecture: `64-bit`"));
        assert!(markdown.contains("- Layer 6 closure readiness: `not-ready-to-close`"));
        assert!(markdown.contains(
            "- Ready checklist item: Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
        ));
        assert!(markdown.contains(
            "- Blocked checklist item: Record Windows-specific validation evidence proving one-to-one parity with macOS for each feature above"
        ));
        assert!(markdown.contains(
            "Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
        ));
        assert!(markdown.contains("Open preview after a 1-second hover debounce"));
        assert!(markdown.contains(
            "Emit structured runtime diagnostics for host gating, hover resolution, placement, and edit lifecycle"
        ));
        assert!(markdown.contains(
            "Real-host evidence requirements referenced by the macOS feature list: `frontmost-file-manager-detection, exact-hovered-markdown-resolution, monitor-selection-and-coordinate-translation`."
        ));
        assert!(
            markdown.contains("Reference features ready for Layer 6 evidence closure: `20/21`.")
        );
        assert!(markdown
            .contains("Reference features still blocked by automated or live-host evidence: `1`."));
        assert!(markdown.contains(
            "Missing automated feature coverage: Allow the preview window to be dragged by its top chrome without breaking hover semantics."
        ));
        assert!(markdown.contains(
            "Reference feature `Open preview after a 1-second hover debounce`: automated lanes `shared-core`; automated status `covered`; parity readiness `ready`; real-host evidence `not required beyond automated parity coverage`"
        ));
        assert!(markdown.contains(
            "Reference feature `Preserve the macOS Markdown rendering surface, layout, and compact chrome copy`: automated lanes `shared-render`; automated status `covered`; parity readiness `ready`; real-host evidence `not required beyond automated parity coverage`"
        ));
        assert!(markdown.contains(
            "Reference feature `Allow the preview window to be dragged by its top chrome without breaking hover semantics`: automated lanes `none`; automated status `missing`; parity readiness `blocked`; real-host evidence `not required beyond automated parity coverage`"
        ));
        assert!(markdown.contains(
            "Reference feature `Resolve the actual hovered Markdown item instead of a nearby or first-visible candidate`: automated lanes `windows-adapter`; automated status `covered`; parity readiness `ready`; real-host evidence `exact-hovered-markdown-resolution (pass)`"
        ));
        assert!(markdown.contains(
            "Reference feature `Preserve the macOS four-tier width model of 560 / 960 / 1440 / 1920`: automated lanes `shared-core`; automated status `covered`; parity readiness `ready`; real-host evidence `monitor-selection-and-coordinate-translation (pass)`"
        ));
        assert!(markdown.contains("Accepted Markdown path: `"));
        assert!(markdown.contains("Presentation mode: `non-list`"));
        assert!(markdown.contains("Explorer view mode: `tile (6)`"));
        assert!(markdown.contains("Selection mode: `containing visible frame`"));
        assert!(markdown.contains("Selected monitor matches shared-core placement rule: `true`"));
        assert!(markdown.contains("Shared-core expected monitor: `Primary monitor`"));
        assert!(markdown.contains("Monitor `Primary monitor`: frame `x=0.0, y=0.0, width=1920.0, height=1080.0`, visible frame `x=0.0, y=40.0, width=1920.0, height=1040.0`, primary `true`"));
    }

    #[test]
    fn report_keeps_frontmost_surface_kind_human_readable() {
        let report = parity_compliant_report(ValidationCaptureProvenance::RealHostSession);

        assert!(report.sections[0]
            .details
            .iter()
            .any(|detail| detail == "Observed surface kind: `explorer-list-view`"));
        assert_ne!(FrontSurfaceKind::ExplorerListView, FrontSurfaceKind::Other);
    }

    #[test]
    fn parity_checklist_item_stays_blocked_until_real_machine_sections_pass() {
        let report = parity_compliant_report(ValidationCaptureProvenance::ValidationFixture);

        assert!(!report.is_ready_to_close_all_mapped_items());
        assert!(!report
            .checklist_items_ready_for_closure()
            .contains(
                &"Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
            ));
        assert!(report
            .checklist_items_still_blocked()
            .contains(
                &"Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
            ));
        assert!(report
            .to_markdown()
            .contains("- Layer 6 closure readiness: `not-ready-to-close`"));
        assert!(report
            .to_markdown()
            .contains("Reference features ready for Layer 6 evidence closure: `14/21`."));
        assert!(report.to_markdown().contains(
            "Reference feature `Allow the preview window to be dragged by its top chrome without breaking hover semantics`: automated lanes `none`; automated status `missing`; parity readiness `blocked`; real-host evidence `not required beyond automated parity coverage`"
        ));
        assert!(report.to_markdown().contains(
            "Reference feature `Preserve the macOS four-tier width model of 560 / 960 / 1440 / 1920`: automated lanes `shared-core`; automated status `covered`; parity readiness `blocked`; real-host evidence `monitor-selection-and-coordinate-translation (not-captured)`"
        ));
        assert!(report.to_markdown().contains(
            "Reference feature `Preserve the macOS four-tier width model of 560 / 960 / 1440 / 1920` blockers: `monitor-selection-and-coordinate-translation`"
        ));
        assert!(report.to_markdown().contains(
            "Capture provenance `validation-fixture` does not satisfy the blueprint requirement for evidence gathered on a real Windows 11 machine with Explorer frontmost, so this section remains `not-captured` even if the probe data looks parity-compliant."
        ));
    }

    #[test]
    fn parity_evidence_checklist_item_stays_blocked_until_real_host_sections_pass() {
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(FrontmostWindowSnapshot::new(
            "hwnd:0x20002",
            999,
            r"C:\Windows\System32\notepad.exe",
            "Notepad",
        ));
        let report = build_windows_validation_evidence_report(
            sample_environment(),
            ValidationCaptureProvenance::RealHostSession,
            &frontmost,
            None,
            &sample_translation(),
        );

        assert!(!report.is_ready_to_close_all_mapped_items());
        assert!(!report
            .checklist_items_ready_for_closure()
            .contains(
                &"Record Windows-specific validation evidence proving one-to-one parity with macOS for each feature above"
            ));
        assert!(report
            .checklist_items_still_blocked()
            .contains(
                &"Record Windows-specific validation evidence proving one-to-one parity with macOS for each feature above"
            ));
        assert!(report
            .to_markdown()
            .contains("- Layer 6 closure readiness: `not-ready-to-close`"));
        assert!(report
            .to_markdown()
            .contains("Reference features ready for Layer 6 evidence closure: `17/21`."));
        assert!(report.to_markdown().contains(
            "Missing automated feature coverage: Allow the preview window to be dragged by its top chrome without breaking hover semantics."
        ));
    }
}
