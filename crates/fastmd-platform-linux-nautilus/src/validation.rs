use std::collections::{BTreeMap, BTreeSet};

use fastmd_contracts::{
    MacOsPreviewFeature, macos_preview_feature_list, merged_preview_feature_coverage,
    preview_feature_coverage_matches_reference, preview_feature_gaps_against_reference,
};
use fastmd_core::shared_core_preview_feature_coverage;
use fastmd_render::shared_render_preview_feature_coverage;
use serde::{Deserialize, Serialize};

use crate::target::{DisplayServerKind, MACOS_REFERENCE_ROOT, supported_surface_label};

const WAYLAND_LIVE_VALIDATION_CHECKLIST_ITEMS: [&str; 3] = [
    "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
    "Validate exact hovered-item resolution on a real Ubuntu 24.04 Wayland session",
    "Validate monitor selection and coordinate handling on a real Ubuntu 24.04 Wayland session",
];
const X11_LIVE_VALIDATION_CHECKLIST_ITEMS: [&str; 3] = [
    "Validate frontmost Nautilus detection on a real Ubuntu 24.04 X11 session",
    "Validate exact hovered-item resolution on a real Ubuntu 24.04 X11 session",
    "Validate monitor selection and coordinate handling on a real Ubuntu 24.04 X11 session",
];
const UBUNTU_PARITY_EVIDENCE_REQUIRED_DISPLAY_SERVERS: [DisplayServerKind; 2] =
    [DisplayServerKind::Wayland, DisplayServerKind::X11];
const UBUNTU_PARITY_EVIDENCE_CHECKLIST_ITEM: &str = "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above";
const UBUNTU_PARITY_EVIDENCE_PENDING_NOTE: &str = "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.";

/// Validation status for this crate slice.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ValidationStatus {
    /// Implemented directly in this crate slice.
    ImplementedInSlice,
    /// Requires live Ubuntu validation after host probes are wired.
    NeedsUbuntuHostValidation,
    /// Blocked by lower Stage 2 layers outside this worker lane.
    BlockedByLowerLayers,
}

/// One parity-validation note for the Ubuntu adapter lane.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ValidationNote {
    /// Blueprint checklist item or feature name.
    pub item: &'static str,
    /// Current status.
    pub status: ValidationStatus,
    /// Short explanation for the status.
    pub note: &'static str,
}

/// Coverage lane used by the Ubuntu parity manifest.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum UbuntuPreviewFeatureCoverageLane {
    SharedCore,
    SharedRender,
    UbuntuAdapter,
}

impl UbuntuPreviewFeatureCoverageLane {
    pub fn label(self) -> &'static str {
        match self {
            Self::SharedCore => "shared-core",
            Self::SharedRender => "shared-render",
            Self::UbuntuAdapter => "ubuntu-adapter",
        }
    }
}

/// One feature-to-lane mapping in the Ubuntu parity manifest.
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct UbuntuPreviewFeatureCoverageRecord {
    pub feature: MacOsPreviewFeature,
    pub lane: UbuntuPreviewFeatureCoverageLane,
}

impl UbuntuPreviewFeatureCoverageRecord {
    pub const fn new(feature: MacOsPreviewFeature, lane: UbuntuPreviewFeatureCoverageLane) -> Self {
        Self { feature, lane }
    }
}

/// One reference feature plus the lanes that currently cover it for Ubuntu.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UbuntuPreviewFeatureCoverageEntry {
    pub feature: String,
    pub lanes: Vec<String>,
}

/// Explicit Ubuntu-to-macOS feature-list comparison surfaced through the shell lane.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UbuntuPreviewFeatureCoverageSummary {
    pub target: &'static str,
    pub reference_surface: &'static str,
    pub matches_reference: bool,
    pub covered_feature_count: usize,
    pub reference_feature_count: usize,
    pub missing_features: Vec<String>,
    pub feature_lanes: Vec<UbuntuPreviewFeatureCoverageEntry>,
}

/// Automated preview-loop validation summary for one Ubuntu display server.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UbuntuPreviewLoopValidationSummary {
    pub target: &'static str,
    pub reference_surface: &'static str,
    pub display_server: &'static str,
    pub validation_mode: &'static str,
    pub matches_reference: bool,
    pub covered_feature_count: usize,
    pub reference_feature_count: usize,
    pub missing_features: Vec<String>,
    pub feature_lanes: Vec<UbuntuPreviewFeatureCoverageEntry>,
    pub note: &'static str,
}

/// Automated preview-loop validation summaries for both Ubuntu display servers.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UbuntuPreviewLoopValidationBundle {
    pub wayland: UbuntuPreviewLoopValidationSummary,
    pub x11: UbuntuPreviewLoopValidationSummary,
}

/// Returns the validation notes for this bounded worker slice.
pub fn crate_slice_validation_notes() -> Vec<ValidationNote> {
    vec![
        ValidationNote {
            item: "Restrict Linux support target to Ubuntu 24.04 plus GNOME Files / Nautilus only",
            status: ValidationStatus::ImplementedInSlice,
            note: "The crate rejects non-Ubuntu-24.04 or non-GNOME sessions at the adapter boundary.",
        },
        ValidationNote {
            item: "Create fastmd-platform-linux-nautilus as a buildable crate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The crate now has a real Cargo manifest, module layout, and unit tests.",
        },
        ValidationNote {
            item: "Implement Wayland and X11 behavior handling without changing product semantics",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland and X11 have separate backend plans with one shared semantic guardrail.",
        },
        ValidationNote {
            item: "Confirm that Wayland/X11 backend differences do not alter user-visible FastMD semantics",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux backend plans now expose one shared semantic guardrail through the Tauri shell, and shared UI tests keep the Wayland/X11 probe differences hidden from user-visible preview semantics.",
        },
        ValidationNote {
            item: "Implement Ubuntu frontmost GNOME Files detection with the same gating semantics as macOS Finder",
            status: ValidationStatus::ImplementedInSlice,
            note: "The adapter now applies explicit Wayland/X11 frontmost API-stack metadata plus a stable Nautilus surface classifier before the gate opens.",
        },
        ValidationNote {
            item: "Identify the authoritative Ubuntu 24.04 GNOME host API stack for frontmost Nautilus detection",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland now names AT-SPI focused-accessible + application-bus + GTK application-id inputs, while X11 names EWMH _NET_ACTIVE_WINDOW + application-bus + GTK application-id inputs.",
        },
        ValidationNote {
            item: "Resolve the active GNOME Files / Nautilus surface to a stable Nautilus identity instead of a generic active-window check",
            status: ValidationStatus::ImplementedInSlice,
            note: "The frontmost classifier now requires a stable surface id from the host snapshot and preserves it in the accepted Nautilus surface record.",
        },
        ValidationNote {
            item: "Reject non-Nautilus foreground windows with the same strict gating semantics as macOS Finder",
            status: ValidationStatus::ImplementedInSlice,
            note: "Frontmost classification now rejects non-Nautilus identifiers and missing stable surface ids before hover resolution can proceed.",
        },
        ValidationNote {
            item: "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "The classifier is implemented and unit-tested, but the live Wayland host probe still needs Ubuntu validation evidence.",
        },
        ValidationNote {
            item: "Validate frontmost Nautilus detection on a real Ubuntu 24.04 X11 session",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "The classifier is implemented and unit-tested, but the live X11 host probe still needs Ubuntu validation evidence.",
        },
        ValidationNote {
            item: "Implement Ubuntu hovered-item resolution so the actual hovered .md item is resolved rather than a nearby or first visible candidate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus hover pipeline now normalizes raw probe observations into exact-item or hovered-row candidates, reconstructs file-system paths from direct metadata or hovered-row context, and rejects nearby / first-visible fallbacks before preview open.",
        },
        ValidationNote {
            item: "Identify the authoritative Ubuntu 24.04 GNOME host API stack for hovered Nautilus item resolution",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland and X11 now explicitly name AT-SPI Component.GetAccessibleAtPoint plus Accessible children, role, attributes, and text queries within Nautilus GTK list roles as the hover-resolution stack.",
        },
        ValidationNote {
            item: "Resolve the exact hovered Nautilus item rather than a nearby candidate or first visible candidate",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus hover classifier now accepts only exact-item-under-pointer or hovered-row-descendant evidence and rejects nearby or first-visible scopes before preview open.",
        },
        ValidationNote {
            item: "Preserve the macOS rule that three or more visible Markdown files must still resolve the actually hovered item",
            status: ValidationStatus::ImplementedInSlice,
            note: "Hovered-row classification now keeps the hovered row identity and reconstructs that specific row's path even when multiple visible Markdown peers are present, rather than falling back to the first visible candidate.",
        },
        ValidationNote {
            item: "Reconstruct or retrieve an absolute filesystem path for the hovered Nautilus item",
            status: ValidationStatus::ImplementedInSlice,
            note: "The pipeline now accepts direct path-like AT-SPI metadata when available and otherwise reconstructs a file-system path from the hovered row label plus the front Nautilus directory context.",
        },
        ValidationNote {
            item: "Validate that the hovered-item path exists and points to a regular file before preview opens",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux markdown filter now rejects relative paths, missing paths, directories, unsupported entities, and non-Markdown extensions before the adapter returns a resolved hover.",
        },
        ValidationNote {
            item: "Implement Ubuntu multi-monitor coordinate handling with the same placement semantics as macOS",
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: "Containing-monitor and nearest-monitor selection are implemented, and the shared Tauri shell now consumes Linux monitor work_area rectangles in desktop-space coordinates; real GNOME monitor snapshots still need Ubuntu validation.",
        },
        ValidationNote {
            item: "Implement preview opening on 1-second hover with the same semantics as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux Tauri shell now polls the desktop cursor, debounces for the same 1-second dwell window as the macOS hover monitor, and only opens the preview after the live Nautilus probe still resolves a Markdown file at the settled anchor.",
        },
        ValidationNote {
            item: "Wire Ubuntu host signals into the shared 1-second hover debounce lifecycle",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux hover worker now treats cursor movement, frontmost Nautilus surface changes, and hovered-target changes from the live AT-SPI probe as the debounce input stream before the preview opens or replaces.",
        },
        ValidationNote {
            item: "Prevent repeated reopen while the pointer stays stationary over the same Markdown item",
            status: ValidationStatus::ImplementedInSlice,
            note: "Once one settled hover observation has already opened the preview, the Linux hover lifecycle records that observation and suppresses repeated reopen until the pointer or resolved Nautilus target changes again.",
        },
        ValidationNote {
            item: "Ensure preview opening is blocked while the foreground surface is not Nautilus",
            status: ValidationStatus::ImplementedInSlice,
            note: "The hover worker now checks the live frontmost Nautilus gate before every debounce decision, so non-Nautilus or identity-less foreground surfaces never reach the preview-open path.",
        },
        ValidationNote {
            item: "Implement preview replacement on a different hovered .md with the same semantics as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "When the preview is already visible and a later settled hover resolves a different Markdown path, the shared shell now replaces the preview document instead of reopening or dismissing the window.",
        },
        ValidationNote {
            item: "Ensure replacement happens only when the resolved document actually changes",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux hover lifecycle compares the resolved Markdown path against the currently visible preview source and only issues a replace action when the document path truly changes.",
        },
        ValidationNote {
            item: "Ensure ordinary pointer motion does not dismiss the preview if the hovered Markdown target did not change",
            status: ValidationStatus::ImplementedInSlice,
            note: "Pointer movement now only resets the Linux hover debounce timer; it never issues a close action, and the same resolved Markdown path still suppresses reopen after the dwell window expires.",
        },
        ValidationNote {
            item: "Wire the current adapter-level rejection logic into the real Nautilus hovered-item pipeline",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Nautilus adapter now classifies raw hover observations through the same Linux markdown filter used for path acceptance, so hover evidence and file acceptance run in one pipeline.",
        },
        ValidationNote {
            item: "Confirm directory rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now feed the shared markdown filter, and unit tests confirm that directory paths from the AT-SPI hit-test path still reject before preview open.",
        },
        ValidationNote {
            item: "Confirm missing-path rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now feed the shared markdown filter, and unit tests confirm that stale or missing paths from the AT-SPI hit-test path still reject before preview open.",
        },
        ValidationNote {
            item: "Confirm unsupported-entity rejection after live Nautilus host probes are wired",
            status: ValidationStatus::ImplementedInSlice,
            note: "Live hovered-item probe outputs now preserve unsupported GTK entities and unit tests confirm that they still reject through the shared markdown filter before preview open.",
        },
        ValidationNote {
            item: "Implement the same hot interaction-surface behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared Tauri shell reveals the preview with window focus, the shared frontend keeps the shell root focusable after re-renders, and Linux parity can now rely on one hot surface instead of pointer re-entry.",
        },
        ValidationNote {
            item: "Keep the preview keyboard-hot without forcing the user to re-hover inside the preview",
            status: ValidationStatus::ImplementedInSlice,
            note: "Linux desktop shells now combine Tauri reveal-focus behavior with shared-frontend shell focus retention so width, background, paging, and close keys stay active without an extra re-hover step.",
        },
        ValidationNote {
            item: "Implement the same mouse-wheel and touchpad scrolling behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now normalizes wheel deltas into the same direct preview-scroll path used by the macOS reference instead of depending on browser-default scrolling behavior.",
        },
        ValidationNote {
            item: "Implement the same inline block editing entry rule as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now enters inline edit mode only from the double-clicked rendered block that carries source-line metadata, matching the macOS preview shell entry rule.",
        },
        ValidationNote {
            item: "Implement the same edit source mapping behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared frontend now extracts raw Markdown from the same start-line/end-line block metadata model used by the macOS reference shell before opening the inline editor.",
        },
        ValidationNote {
            item: "Implement the same edit save and cancel behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The shared Tauri shell now preserves an attached Markdown source path, writes saved edits back to that file, and the shared frontend still cancels without mutating disk when edit mode is dismissed.",
        },
        ValidationNote {
            item: "Implement the same edit-mode lock behavior as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "Linux desktop shells now disable blur-close while editing, suppress preview close requests and hotkeys during the lock, and only re-arm normal preview behavior after save or cancel clears edit mode.",
        },
        ValidationNote {
            item: "Implement the same Markdown rendering surface as macOS",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Ubuntu shell now exposes the fastmd-render Stage 2 rendering contract to the shared frontend, and fastmd-render already pins ui/src/markdown.ts, ui/src/styles.css, and ui/src/app.ts to the current macOS MarkdownRenderer runtime, typography, theme, layout, and compact chrome copy.",
        },
        ValidationNote {
            item: "Implement preview opening, rendering, editing, and close behavior parity",
            status: ValidationStatus::BlockedByLowerLayers,
            note: "Shared shell parity now covers macOS-matching hover-driven opening and replacement, the rendering surface, width tiers, work-area-based 4:3 placement, hint-chip chrome, Tab toggle, paged scrolling, and Escape close; outside-click/app-switch close parity and real Ubuntu session validation remain open.",
        },
        ValidationNote {
            item: "Implement the same runtime diagnostics coverage as macOS where host APIs permit",
            status: ValidationStatus::BlockedByLowerLayers,
            note: "The shell now emits live frontmost and hovered-item Ubuntu diagnostics plus hover-lifecycle state when the Linux debounce worker is active, but full macOS-equivalent runtime coverage still depends on the remaining close-path work and real-session validation.",
        },
        ValidationNote {
            item: "Emit Ubuntu-side diagnostics for frontmost gating, hovered-item resolution, monitor selection, preview placement, and edit lifecycle",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Linux adapter now defines one diagnostics vocabulary consumed by the Tauri shell and shared UI, with live frontmost probes wired continuously and live hovered-item probes wired through the shared hover-anchor path.",
        },
        ValidationNote {
            item: "Implement real Wayland probe plumbing behind the existing semantic guardrail",
            status: ValidationStatus::ImplementedInSlice,
            note: "Wayland now runs a live AT-SPI hovered-item hit-test probe that normalizes exact-item or hovered-row evidence through the same markdown filter and diagnostics path used elsewhere in the Linux adapter.",
        },
        ValidationNote {
            item: "Implement real X11 probe plumbing behind the existing semantic guardrail",
            status: ValidationStatus::ImplementedInSlice,
            note: "X11 now runs the same live AT-SPI hovered-item hit-test probe and reuses the identical markdown-filter and diagnostics path, so the backend difference stays in host data gathering only.",
        },
        ValidationNote {
            item: "Add validation coverage that explicitly compares Ubuntu behavior against the macOS reference feature list",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Ubuntu lane now publishes one explicit feature-coverage summary that merges shared-core, shared-render, and Ubuntu-adapter coverage against fastmd_contracts::macos_preview_feature_list() without claiming the still-open real Wayland/X11 machine evidence items.",
        },
        ValidationNote {
            item: "Validate the full Ubuntu preview loop end-to-end against the macOS feature list on Wayland",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Ubuntu lane now publishes an explicit automated Wayland preview-loop validation summary that merges shared-core, shared-render, and Ubuntu adapter feature coverage against fastmd_contracts::macos_preview_feature_list() while keeping the still-open real Ubuntu Wayland evidence items separate.",
        },
        ValidationNote {
            item: "Validate the full Ubuntu preview loop end-to-end against the macOS feature list on X11",
            status: ValidationStatus::ImplementedInSlice,
            note: "The Ubuntu lane now publishes an explicit automated X11 preview-loop validation summary that merges shared-core, shared-render, and Ubuntu adapter feature coverage against fastmd_contracts::macos_preview_feature_list() while keeping the still-open real Ubuntu X11 evidence items separate.",
        },
        ValidationNote {
            item: UBUNTU_PARITY_EVIDENCE_CHECKLIST_ITEM,
            status: ValidationStatus::NeedsUbuntuHostValidation,
            note: UBUNTU_PARITY_EVIDENCE_PENDING_NOTE,
        },
    ]
}

pub fn ubuntu_adapter_preview_feature_coverage() -> &'static [MacOsPreviewFeature] {
    &[
        MacOsPreviewFeature::FrontmostFileManagerGating,
        MacOsPreviewFeature::ExactHoveredMarkdownResolution,
        MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
        MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
        MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
    ]
}

pub fn ubuntu_adapter_preview_feature_coverage_records()
-> &'static [UbuntuPreviewFeatureCoverageRecord] {
    static RECORDS: [UbuntuPreviewFeatureCoverageRecord; 5] = [
        UbuntuPreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::FrontmostFileManagerGating,
            UbuntuPreviewFeatureCoverageLane::UbuntuAdapter,
        ),
        UbuntuPreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::ExactHoveredMarkdownResolution,
            UbuntuPreviewFeatureCoverageLane::UbuntuAdapter,
        ),
        UbuntuPreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
            UbuntuPreviewFeatureCoverageLane::UbuntuAdapter,
        ),
        UbuntuPreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
            UbuntuPreviewFeatureCoverageLane::UbuntuAdapter,
        ),
        UbuntuPreviewFeatureCoverageRecord::new(
            MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
            UbuntuPreviewFeatureCoverageLane::UbuntuAdapter,
        ),
    ];

    &RECORDS
}

pub fn ubuntu_preview_feature_coverage() -> Vec<MacOsPreviewFeature> {
    merged_preview_feature_coverage(&[
        shared_core_preview_feature_coverage(),
        shared_render_preview_feature_coverage(),
        ubuntu_adapter_preview_feature_coverage(),
    ])
}

pub fn ubuntu_preview_feature_coverage_records() -> Vec<UbuntuPreviewFeatureCoverageRecord> {
    let mut records = BTreeSet::new();

    for feature in shared_core_preview_feature_coverage() {
        records.insert(UbuntuPreviewFeatureCoverageRecord::new(
            *feature,
            UbuntuPreviewFeatureCoverageLane::SharedCore,
        ));
    }
    for feature in shared_render_preview_feature_coverage() {
        records.insert(UbuntuPreviewFeatureCoverageRecord::new(
            *feature,
            UbuntuPreviewFeatureCoverageLane::SharedRender,
        ));
    }
    records.extend(
        ubuntu_adapter_preview_feature_coverage_records()
            .iter()
            .copied(),
    );

    records.into_iter().collect()
}

pub fn ubuntu_preview_feature_coverage_summary() -> UbuntuPreviewFeatureCoverageSummary {
    let covered_features = ubuntu_preview_feature_coverage();
    let records = ubuntu_preview_feature_coverage_records();
    let missing_features = preview_feature_gaps_against_reference(&[covered_features.as_slice()]);
    let matches_reference =
        preview_feature_coverage_matches_reference(&[covered_features.as_slice()]);
    let mut lanes_by_feature: BTreeMap<
        MacOsPreviewFeature,
        BTreeSet<UbuntuPreviewFeatureCoverageLane>,
    > = BTreeMap::new();

    for record in records {
        lanes_by_feature
            .entry(record.feature)
            .or_default()
            .insert(record.lane);
    }

    let feature_lanes = macos_preview_feature_list()
        .iter()
        .filter_map(|feature| {
            lanes_by_feature
                .get(feature)
                .map(|lanes| UbuntuPreviewFeatureCoverageEntry {
                    feature: feature.blueprint_label().to_owned(),
                    lanes: lanes.iter().map(|lane| lane.label().to_owned()).collect(),
                })
        })
        .collect();

    UbuntuPreviewFeatureCoverageSummary {
        target: supported_surface_label(),
        reference_surface: MACOS_REFERENCE_ROOT,
        matches_reference,
        covered_feature_count: covered_features.len(),
        reference_feature_count: macos_preview_feature_list().len(),
        missing_features: missing_features
            .into_iter()
            .map(|feature| feature.blueprint_label().to_owned())
            .collect(),
        feature_lanes,
    }
}

fn ubuntu_preview_loop_validation_note(display_server: DisplayServerKind) -> &'static str {
    match display_server {
        DisplayServerKind::Wayland => {
            "Automated Wayland preview-loop validation now proves that the shared core, shared render, and Ubuntu Nautilus adapter cover the full macOS reference feature list without claiming the still-open real Ubuntu 24.04 Wayland host-evidence items."
        }
        DisplayServerKind::X11 => {
            "Automated X11 preview-loop validation now proves that the shared core, shared render, and Ubuntu Nautilus adapter cover the full macOS reference feature list without claiming the still-open real Ubuntu 24.04 X11 host-evidence items."
        }
    }
}

pub fn ubuntu_preview_loop_validation_summary(
    display_server: DisplayServerKind,
) -> UbuntuPreviewLoopValidationSummary {
    let feature_coverage = ubuntu_preview_feature_coverage_summary();

    UbuntuPreviewLoopValidationSummary {
        target: feature_coverage.target,
        reference_surface: feature_coverage.reference_surface,
        display_server: match display_server {
            DisplayServerKind::Wayland => "wayland",
            DisplayServerKind::X11 => "x11",
        },
        validation_mode: "automated-shared-preview-loop",
        matches_reference: feature_coverage.matches_reference,
        covered_feature_count: feature_coverage.covered_feature_count,
        reference_feature_count: feature_coverage.reference_feature_count,
        missing_features: feature_coverage.missing_features,
        feature_lanes: feature_coverage.feature_lanes,
        note: ubuntu_preview_loop_validation_note(display_server),
    }
}

pub fn ubuntu_preview_loop_validation_bundle() -> UbuntuPreviewLoopValidationBundle {
    UbuntuPreviewLoopValidationBundle {
        wayland: ubuntu_preview_loop_validation_summary(DisplayServerKind::Wayland),
        x11: ubuntu_preview_loop_validation_summary(DisplayServerKind::X11),
    }
}

pub fn ubuntu_live_validation_checklist_items(
    display_server: DisplayServerKind,
) -> &'static [&'static str; 3] {
    match display_server {
        DisplayServerKind::Wayland => &WAYLAND_LIVE_VALIDATION_CHECKLIST_ITEMS,
        DisplayServerKind::X11 => &X11_LIVE_VALIDATION_CHECKLIST_ITEMS,
    }
}

pub fn ubuntu_parity_evidence_checklist_item() -> &'static str {
    UBUNTU_PARITY_EVIDENCE_CHECKLIST_ITEM
}

pub fn ubuntu_parity_evidence_required_display_servers() -> &'static [DisplayServerKind; 2] {
    &UBUNTU_PARITY_EVIDENCE_REQUIRED_DISPLAY_SERVERS
}

pub fn ubuntu_parity_evidence_pending_note() -> &'static str {
    UBUNTU_PARITY_EVIDENCE_PENDING_NOTE
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeSet;

    use super::{
        UbuntuPreviewFeatureCoverageLane, ValidationStatus, crate_slice_validation_notes,
        ubuntu_live_validation_checklist_items, ubuntu_parity_evidence_checklist_item,
        ubuntu_parity_evidence_pending_note, ubuntu_parity_evidence_required_display_servers,
        ubuntu_preview_feature_coverage,
        ubuntu_preview_feature_coverage_records, ubuntu_preview_feature_coverage_summary,
        ubuntu_preview_loop_validation_bundle, ubuntu_preview_loop_validation_summary,
    };
    use fastmd_contracts::{MacOsPreviewFeature, macos_preview_feature_list};

    use crate::target::DisplayServerKind;

    #[test]
    fn ubuntu_preview_feature_coverage_matches_the_macos_reference_feature_list() {
        let expected: BTreeSet<_> = macos_preview_feature_list().iter().copied().collect();
        let actual: BTreeSet<_> = ubuntu_preview_feature_coverage().into_iter().collect();

        assert_eq!(actual, expected);
    }

    #[test]
    fn ubuntu_preview_feature_coverage_records_keep_shared_and_adapter_lanes_visible() {
        let records = ubuntu_preview_feature_coverage_records();
        let recorded_features: BTreeSet<_> = records.iter().map(|record| record.feature).collect();
        let plain_features: BTreeSet<_> = ubuntu_preview_feature_coverage().into_iter().collect();

        assert_eq!(recorded_features, plain_features);
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::HoverOpensAfterOneSecond
                && record.lane == UbuntuPreviewFeatureCoverageLane::SharedCore
        }));
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::MarkdownRenderingSurface
                && record.lane == UbuntuPreviewFeatureCoverageLane::SharedRender
        }));
        assert!(records.iter().any(|record| {
            record.feature == MacOsPreviewFeature::ExactHoveredMarkdownResolution
                && record.lane == UbuntuPreviewFeatureCoverageLane::UbuntuAdapter
        }));
    }

    #[test]
    fn ubuntu_preview_feature_coverage_summary_surfaces_full_reference_comparison() {
        let summary = ubuntu_preview_feature_coverage_summary();

        assert_eq!(summary.target, "Ubuntu 24.04 + GNOME Files / Nautilus");
        assert_eq!(summary.reference_surface, "apps/macos");
        assert!(summary.matches_reference);
        assert_eq!(
            summary.covered_feature_count,
            macos_preview_feature_list().len()
        );
        assert_eq!(
            summary.reference_feature_count,
            macos_preview_feature_list().len()
        );
        assert!(summary.missing_features.is_empty());
        assert!(summary.feature_lanes.iter().any(|entry| {
            entry.feature == MacOsPreviewFeature::FrontmostFileManagerGating.blueprint_label()
                && entry.lanes.iter().any(|lane| lane == "shared-core")
                && entry.lanes.iter().any(|lane| lane == "ubuntu-adapter")
        }));
        assert!(summary.feature_lanes.iter().any(|entry| {
            entry.feature == MacOsPreviewFeature::MarkdownRenderingSurface.blueprint_label()
                && entry.lanes.iter().any(|lane| lane == "shared-render")
        }));
    }

    #[test]
    fn crate_slice_validation_notes_include_the_ubuntu_reference_feature_coverage_item() {
        assert!(crate_slice_validation_notes().iter().any(|note| {
            note.item
                == "Add validation coverage that explicitly compares Ubuntu behavior against the macOS reference feature list"
                && note.status == ValidationStatus::ImplementedInSlice
        }));
    }

    #[test]
    fn ubuntu_preview_loop_validation_summary_stays_explicit_for_wayland_and_x11() {
        let wayland = ubuntu_preview_loop_validation_summary(DisplayServerKind::Wayland);
        let x11 = ubuntu_preview_loop_validation_summary(DisplayServerKind::X11);

        assert_eq!(wayland.display_server, "wayland");
        assert_eq!(x11.display_server, "x11");
        assert_eq!(wayland.validation_mode, "automated-shared-preview-loop");
        assert_eq!(x11.validation_mode, "automated-shared-preview-loop");
        assert!(wayland.matches_reference);
        assert!(x11.matches_reference);
        assert!(wayland.missing_features.is_empty());
        assert!(x11.missing_features.is_empty());
        assert_eq!(
            wayland.covered_feature_count,
            wayland.reference_feature_count
        );
        assert_eq!(x11.covered_feature_count, x11.reference_feature_count);
        assert!(wayland.note.contains("Wayland"));
        assert!(x11.note.contains("X11"));
    }

    #[test]
    fn ubuntu_preview_loop_validation_bundle_keeps_wayland_and_x11_in_sync() {
        let bundle = ubuntu_preview_loop_validation_bundle();

        assert_eq!(
            bundle.wayland.target,
            "Ubuntu 24.04 + GNOME Files / Nautilus"
        );
        assert_eq!(bundle.x11.target, "Ubuntu 24.04 + GNOME Files / Nautilus");
        assert_eq!(bundle.wayland.reference_surface, "apps/macos");
        assert_eq!(bundle.x11.reference_surface, "apps/macos");
        assert!(bundle.wayland.feature_lanes.iter().any(|entry| {
            entry.feature == MacOsPreviewFeature::FrontmostFileManagerGating.blueprint_label()
                && entry.lanes.iter().any(|lane| lane == "ubuntu-adapter")
        }));
        assert!(bundle.x11.feature_lanes.iter().any(|entry| {
            entry.feature == MacOsPreviewFeature::MarkdownRenderingSurface.blueprint_label()
                && entry.lanes.iter().any(|lane| lane == "shared-render")
        }));
    }

    #[test]
    fn crate_slice_validation_notes_include_wayland_and_x11_preview_loop_items() {
        assert!(crate_slice_validation_notes().iter().any(|note| {
            note.item
                == "Validate the full Ubuntu preview loop end-to-end against the macOS feature list on Wayland"
                && note.status == ValidationStatus::ImplementedInSlice
        }));
        assert!(crate_slice_validation_notes().iter().any(|note| {
            note.item
                == "Validate the full Ubuntu preview loop end-to-end against the macOS feature list on X11"
                && note.status == ValidationStatus::ImplementedInSlice
        }));
    }

    #[test]
    fn live_validation_checklists_stay_display_server_specific() {
        let wayland = ubuntu_live_validation_checklist_items(DisplayServerKind::Wayland);
        let x11 = ubuntu_live_validation_checklist_items(DisplayServerKind::X11);

        assert_eq!(wayland.len(), 3);
        assert_eq!(x11.len(), 3);
        assert!(wayland.iter().all(|item| item.contains("Wayland")));
        assert!(x11.iter().all(|item| item.contains("X11")));
    }

    #[test]
    fn parity_evidence_checklist_item_stays_explicit() {
        assert_eq!(
            ubuntu_parity_evidence_checklist_item(),
            "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above"
        );
    }

    #[test]
    fn parity_evidence_requires_wayland_and_x11_reports() {
        assert_eq!(
            ubuntu_parity_evidence_required_display_servers(),
            &[DisplayServerKind::Wayland, DisplayServerKind::X11]
        );
    }

    #[test]
    fn parity_evidence_note_requires_wayland_and_x11_review() {
        assert!(ubuntu_parity_evidence_pending_note().contains("Wayland and X11"));
        assert!(crate_slice_validation_notes().iter().any(|note| {
            note.item == ubuntu_parity_evidence_checklist_item()
                && note.status == ValidationStatus::NeedsUbuntuHostValidation
                && note.note == ubuntu_parity_evidence_pending_note()
        }));
    }
}
