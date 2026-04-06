/// Current validation status for a Windows parity item in this crate.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum FeatureStatus {
    ImplementedInThisCrate,
    PendingAdapterWork,
    PendingSharedCore,
}

/// One Windows parity requirement and the honest status of this crate against it.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct AdapterValidationFeature {
    pub blueprint_item: &'static str,
    pub status: FeatureStatus,
    pub evidence: &'static str,
}

/// Crate-local validation manifest for the Windows lane.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct AdapterValidationManifest {
    pub target: &'static str,
    pub reference_surface: &'static str,
    pub features: &'static [AdapterValidationFeature],
}

pub static WINDOWS_VALIDATION_FEATURES: [AdapterValidationFeature; 11] = [
    AdapterValidationFeature {
        blueprint_item: "Restrict Windows support target to Windows 11 plus Explorer only",
        status: FeatureStatus::ImplementedInThisCrate,
        evidence: "Encoded in README, VALIDATION.md, and WINDOWS_EXPLORER_STAGE2_TARGET.",
    },
    AdapterValidationFeature {
        blueprint_item: "Create `fastmd-platform-windows` as a buildable crate",
        status: FeatureStatus::ImplementedInThisCrate,
        evidence: "Independent Cargo manifest plus crate-local cargo check coverage.",
    },
    AdapterValidationFeature {
        blueprint_item: "Identify the authoritative Windows host API stack for frontmost Explorer detection",
        status: FeatureStatus::ImplementedInThisCrate,
        evidence: "The crate now fixes the frontmost stack to GetForegroundWindow + GetWindowThreadProcessId + QueryFullProcessImageNameW + GetClassNameW + IShellWindows + IWebBrowserApp::HWND.",
    },
    AdapterValidationFeature {
        blueprint_item: "Resolve the active Explorer surface to a stable Explorer identity instead of a generic foreground-window check",
        status: FeatureStatus::ImplementedInThisCrate,
        evidence: "FrontmostWindowSnapshot now resolves a stable surface identity from the matched Explorer shell HWND plus owner process id before it produces a FrontSurface.",
    },
    AdapterValidationFeature {
        blueprint_item: "Reject non-Explorer foreground windows with the same strict gating semantics as macOS Finder",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "The strict classifier is implemented, but the live Windows host probe that feeds it is still pending in this crate.",
    },
    AdapterValidationFeature {
        blueprint_item: "Reject non-Markdown files, directories, and unsupported items with the same semantics as macOS",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "The crate-local WindowsMarkdownFilter mirrors the macOS path checks, but real Explorer hovered-item resolution is not wired yet.",
    },
    AdapterValidationFeature {
        blueprint_item: "Implement Windows frontmost Explorer detection with the same gating semantics as macOS Finder",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "The authoritative API stack and strict classifier are implemented, but the live Windows host probe that calls those APIs is still pending.",
    },
    AdapterValidationFeature {
        blueprint_item: "Implement Windows hovered-item resolution so the actual hovered `.md` item is resolved",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "Explicit seam only; actual Explorer hovered-item resolution remains pending.",
    },
    AdapterValidationFeature {
        blueprint_item: "Implement Windows multi-monitor coordinate handling with the same placement semantics as macOS",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "Explicit seam only; Windows display and coordinate translation remains pending.",
    },
    AdapterValidationFeature {
        blueprint_item: "Implement the same runtime diagnostics coverage as macOS where host APIs permit",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "Diagnostics seam exists but host-backed emission is not implemented.",
    },
    AdapterValidationFeature {
        blueprint_item: "Implement width tiers, background toggle, paging, editing, and close semantics through shared contracts/core",
        status: FeatureStatus::PendingAdapterWork,
        evidence: "Shared contracts/core now encode the macOS reference semantics and explicitly test edit-mode lock plus close-policy parity against the macOS reference; Windows host wiring still needs to drive those rules end-to-end.",
    },
];

pub fn windows_validation_manifest() -> AdapterValidationManifest {
    AdapterValidationManifest {
        target: "Windows 11 + Explorer only",
        reference_surface: "apps/macos",
        features: &WINDOWS_VALIDATION_FEATURES,
    }
}

#[cfg(test)]
mod tests {
    use super::{FeatureStatus, windows_validation_manifest};

    #[test]
    fn validation_manifest_stays_explicit_about_target_and_reference() {
        let manifest = windows_validation_manifest();

        assert_eq!(manifest.target, "Windows 11 + Explorer only");
        assert_eq!(manifest.reference_surface, "apps/macos");
    }

    #[test]
    fn validation_manifest_marks_only_the_completed_slice_as_implemented() {
        let manifest = windows_validation_manifest();

        let implemented = manifest
            .features
            .iter()
            .filter(|feature| feature.status == FeatureStatus::ImplementedInThisCrate)
            .count();

        assert_eq!(implemented, 4);
        assert!(
            manifest
                .features
                .iter()
                .any(|feature| feature.status == FeatureStatus::PendingAdapterWork)
        );
        assert!(
            manifest
                .features
                .iter()
                .all(|feature| feature.status != FeatureStatus::PendingSharedCore)
        );
    }
}
