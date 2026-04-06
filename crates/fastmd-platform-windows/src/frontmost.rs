use std::fmt;

use fastmd_contracts::{
    DocumentPath, FrontSurface, FrontSurfaceIdentity, PlatformId,
    WINDOWS_EXPLORER_FRONTMOST_REFERENCE,
};

/// Authoritative APIs for resolving the active Windows Explorer surface instead
/// of trusting a generic foreground-window check.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WindowsFrontmostApi {
    GetForegroundWindow,
    GetWindowThreadProcessId,
    QueryFullProcessImageNameW,
    GetClassNameW,
    IShellWindows,
    IWebBrowserAppHwnd,
}

/// The required Windows host API stack for frontmost Explorer gating.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WindowsFrontmostApiStack {
    pub foreground_window: WindowsFrontmostApi,
    pub foreground_process: WindowsFrontmostApi,
    pub process_image: WindowsFrontmostApi,
    pub window_class: WindowsFrontmostApi,
    pub shell_windows_enumerator: WindowsFrontmostApi,
    pub explorer_hwnd_bridge: WindowsFrontmostApi,
}

pub static WINDOWS_FRONTMOST_API_STACK: WindowsFrontmostApiStack = WindowsFrontmostApiStack {
    foreground_window: WindowsFrontmostApi::GetForegroundWindow,
    foreground_process: WindowsFrontmostApi::GetWindowThreadProcessId,
    process_image: WindowsFrontmostApi::QueryFullProcessImageNameW,
    window_class: WindowsFrontmostApi::GetClassNameW,
    shell_windows_enumerator: WindowsFrontmostApi::IShellWindows,
    explorer_hwnd_bridge: WindowsFrontmostApi::IWebBrowserAppHwnd,
};

pub const EXPLORER_WINDOW_CLASSES: [&str; 2] = ["CabinetWClass", "ExploreWClass"];

/// Snapshot of the host facts the Windows lane needs before it can say the
/// frontmost surface is really Explorer.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FrontmostWindowSnapshot {
    pub foreground_window_id: String,
    pub process_id: u32,
    pub process_image_name: String,
    pub window_class: String,
    pub window_title: Option<String>,
    pub directory: Option<DocumentPath>,
    pub shell_window_id: Option<String>,
}

impl FrontmostWindowSnapshot {
    pub fn new(
        foreground_window_id: impl Into<String>,
        process_id: u32,
        process_image_name: impl Into<String>,
        window_class: impl Into<String>,
    ) -> Self {
        Self {
            foreground_window_id: foreground_window_id.into(),
            process_id,
            process_image_name: process_image_name.into(),
            window_class: window_class.into(),
            window_title: None,
            directory: None,
            shell_window_id: None,
        }
    }

    pub fn with_window_title(mut self, window_title: impl Into<String>) -> Self {
        self.window_title = Some(window_title.into());
        self
    }

    pub fn with_directory(mut self, directory: impl Into<DocumentPath>) -> Self {
        self.directory = Some(directory.into());
        self
    }

    pub fn with_shell_window_id(mut self, shell_window_id: impl Into<String>) -> Self {
        self.shell_window_id = Some(shell_window_id.into());
        self
    }

    fn stable_identity(&self) -> Option<FrontSurfaceIdentity> {
        let shell_window_id = self.shell_window_id.as_deref()?;
        if shell_window_id != self.foreground_window_id {
            return None;
        }

        Some(FrontSurfaceIdentity::new(shell_window_id).with_process_id(self.process_id))
    }

    fn matches_explorer_process(&self) -> bool {
        executable_basename(&self.process_image_name)
            .eq_ignore_ascii_case(WINDOWS_EXPLORER_FRONTMOST_REFERENCE.app_identifier)
    }

    fn matches_explorer_window_class(&self) -> bool {
        EXPLORER_WINDOW_CLASSES
            .iter()
            .any(|class_name| self.window_class.eq_ignore_ascii_case(class_name))
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum FrontmostSurfaceRejection {
    NonExplorerProcess {
        process_image_name: String,
    },
    NonExplorerWindowClass {
        window_class: String,
    },
    MissingShellWindowMatch {
        foreground_window_id: String,
        shell_window_id: Option<String>,
    },
}

impl fmt::Display for FrontmostSurfaceRejection {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NonExplorerProcess { process_image_name } => write!(
                f,
                "foreground process is not Explorer: {process_image_name}"
            ),
            Self::NonExplorerWindowClass { window_class } => {
                write!(f, "foreground window class is not Explorer: {window_class}")
            }
            Self::MissingShellWindowMatch {
                foreground_window_id,
                shell_window_id,
            } => write!(
                f,
                "foreground window {foreground_window_id} does not match a stable Explorer shell window ({})",
                shell_window_id.as_deref().unwrap_or("<none>")
            ),
        }
    }
}

impl std::error::Error for FrontmostSurfaceRejection {}

pub fn resolve_frontmost_surface(
    snapshot: FrontmostWindowSnapshot,
) -> Result<FrontSurface, FrontmostSurfaceRejection> {
    if !snapshot.matches_explorer_process() {
        return Err(FrontmostSurfaceRejection::NonExplorerProcess {
            process_image_name: snapshot.process_image_name,
        });
    }

    if !snapshot.matches_explorer_window_class() {
        return Err(FrontmostSurfaceRejection::NonExplorerWindowClass {
            window_class: snapshot.window_class,
        });
    }

    let stable_identity = snapshot.stable_identity().ok_or_else(|| {
        FrontmostSurfaceRejection::MissingShellWindowMatch {
            foreground_window_id: snapshot.foreground_window_id.clone(),
            shell_window_id: snapshot.shell_window_id.clone(),
        }
    })?;

    Ok(FrontSurface {
        platform_id: PlatformId::WindowsExplorer,
        surface_kind: WINDOWS_EXPLORER_FRONTMOST_REFERENCE.surface_kind,
        app_identifier: WINDOWS_EXPLORER_FRONTMOST_REFERENCE
            .app_identifier
            .to_string(),
        window_title: snapshot.window_title,
        directory: snapshot.directory,
        stable_identity: Some(stable_identity),
        expected_host: true,
    })
}

fn executable_basename(process_image_name: &str) -> &str {
    process_image_name
        .rsplit(['\\', '/'])
        .next()
        .unwrap_or(process_image_name)
}

#[cfg(test)]
mod tests {
    use super::{
        FrontmostSurfaceRejection, FrontmostWindowSnapshot, WINDOWS_FRONTMOST_API_STACK,
        WindowsFrontmostApi, resolve_frontmost_surface,
    };
    use fastmd_contracts::{FrontSurfaceKind, WINDOWS_EXPLORER_FRONTMOST_REFERENCE};

    #[test]
    fn authoritative_windows_frontmost_api_stack_is_explicit() {
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.foreground_window,
            WindowsFrontmostApi::GetForegroundWindow
        );
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.foreground_process,
            WindowsFrontmostApi::GetWindowThreadProcessId
        );
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.process_image,
            WindowsFrontmostApi::QueryFullProcessImageNameW
        );
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.window_class,
            WindowsFrontmostApi::GetClassNameW
        );
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.shell_windows_enumerator,
            WindowsFrontmostApi::IShellWindows
        );
        assert_eq!(
            WINDOWS_FRONTMOST_API_STACK.explorer_hwnd_bridge,
            WindowsFrontmostApi::IWebBrowserAppHwnd
        );
    }

    #[test]
    fn resolves_a_frontmost_explorer_surface_with_a_stable_identity() {
        let surface = resolve_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10001",
                4_012,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_shell_window_id("hwnd:0x10001")
            .with_window_title("Docs")
            .with_directory(r"C:\Users\example\Docs"),
        )
        .expect("matching Explorer shell window should be accepted");

        assert_eq!(surface.surface_kind, FrontSurfaceKind::ExplorerListView);
        assert_eq!(
            surface.app_identifier,
            WINDOWS_EXPLORER_FRONTMOST_REFERENCE.app_identifier
        );
        assert!(surface.has_stable_identity());
        assert_eq!(
            surface
                .stable_identity()
                .expect("stable identity should be present")
                .native_window_id,
            "hwnd:0x10001"
        );
    }

    #[test]
    fn rejects_non_explorer_processes_even_if_the_window_class_looks_plausible() {
        let rejection = resolve_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10002",
                4_013,
                r"C:\Windows\System32\notepad.exe",
                "CabinetWClass",
            )
            .with_shell_window_id("hwnd:0x10002"),
        )
        .expect_err("non-Explorer processes must stay rejected");

        assert_eq!(
            rejection,
            FrontmostSurfaceRejection::NonExplorerProcess {
                process_image_name: r"C:\Windows\System32\notepad.exe".to_string(),
            }
        );
    }

    #[test]
    fn rejects_generic_foreground_windows_without_a_matched_shell_window_identity() {
        let rejection = resolve_frontmost_surface(
            FrontmostWindowSnapshot::new(
                "hwnd:0x10003",
                4_014,
                r"C:\Windows\explorer.exe",
                "CabinetWClass",
            )
            .with_shell_window_id("hwnd:0x20003"),
        )
        .expect_err("Explorer gating requires the shell window handle to match");

        assert_eq!(
            rejection,
            FrontmostSurfaceRejection::MissingShellWindowMatch {
                foreground_window_id: "hwnd:0x10003".to_string(),
                shell_window_id: Some("hwnd:0x20003".to_string()),
            }
        );
    }
}
