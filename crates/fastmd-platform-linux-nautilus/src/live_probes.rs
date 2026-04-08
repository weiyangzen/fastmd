use std::path::PathBuf;

#[cfg(target_os = "linux")]
use std::process::Command;

use serde::Deserialize;

use crate::adapter::FrontmostGate;
use crate::error::AdapterError;
use crate::filter::{HoverCandidateSource, LinuxMarkdownFilter};
use crate::frontmost::{api_stack_for_display_server, resolve_frontmost_surface};
use crate::geometry::ScreenPoint;
use crate::hover::{
    HoverResolutionScope, HoveredEntityKind, HoveredItemObservation, HoveredItemProbeOutcome,
    HoveredItemSnapshot, HoveredPresentationMode, build_hovered_item_snapshot,
    classify_hovered_item_snapshot,
};
use crate::probes::FrontmostAppSnapshot;
use crate::target::{DisplayServerKind, SessionContext};

const LINUX_FRONTMOST_PROBE: &str = "linux-frontmost-nautilus";
const LINUX_HOVERED_ITEM_PROBE: &str = "linux-hovered-item-nautilus";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LiveFrontmostProbe {
    pub backend: String,
    pub session: SessionContext,
    pub snapshot: FrontmostAppSnapshot,
}

pub fn live_frontmost_gate() -> Result<LiveFrontmostProbe, AdapterError> {
    let session = current_session_context()?;
    let snapshot = probe_frontmost_app(&session)?;
    let backend = match session.display_server {
        DisplayServerKind::Wayland => "live-atspi-wayland".to_owned(),
        DisplayServerKind::X11 => "live-atspi+xprop-x11".to_owned(),
    };

    Ok(LiveFrontmostProbe {
        backend,
        session,
        snapshot,
    })
}

pub fn classify_live_frontmost_gate() -> Result<(LiveFrontmostProbe, FrontmostGate), AdapterError> {
    let probe = live_frontmost_gate()?;
    let api_stack = api_stack_for_display_server(probe.session.display_server);

    let gate = match resolve_frontmost_surface(probe.session.display_server, &probe.snapshot) {
        Ok(surface) => FrontmostGate {
            session: probe.session.clone(),
            frontmost_app: probe.snapshot.clone(),
            detected_surface: Some(surface),
            rejection: None,
            api_stack,
            is_open: true,
        },
        Err(rejection) => FrontmostGate {
            session: probe.session.clone(),
            frontmost_app: probe.snapshot.clone(),
            detected_surface: None,
            rejection: Some(rejection),
            api_stack,
            is_open: false,
        },
    };

    Ok((probe, gate))
}

#[derive(Debug, Clone, PartialEq)]
pub struct LiveHoveredItemProbe {
    pub backend: String,
    pub session: SessionContext,
    pub point: ScreenPoint,
    pub observation: HoveredItemObservation,
    pub snapshot: HoveredItemSnapshot,
}

pub fn live_hovered_item(point: ScreenPoint) -> Result<Option<LiveHoveredItemProbe>, AdapterError> {
    let session = current_session_context()?;
    let Some(observation) = probe_hovered_item(&session, point)? else {
        return Ok(None);
    };
    let snapshot = build_hovered_item_snapshot(observation.clone());

    Ok(Some(LiveHoveredItemProbe {
        backend: observation.backend.clone(),
        session,
        point,
        observation,
        snapshot,
    }))
}

pub fn classify_live_hovered_item(
    point: ScreenPoint,
) -> Result<Option<(LiveHoveredItemProbe, HoveredItemProbeOutcome)>, AdapterError> {
    let Some(probe) = live_hovered_item(point)? else {
        return Ok(None);
    };
    let outcome = classify_hovered_item_snapshot(probe.snapshot.clone(), &LinuxMarkdownFilter);
    Ok(Some((probe, outcome)))
}

fn current_session_context() -> Result<SessionContext, AdapterError> {
    let os_release =
        std::fs::read_to_string("/etc/os-release").map_err(|error| AdapterError::ProbeFailure {
            probe: LINUX_FRONTMOST_PROBE,
            detail: format!("failed to read /etc/os-release: {error}"),
        })?;
    let distro_name =
        parse_os_release_field(&os_release, "NAME").unwrap_or_else(|| "Linux".to_owned());
    let distro_version =
        parse_os_release_field(&os_release, "VERSION_ID").unwrap_or_else(|| "unknown".to_owned());
    let desktop = std::env::var("XDG_CURRENT_DESKTOP")
        .ok()
        .filter(|value| !value.trim().is_empty())
        .or_else(|| std::env::var("DESKTOP_SESSION").ok())
        .unwrap_or_else(|| "unknown".to_owned());
    let display_server = match std::env::var("XDG_SESSION_TYPE").ok().as_deref() {
        Some("wayland") => DisplayServerKind::Wayland,
        Some("x11") => DisplayServerKind::X11,
        _ if std::env::var_os("WAYLAND_DISPLAY").is_some() => DisplayServerKind::Wayland,
        _ if std::env::var_os("DISPLAY").is_some() => DisplayServerKind::X11,
        _ => {
            return Err(AdapterError::ProbeFailure {
                probe: LINUX_FRONTMOST_PROBE,
                detail: "unable to resolve Linux display server from XDG_SESSION_TYPE, WAYLAND_DISPLAY, or DISPLAY".to_owned(),
            })
        }
    };

    Ok(SessionContext {
        distro_name,
        distro_version,
        desktop,
        display_server,
    })
}

fn probe_frontmost_app(session: &SessionContext) -> Result<FrontmostAppSnapshot, AdapterError> {
    let atspi = probe_atspi_frontmost(session.display_server)?;
    let mut snapshot = FrontmostAppSnapshot {
        app_id: atspi.application_id.clone(),
        desktop_entry: atspi
            .application_id
            .as_deref()
            .filter(|value| !value.trim().is_empty())
            .map(|value| format!("{value}.desktop")),
        window_class: None,
        executable: atspi.executable.clone(),
        window_title: atspi.window_title.clone(),
        process_id: atspi.process_id,
        stable_surface_id: atspi.stable_surface_id.clone(),
        focused_role_name: atspi.focused_role_name.clone(),
        focused_name: atspi.focused_name.clone(),
        focused_is_text_input: atspi.focused_is_text_input,
    };

    if session.display_server == DisplayServerKind::X11 {
        let x11 = probe_x11_window_metadata()?;
        if x11.process_id.is_some() {
            snapshot.process_id = x11.process_id;
        }
        if x11.window_title.is_some() {
            snapshot.window_title = x11.window_title;
        }
        if x11.window_class.is_some() {
            snapshot.window_class = x11.window_class;
        }
        if x11.application_id.is_some() {
            snapshot.app_id = x11.application_id.clone();
            snapshot.desktop_entry = x11.application_id.map(|value| format!("{value}.desktop"));
        }
        if x11.stable_surface_id.is_some() {
            snapshot.stable_surface_id = x11.stable_surface_id;
        }
    }

    if snapshot.executable.is_none() {
        snapshot.executable = atspi.executable;
    }

    Ok(snapshot)
}

fn probe_hovered_item(
    session: &SessionContext,
    point: ScreenPoint,
) -> Result<Option<HoveredItemObservation>, AdapterError> {
    let x = point.x.round().to_string();
    let y = point.y.round().to_string();
    let stdout = run_command(
        LINUX_HOVERED_ITEM_PROBE,
        "python3",
        &[
            "-c",
            AT_SPI_HOVERED_ITEM_PROBE_SCRIPT,
            display_server_label(session.display_server),
            &x,
            &y,
        ],
    )?;
    let Some(output) = parse_atspi_hovered_item_probe_output(&stdout)? else {
        return Ok(None);
    };

    Ok(Some(hovered_item_observation_from_probe_output(
        output,
        session.display_server,
    )))
}

fn probe_atspi_frontmost(
    display_server: DisplayServerKind,
) -> Result<AtspiFrontmostProbeOutput, AdapterError> {
    run_command(
        LINUX_FRONTMOST_PROBE,
        "python3",
        &[
            "-c",
            AT_SPI_FRONTMOST_PROBE_SCRIPT,
            display_server_label(display_server),
        ],
    )
    .and_then(|stdout| parse_atspi_frontmost_probe_output(&stdout))
}

fn probe_x11_window_metadata() -> Result<X11WindowProbeOutput, AdapterError> {
    let active_window_stdout = run_command(
        LINUX_FRONTMOST_PROBE,
        "xprop",
        &["-root", "_NET_ACTIVE_WINDOW"],
    )?;
    let window_id = parse_x11_active_window_id(&active_window_stdout).ok_or_else(|| {
        AdapterError::ProbeFailure {
            probe: LINUX_FRONTMOST_PROBE,
            detail: format!(
                "xprop did not return an _NET_ACTIVE_WINDOW id: {}",
                active_window_stdout.trim()
            ),
        }
    })?;

    let properties_stdout = run_command(
        LINUX_FRONTMOST_PROBE,
        "xprop",
        &[
            "-id",
            &window_id,
            "WM_CLASS",
            "_GTK_APPLICATION_ID",
            "_NET_WM_PID",
            "_NET_WM_NAME",
        ],
    )?;

    parse_x11_window_probe_output(&properties_stdout, &window_id)
}

fn run_command(probe: &'static str, program: &str, args: &[&str]) -> Result<String, AdapterError> {
    #[cfg(target_os = "linux")]
    {
        let output = Command::new(program).args(args).output().map_err(|error| {
            AdapterError::ProbeFailure {
                probe,
                detail: format!("{program} failed to launch: {error}"),
            }
        })?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            let stdout = String::from_utf8_lossy(&output.stdout);
            return Err(AdapterError::ProbeFailure {
                probe,
                detail: format!(
                    "{program} exited with status {}: stderr={} stdout={}",
                    output.status,
                    stderr.trim(),
                    stdout.trim()
                ),
            });
        }

        String::from_utf8(output.stdout).map_err(|error| AdapterError::ProbeFailure {
            probe,
            detail: format!("{program} returned non-UTF8 stdout: {error}"),
        })
    }

    #[cfg(not(target_os = "linux"))]
    {
        let _ = (probe, program, args);
        Err(AdapterError::ProbeFailure {
            probe,
            detail: "live Linux probe is only available when this crate is built for Linux"
                .to_owned(),
        })
    }
}

fn parse_os_release_field(contents: &str, key: &str) -> Option<String> {
    contents.lines().find_map(|line| {
        let (field, raw_value) = line.split_once('=')?;
        if field.trim() != key {
            return None;
        }

        Some(raw_value.trim().trim_matches('"').to_owned())
    })
}

fn parse_atspi_frontmost_probe_output(
    raw: &str,
) -> Result<AtspiFrontmostProbeOutput, AdapterError> {
    let probe: AtspiFrontmostProbeOutput =
        serde_json::from_str(raw).map_err(|error| AdapterError::ProbeFailure {
            probe: LINUX_FRONTMOST_PROBE,
            detail: format!("failed to parse AT-SPI frontmost JSON: {error}"),
        })?;

    if let Some(error) = probe
        .error
        .as_deref()
        .filter(|value| !value.trim().is_empty())
    {
        return Err(AdapterError::ProbeFailure {
            probe: LINUX_FRONTMOST_PROBE,
            detail: error.to_owned(),
        });
    }

    Ok(probe)
}

fn parse_atspi_hovered_item_probe_output(
    raw: &str,
) -> Result<Option<AtspiHoveredItemProbeOutput>, AdapterError> {
    let probe: AtspiHoveredItemProbeOutput =
        serde_json::from_str(raw).map_err(|error| AdapterError::ProbeFailure {
            probe: LINUX_HOVERED_ITEM_PROBE,
            detail: format!("failed to parse AT-SPI hovered-item JSON: {error}"),
        })?;

    if probe.no_hit {
        return Ok(None);
    }

    if let Some(error) = probe
        .error
        .as_deref()
        .filter(|value| !value.trim().is_empty())
    {
        return Err(AdapterError::ProbeFailure {
            probe: LINUX_HOVERED_ITEM_PROBE,
            detail: error.to_owned(),
        });
    }

    Ok(Some(probe))
}

fn hovered_item_observation_from_probe_output(
    output: AtspiHoveredItemProbeOutput,
    display_server: DisplayServerKind,
) -> HoveredItemObservation {
    let backend = hovered_item_backend(display_server).to_owned();
    let absolute_path = normalize_optional_path(output.absolute_path);
    let parent_directory = normalize_optional_path(output.parent_directory);
    let item_name = normalize_optional_string(output.item_name);
    let path_source = output
        .path_source
        .as_deref()
        .and_then(hover_candidate_source_from_label)
        .unwrap_or_else(|| default_hover_candidate_source(&absolute_path, &parent_directory));

    let mut entity_kind = output
        .entity_kind
        .as_deref()
        .and_then(hovered_entity_kind_from_label)
        .unwrap_or_else(|| {
            inferred_hovered_entity_kind(&absolute_path, &parent_directory, &item_name)
        });
    let resolution_scope = output
        .resolution_scope
        .as_deref()
        .and_then(hover_resolution_scope_from_label)
        .unwrap_or_else(|| {
            inferred_hover_resolution_scope(&absolute_path, &parent_directory, &item_name)
        });
    let presentation_mode = output
        .presentation_mode
        .as_deref()
        .and_then(hovered_presentation_mode_from_label)
        .unwrap_or_else(|| {
            inferred_hovered_presentation_mode(&absolute_path, &parent_directory, &item_name)
        });
    let unsupported_description = normalize_optional_string(output.unsupported_description)
        .or_else(|| {
            output
                .application_id
                .as_deref()
                .filter(|value| {
                    !(FrontmostAppSnapshot {
                        app_id: Some((*value).to_owned()),
                        desktop_entry: None,
                        window_class: None,
                        executable: None,
                        window_title: None,
                        process_id: None,
                        stable_surface_id: None,
                        focused_role_name: None,
                        focused_name: None,
                        focused_is_text_input: false,
                    })
                    .matches_nautilus()
                })
                .map(|value| {
                    format!("hovered AT-SPI hit-test resolved a non-Nautilus application: {value}")
                })
        });
    if unsupported_description.is_some() {
        entity_kind = HoveredEntityKind::Unsupported;
    }

    HoveredItemObservation {
        entity_kind,
        resolution_scope,
        presentation_mode,
        backend,
        absolute_path,
        parent_directory,
        item_name,
        path_source,
        visible_markdown_peer_count: output.visible_markdown_peer_count,
        unsupported_description,
    }
}

fn normalize_optional_string(raw: Option<String>) -> Option<String> {
    raw.map(|value| value.trim().to_owned())
        .filter(|value| !value.is_empty())
}

fn normalize_optional_path(raw: Option<String>) -> Option<PathBuf> {
    normalize_optional_string(raw).map(PathBuf::from)
}

fn hovered_item_backend(display_server: DisplayServerKind) -> &'static str {
    match display_server {
        DisplayServerKind::Wayland => "live-atspi-wayland-hit-test",
        DisplayServerKind::X11 => "live-atspi-x11-hit-test",
    }
}

fn hover_resolution_scope_from_label(raw: &str) -> Option<HoverResolutionScope> {
    match raw.trim() {
        "exact-item-under-pointer" => Some(HoverResolutionScope::ExactItemUnderPointer),
        "hovered-row-descendant" => Some(HoverResolutionScope::HoveredRowDescendant),
        "nearby-candidate" => Some(HoverResolutionScope::NearbyCandidate),
        "first-visible-item" => Some(HoverResolutionScope::FirstVisibleItem),
        _ => None,
    }
}

fn hovered_entity_kind_from_label(raw: &str) -> Option<HoveredEntityKind> {
    match raw.trim() {
        "file" => Some(HoveredEntityKind::File),
        "directory" => Some(HoveredEntityKind::Directory),
        "unsupported" => Some(HoveredEntityKind::Unsupported),
        _ => None,
    }
}

fn hovered_presentation_mode_from_label(raw: &str) -> Option<HoveredPresentationMode> {
    match raw.trim() {
        "list" => Some(HoveredPresentationMode::List),
        "non-list" => Some(HoveredPresentationMode::NonList),
        _ => None,
    }
}

fn hover_candidate_source_from_label(raw: &str) -> Option<HoverCandidateSource> {
    match raw.trim() {
        "atspi-path-attribute" => Some(HoverCandidateSource::AtspiPathAttribute),
        "atspi-uri-attribute" => Some(HoverCandidateSource::AtspiUriAttribute),
        "hovered-row-label+parent-directory" => {
            Some(HoverCandidateSource::HoveredRowLabelWithParentDirectory)
        }
        "validation-fixture" => Some(HoverCandidateSource::ValidationFixture),
        _ => None,
    }
}

fn default_hover_candidate_source(
    absolute_path: &Option<PathBuf>,
    parent_directory: &Option<PathBuf>,
) -> HoverCandidateSource {
    if absolute_path.is_some() {
        HoverCandidateSource::AtspiPathAttribute
    } else if parent_directory.is_some() {
        HoverCandidateSource::HoveredRowLabelWithParentDirectory
    } else {
        HoverCandidateSource::AtspiPathAttribute
    }
}

fn inferred_hovered_entity_kind(
    absolute_path: &Option<PathBuf>,
    parent_directory: &Option<PathBuf>,
    item_name: &Option<String>,
) -> HoveredEntityKind {
    if absolute_path.as_ref().is_some_and(|path| path.is_dir())
        || parent_directory
            .as_ref()
            .zip(item_name.as_ref())
            .is_some_and(|(parent, name)| parent.join(name).is_dir())
    {
        HoveredEntityKind::Directory
    } else if absolute_path.is_some() || item_name.is_some() {
        HoveredEntityKind::File
    } else {
        HoveredEntityKind::Unsupported
    }
}

fn inferred_hover_resolution_scope(
    absolute_path: &Option<PathBuf>,
    parent_directory: &Option<PathBuf>,
    item_name: &Option<String>,
) -> HoverResolutionScope {
    if absolute_path.is_some() {
        HoverResolutionScope::ExactItemUnderPointer
    } else if parent_directory.is_some() && item_name.is_some() {
        HoverResolutionScope::HoveredRowDescendant
    } else {
        HoverResolutionScope::ExactItemUnderPointer
    }
}

fn inferred_hovered_presentation_mode(
    absolute_path: &Option<PathBuf>,
    parent_directory: &Option<PathBuf>,
    item_name: &Option<String>,
) -> HoveredPresentationMode {
    if absolute_path.is_none() && parent_directory.is_some() && item_name.is_some() {
        HoveredPresentationMode::NonList
    } else {
        HoveredPresentationMode::List
    }
}

fn parse_x11_active_window_id(raw: &str) -> Option<String> {
    raw.split_once('#')
        .map(|(_, value)| value.trim())
        .filter(|value| value.starts_with("0x"))
        .map(ToOwned::to_owned)
}

fn parse_x11_window_probe_output(
    raw: &str,
    window_id: &str,
) -> Result<X11WindowProbeOutput, AdapterError> {
    let mut output = X11WindowProbeOutput {
        stable_surface_id: Some(format!("x11:{window_id}")),
        window_class: None,
        application_id: None,
        process_id: None,
        window_title: None,
    };

    for line in raw.lines().map(str::trim) {
        if let Some((_, value)) = line.split_once("_GTK_APPLICATION_ID") {
            output.application_id = parse_quoted_last_value(value);
            continue;
        }

        if let Some((_, value)) = line.split_once("WM_CLASS") {
            output.window_class = parse_quoted_last_value(value);
            continue;
        }

        if let Some((_, value)) = line.split_once("_NET_WM_PID") {
            output.process_id = value
                .split('=')
                .nth(1)
                .and_then(|raw_pid| raw_pid.trim().parse::<u32>().ok());
            continue;
        }

        if let Some((_, value)) = line.split_once("_NET_WM_NAME") {
            output.window_title = parse_quoted_last_value(value);
        }
    }

    Ok(output)
}

fn parse_quoted_last_value(raw: &str) -> Option<String> {
    raw.split('"')
        .filter(|segment| !segment.trim().is_empty() && !segment.contains('='))
        .last()
        .map(|value| value.trim().to_owned())
}

fn display_server_label(display_server: DisplayServerKind) -> &'static str {
    match display_server {
        DisplayServerKind::Wayland => "wayland",
        DisplayServerKind::X11 => "x11",
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
struct AtspiFrontmostProbeOutput {
    #[serde(default)]
    application_id: Option<String>,
    #[serde(default)]
    executable: Option<String>,
    #[serde(default)]
    process_id: Option<u32>,
    #[serde(default)]
    stable_surface_id: Option<String>,
    #[serde(default)]
    window_title: Option<String>,
    #[serde(default)]
    focused_role_name: Option<String>,
    #[serde(default)]
    focused_name: Option<String>,
    #[serde(default)]
    focused_is_text_input: bool,
    #[serde(default)]
    error: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq, Deserialize)]
struct AtspiHoveredItemProbeOutput {
    #[serde(default)]
    no_hit: bool,
    #[serde(default)]
    application_id: Option<String>,
    #[serde(default)]
    entity_kind: Option<String>,
    #[serde(default)]
    resolution_scope: Option<String>,
    #[serde(default)]
    presentation_mode: Option<String>,
    #[serde(default)]
    absolute_path: Option<String>,
    #[serde(default)]
    parent_directory: Option<String>,
    #[serde(default)]
    item_name: Option<String>,
    #[serde(default)]
    path_source: Option<String>,
    #[serde(default)]
    visible_markdown_peer_count: Option<usize>,
    #[serde(default)]
    unsupported_description: Option<String>,
    #[serde(default)]
    error: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
struct X11WindowProbeOutput {
    stable_surface_id: Option<String>,
    window_class: Option<String>,
    application_id: Option<String>,
    process_id: Option<u32>,
    window_title: Option<String>,
}

const AT_SPI_FRONTMOST_PROBE_SCRIPT: &str = r#"
import json
import os
import sys

display_server = sys.argv[1] if len(sys.argv) > 1 else "unknown"

try:
    import gi
    gi.require_version("Atspi", "2.0")
    from gi.repository import Atspi
except Exception as error:
    print(json.dumps({"error": f"failed to import gi.repository.Atspi: {error}"}))
    sys.exit(0)

def safe_call(obj, name, *args):
    if obj is None:
        return None
    method = getattr(obj, name, None)
    if not callable(method):
        return None
    try:
        return method(*args)
    except Exception:
        return None

def state_contains(accessible, state):
    state_set = safe_call(accessible, "get_state_set")
    if state_set is None:
        return False
    try:
        return bool(state_set.contains(state))
    except Exception:
        return False

def children(accessible):
    count = safe_call(accessible, "get_child_count") or 0
    try:
        count = int(count)
    except Exception:
        count = 0
    for index in range(count):
        child = safe_call(accessible, "get_child_at_index", index)
        if child is not None:
            yield child

def find_focus(accessible, depth=0):
    if accessible is None or depth > 10:
        return None
    if state_contains(accessible, Atspi.StateType.FOCUSED) or state_contains(accessible, Atspi.StateType.ACTIVE):
        return accessible
    for child in children(accessible):
        focused = find_focus(child, depth + 1)
        if focused is not None:
            return focused
    return None

def first_named_window(accessible):
    cursor = accessible
    for _ in range(16):
        role_name = (safe_call(cursor, "get_role_name") or "").lower()
        name = safe_call(cursor, "get_name")
        if name and any(token in role_name for token in ("window", "frame", "dialog")):
            return name
        parent = safe_call(cursor, "get_parent")
        if parent is None or parent == cursor:
            break
        cursor = parent
    return safe_call(accessible, "get_name")

def role_name(accessible):
    return (safe_call(accessible, "get_role_name") or "").strip().lower()

def accessible_name(accessible):
    return (safe_call(accessible, "get_name") or "").strip() or None

def focused_text_input_details(accessible):
    role = role_name(accessible)
    if not role:
        return False, None, accessible_name(accessible)

    editable = state_contains(accessible, Atspi.StateType.EDITABLE)
    explicit_text_input_role = any(
        token in role for token in ("entry", "search", "combo box", "combo_box", "password")
    )
    editable_text_role = editable and any(
        token in role for token in ("text", "label", "document")
    )

    is_text_input = explicit_text_input_role or editable_text_role
    return is_text_input, (role or None), accessible_name(accessible)

def executable_name(process_id):
    if process_id is None:
        return None
    try:
        return os.path.basename(os.readlink(f"/proc/{process_id}/exe"))
    except Exception:
        return None

Atspi.init()
desktop = Atspi.get_desktop(0)
focused = find_focus(desktop)

if focused is None:
    print(json.dumps({"error": f"no focused accessible found for {display_server}"}))
    sys.exit(0)

application = safe_call(focused, "get_application") or focused
process_id = safe_call(application, "get_process_id")
application_id = safe_call(application, "get_id")
window_title = first_named_window(focused) or safe_call(application, "get_name")
focused_name = safe_call(focused, "get_name")
stable_surface_id = safe_call(focused, "get_accessible_id")
focused_is_text_input, focused_role_name, focused_text_name = focused_text_input_details(focused)
if not stable_surface_id:
    stable_surface_id = f"atspi:{display_server}:pid={process_id or 'unknown'}:name={window_title or focused_name or 'unknown'}"

print(json.dumps({
    "application_id": application_id,
    "executable": executable_name(process_id),
    "process_id": process_id,
    "stable_surface_id": stable_surface_id,
    "window_title": window_title,
    "focused_role_name": focused_role_name,
    "focused_name": focused_text_name,
    "focused_is_text_input": focused_is_text_input,
}))
"#;

const AT_SPI_HOVERED_ITEM_PROBE_SCRIPT: &str = r#"
import json
import os
import re
import sys
from urllib.parse import unquote, urlparse

display_server = sys.argv[1] if len(sys.argv) > 1 else "unknown"
try:
    point_x = int(round(float(sys.argv[2]))) if len(sys.argv) > 2 else 0
    point_y = int(round(float(sys.argv[3]))) if len(sys.argv) > 3 else 0
except Exception:
    point_x = 0
    point_y = 0

try:
    import gi
    gi.require_version("Atspi", "2.0")
    from gi.repository import Atspi
except Exception as error:
    print(json.dumps({"error": f"failed to import gi.repository.Atspi: {error}"}))
    sys.exit(0)

def safe_call(obj, name, *args):
    if obj is None:
        return None
    method = getattr(obj, name, None)
    if not callable(method):
        return None
    try:
        return method(*args)
    except Exception:
        return None

def children(accessible):
    count = safe_call(accessible, "get_child_count") or 0
    try:
        count = int(count)
    except Exception:
        count = 0
    for index in range(count):
        child = safe_call(accessible, "get_child_at_index", index)
        if child is not None:
            yield child

def component_iface(accessible):
    return safe_call(accessible, "get_component_iface")

def contains_point(accessible, x, y):
    component = component_iface(accessible)
    if component is None:
        return False
    try:
        return bool(component.contains(x, y, Atspi.CoordType.SCREEN))
    except Exception:
        return False

def accessible_at_point(accessible, x, y):
    component = component_iface(accessible)
    if component is None:
        return None
    try:
        return component.get_accessible_at_point(x, y, Atspi.CoordType.SCREEN)
    except Exception:
        return None

def find_accessible_at_point(accessible, x, y, depth=0, visited=None):
    if accessible is None or depth > 16:
        return None
    if visited is None:
        visited = set()
    marker = id(accessible)
    if marker in visited:
        return accessible
    visited.add(marker)

    if not contains_point(accessible, x, y):
        return None

    hit = accessible_at_point(accessible, x, y)
    if hit is not None and hit != accessible:
        deeper = find_accessible_at_point(hit, x, y, depth + 1, visited)
        return deeper or hit

    for child in children(accessible):
        deeper = find_accessible_at_point(child, x, y, depth + 1, visited)
        if deeper is not None:
            return deeper

    return accessible

def ancestor_chain(accessible):
    chain = []
    cursor = accessible
    for _ in range(24):
        if cursor is None:
            break
        chain.append(cursor)
        parent = safe_call(cursor, "get_parent")
        if parent is None or parent == cursor:
            break
        cursor = parent
    return chain

def role_name(accessible):
    return (safe_call(accessible, "get_role_name") or "").strip().lower()

def accessible_name(accessible):
    return (safe_call(accessible, "get_name") or "").strip() or None

def attributes(accessible):
    raw = safe_call(accessible, "get_attributes_as_array")
    if raw is None:
        raw = safe_call(accessible, "get_attributes")
    if raw is None:
        return {}

    if isinstance(raw, dict):
        return {
            str(key).strip().lower(): str(value).strip()
            for key, value in raw.items()
            if str(value).strip()
        }

    result = {}
    for entry in raw:
        if entry is None:
            continue
        token = str(entry).strip()
        if not token:
            continue
        separator = ":" if ":" in token else "=" if "=" in token else None
        if separator is None:
            continue
        key, value = token.split(separator, 1)
        key = key.strip().lower()
        value = value.strip()
        if key and value:
            result[key] = value
    return result

def decode_path(raw):
    if raw is None:
        return None, None
    value = str(raw).strip()
    if not value:
        return None, None
    if value.startswith("file://"):
        parsed = urlparse(value)
        path = unquote(parsed.path or "")
        if path:
            return os.path.abspath(path), "atspi-uri-attribute"
        return None, None
    if value.startswith("/"):
        return os.path.abspath(os.path.expanduser(value)), "atspi-path-attribute"
    return None, None

def path_from_attributes(attrs):
    keys = (
        "uri",
        "document-uri",
        "file-uri",
        "target-uri",
        "url",
        "path",
        "file-path",
        "filepath",
        "location",
        "filename",
        "current-folder",
        "parent-directory",
        "directory",
    )
    for key in keys:
        if key not in attrs:
            continue
        path, source = decode_path(attrs.get(key))
        if path:
            return path, source
    return None, None

MARKDOWN_NAME_PATTERN = re.compile(r"(?i)([^/\n]+?\.md)\b")

def extract_markdown_name(raw):
    if raw is None:
        return None
    value = str(raw).strip()
    if not value:
        return None

    useful_lines = [line.strip() for line in value.splitlines() if line.strip()]
    first_useful_line = useful_lines[0] if useful_lines else value
    if first_useful_line.startswith("file://"):
        parsed = urlparse(first_useful_line)
        candidate = os.path.basename(unquote(parsed.path or ""))
        return candidate if candidate.lower().endswith(".md") else None
    if first_useful_line.startswith("/"):
        candidate = os.path.basename(first_useful_line)
        return candidate if candidate.lower().endswith(".md") else None

    match = MARKDOWN_NAME_PATTERN.search(first_useful_line)
    if match is not None:
        return match.group(1).strip()

    return first_useful_line if first_useful_line.lower().endswith(".md") else None

def breadth_first_elements(root, max_depth=3, max_nodes=64):
    if root is None:
        return []

    result = []
    queue = [(root, 0)]
    seen = set()
    while queue and len(result) < max_nodes:
        node, depth = queue.pop(0)
        marker = id(node)
        if marker in seen:
            continue
        seen.add(marker)
        result.append(node)
        if depth >= max_depth:
            continue
        for child in children(node):
            queue.append((child, depth + 1))

    return result

def first_path_in_elements(elements):
    for node in elements:
        path, source = path_from_attributes(attributes(node))
        if path:
            return os.path.abspath(path), source
    return None, None

def first_markdown_name_in_elements(elements):
    for node in elements:
        path, _ = path_from_attributes(attributes(node))
        if path:
            candidate = os.path.basename(path)
            if candidate.lower().endswith(".md"):
                return candidate

        candidate = extract_markdown_name(accessible_name(node))
        if candidate is not None:
            return candidate

    return None

def list_row_like(accessible):
    role = role_name(accessible)
    return any(token in role for token in ("row", "list item", "list_item", "tree item"))

def non_list_hit_like(accessible):
    role = role_name(accessible)
    return any(token in role for token in ("icon", "image", "static text", "label"))

def non_list_anchor_like(accessible):
    role = role_name(accessible)
    return any(
        token in role
        for token in (
            "icon",
            "grid",
            "gridcell",
            "grid cell",
            "table cell",
            "table_cell",
            "flow box",
            "flow_box",
            "canvas",
        )
    )

def visible_markdown_peer_count(anchor):
    if anchor is None:
        return None
    parent = safe_call(anchor, "get_parent")
    if parent is None:
        return None

    count = 0
    for child in children(parent):
        name = extract_markdown_name(accessible_name(child))
        if name is not None:
            count += 1
            continue
        for grandchild in breadth_first_elements(child, max_depth=2, max_nodes=24):
            grandchild_name = extract_markdown_name(accessible_name(grandchild))
            if grandchild_name is not None:
                count += 1
                break

    return count if count > 0 else None

Atspi.init()
desktop = Atspi.get_desktop(0)
target = None
for application in children(desktop):
    target = find_accessible_at_point(application, point_x, point_y)
    if target is not None:
        break

if target is None:
    print(json.dumps({"no_hit": True}))
    sys.exit(0)

chain = ancestor_chain(target)
application = safe_call(target, "get_application") or target
application_id = safe_call(application, "get_id") or safe_call(application, "get_name")

direct_path = None
direct_source = None
direct_depth = None
list_row_node = None
list_row_name = None
non_list_anchor = None
parent_directory = None
for depth, node in enumerate(chain):
    attrs = attributes(node)
    path, source = path_from_attributes(attrs)
    if path and direct_path is None:
        direct_path = path
        direct_source = source
        direct_depth = depth
    if parent_directory is None and path:
        candidate_directory = path if os.path.isdir(path) else os.path.dirname(path)
        if candidate_directory:
            parent_directory = os.path.abspath(candidate_directory)
    if list_row_node is None and list_row_like(node):
        list_row_node = node
        list_row_name = extract_markdown_name(accessible_name(node))
    if non_list_anchor is None and depth > 0 and non_list_anchor_like(node):
        non_list_anchor = node

presentation_anchor = list_row_node
presentation_mode = "list"
if presentation_anchor is None and non_list_hit_like(target):
    presentation_anchor = non_list_anchor or (chain[1] if len(chain) > 1 else None)
    if presentation_anchor is not None:
        presentation_mode = "non-list"
elif presentation_anchor is None and non_list_anchor is not None:
    presentation_anchor = non_list_anchor
    presentation_mode = "non-list"

derived_from_anchor = False
anchor_name = None
if presentation_anchor is not None and direct_path is None:
    anchor_subtree = breadth_first_elements(presentation_anchor, max_depth=3, max_nodes=64)
    anchor_path, anchor_source = first_path_in_elements(anchor_subtree)
    if anchor_path is not None:
        direct_path = anchor_path
        direct_source = anchor_source
        derived_from_anchor = True
    anchor_name = first_markdown_name_in_elements(anchor_subtree)
    if parent_directory is None:
        for node in anchor_subtree:
            path, _ = path_from_attributes(attributes(node))
            if path:
                candidate_directory = path if os.path.isdir(path) else os.path.dirname(path)
                if candidate_directory:
                    parent_directory = os.path.abspath(candidate_directory)
                    break

if presentation_anchor is not None and parent_directory is None:
    for node in chain:
        attrs = attributes(node)
        path, _ = path_from_attributes(attrs)
        if path:
            candidate_directory = path if os.path.isdir(path) else os.path.dirname(path)
            if candidate_directory:
                parent_directory = os.path.abspath(candidate_directory)
                break

item_name = extract_markdown_name(accessible_name(target)) or list_row_name or anchor_name
resolution_scope = "exact-item-under-pointer"
if direct_depth is not None and direct_depth > 0:
    resolution_scope = "hovered-row-descendant"
elif derived_from_anchor or (
    direct_path is None and presentation_anchor is not None and parent_directory and item_name
):
    resolution_scope = "hovered-row-descendant"

absolute_path = direct_path
path_source = direct_source or ("hovered-row-label+parent-directory" if parent_directory and item_name else None)

entity_kind = "unsupported"
unsupported_description = None
candidate_path = absolute_path or (
    os.path.abspath(os.path.join(parent_directory, item_name))
    if parent_directory and item_name
    else None
)

if candidate_path:
    entity_kind = "directory" if os.path.isdir(candidate_path) else "file"
elif item_name:
    entity_kind = "file" if item_name.lower().endswith(".md") else "unsupported"

if application_id and str(application_id).strip().lower() not in (
    "org.gnome.nautilus",
    "org.gnome.nautilus.desktop",
    "nautilus",
):
    entity_kind = "unsupported"
    unsupported_description = f"hovered AT-SPI hit-test resolved a non-Nautilus application: {application_id}"
elif candidate_path is None and not (parent_directory and item_name):
    entity_kind = "unsupported"
    unsupported_description = (
        f"hovered AT-SPI hit-test at {point_x},{point_y} did not expose a direct path "
        "or a hovered Nautilus list row / non-list anchor that could be reconstructed into a file path"
    )

print(json.dumps({
    "application_id": application_id,
    "entity_kind": entity_kind,
    "resolution_scope": resolution_scope,
    "presentation_mode": presentation_mode,
    "absolute_path": absolute_path,
    "parent_directory": parent_directory,
    "item_name": item_name,
    "path_source": path_source,
    "visible_markdown_peer_count": visible_markdown_peer_count(presentation_anchor),
    "unsupported_description": unsupported_description,
}))
"#;

#[cfg(test)]
mod tests {
    use std::fs;
    use std::path::{Path, PathBuf};
    use std::time::{SystemTime, UNIX_EPOCH};

    use super::*;

    #[test]
    fn os_release_field_parser_reads_quoted_values() {
        let raw = "NAME=\"Ubuntu\"\nVERSION_ID=\"24.04\"\n";

        assert_eq!(
            parse_os_release_field(raw, "NAME"),
            Some("Ubuntu".to_owned())
        );
        assert_eq!(
            parse_os_release_field(raw, "VERSION_ID"),
            Some("24.04".to_owned())
        );
    }

    #[test]
    fn atspi_frontmost_probe_output_parses_live_fields() {
        let raw = r#"{
  "application_id": "org.gnome.Nautilus",
  "executable": "nautilus",
  "process_id": 4201,
  "stable_surface_id": "atspi:wayland:pid=4201:name=Docs",
  "window_title": "Docs",
  "focused_role_name": "entry",
  "focused_name": "Report.md",
  "focused_is_text_input": true
}"#;

        let parsed = parse_atspi_frontmost_probe_output(raw).unwrap();

        assert_eq!(parsed.application_id, Some("org.gnome.Nautilus".to_owned()));
        assert_eq!(parsed.executable, Some("nautilus".to_owned()));
        assert_eq!(parsed.process_id, Some(4201));
        assert_eq!(parsed.focused_role_name, Some("entry".to_owned()));
        assert_eq!(parsed.focused_name, Some("Report.md".to_owned()));
        assert!(parsed.focused_is_text_input);
    }

    #[test]
    fn x11_active_window_parser_extracts_hex_window_id() {
        let raw = "_NET_ACTIVE_WINDOW(WINDOW): window id # 0x4200011\n";

        assert_eq!(
            parse_x11_active_window_id(raw),
            Some("0x4200011".to_owned())
        );
    }

    #[test]
    fn x11_property_parser_extracts_class_app_id_pid_and_title() {
        let raw = r#"
WM_CLASS(STRING) = "org.gnome.Nautilus", "org.gnome.Nautilus"
_GTK_APPLICATION_ID(STRING) = "org.gnome.Nautilus"
_NET_WM_PID(CARDINAL) = 4202
_NET_WM_NAME(UTF8_STRING) = "Projects"
"#;

        let parsed = parse_x11_window_probe_output(raw, "0x4200011").unwrap();

        assert_eq!(parsed.window_class, Some("org.gnome.Nautilus".to_owned()));
        assert_eq!(parsed.application_id, Some("org.gnome.Nautilus".to_owned()));
        assert_eq!(parsed.process_id, Some(4202));
        assert_eq!(parsed.window_title, Some("Projects".to_owned()));
        assert_eq!(parsed.stable_surface_id, Some("x11:0x4200011".to_owned()));
    }

    #[test]
    fn quoted_value_parser_prefers_the_last_string_value() {
        assert_eq!(
            parse_quoted_last_value(r#"(STRING) = "Files", "org.gnome.Nautilus""#),
            Some("org.gnome.Nautilus".to_owned())
        );
    }

    #[test]
    fn hovered_item_probe_output_parses_no_hit_as_none() {
        let raw = r#"{"no_hit": true}"#;

        let parsed = parse_atspi_hovered_item_probe_output(raw).unwrap();

        assert!(parsed.is_none());
    }

    #[test]
    fn hovered_item_probe_output_parses_live_exact_path_fields() {
        let raw = r#"{
  "application_id": "org.gnome.Nautilus",
  "entity_kind": "file",
  "resolution_scope": "exact-item-under-pointer",
  "presentation_mode": "list",
  "absolute_path": "/home/demo/third.md",
  "item_name": "third.md",
  "path_source": "atspi-path-attribute",
  "visible_markdown_peer_count": 3
}"#;

        let parsed = parse_atspi_hovered_item_probe_output(raw)
            .unwrap()
            .expect("hovered output should be present");
        let observation =
            hovered_item_observation_from_probe_output(parsed, DisplayServerKind::Wayland);

        assert_eq!(observation.entity_kind, HoveredEntityKind::File);
        assert_eq!(observation.presentation_mode, HoveredPresentationMode::List);
        assert_eq!(
            observation.resolution_scope,
            HoverResolutionScope::ExactItemUnderPointer
        );
        assert_eq!(
            observation.absolute_path,
            Some(PathBuf::from("/home/demo/third.md"))
        );
        assert_eq!(
            observation.path_source,
            HoverCandidateSource::AtspiPathAttribute
        );
    }

    #[test]
    fn hovered_item_probe_output_reconstructs_hovered_row_candidates() {
        let raw = r#"{
  "application_id": "org.gnome.Nautilus",
  "entity_kind": "file",
  "resolution_scope": "hovered-row-descendant",
  "presentation_mode": "list",
  "parent_directory": "/home/demo/Docs",
  "item_name": "third.md",
  "path_source": "hovered-row-label+parent-directory",
  "visible_markdown_peer_count": 3
}"#;

        let parsed = parse_atspi_hovered_item_probe_output(raw)
            .unwrap()
            .expect("hovered output should be present");
        let observation =
            hovered_item_observation_from_probe_output(parsed, DisplayServerKind::X11);
        let snapshot = build_hovered_item_snapshot(observation);

        assert_eq!(
            snapshot.candidate,
            crate::filter::HoverCandidate::LocalPath {
                path: PathBuf::from("/home/demo/Docs/third.md"),
                source: HoverCandidateSource::HoveredRowLabelWithParentDirectory,
            }
        );
        assert_eq!(snapshot.presentation_mode, HoveredPresentationMode::List);
    }

    #[test]
    fn hovered_item_probe_output_marks_non_list_icon_candidates() {
        let raw = r#"{
  "application_id": "org.gnome.Nautilus",
  "entity_kind": "file",
  "resolution_scope": "hovered-row-descendant",
  "presentation_mode": "non-list",
  "parent_directory": "/home/demo/Docs",
  "item_name": "Card.md",
  "path_source": "hovered-row-label+parent-directory",
  "visible_markdown_peer_count": 4
}"#;

        let parsed = parse_atspi_hovered_item_probe_output(raw)
            .unwrap()
            .expect("hovered output should be present");
        let observation =
            hovered_item_observation_from_probe_output(parsed, DisplayServerKind::Wayland);

        assert_eq!(observation.presentation_mode, HoveredPresentationMode::NonList);
        assert_eq!(observation.item_name.as_deref(), Some("Card.md"));
    }

    #[test]
    fn live_probe_output_confirms_directory_rejection_after_host_plumbing() {
        let fixture = TempFixture::new();
        let directory = fixture.create_directory("folder.md");

        let observation = hovered_item_observation_from_probe_output(
            AtspiHoveredItemProbeOutput {
                no_hit: false,
                application_id: Some("org.gnome.Nautilus".to_owned()),
                entity_kind: Some("directory".to_owned()),
                resolution_scope: Some("exact-item-under-pointer".to_owned()),
                presentation_mode: Some("list".to_owned()),
                absolute_path: Some(directory.to_string_lossy().into_owned()),
                parent_directory: None,
                item_name: Some("folder.md".to_owned()),
                path_source: Some("atspi-path-attribute".to_owned()),
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
                error: None,
            },
            DisplayServerKind::Wayland,
        );
        let outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(observation),
            &LinuxMarkdownFilter,
        );

        assert!(matches!(
            outcome.rejection,
            Some(
                crate::hover::HoveredItemResolutionRejection::CandidateRejected {
                    rejection: crate::filter::HoverCandidateRejection::Directory { .. }
                }
            )
        ));
    }

    #[test]
    fn live_probe_output_confirms_missing_path_rejection_after_host_plumbing() {
        let missing = temp_path("missing.md");

        let observation = hovered_item_observation_from_probe_output(
            AtspiHoveredItemProbeOutput {
                no_hit: false,
                application_id: Some("org.gnome.Nautilus".to_owned()),
                entity_kind: Some("file".to_owned()),
                resolution_scope: Some("exact-item-under-pointer".to_owned()),
                presentation_mode: Some("list".to_owned()),
                absolute_path: Some(missing.to_string_lossy().into_owned()),
                parent_directory: None,
                item_name: Some("missing.md".to_owned()),
                path_source: Some("atspi-path-attribute".to_owned()),
                visible_markdown_peer_count: Some(1),
                unsupported_description: None,
                error: None,
            },
            DisplayServerKind::Wayland,
        );
        let outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(observation),
            &LinuxMarkdownFilter,
        );

        assert!(matches!(
            outcome.rejection,
            Some(
                crate::hover::HoveredItemResolutionRejection::CandidateRejected {
                    rejection: crate::filter::HoverCandidateRejection::MissingPath { .. }
                }
            )
        ));
    }

    #[test]
    fn live_probe_output_confirms_unsupported_entity_rejection_after_host_plumbing() {
        let observation = hovered_item_observation_from_probe_output(
            AtspiHoveredItemProbeOutput {
                no_hit: false,
                application_id: Some("org.gnome.Nautilus".to_owned()),
                entity_kind: Some("unsupported".to_owned()),
                resolution_scope: Some("exact-item-under-pointer".to_owned()),
                presentation_mode: Some("non-list".to_owned()),
                absolute_path: None,
                parent_directory: None,
                item_name: None,
                path_source: Some("atspi-path-attribute".to_owned()),
                visible_markdown_peer_count: None,
                unsupported_description: Some(
                    "hovered GTK widget was not a Nautilus file row".to_owned(),
                ),
                error: None,
            },
            DisplayServerKind::X11,
        );
        let outcome = classify_hovered_item_snapshot(
            build_hovered_item_snapshot(observation),
            &LinuxMarkdownFilter,
        );

        assert!(matches!(
            outcome.rejection,
            Some(
                crate::hover::HoveredItemResolutionRejection::CandidateRejected {
                    rejection: crate::filter::HoverCandidateRejection::UnsupportedItem { .. }
                }
            )
        ));
    }

    struct TempFixture {
        root: PathBuf,
    }

    impl TempFixture {
        fn new() -> Self {
            let root = temp_path("fixture-root");
            fs::create_dir_all(&root).expect("temp fixture root should be created");
            Self { root }
        }

        fn create_directory(&self, relative_path: impl AsRef<Path>) -> PathBuf {
            let path = self.root.join(relative_path);
            fs::create_dir_all(&path).expect("temp directory should be created");
            path
        }
    }

    impl Drop for TempFixture {
        fn drop(&mut self) {
            let _ = fs::remove_dir_all(&self.root);
        }
    }

    fn temp_path(name: &str) -> PathBuf {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("system time should be after unix epoch")
            .as_nanos();
        std::env::temp_dir().join(format!("fastmd-live-probes-{nonce}-{name}"))
    }
}
