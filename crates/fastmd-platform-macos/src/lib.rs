#![doc = include_str!("../README.md")]
#![forbid(unsafe_code)]

use fastmd_contracts::{merged_preview_feature_coverage, MacOsPreviewFeature};
use fastmd_core::shared_core_preview_feature_coverage;
use fastmd_render::shared_render_preview_feature_coverage;

/// Stage 2 keeps macOS Finder as the behavioral reference implementation while
/// shared Rust/Tauri layers are introduced.
pub const STAGE2_REFERENCE_HOST: &str = "macOS Finder";

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MacOSAdapterState {
    ReferenceOnly,
    SharedCoreBridged,
}

impl Default for MacOSAdapterState {
    fn default() -> Self {
        Self::ReferenceOnly
    }
}

pub fn macos_reference_adapter_preview_feature_coverage() -> &'static [MacOsPreviewFeature] {
    &[
        MacOsPreviewFeature::ExactHoveredMarkdownResolution,
        MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly,
        MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation,
        MacOsPreviewFeature::RuntimeDiagnosticsCoverage,
    ]
}

pub fn macos_reference_preview_feature_coverage() -> Vec<MacOsPreviewFeature> {
    merged_preview_feature_coverage(&[
        shared_core_preview_feature_coverage(),
        shared_render_preview_feature_coverage(),
        macos_reference_adapter_preview_feature_coverage(),
    ])
}

#[cfg(test)]
mod tests {
    use super::{
        macos_reference_adapter_preview_feature_coverage, macos_reference_preview_feature_coverage,
        MacOSAdapterState, STAGE2_REFERENCE_HOST,
    };
    use fastmd_contracts::{
        macos_preview_feature_list, preview_feature_coverage_matches_reference,
        preview_feature_gaps_against_reference, MacOsPreviewFeature,
    };
    use std::collections::BTreeSet;

    #[test]
    fn macos_reference_host_is_explicit() {
        assert_eq!(STAGE2_REFERENCE_HOST, "macOS Finder");
    }

    #[test]
    fn default_state_starts_as_reference_only() {
        assert_eq!(
            MacOSAdapterState::default(),
            MacOSAdapterState::ReferenceOnly
        );
    }

    #[test]
    fn macos_reference_adapter_preview_feature_coverage_stays_explicit() {
        let features: BTreeSet<_> = macos_reference_adapter_preview_feature_coverage()
            .iter()
            .copied()
            .collect();

        assert_eq!(features.len(), 4);
        assert!(features.contains(&MacOsPreviewFeature::ExactHoveredMarkdownResolution));
        assert!(features.contains(&MacOsPreviewFeature::AcceptedLocalMarkdownFilesOnly));
        assert!(features.contains(&MacOsPreviewFeature::MonitorSelectionAndCoordinateTranslation));
        assert!(features.contains(&MacOsPreviewFeature::RuntimeDiagnosticsCoverage));
    }

    #[test]
    fn macos_reference_preview_feature_coverage_matches_the_reference_feature_list() {
        let actual: BTreeSet<_> = macos_reference_preview_feature_coverage()
            .into_iter()
            .collect();
        let expected: BTreeSet<_> = macos_preview_feature_list().iter().copied().collect();

        assert_eq!(actual, expected);
        assert!(preview_feature_coverage_matches_reference(&[
            fastmd_core::shared_core_preview_feature_coverage(),
            fastmd_render::shared_render_preview_feature_coverage(),
            macos_reference_adapter_preview_feature_coverage(),
        ]));
        assert!(preview_feature_gaps_against_reference(&[
            fastmd_core::shared_core_preview_feature_coverage(),
            fastmd_render::shared_render_preview_feature_coverage(),
            macos_reference_adapter_preview_feature_coverage(),
        ])
        .is_empty());
    }
}
