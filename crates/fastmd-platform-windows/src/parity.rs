pub use fastmd_contracts::{
    BackgroundMode, BackgroundToggleKey, BackgroundToggleReference, ClosePolicyReference,
    CoordinateSpaceReference, EditEntryReference, EditModeReference, FrontmostFileManagerReference,
    HintChipReference, HoverResolutionReference, InteractionReference, MacOsReferenceBehavior,
    MultiMonitorReference, PagingReference, PlacementBoundsReference, PreviewGeometryReference,
    MACOS_REFERENCE_BEHAVIOR,
};

/// Stage 2 Windows target locked by this lane.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WindowsExplorerStage2Target {
    pub operating_system: &'static str,
    pub file_manager: &'static str,
    pub parity_reference_surface: &'static str,
}

pub static WINDOWS_EXPLORER_STAGE2_TARGET: WindowsExplorerStage2Target =
    WindowsExplorerStage2Target {
        operating_system: "Windows 11",
        file_manager: "Explorer",
        parity_reference_surface: "apps/macos",
    };

#[cfg(test)]
mod tests {
    use super::{
        BackgroundMode, BackgroundToggleKey, CoordinateSpaceReference, EditEntryReference,
        PlacementBoundsReference, MACOS_REFERENCE_BEHAVIOR, WINDOWS_EXPLORER_STAGE2_TARGET,
    };

    #[test]
    fn target_is_explicitly_windows_11_plus_explorer_only() {
        assert_eq!(
            WINDOWS_EXPLORER_STAGE2_TARGET.operating_system,
            "Windows 11"
        );
        assert_eq!(WINDOWS_EXPLORER_STAGE2_TARGET.file_manager, "Explorer");
        assert_eq!(
            WINDOWS_EXPLORER_STAGE2_TARGET.parity_reference_surface,
            "apps/macos"
        );
    }

    #[test]
    fn macos_reference_comes_from_shared_contracts() {
        assert_eq!(MACOS_REFERENCE_BEHAVIOR.reference_surface, "apps/macos");
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR
                .frontmost_file_manager
                .app_identifier,
            "com.apple.finder"
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.preview_geometry.width_tiers_px,
            [560, 960, 1_440, 1_920]
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.preview_geometry.aspect_ratio,
            (4, 3)
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.background_modes,
            [BackgroundMode::White, BackgroundMode::Black]
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.background_toggle.trigger_key,
            BackgroundToggleKey::Tab
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.multi_monitor.coordinate_space,
            CoordinateSpaceReference::DesktopSpace
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.multi_monitor.placement_bounds,
            PlacementBoundsReference::VisibleFrame
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.edit_mode.entry,
            EditEntryReference::DoubleClickSmallestMatchingBlock
        );
        assert_eq!(
            MACOS_REFERENCE_BEHAVIOR.hint_chip.width_label(2, 4),
            "← 3/4 →"
        );
    }
}
