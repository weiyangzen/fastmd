use std::sync::Mutex;

use serde::Serialize;
use tauri::{
    AppHandle, Emitter, Manager, PhysicalPosition, PhysicalSize, Position, Size, State,
    WebviewWindow, WindowEvent,
};
use tauri_plugin_global_shortcut::Builder as GlobalShortcutBuilder;

const PREVIEW_WINDOW_LABEL: &str = "preview";
const SHELL_STATE_EVENT: &str = "fastmd://shell-state";
const HOST_CAPABILITIES_EVENT: &str = "fastmd://host-capabilities";
const CLOSE_REQUESTED_EVENT: &str = "fastmd://close-requested";
const WIDTH_TIERS: [u32; 4] = [560, 960, 1440, 1920];

#[derive(Clone, Copy, Serialize)]
#[serde(rename_all = "camelCase")]
enum BackgroundMode {
    White,
    Black,
}

impl BackgroundMode {
    fn toggled(self) -> Self {
        match self {
            Self::White => Self::Black,
            Self::Black => Self::White,
        }
    }
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct ShellStatePayload {
    document_title: String,
    markdown: String,
    width_tiers: [u32; 4],
    selected_width_tier_index: usize,
    background_mode: BackgroundMode,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct HostCapabilitiesPayload {
    platform_id: &'static str,
    accessibility_permission: &'static str,
    frontmost_file_manager: &'static str,
    preview_window_positioning: bool,
    global_shortcut_registered: bool,
    close_on_blur_enabled: bool,
    can_persist_preview_edits: bool,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BootstrapPayload {
    shell_state: ShellStatePayload,
    host_capabilities: HostCapabilitiesPayload,
}

#[derive(Clone, Copy, Serialize)]
#[serde(rename_all = "camelCase")]
struct ScreenPoint {
    x: f64,
    y: f64,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct PreviewGeometryPayload {
    x: i32,
    y: i32,
    width: u32,
    height: u32,
}

#[derive(Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct CloseRequestPayload {
    reason: String,
}

struct ShellBridgeState {
    shell_state: Mutex<ShellStatePayload>,
    host_capabilities: Mutex<HostCapabilitiesPayload>,
    is_editing: Mutex<bool>,
    last_anchor: Mutex<Option<ScreenPoint>>,
}

impl ShellBridgeState {
    fn new() -> Self {
        let markdown = include_str!("../../../../README.md").to_owned();
        Self {
            shell_state: Mutex::new(ShellStatePayload {
                document_title: "README.md".to_owned(),
                markdown,
                width_tiers: WIDTH_TIERS,
                selected_width_tier_index: 0,
                background_mode: BackgroundMode::White,
            }),
            host_capabilities: Mutex::new(HostCapabilitiesPayload {
                platform_id: detected_platform_id(),
                accessibility_permission: "unknown",
                frontmost_file_manager: "unknown",
                preview_window_positioning: true,
                global_shortcut_registered: true,
                close_on_blur_enabled: true,
                can_persist_preview_edits: false,
            }),
            is_editing: Mutex::new(false),
            last_anchor: Mutex::new(None),
        }
    }

    fn bootstrap_payload(&self) -> BootstrapPayload {
        BootstrapPayload {
            shell_state: self.snapshot_shell_state(),
            host_capabilities: self.snapshot_host_capabilities(),
        }
    }

    fn snapshot_shell_state(&self) -> ShellStatePayload {
        self.shell_state.lock().unwrap().clone()
    }

    fn snapshot_host_capabilities(&self) -> HostCapabilitiesPayload {
        self.host_capabilities.lock().unwrap().clone()
    }
}

fn detected_platform_id() -> &'static str {
    if cfg!(target_os = "macos") {
        "macos"
    } else if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "linux") {
        "ubuntu"
    } else {
        "shell"
    }
}

fn emit_shell_state(app: &AppHandle, state: &ShellBridgeState) -> Result<(), String> {
    app.emit(SHELL_STATE_EVENT, state.snapshot_shell_state())
        .map_err(|error| error.to_string())
}

fn emit_host_capabilities(app: &AppHandle, state: &ShellBridgeState) -> Result<(), String> {
    app.emit(HOST_CAPABILITIES_EVENT, state.snapshot_host_capabilities())
        .map_err(|error| error.to_string())
}

fn current_anchor_or_monitor_center(
    window: &WebviewWindow,
    state: &ShellBridgeState,
) -> Result<ScreenPoint, String> {
    if let Some(anchor) = *state.last_anchor.lock().unwrap() {
        return Ok(anchor);
    }

    let monitor = window
        .current_monitor()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| "No monitor is available for preview geometry.".to_owned())?;
    let monitor_position = monitor.position();
    let monitor_size = monitor.size();

    Ok(ScreenPoint {
        x: f64::from(monitor_position.x + (monitor_size.width as i32 / 2)),
        y: f64::from(monitor_position.y + (monitor_size.height as i32 / 2)),
    })
}

fn compute_preview_geometry(
    anchor: ScreenPoint,
    monitor_position: PhysicalPosition<i32>,
    monitor_size: PhysicalSize<u32>,
    requested_width: u32,
) -> PreviewGeometryPayload {
    let aspect_ratio = 4.0 / 3.0;
    let edge_inset = 12.0;
    let pointer_offset = 18.0;

    let min_x = monitor_position.x as f64 + edge_inset;
    let min_y = monitor_position.y as f64 + edge_inset;
    let available_width = (monitor_size.width as f64 - edge_inset * 2.0).max(320.0);
    let available_height = (monitor_size.height as f64 - edge_inset * 2.0).max(240.0);
    let max_fit_width = available_width.min(available_height * aspect_ratio);
    let max_fit_height = max_fit_width / aspect_ratio;

    let requested_width = requested_width as f64;
    let requested_height = requested_width / aspect_ratio;
    let width = requested_width.min(max_fit_width);
    let height = requested_height.min(max_fit_height);

    let max_x = monitor_position.x as f64 + monitor_size.width as f64 - width - edge_inset;
    let max_y = monitor_position.y as f64 + monitor_size.height as f64 - height - edge_inset;

    let mut origin_x = anchor.x + pointer_offset;
    let mut origin_y = anchor.y - height - pointer_offset;

    if origin_x > max_x {
        origin_x = anchor.x - width - pointer_offset;
    }
    if origin_x < min_x {
        origin_x = min_x;
    }
    if origin_x > max_x {
        origin_x = max_x;
    }

    if origin_y < min_y {
        origin_y = anchor.y + pointer_offset;
    }
    if origin_y > max_y {
        origin_y = max_y;
    }
    if origin_y < min_y {
        origin_y = min_y;
    }

    PreviewGeometryPayload {
        x: origin_x.round() as i32,
        y: origin_y.round() as i32,
        width: width.round() as u32,
        height: height.round() as u32,
    }
}

fn apply_preview_geometry_internal(
    window: &WebviewWindow,
    state: &ShellBridgeState,
    anchor: Option<ScreenPoint>,
) -> Result<PreviewGeometryPayload, String> {
    let monitor = window
        .current_monitor()
        .map_err(|error| error.to_string())?
        .ok_or_else(|| "No monitor is available for preview geometry.".to_owned())?;

    let effective_anchor = match anchor {
        Some(anchor) => {
            *state.last_anchor.lock().unwrap() = Some(anchor);
            anchor
        }
        None => current_anchor_or_monitor_center(window, state)?,
    };

    let requested_width = {
        let shell_state = state.shell_state.lock().unwrap();
        shell_state.width_tiers[shell_state.selected_width_tier_index]
    };

    let geometry = compute_preview_geometry(
        effective_anchor,
        *monitor.position(),
        *monitor.size(),
        requested_width,
    );

    window
        .set_size(Size::Physical(PhysicalSize::new(
            geometry.width,
            geometry.height,
        )))
        .map_err(|error| error.to_string())?;
    window
        .set_position(Position::Physical(PhysicalPosition::new(
            geometry.x, geometry.y,
        )))
        .map_err(|error| error.to_string())?;

    Ok(geometry)
}

fn reveal_preview_window(window: &WebviewWindow, state: &ShellBridgeState) -> Result<(), String> {
    let _ = apply_preview_geometry_internal(window, state, None)?;
    window.show().map_err(|error| error.to_string())?;
    window.set_focus().map_err(|error| error.to_string())
}

#[tauri::command]
fn bootstrap_shell(state: State<'_, ShellBridgeState>) -> BootstrapPayload {
    state.bootstrap_payload()
}

#[tauri::command]
fn set_editing_state(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
    editing: bool,
) -> Result<(), String> {
    *state.is_editing.lock().unwrap() = editing;
    {
        let mut host_capabilities = state.host_capabilities.lock().unwrap();
        host_capabilities.close_on_blur_enabled = !editing;
    }
    emit_host_capabilities(&app, &state)
}

#[tauri::command]
fn adjust_width_tier(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    delta: i32,
) -> Result<ShellStatePayload, String> {
    {
        let mut shell_state = state.shell_state.lock().unwrap();
        let current = shell_state.selected_width_tier_index as i32;
        let next = (current + delta).clamp(0, shell_state.width_tiers.len() as i32 - 1);
        shell_state.selected_width_tier_index = next as usize;
    }
    let _ = apply_preview_geometry_internal(&window, &state, None)?;
    emit_shell_state(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn toggle_background_mode(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
) -> Result<ShellStatePayload, String> {
    {
        let mut shell_state = state.shell_state.lock().unwrap();
        shell_state.background_mode = shell_state.background_mode.toggled();
    }
    emit_shell_state(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn replace_preview_markdown(
    app: AppHandle,
    state: State<'_, ShellBridgeState>,
    markdown: String,
) -> Result<ShellStatePayload, String> {
    {
        let mut shell_state = state.shell_state.lock().unwrap();
        shell_state.markdown = markdown;
    }
    emit_shell_state(&app, &state)?;
    Ok(state.snapshot_shell_state())
}

#[tauri::command]
fn request_preview_close(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    reason: String,
) -> Result<(), String> {
    if *state.is_editing.lock().unwrap() {
        return Ok(());
    }
    window.hide().map_err(|error| error.to_string())?;
    app.emit(
        CLOSE_REQUESTED_EVENT,
        CloseRequestPayload {
            reason: reason.clone(),
        },
    )
    .map_err(|error| error.to_string())
}

#[tauri::command]
fn apply_preview_geometry(
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
    anchor: Option<ScreenPoint>,
) -> Result<PreviewGeometryPayload, String> {
    apply_preview_geometry_internal(&window, &state, anchor)
}

#[tauri::command]
fn reveal_preview(
    app: AppHandle,
    window: WebviewWindow,
    state: State<'_, ShellBridgeState>,
) -> Result<(), String> {
    reveal_preview_window(&window, &state)?;
    emit_shell_state(&app, &state)?;
    emit_host_capabilities(&app, &state)
}

fn main() {
    let shell_state = ShellBridgeState::new();
    let global_shortcut_plugin = GlobalShortcutBuilder::new()
        .with_shortcut("CmdOrCtrl+Shift+P")
        .expect("failed to register the FastMD preview re-open shortcut")
        .with_handler(|app, _, _| {
            if let Some(window) = app.get_webview_window(PREVIEW_WINDOW_LABEL) {
                if let Some(state) = app.try_state::<ShellBridgeState>() {
                    let _ = reveal_preview_window(&window, &state);
                    let _ = emit_shell_state(app, &state);
                    let _ = emit_host_capabilities(app, &state);
                }
            }
        })
        .build();

    tauri::Builder::default()
        .manage(shell_state)
        .plugin(global_shortcut_plugin)
        .invoke_handler(tauri::generate_handler![
            bootstrap_shell,
            set_editing_state,
            adjust_width_tier,
            toggle_background_mode,
            replace_preview_markdown,
            request_preview_close,
            apply_preview_geometry,
            reveal_preview,
        ])
        .on_window_event(|window, event| {
            if window.label() != PREVIEW_WINDOW_LABEL {
                return;
            }

            if let WindowEvent::Focused(false) = event {
                let Some(state) = window.app_handle().try_state::<ShellBridgeState>() else {
                    return;
                };
                if !state
                    .host_capabilities
                    .lock()
                    .unwrap()
                    .close_on_blur_enabled
                {
                    return;
                }
                let _ = window.hide();
                let _ = window.app_handle().emit(
                    CLOSE_REQUESTED_EVENT,
                    CloseRequestPayload {
                        reason: "focus-lost".to_owned(),
                    },
                );
            }
        })
        .setup(|app| {
            let window = app
                .get_webview_window(PREVIEW_WINDOW_LABEL)
                .ok_or_else(|| std::io::Error::other("The preview window is not configured."))?;
            let state = app.state::<ShellBridgeState>();
            reveal_preview_window(&window, &state).map_err(std::io::Error::other)?;
            emit_shell_state(app.handle(), &state).map_err(std::io::Error::other)?;
            emit_host_capabilities(app.handle(), &state).map_err(std::io::Error::other)?;
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("failed to run the FastMD desktop Tauri shell");
}
