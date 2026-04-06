export type BackgroundMode = "white" | "black";
export type PlatformId = "macos" | "windows" | "ubuntu" | "shell";
export type RuntimeMode = "desktop" | "fallback";
export type PermissionState = "granted" | "denied" | "unknown";
export type FileManagerId = "finder" | "explorer" | "nautilus" | "unknown";
export type CloseReason = "escape" | "focus-lost" | "outside-click" | "app-switch" | string;

export interface ScreenPoint {
  x: number;
  y: number;
}

export interface ShellState {
  documentTitle: string;
  markdown: string;
  contentBaseUrl?: string | null;
  widthTiers: number[];
  selectedWidthTierIndex: number;
  backgroundMode: BackgroundMode;
}

export interface HostCapabilities {
  platformId: PlatformId;
  runtimeMode: RuntimeMode;
  accessibilityPermission: PermissionState;
  frontmostFileManager: FileManagerId;
  previewWindowPositioning: boolean;
  globalShortcutRegistered: boolean;
  closeOnBlurEnabled: boolean;
  canPersistPreviewEdits: boolean;
  linuxProbePlans?: LinuxProbePlans | null;
}

export interface LinuxProbePlans {
  waylandFrontmostApiStack: string;
  x11FrontmostApiStack: string;
  waylandHoveredItemApiStack: string;
  x11HoveredItemApiStack: string;
}

export interface BootstrapPayload {
  shellState: ShellState;
  hostCapabilities: HostCapabilities;
}

export interface PreviewGeometry {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface CloseRequest {
  reason: CloseReason;
}
