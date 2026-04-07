use std::collections::BTreeSet;

use fastmd_contracts::{
    macos_preview_feature_list, preview_feature_coverage_matches_reference, MacOsPreviewFeature,
    ScreenPoint,
};

use crate::{
    windows_preview_loop_feature_coverage, FrontmostSurfaceProbe, HoveredItemProbeOutcome,
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
    frontmost: &FrontmostSurfaceProbe,
    hover: Option<&HoveredItemProbeOutcome>,
    translation: &WindowsCoordinateTranslation,
) -> WindowsValidationEvidenceReport {
    let frontmost_section = build_frontmost_section(frontmost);
    let hover_section = build_hover_section(frontmost, hover);
    let coordinate_section = build_coordinate_section(translation);
    let feature_coverage_section =
        build_feature_coverage_section(&[&frontmost_section, &hover_section, &coordinate_section]);

    WindowsValidationEvidenceReport {
        target: WINDOWS_VALIDATION_REPORT_TARGET,
        reference_surface: MACOS_REFERENCE_BEHAVIOR.reference_surface,
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
    let translation = adapter.translate_coordinates(ScreenPoint::new(0.0, 0.0))?;
    let frontmost = adapter.probe_frontmost_surface()?;
    let hover = match frontmost.detected_surface.as_ref() {
        Some(surface) => Some(adapter.resolve_hovered_item(surface, translation.cursor.clone())?),
        None => None,
    };

    Ok(build_windows_validation_evidence_report(
        &frontmost,
        hover.as_ref(),
        &translation,
    ))
}

fn build_frontmost_section(frontmost: &FrontmostSurfaceProbe) -> ValidationEvidenceSection {
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

    ValidationEvidenceSection {
        title: "Frontmost Explorer Detection",
        status: if frontmost.allowed {
            EvidenceSectionStatus::Pass
        } else {
            EvidenceSectionStatus::Fail
        },
        checklist_items: &FRONTMOST_CHECKLIST_ITEMS,
        details,
    }
}

fn build_hover_section(
    frontmost: &FrontmostSurfaceProbe,
    hover: Option<&HoveredItemProbeOutcome>,
) -> ValidationEvidenceSection {
    let Some(hover) = hover else {
        return ValidationEvidenceSection {
            title: "Exact Hovered-Item Resolution",
            status: EvidenceSectionStatus::NotCaptured,
            checklist_items: &HOVER_CHECKLIST_ITEMS,
            details: vec![
                if frontmost.allowed {
                    "Hover evidence was not captured even though Explorer was accepted as the frontmost surface.".to_string()
                } else {
                    "Hover evidence was not captured because the current frontmost surface was not accepted as Explorer.".to_string()
                },
                "Run this capture again with Explorer frontmost and the pointer resting on a local `.md` item.".to_string(),
            ],
        };
    };

    let mut details = vec![
        format!(
            "Resolution scope: `{}`",
            hover_scope_label(hover.snapshot.resolution_scope)
        ),
        format!("Backend: `{}`", hover.snapshot.backend),
    ];

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

    ValidationEvidenceSection {
        title: "Exact Hovered-Item Resolution",
        status: if hover.accepted.is_some() && hover.rejection.is_none() {
            EvidenceSectionStatus::Pass
        } else {
            EvidenceSectionStatus::Fail
        },
        checklist_items: &HOVER_CHECKLIST_ITEMS,
        details,
    }
}

fn build_coordinate_section(
    translation: &WindowsCoordinateTranslation,
) -> ValidationEvidenceSection {
    let selection_mode = if translation
        .selected_monitor
        .contains_point_in_visible_frame(&translation.cursor)
    {
        "containing visible frame"
    } else {
        "nearest visible frame fallback"
    };
    let selected_monitor_name = translation
        .selected_monitor
        .name
        .as_deref()
        .unwrap_or(translation.selected_monitor.id.as_str());

    ValidationEvidenceSection {
        title: "Multi-Monitor Coordinate Handling",
        status: EvidenceSectionStatus::Pass,
        checklist_items: &COORDINATE_CHECKLIST_ITEMS,
        details: vec![
            format!(
                "Cursor in shared desktop space: `{}`",
                format_point(&translation.cursor)
            ),
            format!("Translated monitor count: `{}`", translation.monitors.len()),
            format!("Selected monitor: `{}`", selected_monitor_name),
            format!("Selection mode: `{selection_mode}`"),
            format!(
                "Selected monitor frame: `{}`",
                format_rect(&translation.selected_monitor.frame)
            ),
            format!(
                "Selected monitor visible frame: `{}`",
                format_rect(&translation.selected_monitor.visible_frame)
            ),
            translation.notes.to_string(),
        ],
    }
}

fn build_feature_coverage_section(
    prerequisite_sections: &[&ValidationEvidenceSection],
) -> ValidationEvidenceSection {
    let covered_features = windows_preview_loop_feature_coverage();
    let covered_set: BTreeSet<_> = covered_features.iter().copied().collect();
    let matches_reference =
        preview_feature_coverage_matches_reference(&[covered_features.as_slice()]);
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

    if matches_reference {
        details.push(
            "Shared contracts, shared core, shared render, and the Windows preview loop cover the full macOS reference feature list in automated validation.".to_string(),
        );
    } else {
        let missing: Vec<_> = macos_preview_feature_list()
            .iter()
            .copied()
            .filter(|feature| !covered_set.contains(feature))
            .collect();
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

    for feature in macos_preview_feature_list() {
        let status = if covered_set.contains(feature) {
            "covered"
        } else {
            "missing"
        };
        details.push(format!(
            "Reference feature `{}`: `{status}`",
            feature.blueprint_label()
        ));
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

fn format_point(point: &ScreenPoint) -> String {
    format!("x={:.1}, y={:.1}", point.x, point.y)
}

fn format_rect(rect: &fastmd_contracts::ScreenRect) -> String {
    format!(
        "x={:.1}, y={:.1}, width={:.1}, height={:.1}",
        rect.x, rect.y, rect.width, rect.height
    )
}

fn feature_label_list(features: &[MacOsPreviewFeature]) -> String {
    features
        .iter()
        .map(|feature| feature.blueprint_label())
        .collect::<Vec<_>>()
        .join("; ")
}

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use fastmd_contracts::{
        FrontSurfaceKind, HoverResolutionScope, MonitorMetadata, ScreenPoint, ScreenRect,
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

    fn accepted_report() -> WindowsValidationEvidenceReport {
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
            backend: "uiautomation-element-from-point+shell-parse-name".to_string(),
            element_name: Some("hovered.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
        });

        build_windows_validation_evidence_report(&frontmost, Some(&hover), &sample_translation())
    }

    #[test]
    fn report_marks_all_sections_pass_when_live_probe_inputs_are_parity_compliant() {
        let report = accepted_report();

        assert_eq!(report.sections.len(), 4);
        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[1].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[2].status, EvidenceSectionStatus::Pass);
        assert_eq!(report.sections[3].status, EvidenceSectionStatus::Pass);
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
        let report =
            build_windows_validation_evidence_report(&frontmost, None, &sample_translation());

        assert_eq!(report.sections[0].status, EvidenceSectionStatus::Fail);
        assert_eq!(
            report.sections[1].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert_eq!(
            report.sections[3].status,
            EvidenceSectionStatus::NotCaptured
        );
        assert!(report.to_markdown().contains(
            "Hover evidence was not captured because the current frontmost surface was not accepted as Explorer."
        ));
    }

    #[test]
    fn markdown_report_includes_real_machine_capture_command_outputs_and_feature_labels() {
        let report = accepted_report();
        let markdown = report.to_markdown();

        assert!(markdown.contains("# Windows 11 Explorer Validation Evidence Report"));
        assert!(markdown.contains("## Frontmost Explorer Detection"));
        assert!(markdown.contains("## Exact Hovered-Item Resolution"));
        assert!(markdown.contains("## Multi-Monitor Coordinate Handling"));
        assert!(markdown.contains("## Automated macOS-Parity Feature Coverage"));
        assert!(markdown.contains("- Layer 6 closure readiness: `ready-to-close`"));
        assert!(markdown.contains(
            "- Ready checklist item: Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
        ));
        assert!(markdown.contains(
            "Record validation evidence for frontmost Explorer detection on a real Windows 11 machine"
        ));
        assert!(markdown.contains("Open preview after a 1-second hover debounce"));
        assert!(markdown.contains(
            "Emit structured runtime diagnostics for host gating, hover resolution, placement, and edit lifecycle"
        ));
        assert!(markdown.contains("Accepted Markdown path: `"));
        assert!(markdown.contains("Selection mode: `containing visible frame`"));
    }

    #[test]
    fn report_keeps_frontmost_surface_kind_human_readable() {
        let report = accepted_report();

        assert!(report.sections[0]
            .details
            .iter()
            .any(|detail| detail == "Observed surface kind: `explorer-list-view`"));
        assert_ne!(FrontSurfaceKind::ExplorerListView, FrontSurfaceKind::Other);
    }

    #[test]
    fn parity_checklist_item_stays_blocked_until_real_machine_sections_pass() {
        let adapter = ExplorerAdapter::new();
        let frontmost = adapter.classify_frontmost_surface(FrontmostWindowSnapshot::new(
            "hwnd:0x20002",
            999,
            r"C:\Windows\System32\notepad.exe",
            "Notepad",
        ));
        let report =
            build_windows_validation_evidence_report(&frontmost, None, &sample_translation());

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
        assert!(report.to_markdown().contains(
            "Automated coverage matches the macOS reference list, but the parity-evidence checklist item stays blocked until these real-machine sections pass: Frontmost Explorer Detection (fail); Exact Hovered-Item Resolution (not-captured)."
        ));
    }
}
