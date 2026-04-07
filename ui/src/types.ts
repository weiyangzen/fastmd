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
  sourceDocumentPath?: string | null;
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
  hotInteractionSurface?: HotInteractionSurface | null;
  linuxProbePlans?: LinuxProbePlans | null;
  linuxPreviewPlacement?: LinuxPreviewPlacement | null;
  linuxRuntimeDiagnostics?: LinuxRuntimeDiagnostics | null;
}

export interface HotInteractionSurface {
  windowFocusStrategy: string;
  domFocusTarget: string;
  pointerScrollRouting: string;
}

export interface LinuxProbePlans {
  waylandFrontmostApiStack: string;
  x11FrontmostApiStack: string;
  waylandHoveredItemApiStack: string;
  x11HoveredItemApiStack: string;
}

export interface LinuxPreviewPlacement {
  monitorWorkAreaSource: string;
  monitorSelectionPolicy: string;
  coordinateSpace: string;
  aspectRatio: string;
  edgeInsetPx: number;
  pointerOffsetPx: number;
}

export interface PreviewGeometryRect {
  x: number;
  y: number;
  width: number;
  height: number;
}

export interface LinuxFrontmostGateDiagnostic {
  status: string;
  displayServer: string;
  apiStack: string;
  observedIdentifier?: string | null;
  stableSurfaceId?: string | null;
  isOpen?: boolean | null;
  rejection?: string | null;
  note: string;
}

export interface LinuxHoveredItemDiagnostic {
  status: string;
  displayServer: string;
  apiStack: string;
  backend?: string | null;
  resolutionScope?: string | null;
  entityKind?: string | null;
  itemName?: string | null;
  path?: string | null;
  pathSource?: string | null;
  visibleMarkdownPeerCount?: number | null;
  accepted?: boolean | null;
  rejection?: string | null;
  note: string;
}

export interface LinuxMonitorSelectionDiagnostic {
  status: string;
  selectionPolicy: string;
  anchor?: ScreenPoint | null;
  selectedMonitorId?: string | null;
  usedNearestFallback?: boolean | null;
  workArea?: PreviewGeometryRect | null;
  note: string;
}

export interface LinuxPreviewPlacementDiagnostic {
  status: string;
  policy: string;
  requestedWidth?: number | null;
  appliedGeometry?: PreviewGeometry | null;
  note: string;
}

export interface LinuxEditLifecycleDiagnostic {
  status: string;
  policy: string;
  editing: boolean;
  closeOnBlurEnabled: boolean;
  canPersistPreviewEdits: boolean;
  lastCloseReason?: string | null;
  note: string;
}

export interface LinuxRuntimeDiagnostics {
  displayServer: string;
  frontmostGate: LinuxFrontmostGateDiagnostic;
  hoveredItem: LinuxHoveredItemDiagnostic;
  monitorSelection: LinuxMonitorSelectionDiagnostic;
  previewPlacement: LinuxPreviewPlacementDiagnostic;
  editLifecycle: LinuxEditLifecycleDiagnostic;
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
