#![doc = include_str!("../README.md")]
#![forbid(unsafe_code)]

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

#[cfg(test)]
mod tests {
    use super::{MacOSAdapterState, STAGE2_REFERENCE_HOST};

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
}
