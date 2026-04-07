use std::fmt;
#[cfg(target_os = "windows")]
use std::io::Write;
#[cfg(target_os = "windows")]
use std::process::{Command, Stdio};

use fastmd_contracts::{MonitorMetadata, ScreenPoint, ScreenRect};
use fastmd_core::select_monitor_for_anchor;
use serde::Deserialize;

/// Authoritative APIs for translating the Windows desktop into the shared
/// desktop-space model used by FastMD core placement logic.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum WindowsCoordinateApi {
    CursorPosition,
    ScreenAllScreens,
    ScreenBounds,
    ScreenWorkingArea,
    VirtualScreenBounds,
}

/// The required Windows host API stack for monitor enumeration and desktop
/// coordinate translation.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct WindowsCoordinateApiStack {
    pub cursor_position: WindowsCoordinateApi,
    pub monitor_enumerator: WindowsCoordinateApi,
    pub monitor_bounds: WindowsCoordinateApi,
    pub monitor_work_area: WindowsCoordinateApi,
    pub virtual_desktop_bounds: WindowsCoordinateApi,
}

pub static WINDOWS_COORDINATE_API_STACK: WindowsCoordinateApiStack = WindowsCoordinateApiStack {
    cursor_position: WindowsCoordinateApi::CursorPosition,
    monitor_enumerator: WindowsCoordinateApi::ScreenAllScreens,
    monitor_bounds: WindowsCoordinateApi::ScreenBounds,
    monitor_work_area: WindowsCoordinateApi::ScreenWorkingArea,
    virtual_desktop_bounds: WindowsCoordinateApi::VirtualScreenBounds,
};

#[cfg(target_os = "windows")]
const WINDOWS_COORDINATE_PROBE_SCRIPT: &str = r#"
Add-Type -AssemblyName System.Windows.Forms

function Convert-Rect {
    param([System.Drawing.Rectangle]$Rect)

    [pscustomobject]@{
        x = [double]$Rect.X
        y = [double]$Rect.Y
        width = [double]$Rect.Width
        height = [double]$Rect.Height
    }
}

$cursor = [System.Windows.Forms.Cursor]::Position
$virtualDesktop = [System.Windows.Forms.SystemInformation]::VirtualScreen
$screens = [System.Windows.Forms.Screen]::AllScreens | ForEach-Object {
    [pscustomobject]@{
        id = [string]$_.DeviceName
        name = [string]$_.DeviceName
        is_primary = [bool]$_.Primary
        scale_factor = 1.0
        frame = Convert-Rect $_.Bounds
        working_area = Convert-Rect $_.WorkingArea
    }
}

[pscustomobject]@{
    cursor = @{
        x = [double]$cursor.X
        y = [double]$cursor.Y
    }
    virtual_desktop = Convert-Rect $virtualDesktop
    monitors = @($screens)
} | ConvertTo-Json -Compress -Depth 6
"#;

#[derive(Clone, Debug, PartialEq)]
pub struct WindowsMonitorLayoutSnapshot {
    pub cursor: ScreenPoint,
    pub monitors: Vec<MonitorMetadata>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct WindowsCoordinateTranslation {
    pub cursor: ScreenPoint,
    pub monitors: Vec<MonitorMetadata>,
    pub selected_monitor: MonitorMetadata,
    pub api_stack: &'static WindowsCoordinateApiStack,
    pub notes: &'static str,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CoordinateProbeError {
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
    NoMonitors,
}

impl fmt::Display for CoordinateProbeError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::ProbeLaunchFailed { message } => {
                write!(f, "failed to launch Windows coordinate probe: {message}")
            }
            Self::ProbeExecutionFailed {
                status_code,
                stderr,
            } => write!(
                f,
                "Windows coordinate probe failed with status {:?}: {}",
                status_code, stderr
            ),
            Self::EmptyProbeOutput => write!(f, "Windows coordinate probe returned no JSON output"),
            Self::InvalidProbeOutput { message, .. } => {
                write!(
                    f,
                    "Windows coordinate probe returned invalid JSON: {message}"
                )
            }
            Self::NoMonitors => write!(
                f,
                "Windows coordinate probe did not return any monitors to classify"
            ),
        }
    }
}

impl std::error::Error for CoordinateProbeError {}

#[derive(Debug, Deserialize)]
struct CoordinatePayload {
    cursor: PointPayload,
    virtual_desktop: RectPayload,
    monitors: Vec<MonitorPayload>,
}

#[derive(Debug, Deserialize)]
struct MonitorPayload {
    id: String,
    #[serde(default)]
    name: Option<String>,
    frame: RectPayload,
    working_area: RectPayload,
    #[serde(default = "default_scale_factor")]
    scale_factor: f64,
    #[serde(default)]
    is_primary: bool,
}

#[derive(Debug, Deserialize)]
struct PointPayload {
    x: f64,
    y: f64,
}

#[derive(Debug, Deserialize)]
struct RectPayload {
    x: f64,
    y: f64,
    width: f64,
    height: f64,
}

pub fn parse_monitor_layout_snapshot(
    raw_output: &str,
) -> Result<WindowsMonitorLayoutSnapshot, CoordinateProbeError> {
    let trimmed_output = raw_output.trim().trim_start_matches('\u{feff}').trim();
    if trimmed_output.is_empty() {
        return Err(CoordinateProbeError::EmptyProbeOutput);
    }

    let payload: CoordinatePayload = serde_json::from_str(trimmed_output).map_err(|error| {
        CoordinateProbeError::InvalidProbeOutput {
            output: trimmed_output.to_string(),
            message: error.to_string(),
        }
    })?;

    let desktop_bottom = payload.virtual_desktop.y + payload.virtual_desktop.height;
    let cursor = translate_windows_desktop_point(payload.cursor, desktop_bottom);
    let monitors = payload
        .monitors
        .into_iter()
        .map(|monitor| MonitorMetadata {
            id: monitor.id,
            name: monitor.name.filter(|value| !value.trim().is_empty()),
            frame: translate_windows_desktop_rect(monitor.frame, desktop_bottom),
            visible_frame: translate_windows_desktop_rect(monitor.working_area, desktop_bottom),
            scale_factor: monitor.scale_factor,
            is_primary: monitor.is_primary,
        })
        .collect();

    Ok(WindowsMonitorLayoutSnapshot { cursor, monitors })
}

pub fn classify_monitor_layout(
    snapshot: WindowsMonitorLayoutSnapshot,
) -> Result<WindowsCoordinateTranslation, CoordinateProbeError> {
    let selected_monitor = select_monitor_for_anchor(&snapshot.monitors, &snapshot.cursor)
        .cloned()
        .ok_or(CoordinateProbeError::NoMonitors)?;

    Ok(WindowsCoordinateTranslation {
        cursor: snapshot.cursor,
        monitors: snapshot.monitors,
        selected_monitor,
        api_stack: &WINDOWS_COORDINATE_API_STACK,
        notes: "Windows monitor bounds and work areas are translated into the shared desktop-space model, then the containing visible frame is preferred before falling back to the nearest visible frame.",
    })
}

#[cfg(target_os = "windows")]
pub fn probe_monitor_layout_snapshot() -> Result<WindowsMonitorLayoutSnapshot, CoordinateProbeError>
{
    let mut child = Command::new("powershell.exe")
        .arg("-NoProfile")
        .arg("-NonInteractive")
        .arg("-Command")
        .arg("-")
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|error| CoordinateProbeError::ProbeLaunchFailed {
            message: error.to_string(),
        })?;

    {
        let Some(mut stdin) = child.stdin.take() else {
            return Err(CoordinateProbeError::ProbeLaunchFailed {
                message: "PowerShell stdin was not available for the coordinate probe.".to_string(),
            });
        };

        stdin
            .write_all(WINDOWS_COORDINATE_PROBE_SCRIPT.as_bytes())
            .and_then(|_| stdin.flush())
            .map_err(|error| CoordinateProbeError::ProbeLaunchFailed {
                message: error.to_string(),
            })?;
    }

    let output =
        child
            .wait_with_output()
            .map_err(|error| CoordinateProbeError::ProbeLaunchFailed {
                message: error.to_string(),
            })?;

    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(CoordinateProbeError::ProbeExecutionFailed {
            status_code: output.status.code(),
            stderr: if stderr.is_empty() {
                "PowerShell exited without stderr output.".to_string()
            } else {
                stderr
            },
        });
    }

    parse_monitor_layout_snapshot(&String::from_utf8_lossy(&output.stdout))
}

fn default_scale_factor() -> f64 {
    1.0
}

fn translate_windows_desktop_point(point: PointPayload, desktop_bottom: f64) -> ScreenPoint {
    ScreenPoint::new(point.x, desktop_bottom - point.y)
}

fn translate_windows_desktop_rect(rect: RectPayload, desktop_bottom: f64) -> ScreenRect {
    ScreenRect::new(
        rect.x,
        desktop_bottom - (rect.y + rect.height),
        rect.width,
        rect.height,
    )
}

#[cfg(test)]
mod tests {
    use super::{
        classify_monitor_layout, parse_monitor_layout_snapshot, CoordinateProbeError,
        WindowsCoordinateApi, WINDOWS_COORDINATE_API_STACK,
    };

    #[test]
    fn authoritative_windows_coordinate_api_stack_is_explicit() {
        assert_eq!(
            WINDOWS_COORDINATE_API_STACK.cursor_position,
            WindowsCoordinateApi::CursorPosition
        );
        assert_eq!(
            WINDOWS_COORDINATE_API_STACK.monitor_enumerator,
            WindowsCoordinateApi::ScreenAllScreens
        );
        assert_eq!(
            WINDOWS_COORDINATE_API_STACK.monitor_bounds,
            WindowsCoordinateApi::ScreenBounds
        );
        assert_eq!(
            WINDOWS_COORDINATE_API_STACK.monitor_work_area,
            WindowsCoordinateApi::ScreenWorkingArea
        );
        assert_eq!(
            WINDOWS_COORDINATE_API_STACK.virtual_desktop_bounds,
            WindowsCoordinateApi::VirtualScreenBounds
        );
    }

    #[test]
    fn parser_translates_windows_desktop_coordinates_into_shared_space() {
        let snapshot = parse_monitor_layout_snapshot(
            r#"{
                "cursor":{"x":120.0,"y":100.0},
                "virtual_desktop":{"x":-1920.0,"y":0.0,"width":3840.0,"height":1080.0},
                "monitors":[
                    {
                        "id":"\\\\.\\DISPLAY1",
                        "name":"\\\\.\\DISPLAY1",
                        "is_primary":true,
                        "scale_factor":1.0,
                        "frame":{"x":0.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":0.0,"y":0.0,"width":1920.0,"height":1040.0}
                    },
                    {
                        "id":"\\\\.\\DISPLAY2",
                        "name":"\\\\.\\DISPLAY2",
                        "is_primary":false,
                        "scale_factor":1.0,
                        "frame":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1040.0}
                    }
                ]
            }"#,
        )
        .expect("valid coordinate probe JSON should parse");

        assert_eq!(snapshot.cursor.x, 120.0);
        assert_eq!(snapshot.cursor.y, 980.0);
        assert_eq!(snapshot.monitors.len(), 2);
        assert_eq!(snapshot.monitors[0].frame.y, 0.0);
        assert_eq!(snapshot.monitors[0].visible_frame.y, 40.0);
        assert_eq!(snapshot.monitors[1].frame.x, -1920.0);
    }

    #[test]
    fn classifier_prefers_the_monitor_whose_visible_frame_contains_the_cursor() {
        let snapshot = parse_monitor_layout_snapshot(
            r#"{
                "cursor":{"x":-240.0,"y":100.0},
                "virtual_desktop":{"x":-1920.0,"y":0.0,"width":3840.0,"height":1080.0},
                "monitors":[
                    {
                        "id":"right",
                        "name":"right",
                        "is_primary":true,
                        "scale_factor":1.0,
                        "frame":{"x":0.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":0.0,"y":0.0,"width":1920.0,"height":1040.0}
                    },
                    {
                        "id":"left",
                        "name":"left",
                        "is_primary":false,
                        "scale_factor":1.0,
                        "frame":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1040.0}
                    }
                ]
            }"#,
        )
        .expect("valid coordinate probe JSON should parse");

        let translation =
            classify_monitor_layout(snapshot).expect("a containing monitor should be selected");

        assert_eq!(translation.selected_monitor.id, "left");
        assert_eq!(
            translation.api_stack.monitor_work_area,
            WindowsCoordinateApi::ScreenWorkingArea
        );
    }

    #[test]
    fn classifier_falls_back_to_the_nearest_visible_frame() {
        let snapshot = parse_monitor_layout_snapshot(
            r#"{
                "cursor":{"x":120.0,"y":1070.0},
                "virtual_desktop":{"x":-1920.0,"y":0.0,"width":3840.0,"height":1080.0},
                "monitors":[
                    {
                        "id":"left",
                        "name":"left",
                        "is_primary":false,
                        "scale_factor":1.0,
                        "frame":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":-1920.0,"y":0.0,"width":1920.0,"height":1040.0}
                    },
                    {
                        "id":"right",
                        "name":"right",
                        "is_primary":true,
                        "scale_factor":1.0,
                        "frame":{"x":0.0,"y":0.0,"width":1920.0,"height":1080.0},
                        "working_area":{"x":0.0,"y":0.0,"width":1920.0,"height":1040.0}
                    }
                ]
            }"#,
        )
        .expect("valid coordinate probe JSON should parse");

        let translation = classify_monitor_layout(snapshot)
            .expect("the nearest visible frame should be selected");

        assert_eq!(translation.cursor.y, 10.0);
        assert_eq!(translation.selected_monitor.id, "right");
    }

    #[test]
    fn parser_rejects_invalid_json() {
        let error = parse_monitor_layout_snapshot("not json")
            .expect_err("invalid coordinate probe JSON must stay rejected");

        assert!(matches!(
            error,
            CoordinateProbeError::InvalidProbeOutput { .. }
        ));
    }

    #[test]
    fn classifier_rejects_empty_monitor_lists() {
        let snapshot = parse_monitor_layout_snapshot(
            r#"{
                "cursor":{"x":120.0,"y":100.0},
                "virtual_desktop":{"x":0.0,"y":0.0,"width":1920.0,"height":1080.0},
                "monitors":[]
            }"#,
        )
        .expect("empty monitor lists still parse as a snapshot");

        let error = classify_monitor_layout(snapshot)
            .expect_err("an empty monitor set cannot be classified");
        assert_eq!(error, CoordinateProbeError::NoMonitors);
    }
}
