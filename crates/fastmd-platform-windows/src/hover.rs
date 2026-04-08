use std::fmt;
use std::path::PathBuf;
#[cfg(target_os = "windows")]
use std::{
    io::Write,
    process::{Command, Stdio},
};

use fastmd_contracts::{FrontSurface, HoverResolutionScope, MACOS_REFERENCE_BEHAVIOR, ScreenPoint};
use serde::Deserialize;

use crate::filter::{
    AcceptedMarkdownPath, HoverCandidate, HoverCandidateRejection, HoverCandidateSource,
    WindowsMarkdownFilter,
};

/// Authoritative APIs for resolving the actual Explorer item under the pointer
/// instead of using nearby or first-visible heuristics.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WindowsHoverApi {
    ElementFromPoint,
    ControlViewWalker,
    CurrentName,
    IShellWindows,
    IWebBrowserAppHwnd,
    FolderParseName,
    FolderItemPath,
}

/// The required Windows host API stack for exact Explorer hovered-item
/// resolution.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WindowsHoverApiStack {
    pub element_from_point: WindowsHoverApi,
    pub ancestor_walk: WindowsHoverApi,
    pub element_name: WindowsHoverApi,
    pub shell_windows_enumerator: WindowsHoverApi,
    pub explorer_hwnd_bridge: WindowsHoverApi,
    pub folder_parse_name: WindowsHoverApi,
    pub folder_item_path: WindowsHoverApi,
}

pub static WINDOWS_HOVER_API_STACK: WindowsHoverApiStack = WindowsHoverApiStack {
    element_from_point: WindowsHoverApi::ElementFromPoint,
    ancestor_walk: WindowsHoverApi::ControlViewWalker,
    element_name: WindowsHoverApi::CurrentName,
    shell_windows_enumerator: WindowsHoverApi::IShellWindows,
    explorer_hwnd_bridge: WindowsHoverApi::IWebBrowserAppHwnd,
    folder_parse_name: WindowsHoverApi::FolderParseName,
    folder_item_path: WindowsHoverApi::FolderItemPath,
};

#[cfg(target_os = "windows")]
const WINDOWS_HOVER_PROBE_TEMPLATE: &str = r#"
$CursorX = [double]__CURSOR_X__
$CursorY = [double]__CURSOR_Y__
$ExpectedShellWindowId = __SHELL_WINDOW_ID__
$FrontDirectory = __FRONT_DIRECTORY__

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName WindowsBase

function New-HoverPayload {
    param(
        [string]$ResolutionScope,
        [string]$Backend,
        [string]$Path,
        [string]$UnsupportedDescription,
        [string]$ElementName
    )

    [pscustomobject]@{
        resolution_scope = $ResolutionScope
        backend = $Backend
        path = if ([string]::IsNullOrWhiteSpace($Path)) { $null } else { $Path }
        unsupported_description = if ([string]::IsNullOrWhiteSpace($UnsupportedDescription)) { $null } else { $UnsupportedDescription }
        element_name = if ([string]::IsNullOrWhiteSpace($ElementName)) { $null } else { $ElementName }
        shell_window_id = if ([string]::IsNullOrWhiteSpace($ExpectedShellWindowId)) { $null } else { $ExpectedShellWindowId }
    } | ConvertTo-Json -Compress -Depth 4
}

function Test-IsExplorerItemControlType {
    param([System.Windows.Automation.AutomationElement]$Element)

    if ($null -eq $Element) {
        return $false
    }

    $controlType = $Element.Current.ControlType
    return (
        ($controlType -eq [System.Windows.Automation.ControlType]::ListItem) -or
        ($controlType -eq [System.Windows.Automation.ControlType]::DataItem)
    )
}

function Resolve-ExplorerListItem {
    param([System.Windows.Automation.AutomationElement]$StartElement)

    if (Test-IsExplorerItemControlType $StartElement) {
        return @{
            item = $StartElement
            scope = 'exact-item-under-pointer'
        }
    }

    $walker = [System.Windows.Automation.TreeWalker]::ControlViewWalker
    $current = $StartElement

    while ($null -ne $current) {
        $current = $walker.GetParent($current)
        if (Test-IsExplorerItemControlType $current) {
            return @{
                item = $current
                scope = 'hovered-row-descendant'
            }
        }
    }

    return $null
}

$shellApplication = New-Object -ComObject Shell.Application
$shellWindows = $shellApplication.Windows()
$matchedShellWindow = $null
$folderItem = $null

try {
    foreach ($candidate in @($shellWindows)) {
        if ($null -eq $candidate) {
            continue
        }

        try {
            $candidateWindowId = ('hwnd:0x{0:X}' -f ([uint64]([int64]$candidate.HWND)))
            if ($candidateWindowId -eq $ExpectedShellWindowId) {
                $matchedShellWindow = $candidate
                break
            }
        } catch {
            continue
        }
    }

    if ($null -eq $matchedShellWindow) {
        throw "ShellWindows did not contain the expected Explorer HWND $ExpectedShellWindowId."
    }

    try {
        $point = New-Object System.Windows.Point($CursorX, $CursorY)
        $element = [System.Windows.Automation.AutomationElement]::FromPoint($point)
    } catch {
        throw "UI Automation ElementFromPoint failed at ($CursorX,$CursorY): $($_.Exception.Message)"
    }

    if ($null -eq $element) {
        Write-Output (New-HoverPayload `
            -ResolutionScope 'exact-item-under-pointer' `
            -Backend 'uiautomation-element-from-point+shell-parse-name' `
            -UnsupportedDescription 'UI Automation returned no element for the pointer location.')
        return
    }

    $resolved = Resolve-ExplorerListItem $element
    $exactName = $null

    try {
        $exactName = [string]$element.Current.Name
    } catch {
    }

    if ($null -eq $resolved) {
        Write-Output (New-HoverPayload `
            -ResolutionScope 'exact-item-under-pointer' `
            -Backend 'uiautomation-element-from-point+shell-parse-name' `
            -UnsupportedDescription 'Pointer did not resolve to an Explorer list item or hovered-row descendant.' `
            -ElementName $exactName)
        return
    }

    $itemElement = $resolved.item
    $resolutionScope = [string]$resolved.scope
    $elementName = [string]$itemElement.Current.Name

    if ([string]::IsNullOrWhiteSpace($elementName)) {
        Write-Output (New-HoverPayload `
            -ResolutionScope $resolutionScope `
            -Backend 'uiautomation-element-from-point+shell-parse-name' `
            -UnsupportedDescription 'Explorer item resolved from the pointer did not expose a usable name.')
        return
    }

    $resolvedPath = $null

    try {
        $folder = $matchedShellWindow.Document.Folder
        if ($null -ne $folder) {
            $folderItem = $folder.ParseName($elementName)
        }
    } catch {
    }

    if ($null -ne $folderItem) {
        try {
            $candidatePath = [string]$folderItem.Path
            if (-not [string]::IsNullOrWhiteSpace($candidatePath)) {
                $resolvedPath = $candidatePath
            }
        } catch {
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedPath) -and -not [string]::IsNullOrWhiteSpace($FrontDirectory)) {
        try {
            $resolvedPath = Join-Path -Path $FrontDirectory -ChildPath $elementName
        } catch {
        }
    }

    if ([string]::IsNullOrWhiteSpace($resolvedPath)) {
        Write-Output (New-HoverPayload `
            -ResolutionScope $resolutionScope `
            -Backend 'uiautomation-element-from-point+shell-parse-name' `
            -UnsupportedDescription 'Explorer item name could not be converted into an absolute filesystem path.' `
            -ElementName $elementName)
        return
    }

    Write-Output (New-HoverPayload `
        -ResolutionScope $resolutionScope `
        -Backend 'uiautomation-element-from-point+shell-parse-name' `
        -Path $resolvedPath `
        -ElementName $elementName)
} finally {
    if ($null -ne $folderItem) {
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($folderItem)
    }
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
pub enum HoverProbeError {
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
    InvalidFrontSurfaceContext {
        message: String,
    },
}

impl fmt::Display for HoverProbeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ProbeLaunchFailed { message } => {
                write!(f, "failed to launch Windows hover probe: {message}")
            }
            Self::ProbeExecutionFailed {
                status_code,
                stderr,
            } => write!(
                f,
                "Windows hover probe failed with status {:?}: {}",
                status_code, stderr
            ),
            Self::EmptyProbeOutput => write!(f, "Windows hover probe returned no JSON output"),
            Self::InvalidProbeOutput { message, .. } => {
                write!(f, "Windows hover probe returned invalid JSON: {message}")
            }
            Self::InvalidFrontSurfaceContext { message } => {
                write!(
                    f,
                    "Windows hover probe requires Explorer surface context: {message}"
                )
            }
        }
    }
}

impl std::error::Error for HoverProbeError {}

/// Snapshot of the exact or hovered-row Explorer item the Windows lane resolved
/// from the pointer.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HoveredExplorerItemSnapshot {
    pub candidate: HoverCandidate,
    pub resolution_scope: HoverResolutionScope,
    pub backend: String,
    pub element_name: Option<String>,
    pub shell_window_id: Option<String>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum HoveredItemResolutionRejection {
    InsufficientEvidence { scope: HoverResolutionScope },
    CandidateRejected { rejection: HoverCandidateRejection },
}

impl fmt::Display for HoveredItemResolutionRejection {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InsufficientEvidence { scope } => write!(
                f,
                "hovered Explorer item used a non-parity resolution scope: {scope:?}"
            ),
            Self::CandidateRejected { rejection } => rejection.fmt(f),
        }
    }
}

impl std::error::Error for HoveredItemResolutionRejection {}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct HoveredItemProbeOutcome {
    pub snapshot: HoveredExplorerItemSnapshot,
    pub accepted: Option<AcceptedMarkdownPath>,
    pub rejection: Option<HoveredItemResolutionRejection>,
    pub api_stack: &'static WindowsHoverApiStack,
    pub notes: &'static str,
}

#[derive(Debug, Deserialize)]
struct HoveredExplorerItemSnapshotPayload {
    resolution_scope: HoverResolutionScope,
    backend: String,
    #[serde(default)]
    path: Option<String>,
    #[serde(default)]
    unsupported_description: Option<String>,
    #[serde(default)]
    element_name: Option<String>,
    #[serde(default)]
    shell_window_id: Option<String>,
}

pub fn parse_hovered_item_snapshot(
    raw_output: &str,
) -> Result<HoveredExplorerItemSnapshot, HoverProbeError> {
    let trimmed_output = raw_output.trim().trim_start_matches('\u{feff}').trim();
    if trimmed_output.is_empty() {
        return Err(HoverProbeError::EmptyProbeOutput);
    }

    let payload: HoveredExplorerItemSnapshotPayload = serde_json::from_str(trimmed_output)
        .map_err(|error| HoverProbeError::InvalidProbeOutput {
            output: trimmed_output.to_string(),
            message: error.to_string(),
        })?;

    let HoveredExplorerItemSnapshotPayload {
        resolution_scope,
        backend,
        path,
        unsupported_description,
        element_name,
        shell_window_id,
    } = payload;

    let candidate = if let Some(path) = path.filter(|path| !path.trim().is_empty()) {
        HoverCandidate::LocalPath {
            path: PathBuf::from(path),
            source: HoverCandidateSource::ExplorerShellItem,
        }
    } else {
        let description = unsupported_description
            .filter(|value| !value.trim().is_empty())
            .or_else(|| {
                element_name
                    .as_ref()
                    .map(|name| format!("unsupported Explorer hover target: {name}"))
            })
            .unwrap_or_else(|| "unsupported Explorer hover target".to_string());

        HoverCandidate::UnsupportedItem {
            description,
            source: HoverCandidateSource::ExplorerUiAutomation,
        }
    };

    Ok(HoveredExplorerItemSnapshot {
        candidate,
        resolution_scope,
        backend,
        element_name: element_name.filter(|value| !value.trim().is_empty()),
        shell_window_id: shell_window_id.filter(|value| !value.trim().is_empty()),
    })
}

pub fn classify_hovered_item_snapshot(
    snapshot: HoveredExplorerItemSnapshot,
    filter: &WindowsMarkdownFilter,
) -> HoveredItemProbeOutcome {
    let resolution_scope = snapshot.resolution_scope;

    if !MACOS_REFERENCE_BEHAVIOR
        .hover_resolution
        .accepts_scope(resolution_scope)
    {
        return HoveredItemProbeOutcome {
            snapshot,
            accepted: None,
            rejection: Some(HoveredItemResolutionRejection::InsufficientEvidence {
                scope: resolution_scope,
            }),
            api_stack: &WINDOWS_HOVER_API_STACK,
            notes: "The Windows hover pipeline rejects nearby and first-visible fallbacks so Explorer hover resolution stays anchored to the actual pointer target.",
        };
    }

    match filter.accept_candidate(snapshot.candidate.clone()) {
        Ok(accepted) => HoveredItemProbeOutcome {
            snapshot,
            accepted: Some(accepted),
            rejection: None,
            api_stack: &WINDOWS_HOVER_API_STACK,
            notes: "The Windows hover pipeline accepts only exact-item or hovered-row evidence, then reuses the shared local-Markdown file filter before FastMD opens a preview.",
        },
        Err(rejection) => HoveredItemProbeOutcome {
            snapshot,
            accepted: None,
            rejection: Some(HoveredItemResolutionRejection::CandidateRejected { rejection }),
            api_stack: &WINDOWS_HOVER_API_STACK,
            notes: "The Windows hover pipeline keeps unsupported entities, stale paths, directories, and non-Markdown files out of FastMD before preview open.",
        },
    }
}

#[cfg(target_os = "windows")]
pub fn probe_hovered_item_snapshot(
    front_surface: &FrontSurface,
    cursor: ScreenPoint,
) -> Result<HoveredExplorerItemSnapshot, HoverProbeError> {
    let Some(shell_window_id) = front_surface
        .stable_identity()
        .map(|identity| identity.native_window_id.as_str())
    else {
        return Err(HoverProbeError::InvalidFrontSurfaceContext {
            message: "missing stable Explorer shell window id".to_string(),
        });
    };

    let Some(front_directory) = front_surface.directory.as_ref().map(|path| path.as_str()) else {
        return Err(HoverProbeError::InvalidFrontSurfaceContext {
            message: "missing frontmost Explorer directory".to_string(),
        });
    };

    let script = build_hover_probe_script(cursor, shell_window_id, front_directory);
    let mut child = Command::new("powershell.exe")
        .arg("-NoProfile")
        .arg("-NonInteractive")
        .arg("-Command")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| HoverProbeError::ProbeLaunchFailed {
            message: error.to_string(),
        })?;

    {
        let Some(mut stdin) = child.stdin.take() else {
            return Err(HoverProbeError::ProbeLaunchFailed {
                message: "PowerShell stdin was not available for the hover probe.".to_string(),
            });
        };

        stdin
            .write_all(script.as_bytes())
            .and_then(|_| stdin.flush())
            .map_err(|error| HoverProbeError::ProbeLaunchFailed {
                message: error.to_string(),
            })?;
    }

    let output = child
        .wait_with_output()
        .map_err(|error| HoverProbeError::ProbeLaunchFailed {
            message: error.to_string(),
        })?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(HoverProbeError::ProbeExecutionFailed {
            status_code: output.status.code(),
            stderr: if stderr.is_empty() {
                "PowerShell exited without stderr output.".to_string()
            } else {
                stderr
            },
        });
    }

    parse_hovered_item_snapshot(&String::from_utf8_lossy(&output.stdout))
}

#[cfg(target_os = "windows")]
fn build_hover_probe_script(
    cursor: ScreenPoint,
    shell_window_id: &str,
    front_directory: &str,
) -> String {
    WINDOWS_HOVER_PROBE_TEMPLATE
        .replace("__CURSOR_X__", &cursor.x.to_string())
        .replace("__CURSOR_Y__", &cursor.y.to_string())
        .replace(
            "__SHELL_WINDOW_ID__",
            &powershell_single_quoted(shell_window_id),
        )
        .replace(
            "__FRONT_DIRECTORY__",
            &powershell_single_quoted(front_directory),
        )
}

#[cfg(target_os = "windows")]
fn powershell_single_quoted(value: &str) -> String {
    format!("'{}'", value.replace('\'', "''"))
}

#[cfg(test)]
mod tests {
    use super::{
        HoverProbeError, HoveredExplorerItemSnapshot, HoveredItemResolutionRejection,
        WINDOWS_HOVER_API_STACK, WindowsHoverApi, WindowsHoverApiStack,
        classify_hovered_item_snapshot, parse_hovered_item_snapshot,
    };
    use crate::filter::{
        HoverCandidate, HoverCandidateRejection, HoverCandidateSource, WindowsMarkdownFilter,
    };
    use fastmd_contracts::HoverResolutionScope;
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    #[derive(Debug)]
    struct TempFixture {
        root: PathBuf,
    }

    impl TempFixture {
        fn new() -> Self {
            let nonce = SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .expect("system time should be after unix epoch")
                .as_nanos();
            let root = std::env::temp_dir().join(format!(
                "fastmd-platform-windows-hover-{nonce}-{}",
                std::process::id()
            ));
            fs::create_dir_all(&root).expect("temp directory should be created");
            Self { root }
        }

        fn write_file(&self, relative_path: impl AsRef<Path>, contents: &str) -> PathBuf {
            let path = self.root.join(relative_path);
            fs::write(&path, contents).expect("temp file should be written");
            path
        }
    }

    impl Drop for TempFixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }

    fn classify(snapshot: HoveredExplorerItemSnapshot) -> super::HoveredItemProbeOutcome {
        classify_hovered_item_snapshot(snapshot, &WindowsMarkdownFilter)
    }

    #[test]
    fn authoritative_windows_hover_api_stack_is_explicit() {
        let stack: WindowsHoverApiStack = WINDOWS_HOVER_API_STACK;

        assert_eq!(stack.element_from_point, WindowsHoverApi::ElementFromPoint);
        assert_eq!(stack.ancestor_walk, WindowsHoverApi::ControlViewWalker);
        assert_eq!(stack.element_name, WindowsHoverApi::CurrentName);
        assert_eq!(
            stack.shell_windows_enumerator,
            WindowsHoverApi::IShellWindows
        );
        assert_eq!(
            stack.explorer_hwnd_bridge,
            WindowsHoverApi::IWebBrowserAppHwnd
        );
        assert_eq!(stack.folder_parse_name, WindowsHoverApi::FolderParseName);
        assert_eq!(stack.folder_item_path, WindowsHoverApi::FolderItemPath);
    }

    #[test]
    fn parses_exact_hover_json_into_a_shell_item_candidate() {
        let snapshot = parse_hovered_item_snapshot(
            r#"{
                "resolution_scope":"exact-item-under-pointer",
                "backend":"uiautomation-element-from-point+shell-parse-name",
                "path":"C:\\Users\\example\\Docs\\notes.md",
                "element_name":"notes.md",
                "shell_window_id":"hwnd:0x10001"
            }"#,
        )
        .expect("hover probe JSON should parse");

        assert_eq!(
            snapshot.resolution_scope,
            HoverResolutionScope::ExactItemUnderPointer
        );
        assert_eq!(
            snapshot.candidate,
            HoverCandidate::LocalPath {
                path: PathBuf::from(r"C:\Users\example\Docs\notes.md"),
                source: HoverCandidateSource::ExplorerShellItem,
            }
        );
        assert_eq!(snapshot.element_name.as_deref(), Some("notes.md"));
        assert_eq!(snapshot.shell_window_id.as_deref(), Some("hwnd:0x10001"));
    }

    #[test]
    fn parses_unsupported_hover_json_into_a_ui_automation_candidate() {
        let snapshot = parse_hovered_item_snapshot(
            r#"{
                "resolution_scope":"exact-item-under-pointer",
                "backend":"uiautomation-element-from-point+shell-parse-name",
                "unsupported_description":"Pointer did not resolve to an Explorer list item.",
                "element_name":"Address"
            }"#,
        )
        .expect("unsupported hover JSON should parse");

        assert_eq!(
            snapshot.candidate,
            HoverCandidate::UnsupportedItem {
                description: "Pointer did not resolve to an Explorer list item.".to_string(),
                source: HoverCandidateSource::ExplorerUiAutomation,
            }
        );
    }

    #[test]
    fn hover_probe_parser_rejects_invalid_json() {
        let error = parse_hovered_item_snapshot("not json")
            .expect_err("invalid probe output should stay rejected");

        assert!(matches!(error, HoverProbeError::InvalidProbeOutput { .. }));
    }

    #[test]
    fn classifier_accepts_exact_markdown_paths() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("notes.md", "# hi");
        let outcome = classify(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: path.clone(),
                source: HoverCandidateSource::ExplorerShellItem,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            backend: "test".to_string(),
            element_name: Some("notes.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
        });

        assert_eq!(
            outcome.accepted.as_ref().map(|accepted| accepted.path()),
            Some(path.as_path())
        );
        assert!(outcome.rejection.is_none());
        assert_eq!(
            outcome.api_stack.element_from_point,
            WindowsHoverApi::ElementFromPoint
        );
    }

    #[test]
    fn classifier_accepts_hovered_row_descendants() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("descendant.MD", "# hi");
        let outcome = classify(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: path.clone(),
                source: HoverCandidateSource::ExplorerShellItem,
            },
            resolution_scope: HoverResolutionScope::HoveredRowDescendant,
            backend: "test".to_string(),
            element_name: Some("descendant.MD".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
        });

        assert_eq!(
            outcome.accepted.as_ref().map(|accepted| accepted.path()),
            Some(path.as_path())
        );
        assert!(outcome.rejection.is_none());
    }

    #[test]
    fn classifier_rejects_nearby_or_first_visible_fallbacks() {
        let fixture = TempFixture::new();
        let path = fixture.write_file("nearby.md", "# hi");

        for scope in [
            HoverResolutionScope::NearbyCandidate,
            HoverResolutionScope::FirstVisibleItem,
        ] {
            let outcome = classify(HoveredExplorerItemSnapshot {
                candidate: HoverCandidate::LocalPath {
                    path: path.clone(),
                    source: HoverCandidateSource::ExplorerShellItem,
                },
                resolution_scope: scope,
                backend: "test".to_string(),
                element_name: Some("nearby.md".to_string()),
                shell_window_id: Some("hwnd:0x10001".to_string()),
            });

            assert!(outcome.accepted.is_none());
            assert_eq!(
                outcome.rejection,
                Some(HoveredItemResolutionRejection::InsufficientEvidence { scope })
            );
        }
    }

    #[test]
    fn classifier_routes_filter_rejections_through_the_hover_pipeline() {
        let relative = classify(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::LocalPath {
                path: PathBuf::from("notes.md"),
                source: HoverCandidateSource::ExplorerShellItem,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            backend: "test".to_string(),
            element_name: Some("notes.md".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
        });
        assert_eq!(
            relative.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::RelativePath {
                    path: PathBuf::from("notes.md"),
                    source: HoverCandidateSource::ExplorerShellItem,
                },
            })
        );

        let unsupported = classify(HoveredExplorerItemSnapshot {
            candidate: HoverCandidate::UnsupportedItem {
                description: "Pointer did not resolve to an Explorer list item.".to_string(),
                source: HoverCandidateSource::ExplorerUiAutomation,
            },
            resolution_scope: HoverResolutionScope::ExactItemUnderPointer,
            backend: "test".to_string(),
            element_name: Some("Address".to_string()),
            shell_window_id: Some("hwnd:0x10001".to_string()),
        });
        assert_eq!(
            unsupported.rejection,
            Some(HoveredItemResolutionRejection::CandidateRejected {
                rejection: HoverCandidateRejection::UnsupportedItem {
                    description: "Pointer did not resolve to an Explorer list item.".to_string(),
                    source: HoverCandidateSource::ExplorerUiAutomation,
                },
            })
        );
    }
}
