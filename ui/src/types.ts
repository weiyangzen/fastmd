export type BackgroundMode = "white" | "black";
export type PlatformId = "macos" | "windows" | "ubuntu" | "shell";
export type RuntimeMode = "desktop" | "fallback";
export type PermissionState = "granted" | "denied" | "unknown";
export type FileManagerId = "finder" | "explorer" | "nautilus" | "unknown";
export type CloseReason = "escape" | "focus-lost" | "outside-click" | "app-switch" | string;
export type LinuxDiagnosticStatus = "pending-live-probe" | "emitted" | "probe-failed" | string;
export type LinuxValidationNoteStatus =
  | "implemented-in-slice"
  | "needs-ubuntu-host-validation"
  | "blocked-by-lower-layers"
  | string;
export type LinuxValidationSectionStatus = "pass" | "fail" | "not-captured" | string;
export type LinuxValidationEvidenceStatus =
  | "cross-session-review-required"
  | "cross-session-captured-awaiting-review"
  | string;
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
  linuxParityCoverage?: LinuxParityCoverage | null;
  linuxPreviewLoopValidation?: LinuxPreviewLoopValidation | null;
  linuxValidationEvidence?: LinuxValidationEvidence | null;
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
  renderPipeline: string;
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

export interface LinuxParityCoverageFeature {
  feature: string;
  lanes: string[];
}

export interface LinuxParityCoverage {
  target: string;
  referenceSurface: string;
  matchesReference: boolean;
  coveredFeatureCount: number;
  referenceFeatureCount: number;
  missingFeatures: string[];
  featureLanes: LinuxParityCoverageFeature[];
}

export interface LinuxPreviewLoopValidationSummary {
  target: string;
  referenceSurface: string;
  displayServer: string;
  validationMode: string;
  matchesReference: boolean;
  coveredFeatureCount: number;
  referenceFeatureCount: number;
  missingFeatures: string[];
  featureLanes: LinuxParityCoverageFeature[];
  note: string;
}

export interface LinuxPreviewLoopValidation {
  wayland: LinuxPreviewLoopValidationSummary;
  x11: LinuxPreviewLoopValidationSummary;
}

export interface LinuxValidationEvidence {
  status: LinuxValidationEvidenceStatus;
  checklistItem: string;
  note: string;
  requiredDisplayServers: string[];
  capturedDisplayServers: string[];
  missingDisplayServers: string[];
  readyDisplayServerReports: string[];
  latestReports: LinuxValidationEvidenceReport[];
}

export interface LinuxValidationEvidenceReport {
  displayServer: string;
  capturedAtUnixMs: number;
  readyToCloseDisplayServerReport: boolean;
  reportJsonPath: string;
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
  textInputActive?: boolean | null;
  textInputRole?: string | null;
  textInputName?: string | null;
  inferredBlurCloseReason?: CloseReason | null;
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

export interface LinuxValidationNote {
  item: string;
  status: LinuxValidationNoteStatus;
  note: string;
}

export interface LinuxValidationSection {
  title: string;
  status: LinuxValidationSectionStatus;
  checklistItems: string[];
  details: string[];
}

export interface LinuxValidationReport {
  target: string;
  referenceSurface: string;
  displayServer: string;
  capturedAtUnixMs: number;
  anchor?: ScreenPoint | null;
  readyToCloseDisplayServerReport: boolean;
  crossSessionParityEvidenceReady: boolean;
  crossSessionParityEvidenceNote: string;
  crossSessionRequiredDisplayServers: string[];
  crossSessionCapturedDisplayServers: string[];
  crossSessionMissingDisplayServers: string[];
  crossSessionReadyDisplayServerReports: string[];
  readyChecklistItems: string[];
  blockedChecklistItems: string[];
  sections: LinuxValidationSection[];
  notes: LinuxValidationNote[];
  markdown: string;
}

export interface DesktopShellValidationSnapshot {
  capturedAtUnixMs: number;
  shellState: ShellState;
  hostCapabilities: HostCapabilities;
  linuxValidationReport: LinuxValidationReport | null;
}

export interface DesktopShellValidationArtifactExport {
  capturedAtUnixMs: number;
  outputDirectory: string;
  snapshotMarkdownPath: string;
  linuxValidationReportMarkdownPath?: string | null;
  linuxValidationReportJsonPath?: string | null;
  displayServer?: string | null;
  linuxValidationEvidence?: LinuxValidationEvidence | null;
}

export interface DesktopShellDebugApi {
  captureLinuxValidationReport: (
    anchor?: ScreenPoint,
  ) => Promise<LinuxValidationReport | null>;
  captureDesktopShellValidationSnapshot: (
    anchor?: ScreenPoint,
  ) => Promise<DesktopShellValidationSnapshot | null>;
  exportDesktopShellValidationArtifacts: (
    anchor?: ScreenPoint,
  ) => Promise<DesktopShellValidationArtifactExport | null>;
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
