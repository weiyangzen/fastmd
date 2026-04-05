#![forbid(unsafe_code)]

//! Ubuntu 24.04 GNOME Files / Nautilus adapter seams for FastMD Stage 2.
//!
//! This crate is intentionally scoped to the Stage 2 Linux lane defined in
//! `Docs/Stage2_Blueprint.md`. It encodes the parity target explicitly:
//! Ubuntu 24.04 + GNOME Files / Nautilus must reproduce the current macOS
//! behavior under `apps/macos` rather than invent Linux-specific product rules.

pub mod adapter;
pub mod backends;
pub mod error;
pub mod geometry;
pub mod probes;
pub mod target;
pub mod validation;

pub use adapter::{FrontmostGate, NautilusPlatformAdapter, ResolvedHover};
pub use error::AdapterError;
pub use geometry::{Monitor, MonitorLayout, ScreenPoint, ScreenRect};
pub use probes::{
    FrontmostAppProbe,
    FrontmostAppSnapshot,
    HoverResolutionScope,
    HoveredEntityKind,
    HoveredItemProbe,
    HoveredItemSnapshot,
    MonitorProbe,
    NautilusProbeSuite,
    SessionProbe,
};
pub use target::{
    supported_surface_label,
    DisplayServerKind,
    SessionContext,
    MACOS_REFERENCE_ROOT,
    TARGET_DESKTOP,
    TARGET_DISTRO_NAME,
    TARGET_DISTRO_VERSION_PREFIX,
    TARGET_FILE_MANAGER,
};
pub use validation::{crate_slice_validation_notes, ValidationNote, ValidationStatus};
