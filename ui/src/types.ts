export type BackgroundMode = "white" | "black";
export type PlatformId = "macos" | "windows" | "ubuntu" | "shell";
export type RuntimeMode = "desktop" | "fallback";
export type PermissionState = "granted" | "denied" | "unknown";
export type FileManagerId = "finder" | "explorer" | "nautilus" | "unknown";
export type CloseReason = "escape" | "focus-lost" | "outside-click" | "app-switch" | string;
export type LinuxDiagnosticStatus = "pending-live-probe" | "emitted" | "probe-failed" | string;
export type LinuxHoverResolutionScope =
  | "exact-item-under-pointer"
  | "hovered-row-descendant"
  | "nearby-candidate"
  | "first-visible-item"
  | string;
export type LinuxHoveredEntityKind = "file" | "directory" | "unsupported" | string;
export type MarkdownFeature =
  | "heading"
  | "paragraph"
  | "emphasis"
  | "strong"
  | "fenced-code"
  | "syntax-highlighted-code"
  | "blockquote"
  | "task-list"
  | "table"
  | "mermaid"
  | "math"
  | "image"
  | "footnote"
  | "html-block";

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
  sharedRenderingSurface?: SharedRenderingSurface | null;
  linuxProbePlans?: LinuxProbePlans | null;
  linuxPreviewPlacement?: LinuxPreviewPlacement | null;
  linuxRuntimeDiagnostics?: LinuxRuntimeDiagnostics | null;
}

export interface HotInteractionSurface {
  windowFocusStrategy: string;
  domFocusTarget: string;
  pointerScrollRouting: string;
}

export interface SharedRenderingSurface {
  source: string;
  macosReferenceRenderer: string;
  supportedFeatures: MarkdownFeature[];
  widthTiersPx: number[];
  aspectRatio: number;
}

export interface LinuxProbePlans {
  waylandFrontmostApiStack: string;
  x11FrontmostApiStack: string;
  waylandHoveredItemApiStack: string;
  x11HoveredItemApiStack: string;
  semanticGuardrail: string;
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
  status: LinuxDiagnosticStatus;
  displayServer: string;
  backend?: string | null;
  apiStack: string;
  observedIdentifier?: string | null;
  stableSurfaceId?: string | null;
  windowTitle?: string | null;
  processId?: number | null;
  isOpen?: boolean | null;
  rejection?: string | null;
  detail?: string | null;
  note: string;
}

export interface LinuxHoveredItemDiagnostic {
  status: LinuxDiagnosticStatus;
  displayServer: string;
  apiStack: string;
  backend?: string | null;
  resolutionScope?: LinuxHoverResolutionScope | null;
  entityKind?: LinuxHoveredEntityKind | null;
  itemName?: string | null;
  path?: string | null;
  pathSource?: string | null;
  visibleMarkdownPeerCount?: number | null;
  accepted?: boolean | null;
  rejection?: string | null;
  detail?: string | null;
  note: string;
}

export interface LinuxMonitorSelectionDiagnostic {
  status: LinuxDiagnosticStatus;
  selectionPolicy: string;
  anchor?: ScreenPoint | null;
  selectedMonitorId?: string | null;
  usedNearestFallback?: boolean | null;
  workArea?: PreviewGeometryRect | null;
  note: string;
}

export interface LinuxPreviewPlacementDiagnostic {
  status: LinuxDiagnosticStatus;
  policy: string;
  requestedWidth?: number | null;
  appliedGeometry?: PreviewGeometry | null;
  note: string;
}

export interface LinuxEditLifecycleDiagnostic {
  status: LinuxDiagnosticStatus;
  policy: string;
  editing: boolean;
  closeOnBlurEnabled: boolean;
  canPersistPreviewEdits: boolean;
  lastCloseReason?: string | null;
  note: string;
}

export interface LinuxHoverLifecycleDiagnostic {
  status: LinuxDiagnosticStatus;
  pollingIntervalMs: number;
  triggerDelayMs: number;
  lastAnchor?: ScreenPoint | null;
  observedPath?: string | null;
  previewVisible: boolean;
  previewPath?: string | null;
  lastAction?: string | null;
  note: string;
}

export interface LinuxRuntimeDiagnostics {
  displayServer: string;
  frontmostGate: LinuxFrontmostGateDiagnostic;
  hoveredItem: LinuxHoveredItemDiagnostic;
  monitorSelection: LinuxMonitorSelectionDiagnostic;
  previewPlacement: LinuxPreviewPlacementDiagnostic;
  editLifecycle: LinuxEditLifecycleDiagnostic;
  hoverLifecycle?: LinuxHoverLifecycleDiagnostic | null;
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
