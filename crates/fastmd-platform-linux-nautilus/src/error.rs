use std::error::Error;
use std::fmt;

/// Errors returned by the Ubuntu/Nautilus adapter boundary.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AdapterError {
    /// The observed host surface is outside the Stage 2 Linux scope.
    UnsupportedTargetSurface {
        distro_name: String,
        distro_version: String,
        desktop: String,
    },
    /// A host probe failed while gathering adapter input.
    ProbeFailure {
        probe: &'static str,
        detail: String,
    },
}

impl fmt::Display for AdapterError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedTargetSurface {
                distro_name,
                distro_version,
                desktop,
            } => write!(
                f,
                "unsupported target surface: distro={distro_name}, version={distro_version}, desktop={desktop}"
            ),
            Self::ProbeFailure { probe, detail } => {
                write!(f, "probe failure in {probe}: {detail}")
            }
        }
    }
}

impl Error for AdapterError {}
