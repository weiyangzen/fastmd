use std::fmt;
use std::path::PathBuf;

use crate::filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, HoverCandidateSource,
    LinuxMarkdownFilter,
};
use crate::target::DisplayServerKind;

/// How strongly the backend can prove that a resolved item came from the
/// pointer location.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HoverResolutionScope {
    /// The backend identified the item directly under the pointer.
    ExactItemUnderPointer,
    /// The backend identified the hovered row/container and then resolved the
    /// item inside that hovered row. This matches the macOS fallback shape.
    HoveredRowDescendant,
    /// A nearby candidate was chosen heuristically.
    NearbyCandidate,
    /// The first visible item was used as a fallback.
    FirstVisibleItem,
}

impl HoverResolutionScope {
    /// Returns true only for scopes that preserve macOS parity expectations.
    pub fn supports_macos_parity(self) -> bool {
        matches!(
            self,
            Self::ExactItemUnderPointer | Self::HoveredRowDescendant
        )
    }
}

/// What kind of entity the backend believes it resolved.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum HoveredEntityKind {
    /// Regular file.
    File,
    /// Directory or folder.
    Directory,
    /// Anything else that FastMD should reject.
    Unsupported,
}

/// Authoritative host-facing inputs for hovered Nautilus item resolution.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NautilusHoveredItemApi {
    /// `org.a11y.atspi.Component.GetAccessibleAtPoint` in screen coordinates.
    AtspiComponentGetAccessibleAtPoint,
    /// `org.a11y.atspi.Accessible.GetChildren` /
    /// `org.a11y.atspi.Accessible.GetChildAtIndex` on the hovered lineage.
    AtspiAccessibleGetChildren,
    /// `org.a11y.atspi.Accessible.GetRole` / `GetRoleName` for list and row
    /// classification.
    AtspiAccessibleGetRole,
    /// `org.a11y.atspi.Accessible.GetAttributes` for URI or path-style
    /// metadata exposed by Nautilus widgets.
    AtspiAccessibleGetAttributes,
    /// `org.a11y.atspi.Text.GetText` for the visible file-name label when no
    /// direct URI-like attribute is available.
    AtspiTextGetText,
    /// GTK accessibility roles used by Nautilus rows and list descendants.
    GtkAccessibleListRoles,
}

impl NautilusHoveredItemApi {
    /// Stable human-readable diagnostic label.
    pub const fn label(self) -> &'static str {
        match self {
            Self::AtspiComponentGetAccessibleAtPoint => {
                "AT-SPI Component.GetAccessibleAtPoint(screen)"
            }
            Self::AtspiAccessibleGetChildren => "AT-SPI Accessible.GetChildren/GetChildAtIndex",
            Self::AtspiAccessibleGetRole => "AT-SPI Accessible.GetRole/GetRoleName",
            Self::AtspiAccessibleGetAttributes => "AT-SPI Accessible.GetAttributes",
            Self::AtspiTextGetText => "AT-SPI Text.GetText",
            Self::GtkAccessibleListRoles => "GTK accessible roles LIST/LIST_ITEM/ROW",
        }
    }
}

/// Explicit hovered-item detection stack for one Linux display-server backend.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct NautilusHoveredItemApiStack {
    pub display_server: DisplayServerKind,
    pub pointer_hit_test: NautilusHoveredItemApi,
    pub lineage_walk: NautilusHoveredItemApi,
    pub role_filter: NautilusHoveredItemApi,
    pub metadata_attributes: NautilusHoveredItemApi,
    pub visible_label_text: NautilusHoveredItemApi,
    pub gtk_role_reference: NautilusHoveredItemApi,
}

impl NautilusHoveredItemApiStack {
    /// Stable summary for diagnostics and documentation.
    pub fn diagnostic_summary(self) -> String {
        format!(
            "pointer={} + lineage={} + role={} + metadata={} + label={} + gtk_roles={}",
            self.pointer_hit_test.label(),
            self.lineage_walk.label(),
            self.role_filter.label(),
            self.metadata_attributes.label(),
            self.visible_label_text.label(),
            self.gtk_role_reference.label(),
        )
    }
}

pub static WAYLAND_HOVERED_ITEM_API_STACK: NautilusHoveredItemApiStack =
    NautilusHoveredItemApiStack {
        display_server: DisplayServerKind::Wayland,
        pointer_hit_test: NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint,
        lineage_walk: NautilusHoveredItemApi::AtspiAccessibleGetChildren,
        role_filter: NautilusHoveredItemApi::AtspiAccessibleGetRole,
        metadata_attributes: NautilusHoveredItemApi::AtspiAccessibleGetAttributes,
        visible_label_text: NautilusHoveredItemApi::AtspiTextGetText,
        gtk_role_reference: NautilusHoveredItemApi::GtkAccessibleListRoles,
    };

pub static X11_HOVERED_ITEM_API_STACK: NautilusHoveredItemApiStack = NautilusHoveredItemApiStack {
    display_server: DisplayServerKind::X11,
    pointer_hit_test: NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint,
    lineage_walk: NautilusHoveredItemApi::AtspiAccessibleGetChildren,
    role_filter: NautilusHoveredItemApi::AtspiAccessibleGetRole,
    metadata_attributes: NautilusHoveredItemApi::AtspiAccessibleGetAttributes,
    visible_label_text: NautilusHoveredItemApi::AtspiTextGetText,
    gtk_role_reference: NautilusHoveredItemApi::GtkAccessibleListRoles,
};

pub fn hovered_item_api_stack_for_display_server(
    display_server: DisplayServerKind,
) -> &'static NautilusHoveredItemApiStack {
    match display_server {
        DisplayServerKind::Wayland => &WAYLAND_HOVERED_ITEM_API_STACK,
        DisplayServerKind::X11 => &X11_HOVERED_ITEM_API_STACK,
    }
}

/// Raw Nautilus hover observation produced by the eventual Wayland/X11 host
/// probes before macOS parity filtering runs.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HoveredItemObservation {
    /// File, directory, or unsupported entity.
    pub entity_kind: HoveredEntityKind,
    /// Evidence quality for the resolved item.
    pub resolution_scope: HoverResolutionScope,
    /// Backend label for runtime diagnostics.
    pub backend: String,
    /// Direct path recovered from a path-like AT-SPI attribute when available.
    pub absolute_path: Option<PathBuf>,
    /// Parent directory of the hovered Nautilus surface when direct path-like
    /// metadata is unavailable.
    pub parent_directory: Option<PathBuf>,
    /// Hovered item label used with the parent directory to reconstruct an
    /// absolute file-system path.
    pub item_name: Option<String>,
    /// Source of the candidate path or reconstruction inputs.
    pub path_source: HoverCandidateSource,
    /// Number of visible Markdown peers in the hovered list or row context.
    pub visible_markdown_peer_count: Option<usize>,
    /// Explicit unsupported description when the hovered entity is not a file
    /// candidate FastMD can open.
    pub unsupported_description: Option<String>,
}

/// Host snapshot for the currently hovered file-manager item after Nautilus
/// probe data has been normalized into a candidate path or unsupported item.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HoveredItemSnapshot {
    pub candidate: HoverCandidate,
    pub entity_kind: HoveredEntityKind,
    pub resolution_scope: HoverResolutionScope,
    pub backend: String,
    pub item_name: Option<String>,
    pub path_source: HoverCandidateSource,
    pub visible_markdown_peer_count: Option<usize>,
}

/// Why a hovered Nautilus observation did not satisfy the macOS-matching
/// hovered-item contract.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum HoveredItemResolutionRejection {
    InsufficientEvidence { scope: HoverResolutionScope },
    CandidateRejected { rejection: HoverCandidateRejection },
}

impl fmt::Display for HoveredItemResolutionRejection {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InsufficientEvidence { scope } => write!(
                f,
                "hovered Nautilus item used a non-parity resolution scope: {scope:?}"
            ),
            Self::CandidateRejected { rejection } => {
                write!(
                    f,
                    "hovered Nautilus item failed markdown acceptance: {rejection}"
                )
            }
        }
    }
}

impl std::error::Error for HoveredItemResolutionRejection {}

/// Classification result for one normalized Nautilus hovered-item snapshot.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct HoveredItemProbeOutcome {
    pub snapshot: HoveredItemSnapshot,
    pub accepted: Option<AcceptedMarkdownPath>,
    pub rejection: Option<HoveredItemResolutionRejection>,
    pub notes: &'static str,
}

pub fn build_hovered_item_snapshot(observation: HoveredItemObservation) -> HoveredItemSnapshot {
    let HoveredItemObservation {
        entity_kind,
        resolution_scope,
        backend,
        absolute_path,
        parent_directory,
        item_name,
        path_source,
        visible_markdown_peer_count,
        unsupported_description,
    } = observation;

    let normalized_item_name = item_name
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(ToOwned::to_owned);

    let candidate = if let Some(description) = unsupported_description
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
    {
        HoverCandidate::UnsupportedItem {
            description: description.to_string(),
            source: path_source,
        }
    } else if let Some(path) = absolute_path {
        HoverCandidate::LocalPath {
            path,
            source: path_source,
        }
    } else if let (Some(parent_directory), Some(item_name)) =
        (parent_directory, normalized_item_name.clone())
    {
        HoverCandidate::LocalPath {
            path: parent_directory.join(item_name),
            source: path_source,
        }
    } else {
        HoverCandidate::UnsupportedItem {
            description:
                "hovered Nautilus item did not expose a direct path or enough context to reconstruct one"
                    .to_string(),
            source: path_source,
        }
    };

    HoveredItemSnapshot {
        candidate,
        entity_kind,
        resolution_scope,
        backend,
        item_name: normalized_item_name,
        path_source,
        visible_markdown_peer_count,
    }
}

pub fn classify_hovered_item_snapshot(
    snapshot: HoveredItemSnapshot,
    filter: &LinuxMarkdownFilter,
) -> HoveredItemProbeOutcome {
    let resolution_scope = snapshot.resolution_scope;

    if !resolution_scope.supports_macos_parity() {
        return HoveredItemProbeOutcome {
            snapshot,
            accepted: None,
            rejection: Some(HoveredItemResolutionRejection::InsufficientEvidence {
                scope: resolution_scope,
            }),
            notes: "The Nautilus hover pipeline accepts only exact-item or hovered-row evidence and rejects nearby or first-visible fallbacks before FastMD opens a preview.",
        };
    }

    match filter.accept_candidate(snapshot.candidate.clone()) {
        Ok(accepted) => HoveredItemProbeOutcome {
            snapshot,
            accepted: Some(accepted),
            rejection: None,
            notes: "The Nautilus hover pipeline accepts exact-item or hovered-row evidence, reconstructs an absolute path from AT-SPI metadata or hovered-row context, and then reuses the crate-local Markdown filter before preview open.",
        },
        Err(rejection) => HoveredItemProbeOutcome {
            snapshot,
            accepted: None,
            rejection: Some(HoveredItemResolutionRejection::CandidateRejected { rejection }),
            notes: "The Nautilus hover pipeline resolves a path candidate before reusing the crate-local Markdown filter, so stale paths, directories, unsupported items, and non-Markdown files are rejected before preview open.",
        },
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::filter::HoverCandidateSource;
    use std::fs;
    use std::path::Path;
    use std::time::{SystemTime, UNIX_EPOCH};

    #[test]
    fn authoritative_hovered_item_api_stacks_are_explicit() {
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.pointer_hit_test,
            NautilusHoveredItemApi::AtspiComponentGetAccessibleAtPoint
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.lineage_walk,
            NautilusHoveredItemApi::AtspiAccessibleGetChildren
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.role_filter,
            NautilusHoveredItemApi::AtspiAccessibleGetRole
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.metadata_attributes,
            NautilusHoveredItemApi::AtspiAccessibleGetAttributes
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.visible_label_text,
            NautilusHoveredItemApi::AtspiTextGetText
        );
        assert_eq!(
            WAYLAND_HOVERED_ITEM_API_STACK.gtk_role_reference,
            NautilusHoveredItemApi::GtkAccessibleListRoles
        );
    }

    #[test]
    fn hovered_item_stack_lookup_matches_the_display_server() {
        assert_eq!(
            hovered_item_api_stack_for_display_server(DisplayServerKind::Wayland),
            &WAYLAND_HOVERED_ITEM_API_STACK
        );
        assert_eq!(
            hovered_item_api_stack_for_display_server(DisplayServerKind::X11),
            &X11_HOVERED_ITEM_API_STACK
        );
    }

    #[test]
    fn hovered_item_stack_summary_stays_diagnostic_friendly() {
        let summary = WAYLAND_HOVERED_ITEM_API_STACK.diagnostic_summary();

        assert!(summary.contains("AT-SPI Component.GetAccessibleAtPoint(screen)"));
        assert!(summary.contains("AT-SPI Accessible.GetAttributes"));
        assert!(summary.contains("GTK accessible roles LIST/LIST_ITEM/ROW"));
    }

    #[test]
    fn builds_snapshot_from_hovered_row_context_without_picking_the_first_visible_item() {
        let parent = temp_path("docs");
        fs::create_dir_all(&parent).expect("parent directory should be created");

        let snapshot = build_hovered_item_snapshot(HoveredItemObservation {
            entity_kind: HoveredEntityKind::File,
            resolution_scope: HoverResolutionScope::HoveredRowDescendant,
            backend: "atspi".to_string(),
            absolute_path: None,
            parent_directory: Some(parent.clone()),
            item_name: Some("third.md".to_string()),
            path_source: HoverCandidateSource::HoveredRowLabelWithParentDirectory,
            visible_markdown_peer_count: Some(3),
            unsupported_description: None,
        });

        assert_eq!(
            snapshot.path_source,
            HoverCandidateSource::HoveredRowLabelWithParentDirectory
        );
        assert_eq!(snapshot.visible_markdown_peer_count, Some(3));
        assert_eq!(snapshot.item_name.as_deref(), Some("third.md"));
        assert_eq!(
            snapshot.candidate,
            HoverCandidate::LocalPath {
                path: parent.join("third.md"),
                source: HoverCandidateSource::HoveredRowLabelWithParentDirectory,
            }
        );

        cleanup_path(&parent);
    }

    #[test]
    fn classifier_accepts_exact_and_hovered_row_markdown_files() {
        let filter = LinuxMarkdownFilter;
        let exact = temp_path("exact.md");
        let row = temp_path("row.md");
        write_file(&exact);
        write_file(&row);

        let exact_outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: Some(exact.clone()),
                parent_directory: None,
                item_name: Some("exact.md".to_string()),
                path_source: HoverCandidateSource::AtspiPathAttribute,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            }),
            &filter,
        );
        assert_eq!(
            exact_outcome
                .accepted
                .as_ref()
                .map(|accepted| accepted.path()),
            Some(exact.as_path())
        );

        let row_outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::HoveredRowDescendant,
                backend: "fixture".to_string(),
                absolute_path: None,
                parent_directory: row.parent().map(Path::to_path_buf),
                item_name: row
                    .file_name()
                    .and_then(|value| value.to_str())
                    .map(ToOwned::to_owned),
                path_source: HoverCandidateSource::HoveredRowLabelWithParentDirectory,
                visible_markdown_peer_count: Some(4),
                unsupported_description: None,
            }),
            &filter,
        );
        assert_eq!(
            row_outcome
                .accepted
                .as_ref()
                .map(|accepted| accepted.path()),
            Some(row.as_path())
        );

        cleanup_path(&exact);
        cleanup_path(&row);
    }

    #[test]
    fn classifier_rejects_nearby_and_first_visible_scopes() {
        let filter = LinuxMarkdownFilter;
        let file = temp_path("nearby.md");
        write_file(&file);

        for scope in [
            HoverResolutionScope::NearbyCandidate,
            HoverResolutionScope::FirstVisibleItem,
        ] {
            let outcome = classify_hovered_item_snapshot(
                build_hovered_item_snapshot(HoveredItemObservation {
                    entity_kind: HoveredEntityKind::File,
                    resolution_scope: scope,
                    backend: "fixture".to_string(),
                    absolute_path: Some(file.clone()),
                    parent_directory: None,
                    item_name: Some("nearby.md".to_string()),
                    path_source: HoverCandidateSource::ValidationFixture,
                    visible_markdown_peer_count: Some(5),
                    unsupported_description: None,
                }),
                &filter,
            );

            assert!(outcome.accepted.is_none());
            assert_eq!(
                outcome.rejection,
                Some(HoveredItemResolutionRejection::InsufficientEvidence { scope })
            );
        }

        cleanup_path(&file);
    }

    #[test]
    fn classifier_rejects_missing_relative_directories_and_unsupported_entities() {
        let filter = LinuxMarkdownFilter;
        let directory = temp_path("folder.md");
        let txt = temp_path("notes.txt");
        fs::create_dir_all(&directory).expect("directory should be created");
        write_file(&txt);

        let relative = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: Some(PathBuf::from("relative.md")),
                parent_directory: None,
                item_name: Some("relative.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            }),
            &filter,
        );
        assert!(matches!(
            relative.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::RelativePath { .. }
            })
        ));

        let missing = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: Some(temp_path("missing.md")),
                parent_directory: None,
                item_name: Some("missing.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            }),
            &filter,
        );
        assert!(matches!(
            missing.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::MissingPath { .. }
            })
        ));

        let directory_outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::Directory,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: Some(directory.clone()),
                parent_directory: None,
                item_name: Some("folder.md".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            }),
            &filter,
        );
        assert!(matches!(
            directory_outcome.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::Directory { .. }
            })
        ));

        let unsupported = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::Unsupported,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: None,
                parent_directory: None,
                item_name: None,
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: None,
                unsupported_description: Some(
                    "hovered GTK widget was not a Nautilus file row".to_string(),
                ),
            }),
            &filter,
        );
        assert!(matches!(
            unsupported.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::UnsupportedItem { .. }
            })
        ));

        let unsupported_extension = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(HoveredItemObservation {
                entity_kind: HoveredEntityKind::File,
                resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
                backend: "fixture".to_string(),
                absolute_path: Some(txt.clone()),
                parent_directory: None,
                item_name: Some("notes.txt".to_string()),
                path_source: HoverCandidateSource::ValidationFixture,
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
            }),
            &filter,
        );
        assert!(matches!(
            unsupported_extension.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::UnsupportedExtension { .. }
            })
        ));

        cleanup_path(&directory);
        cleanup_path(&txt);
    }

    fn temp_path(name: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time should be after unix epoch")
            .as_nanos();
        std::env::temp_dir().join(format!("fastmd-nautilus-hover-{nonce}-{name}"))
    }

    fn write_file(path: &Path) {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent).expect("parent directory should be created");
        }
        fs::write(path, "# hello\n").expect("file should be written");
    }

    fn cleanup_path(path: &Path) {
        if path.is_dir() {
            let _ = fs::remove_dir_all(path);
        } else {
            let _ = fs::remove_file(path);
        }
    }
}
