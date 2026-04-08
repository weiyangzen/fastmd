import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";

import type {
  DesktopShellValidationArtifactExport,
  BootstrapPayload,
  CloseReason,
  CloseRequest,
  DesktopShellValidationSnapshot,
  HostCapabilities,
  HotInteractionSurface,
  LinuxEditLifecycleDiagnostic,
  LinuxFrontmostGateDiagnostic,
  LinuxParityCoverage,
  LinuxPreviewLoopValidation,
  LinuxProbePlans,
  LinuxValidationEvidence,
  LinuxValidationEvidenceReport,
  LinuxValidationReport,
  LinuxRuntimeDiagnostics,
  PreviewGeometry,
  ScreenPoint,
  SharedRenderingSurface,
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

export async function replacePreviewMarkdown(
  markdown: string,
  contentBaseUrl?: string | null,
  sourceDocumentPath?: string | null,
  documentTitle?: string | null,
): Promise<ShellState | null> {
  return safeInvoke<ShellState>("replace_preview_markdown", {
    markdown,
    contentBaseUrl,
    sourceDocumentPath,
    documentTitle,
  });
}

export async function savePreviewMarkdown(markdown: string): Promise<ShellState | null> {
  return safeInvoke<ShellState>("save_preview_markdown", { markdown });
}

export async function requestPreviewClose(reason: CloseReason): Promise<void> {
  await safeInvoke("request_preview_close", { reason });
}

export async function applyPreviewGeometry(anchor?: ScreenPoint): Promise<PreviewGeometry | null> {
  return safeInvoke<PreviewGeometry>("apply_preview_geometry", { anchor });
}

export async function captureLinuxValidationReport(
  anchor?: ScreenPoint,
): Promise<LinuxValidationReport | null> {
  return safeInvoke<LinuxValidationReport>("capture_linux_validation_report", { anchor });
}

export async function captureDesktopShellValidationSnapshot(
  anchor?: ScreenPoint,
): Promise<DesktopShellValidationSnapshot | null> {
  return safeInvoke<DesktopShellValidationSnapshot>(
    "capture_desktop_shell_validation_snapshot",
    { anchor },
  );
}

export async function exportDesktopShellValidationArtifacts(
  anchor?: ScreenPoint,
): Promise<DesktopShellValidationArtifactExport | null> {
  return safeInvoke<DesktopShellValidationArtifactExport>(
    "export_desktop_shell_validation_artifacts",
    { anchor },
  );
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

export function readLinuxProbePlans(capabilities: HostCapabilities): LinuxProbePlans | null {
  return capabilities.linuxProbePlans ?? null;
}

export function readLinuxProbePlanSemanticGuardrail(
  capabilities: HostCapabilities,
): string | null {
  return capabilities.linuxProbePlans?.semanticGuardrail ?? null;
}

export function readHotInteractionSurface(
  capabilities: HostCapabilities,
): HotInteractionSurface | null {
  return capabilities.hotInteractionSurface ?? null;
}

export function readSharedRenderingSurface(
  capabilities: HostCapabilities,
): SharedRenderingSurface | null {
  return capabilities.sharedRenderingSurface ?? null;
}

export function readSharedRenderingPipeline(capabilities: HostCapabilities): string | null {
  return capabilities.sharedRenderingSurface?.renderPipeline ?? null;
}

export function readLinuxRuntimeDiagnostics(
  capabilities: HostCapabilities,
): LinuxRuntimeDiagnostics | null {
  return capabilities.linuxRuntimeDiagnostics ?? null;
}

export function readLinuxParityCoverage(
  capabilities: HostCapabilities,
): LinuxParityCoverage | null {
  return capabilities.linuxParityCoverage ?? null;
}

export function readLinuxPreviewLoopValidation(
  capabilities: HostCapabilities,
): LinuxPreviewLoopValidation | null {
  return capabilities.linuxPreviewLoopValidation ?? null;
}

export function readLinuxValidationEvidence(
  capabilities: HostCapabilities,
): LinuxValidationEvidence | null {
  return capabilities.linuxValidationEvidence ?? null;
}

export function readLinuxValidationEvidenceLatestReports(
  capabilities: HostCapabilities,
): LinuxValidationEvidenceReport[] {
  return capabilities.linuxValidationEvidence?.latestReports ?? [];
}

export function readLinuxFrontmostGateDiagnostic(
  capabilities: HostCapabilities,
): LinuxRuntimeDiagnostics["frontmostGate"] | null {
  return capabilities.linuxRuntimeDiagnostics?.frontmostGate ?? null;
}

export function readLinuxFrontmostTextInputState(
  capabilities: HostCapabilities,
): Pick<
  LinuxFrontmostGateDiagnostic,
  "textInputActive" | "textInputRole" | "textInputName"
> | null {
  const gate = readLinuxFrontmostGateDiagnostic(capabilities);
  if (!gate) {
    return null;
  }

  return {
    textInputActive: gate.textInputActive ?? null,
    textInputRole: gate.textInputRole ?? null,
    textInputName: gate.textInputName ?? null,
  };
}

export function readLinuxHoveredItemDiagnostic(
  capabilities: HostCapabilities,
): LinuxRuntimeDiagnostics["hoveredItem"] | null {
  return capabilities.linuxRuntimeDiagnostics?.hoveredItem ?? null;
}

export function readLinuxEditLifecycleDiagnostic(
  capabilities: HostCapabilities,
): LinuxEditLifecycleDiagnostic | null {
  return capabilities.linuxRuntimeDiagnostics?.editLifecycle ?? null;
}

export function readLinuxHoverLifecycleDiagnostic(
  capabilities: HostCapabilities,
): LinuxRuntimeDiagnostics["hoverLifecycle"] | null {
  return capabilities.linuxRuntimeDiagnostics?.hoverLifecycle ?? null;
}
