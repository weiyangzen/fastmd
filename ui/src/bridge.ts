import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";

import type {
  BootstrapPayload,
  CloseReason,
  CloseRequest,
  HostCapabilities,
  PreviewGeometry,
  ScreenPoint,
  ShellState,
} from "./types";

export const SHELL_STATE_EVENT = "fastmd://shell-state";
export const HOST_CAPABILITIES_EVENT = "fastmd://host-capabilities";
export const CLOSE_REQUESTED_EVENT = "fastmd://close-requested";

function isTauriRuntime(): boolean {
  return typeof window !== "undefined" && ("__TAURI_INTERNALS__" in window || "__TAURI__" in window);
}

async function safeInvoke<T>(command: string, args?: Record<string, unknown>): Promise<T | null> {
  if (!isTauriRuntime()) {
    return null;
  }

  try {
    return await invoke<T>(command, args);
  } catch (error) {
    console.warn(`FastMD bridge invoke failed for ${command}`, error);
    return null;
  }
}

export async function bootstrapShell(): Promise<BootstrapPayload | null> {
  return safeInvoke<BootstrapPayload>("bootstrap_shell");
}

export async function setEditingState(editing: boolean): Promise<void> {
  await safeInvoke("set_editing_state", { editing });
}

export async function adjustWidthTier(delta: number): Promise<ShellState | null> {
  return safeInvoke<ShellState>("adjust_width_tier", { delta });
}

export async function toggleBackgroundMode(): Promise<ShellState | null> {
  return safeInvoke<ShellState>("toggle_background_mode");
}

export async function replacePreviewMarkdown(markdown: string): Promise<ShellState | null> {
  return safeInvoke<ShellState>("replace_preview_markdown", { markdown });
}

export async function requestPreviewClose(reason: CloseReason): Promise<void> {
  await safeInvoke("request_preview_close", { reason });
}

export async function applyPreviewGeometry(anchor?: ScreenPoint): Promise<PreviewGeometry | null> {
  return safeInvoke<PreviewGeometry>("apply_preview_geometry", { anchor });
}

export async function revealPreview(): Promise<void> {
  await safeInvoke("reveal_preview");
}

export async function listenToShellState(
  callback: (payload: ShellState) => void,
): Promise<() => void> {
  if (!isTauriRuntime()) {
    return () => {};
  }

  return listen<ShellState>(SHELL_STATE_EVENT, (event) => {
    callback(event.payload);
  });
}

export async function listenToHostCapabilities(
  callback: (payload: HostCapabilities) => void,
): Promise<() => void> {
  if (!isTauriRuntime()) {
    return () => {};
  }

  return listen<HostCapabilities>(HOST_CAPABILITIES_EVENT, (event) => {
    callback(event.payload);
  });
}

export async function listenToCloseRequests(
  callback: (payload: CloseRequest) => void,
): Promise<() => void> {
  if (!isTauriRuntime()) {
    return () => {};
  }

  return listen<CloseRequest>(CLOSE_REQUESTED_EVENT, (event) => {
    callback(event.payload);
  });
}
