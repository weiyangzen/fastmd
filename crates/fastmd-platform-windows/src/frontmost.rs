use std::fmt;
#[cfg(target_os = "windows")]
use std::io::Write;
#[cfg(target_os = "windows")]
use std::process::{Command, Stdio};

use fastmd_contracts::{
    DocumentPath, FrontSurface, FrontSurfaceIdentity, FrontSurfaceKind, PlatformId,
    WINDOWS_EXPLORER_FRONTMOST_REFERENCE,
};
use serde::Deserialize;

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

#[cfg(target_os = "windows")]
const WINDOWS_FRONTMOST_PROBE_SCRIPT: &str = r#"
$signature = @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class FastMDFrontmostNative {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();

    [DllImport("user32.dll", SetLastError=true)]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("user32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern int GetClassNameW(IntPtr hWnd, StringBuilder className, int maxCount);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern IntPtr OpenProcess(uint desiredAccess, bool inheritHandle, uint processId);

    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
    public static extern bool QueryFullProcessImageNameW(IntPtr hProcess, uint flags, StringBuilder imageName, ref uint size);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr handle);
}
'@

Add-Type -TypeDefinition $signature

$PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
$foregroundWindow = [FastMDFrontmostNative]::GetForegroundWindow()
if ($foregroundWindow -eq [IntPtr]::Zero) {
    throw "GetForegroundWindow returned a null HWND."
}

$processId = [uint32]0
[void][FastMDFrontmostNative]::GetWindowThreadProcessId($foregroundWindow, [ref]$processId)
if ($processId -eq 0) {
    throw "GetWindowThreadProcessId returned pid 0."
}

$classNameBuilder = New-Object System.Text.StringBuilder 512
$classNameLength = [FastMDFrontmostNative]::GetClassNameW(
    $foregroundWindow,
    $classNameBuilder,
    $classNameBuilder.Capacity
)
if ($classNameLength -le 0) {
    throw "GetClassNameW failed for the foreground HWND."
}

$processHandle = [FastMDFrontmostNative]::OpenProcess(
    $PROCESS_QUERY_LIMITED_INFORMATION,
    $false,
    $processId
)
if ($processHandle -eq [IntPtr]::Zero) {
    throw "OpenProcess failed for pid $processId."
}

try {
    $imageNameBuilder = New-Object System.Text.StringBuilder 4096
    $imageNameLength = [uint32]$imageNameBuilder.Capacity
    if (-not [FastMDFrontmostNative]::QueryFullProcessImageNameW(
        $processHandle,
        0,
        $imageNameBuilder,
        [ref]$imageNameLength
    )) {
        throw "QueryFullProcessImageNameW failed for pid $processId."
    }

    $processImageName = $imageNameBuilder.ToString()
} finally {
    [void][FastMDFrontmostNative]::CloseHandle($processHandle)
}

# Shell.Application.Windows() projects the same ShellWindows / IWebBrowserApp
# HWND bridge the Stage 2 blueprint requires for stable Explorer identity.
$shellApplication = New-Object -ComObject Shell.Application
$shellWindows = $shellApplication.Windows()
$matchedShellWindow = $null

try {
    foreach ($candidate in @($shellWindows)) {
        if ($null -eq $candidate) {
            continue
        }

        try {
            if ([int64]$candidate.HWND -eq $foregroundWindow.ToInt64()) {
                $matchedShellWindow = $candidate
                break
            }
        } catch {
            continue
        }
    }

    $directory = $null
    $windowTitle = $null
    $shellWindowId = $null

    if ($null -ne $matchedShellWindow) {
        $windowTitle = [string]$matchedShellWindow.LocationName
        $shellWindowId = ('hwnd:0x{0:X}' -f ([uint64]([int64]$matchedShellWindow.HWND)))

        try {
            $candidatePath = [string]$matchedShellWindow.Document.Folder.Self.Path
            if (-not [string]::IsNullOrWhiteSpace($candidatePath)) {
                $directory = $candidatePath
            }
        } catch {
        }
    }

    [pscustomobject]@{
        foreground_window_id = ('hwnd:0x{0:X}' -f ([uint64]([int64]$foregroundWindow)))
        process_id = [uint32]$processId
        process_image_name = $processImageName
        window_class = $classNameBuilder.ToString()
        window_title = if ([string]::IsNullOrWhiteSpace($windowTitle)) { $null } else { $windowTitle }
        directory = if ([string]::IsNullOrWhiteSpace($directory)) { $null } else { $directory }
        shell_window_id = if ([string]::IsNullOrWhiteSpace($shellWindowId)) { $null } else { $shellWindowId }
    } | ConvertTo-Json -Compress -Depth 3
} finally {
    if ($null -ne $matchedShellWindow) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($matchedShellWindow)
    }
    if ($null -ne $shellWindows) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shellWindows)
    }
    if ($null -ne $shellApplication) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($shellApplication)
    }
}
"#;

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum FrontmostProbeError {
    ProbeLaunchFailed {
        message: String,
    },
    ProbeExecutionFailed {
        status_code: Option<i32>,
        stderr: String,
    },
    EmptyProbeOutput,
    InvalidProbeOutput {
        output: String,
        message: String,
    },
}

impl fmt::Display for FrontmostProbeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ProbeLaunchFailed { message } => {
                write!(f, "failed to launch Windows frontmost probe: {message}")
            }
            Self::ProbeExecutionFailed {
                status_code,
                stderr,
            } => write!(
                f,
                "Windows frontmost probe failed with status {:?}: {}",
                status_code, stderr
            ),
            Self::EmptyProbeOutput => write!(f, "Windows frontmost probe returned no JSON output"),
            Self::InvalidProbeOutput { message, .. } => {
                write!(
                    f,
                    "Windows frontmost probe returned invalid JSON: {message}"
                )
            }
        }
    }
}

impl std::error::Error for FrontmostProbeError {}

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

    pub fn observed_surface(&self) -> FrontSurface {
        let matches_explorer_process = self.matches_explorer_process();
        let matches_explorer_window_class = self.matches_explorer_window_class();
        let stable_identity = self.stable_identity();

        FrontSurface {
            platform_id: PlatformId::WindowsExplorer,
            surface_kind: if matches_explorer_process && matches_explorer_window_class {
                WINDOWS_EXPLORER_FRONTMOST_REFERENCE.surface_kind
            } else {
                FrontSurfaceKind::Other
            },
            app_identifier: executable_basename(&self.process_image_name).to_string(),
            window_title: self.window_title.clone(),
            directory: self.directory.clone(),
            stable_identity: stable_identity.clone(),
            expected_host: matches_explorer_process
                && matches_explorer_window_class
                && stable_identity.is_some(),
        }
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

#[derive(Debug, Deserialize)]
struct FrontmostWindowSnapshotPayload {
    foreground_window_id: String,
    process_id: u32,
    process_image_name: String,
    window_class: String,
    #[serde(default)]
    window_title: Option<String>,
    #[serde(default)]
    directory: Option<String>,
    #[serde(default)]
    shell_window_id: Option<String>,
}

pub fn parse_frontmost_window_snapshot(
    raw_output: &str,
) -> Result<FrontmostWindowSnapshot, FrontmostProbeError> {
    let trimmed_output = raw_output.trim().trim_start_matches('\u{feff}').trim();
    if trimmed_output.is_empty() {
        return Err(FrontmostProbeError::EmptyProbeOutput);
    }

    let payload: FrontmostWindowSnapshotPayload =
        serde_json::from_str(trimmed_output).map_err(|error| {
            FrontmostProbeError::InvalidProbeOutput {
                output: trimmed_output.to_string(),
                message: error.to_string(),
            }
        })?;

    let mut snapshot = FrontmostWindowSnapshot::new(
        payload.foreground_window_id,
        payload.process_id,
        payload.process_image_name,
        payload.window_class,
    );

    if let Some(window_title) = payload
        .window_title
        .filter(|title| !title.trim().is_empty())
    {
        snapshot = snapshot.with_window_title(window_title);
    }

    if let Some(directory) = payload.directory.filter(|path| !path.trim().is_empty()) {
        snapshot = snapshot.with_directory(directory);
    }

    if let Some(shell_window_id) = payload
        .shell_window_id
        .filter(|window_id| !window_id.trim().is_empty())
    {
        snapshot = snapshot.with_shell_window_id(shell_window_id);
    }

    Ok(snapshot)
}

#[cfg(target_os = "windows")]
pub fn probe_frontmost_window_snapshot() -> Result<FrontmostWindowSnapshot, FrontmostProbeError> {
    let mut child = Command::new("powershell.exe")
        .arg("-NoProfile")
        .arg("-NonInteractive")
        .arg("-Command")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| FrontmostProbeError::ProbeLaunchFailed {
            message: error.to_string(),
        })?;

    {
        let Some(mut stdin) = child.stdin.take() else {
            return Err(FrontmostProbeError::ProbeLaunchFailed {
                message: "PowerShell stdin was not available for the frontmost probe.".to_string(),
            });
        };

        stdin
            .write_all(WINDOWS_FRONTMOST_PROBE_SCRIPT.as_bytes())
            .and_then(|_| stdin.flush())
            .map_err(|error| FrontmostProbeError::ProbeLaunchFailed {
                message: error.to_string(),
            })?;
    }

    let output =
        child
            .wait_with_output()
            .map_err(|error| FrontmostProbeError::ProbeLaunchFailed {
                message: error.to_string(),
            })?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(FrontmostProbeError::ProbeExecutionFailed {
            status_code: output.status.code(),
            stderr: if stderr.is_empty() {
                "PowerShell exited without stderr output.".to_string()
            } else {
                stderr
            },
        });
    }

    parse_frontmost_window_snapshot(&String::from_utf8_lossy(&output.stdout))
}

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

    let mut surface = snapshot.observed_surface();
    surface.app_identifier = WINDOWS_EXPLORER_FRONTMOST_REFERENCE
        .app_identifier
        .to_string();
    surface.stable_identity = Some(stable_identity);
    surface.expected_host = true;

    Ok(surface)
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
        FrontmostProbeError, FrontmostSurfaceRejection, FrontmostWindowSnapshot,
        WINDOWS_FRONTMOST_API_STACK, WindowsFrontmostApi, parse_frontmost_window_snapshot,
        resolve_frontmost_surface,
    };
    use fastmd_contracts::{
        DocumentPath, FrontSurfaceKind, PlatformId, WINDOWS_EXPLORER_FRONTMOST_REFERENCE,
    };

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

    #[test]
    fn observed_surface_preserves_rejected_foreground_context_for_shared_core_gating() {
        let snapshot = FrontmostWindowSnapshot::new(
            "hwnd:0x10004",
            4_015,
            r"C:\Windows\explorer.exe",
            "CabinetWClass",
        )
        .with_window_title("Downloads")
        .with_directory(r"C:\Users\example\Downloads")
        .with_shell_window_id("hwnd:0x20004");

        let surface = snapshot.observed_surface();

        assert_eq!(surface.platform_id, PlatformId::WindowsExplorer);
        assert_eq!(surface.surface_kind, FrontSurfaceKind::ExplorerListView);
        assert_eq!(surface.app_identifier, "explorer.exe");
        assert_eq!(surface.window_title.as_deref(), Some("Downloads"));
        assert_eq!(
            surface.directory.as_ref().map(DocumentPath::as_str),
            Some(r"C:\Users\example\Downloads")
        );
        assert!(!surface.expected_host);
        assert!(!surface.has_stable_identity());
    }

    #[test]
    fn parses_live_probe_json_into_a_frontmost_snapshot() {
        let snapshot = parse_frontmost_window_snapshot(
            r#"{
                "foreground_window_id":"hwnd:0x10001",
                "process_id":4012,
                "process_image_name":"C:\\Windows\\explorer.exe",
                "window_class":"CabinetWClass",
                "window_title":"Docs",
                "directory":"C:\\Users\\example\\Docs",
                "shell_window_id":"hwnd:0x10001"
            }"#,
        )
        .expect("valid probe JSON should parse");

        assert_eq!(snapshot.foreground_window_id, "hwnd:0x10001");
        assert_eq!(snapshot.process_id, 4_012);
        assert_eq!(snapshot.process_image_name, r"C:\Windows\explorer.exe");
        assert_eq!(snapshot.window_class, "CabinetWClass");
        assert_eq!(snapshot.window_title.as_deref(), Some("Docs"));
        assert_eq!(
            snapshot.directory.as_ref().map(DocumentPath::as_str),
            Some(r"C:\Users\example\Docs")
        );
        assert_eq!(snapshot.shell_window_id.as_deref(), Some("hwnd:0x10001"));
    }

    #[test]
    fn rejects_invalid_probe_json_output() {
        let error = parse_frontmost_window_snapshot("not json")
            .expect_err("invalid probe output must be rejected");

        assert!(matches!(
            error,
            FrontmostProbeError::InvalidProbeOutput { .. }
        ));
    }
}
