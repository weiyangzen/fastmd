import { vi } from "vitest";

const {
  bootstrapShellMock,
  captureDesktopShellValidationSnapshotMock,
  captureLinuxValidationReportMock,
  exportDesktopShellValidationArtifactsMock,
  listenToCloseRequestsMock,
  listenToHostCapabilitiesMock,
  listenToShellStateMock,
  replacePreviewMarkdownMock,
  requestPreviewCloseMock,
  renderMarkdownDocumentMock,
  savePreviewMarkdownMock,
  setEditingStateMock,
  startPreviewWindowDragMock,
  markdownRenderState,
} = vi.hoisted(() => ({
  bootstrapShellMock: vi.fn(async () => null),
  captureDesktopShellValidationSnapshotMock: vi.fn(async () => null),
  captureLinuxValidationReportMock: vi.fn(async () => null),
  exportDesktopShellValidationArtifactsMock: vi.fn(async () => null),
  listenToCloseRequestsMock: vi.fn(async () => () => {}),
  listenToHostCapabilitiesMock: vi.fn(async () => () => {}),
  listenToShellStateMock: vi.fn(async () => () => {}),
  replacePreviewMarkdownMock: vi.fn(async () => null),
  requestPreviewCloseMock: vi.fn(async () => {}),
  renderMarkdownDocumentMock: vi.fn(),
  savePreviewMarkdownMock: vi.fn(async () => null),
  setEditingStateMock: vi.fn(async () => {}),
  startPreviewWindowDragMock: vi.fn(async () => {}),
  markdownRenderState: {
    defaultImplementation: undefined as
      | typeof import("./markdown").renderMarkdownDocument
      | undefined,
  },
}));

vi.mock("./bridge", async () => {
  const actual = await vi.importActual<typeof import("./bridge")>("./bridge");
  return {
    ...actual,
    bootstrapShell: bootstrapShellMock,
    captureDesktopShellValidationSnapshot: captureDesktopShellValidationSnapshotMock,
    captureLinuxValidationReport: captureLinuxValidationReportMock,
    exportDesktopShellValidationArtifacts: exportDesktopShellValidationArtifactsMock,
    listenToCloseRequests: listenToCloseRequestsMock,
    listenToHostCapabilities: listenToHostCapabilitiesMock,
    listenToShellState: listenToShellStateMock,
    replacePreviewMarkdown: replacePreviewMarkdownMock,
    requestPreviewClose: requestPreviewCloseMock,
    savePreviewMarkdown: savePreviewMarkdownMock,
    setEditingState: setEditingStateMock,
    startPreviewWindowDrag: startPreviewWindowDragMock,
  };
});

vi.mock("./markdown", async () => {
  const actual = await vi.importActual<typeof import("./markdown")>("./markdown");
  markdownRenderState.defaultImplementation = actual.renderMarkdownDocument;
  renderMarkdownDocumentMock.mockImplementation(actual.renderMarkdownDocument);
  return {
    ...actual,
    renderMarkdownDocument: renderMarkdownDocumentMock,
  };
});

import {
  normalizeWheelScrollDelta,
  PreviewShellApp,
  resolvePagedScrollTargets,
} from "./app";
import { demoBootstrapPayload } from "./fixtures";

let app: PreviewShellApp | null = null;

function createApp(payload = demoBootstrapPayload): PreviewShellApp {
  document.body.innerHTML = '<div id="app"></div>';
  const container = document.getElementById("app");
  if (!container) {
    throw new Error("missing test mount");
  }
  app = new PreviewShellApp(container, payload);
  return app;
}

describe("FastMD shared preview shell", () => {
  afterEach(() => {
    app?.destroy();
    app = null;
    bootstrapShellMock.mockClear();
    captureDesktopShellValidationSnapshotMock.mockClear();
    captureLinuxValidationReportMock.mockClear();
    exportDesktopShellValidationArtifactsMock.mockClear();
    listenToCloseRequestsMock.mockClear();
    listenToHostCapabilitiesMock.mockClear();
    listenToShellStateMock.mockClear();
    replacePreviewMarkdownMock.mockClear();
    requestPreviewCloseMock.mockClear();
    renderMarkdownDocumentMock.mockImplementation(markdownRenderState.defaultImplementation!);
    renderMarkdownDocumentMock.mockClear();
    savePreviewMarkdownMock.mockClear();
    setEditingStateMock.mockClear();
    startPreviewWindowDragMock.mockClear();
    document.body.innerHTML = "";
  });

  it("renders the current width tier in the compact hint chip", () => {
    createApp();
    expect(document.body.textContent).toContain("← 1/4 →");
    expect(document.body.textContent).toContain("Tab");
  });

  it("advances the width tier with the same arrow semantics", async () => {
    createApp();
    window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.body.textContent).toContain("← 2/4 →");
  });

  it("toggles the background mode on Tab", async () => {
    createApp();
    expect(document.body.dataset.backgroundMode).toBe("white");
    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Tab", bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.body.dataset.backgroundMode).toBe("black");
  });

  it("enters and exits inline edit mode from a double-clicked block", async () => {
    createApp();
    await new Promise((resolve) => setTimeout(resolve, 0));
    const block = document.querySelector(".md-block");
    expect(block).not.toBeNull();
    block?.dispatchEvent(new MouseEvent("dblclick", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.body.classList.contains("is-editing")).toBe(true);
    expect(document.querySelector("#inline-editor-textarea")).not.toBeNull();

    const cancelButton = document.querySelector("#inline-editor-cancel");
    cancelButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(document.body.classList.contains("is-editing")).toBe(false);
  });

  it("injects a content base URL for local media resolution", async () => {
    createApp({
      ...demoBootstrapPayload,
      shellState: {
        ...demoBootstrapPayload.shellState,
        markdown: '<video controls><source src="./clip.mp4" type="video/mp4"></video>',
        contentBaseUrl: "file:///Users/wangweiyang/Downloads/",
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const base = document.head.querySelector('base[data-fastmd-content-base="true"]');
    expect(base).not.toBeNull();
    expect(base?.getAttribute("href")).toBe("file:///Users/wangweiyang/Downloads/");
    expect(document.querySelector("video")).not.toBeNull();
  });

  it("hides unattached-save scaffolding copy on desktop shells with a real source attachment", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        canPersistPreviewEdits: true,
      },
      shellState: {
        ...demoBootstrapPayload.shellState,
        sourceDocumentPath: "/tmp/attached.md",
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const capabilitySummary = document.querySelector('[data-role="capability-summary"]');
    const statusBanner = document.querySelector('[data-role="status-banner"]') as HTMLElement | null;

    expect(capabilitySummary?.textContent).toBe("");
    expect((capabilitySummary as HTMLElement | null)?.hidden).toBe(true);
    expect(statusBanner?.hidden).toBe(true);
    expect(document.body.textContent).not.toContain("browser shell fallback");
    expect(document.body.textContent).not.toContain("Edits stay in memory until the preview");
  });

  it("surfaces an honest unattached-save note on desktop shells without a file attachment", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        canPersistPreviewEdits: false,
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const statusBanner = document.querySelector('[data-role="status-banner"]') as HTMLElement | null;

    expect(statusBanner?.hidden).toBe(false);
    expect(statusBanner?.textContent).toContain("attached to a local Markdown file");
  });

  it("registers a hidden desktop validation-report capture API", async () => {
    const report = {
      target: "Ubuntu 24.04 + GNOME Files / Nautilus",
      referenceSurface: "apps/macos",
      displayServer: "wayland",
      capturedAtUnixMs: 1710000000000,
      anchor: { x: 240, y: 180 },
      readyToCloseDisplayServerReport: true,
      crossSessionParityEvidenceReady: false,
      crossSessionParityEvidenceNote:
        "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.",
      crossSessionRequiredDisplayServers: ["wayland", "x11"],
      crossSessionCapturedDisplayServers: [],
      crossSessionMissingDisplayServers: ["wayland", "x11"],
      crossSessionReadyDisplayServerReports: [],
      readyChecklistItems: [
        "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
      ],
      blockedChecklistItems: [
        "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
      ],
      sections: [],
      notes: [],
      markdown: "# Ubuntu 24.04 GNOME Files Validation Evidence Report",
    };
    captureLinuxValidationReportMock.mockResolvedValueOnce(report);

    createApp();

    const captured = await window.__FASTMD_DESKTOP__?.captureLinuxValidationReport({
      x: 240,
      y: 180,
    });

    expect(captureLinuxValidationReportMock).toHaveBeenCalledWith({ x: 240, y: 180 });
    expect(captured).toEqual(report);
    expect(document.body.textContent).not.toContain(
      "Ubuntu 24.04 GNOME Files Validation Evidence Report",
    );
  });

  it("registers a hidden desktop shell validation snapshot API", async () => {
    const snapshot = {
      capturedAtUnixMs: 1710000000123,
      shellState: demoBootstrapPayload.shellState,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
      },
      linuxValidationReport: {
        target: "Ubuntu 24.04 + GNOME Files / Nautilus",
        referenceSurface: "apps/macos",
        displayServer: "wayland",
        capturedAtUnixMs: 1710000000000,
        anchor: { x: 240, y: 180 },
        readyToCloseDisplayServerReport: true,
        crossSessionParityEvidenceReady: false,
        crossSessionParityEvidenceNote:
          "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.",
        crossSessionRequiredDisplayServers: ["wayland", "x11"],
        crossSessionCapturedDisplayServers: [],
        crossSessionMissingDisplayServers: ["wayland", "x11"],
        crossSessionReadyDisplayServerReports: [],
        readyChecklistItems: [
          "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
        ],
        blockedChecklistItems: [
          "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
        ],
        sections: [],
        notes: [],
        markdown: "# Ubuntu 24.04 GNOME Files Validation Evidence Report",
      },
    };
    captureDesktopShellValidationSnapshotMock.mockResolvedValueOnce(snapshot);

    createApp();

    const captured = await window.__FASTMD_DESKTOP__?.captureDesktopShellValidationSnapshot({
      x: 240,
      y: 180,
    });

    expect(captureDesktopShellValidationSnapshotMock).toHaveBeenCalledWith({
      x: 240,
      y: 180,
    });
    expect(captured).toEqual(snapshot);
    expect(document.body.textContent).not.toContain("capturedAtUnixMs");
    expect(document.body.textContent).not.toContain(
      "Record Ubuntu-specific validation evidence",
    );
  });

  it("registers a hidden desktop validation artifact export API", async () => {
    const exportPayload = {
      capturedAtUnixMs: 1710000000456,
      outputDirectory: "/repo/Docs/Test_Logs",
      snapshotMarkdownPath:
        "/repo/Docs/Test_Logs/desktop-shell-validation-snapshot-wayland-1710000000456.md",
      linuxValidationReportMarkdownPath:
        "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.md",
      linuxValidationReportJsonPath:
        "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.json",
      displayServer: "wayland",
      linuxValidationEvidence: {
        status: "cross-session-review-required",
        checklistItem:
          "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
        note:
          "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.",
        requiredDisplayServers: ["wayland", "x11"],
        capturedDisplayServers: ["wayland"],
        missingDisplayServers: ["x11"],
        readyDisplayServerReports: ["wayland"],
        latestReports: [
          {
            displayServer: "wayland",
            capturedAtUnixMs: 1710000000000,
            readyToCloseDisplayServerReport: true,
            reportJsonPath:
              "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.json",
          },
        ],
      },
    };
    exportDesktopShellValidationArtifactsMock.mockResolvedValueOnce(exportPayload);

    createApp();

    const exported = await window.__FASTMD_DESKTOP__?.exportDesktopShellValidationArtifacts({
      x: 320,
      y: 200,
    });

    expect(exportDesktopShellValidationArtifactsMock).toHaveBeenCalledWith({
      x: 320,
      y: 200,
    });
    expect(exported).toEqual(exportPayload);
    expect(document.body.textContent).not.toContain("Docs/Test_Logs");
    expect(document.body.textContent).not.toContain(
      "desktop-shell-validation-snapshot-wayland",
    );
  });

  it("connects the preview shell through the desktop bridge bootstrap and listeners", async () => {
    const shellStateUnlisten = vi.fn();
    const hostCapabilitiesUnlisten = vi.fn();
    const closeRequestsUnlisten = vi.fn();

    bootstrapShellMock.mockResolvedValueOnce({
      shellState: {
        ...demoBootstrapPayload.shellState,
        documentTitle: "Bootstrapped.md",
        markdown: "# bootstrapped\n",
      },
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
      },
    });
    listenToShellStateMock.mockImplementationOnce(async (callback) => {
      callback({
        ...demoBootstrapPayload.shellState,
        documentTitle: "Connected.md",
        markdown: "# connected\n",
      });
      return shellStateUnlisten;
    });
    listenToHostCapabilitiesMock.mockImplementationOnce(async (callback) => {
      callback({
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxValidationEvidence: {
          status: "cross-session-review-required",
          checklistItem:
            "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
          note:
            "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.",
          requiredDisplayServers: ["wayland", "x11"],
          capturedDisplayServers: [],
          missingDisplayServers: ["wayland", "x11"],
          readyDisplayServerReports: [],
          latestReports: [],
        },
      });
      return hostCapabilitiesUnlisten;
    });
    listenToCloseRequestsMock.mockImplementationOnce(async (callback) => {
      callback({ reason: "app-switch" });
      return closeRequestsUnlisten;
    });

    const connectedApp = createApp();
    await connectedApp.connect();
    await new Promise((resolve) => setTimeout(resolve, 0));

    const shell = document.querySelector(".shell") as HTMLElement | null;
    const statusBanner = document.querySelector('[data-role="status-banner"]') as HTMLElement | null;

    expect(bootstrapShellMock).toHaveBeenCalledTimes(1);
    expect(listenToShellStateMock).toHaveBeenCalledTimes(1);
    expect(listenToHostCapabilitiesMock).toHaveBeenCalledTimes(1);
    expect(listenToCloseRequestsMock).toHaveBeenCalledTimes(1);
    expect(document.body.textContent).toContain("Connected.md");
    expect(shell?.dataset.linuxValidationEvidenceStatus).toBe(
      "cross-session-review-required",
    );
    expect(shell?.dataset.linuxValidationEvidenceNote).toContain("Wayland and X11");
    expect(statusBanner?.hidden).toBe(false);
    expect(statusBanner?.textContent).toContain("Preview close requested: app-switch.");

    connectedApp.destroy();

    expect(shellStateUnlisten).toHaveBeenCalledTimes(1);
    expect(hostCapabilitiesUnlisten).toHaveBeenCalledTimes(1);
    expect(closeRequestsUnlisten).toHaveBeenCalledTimes(1);
  });

  it("stores cross-session Ubuntu parity-evidence requirements as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxValidationEvidence: {
          status: "cross-session-review-required",
          checklistItem:
            "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
          note:
            "Single-session validation reports can only prove one live Ubuntu display server at a time. Keep the umbrella Ubuntu parity-evidence checklist item open until reviewed real-machine evidence exists for both Wayland and X11.",
          requiredDisplayServers: ["wayland", "x11"],
          capturedDisplayServers: [],
          missingDisplayServers: ["wayland", "x11"],
          readyDisplayServerReports: [],
          latestReports: [],
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxValidationEvidenceStatus).toBe(
      "cross-session-review-required",
    );
    expect(shell?.dataset.linuxValidationEvidenceChecklistItem).toContain(
      "Record Ubuntu-specific validation evidence",
    );
    expect(shell?.dataset.linuxValidationEvidenceNote).toContain("Wayland and X11");
    expect(shell?.dataset.linuxValidationEvidenceRequiredDisplayServers).toBe(
      JSON.stringify(["wayland", "x11"]),
    );
    expect(shell?.dataset.linuxValidationEvidenceMissingDisplayServers).toBe(
      JSON.stringify(["wayland", "x11"]),
    );
    expect(shell?.dataset.linuxValidationEvidenceLatestReports).toBe("[]");
    expect(document.body.textContent).not.toContain("cross-session-review-required");
    expect(document.body.textContent).not.toContain(
      "Record Ubuntu-specific validation evidence",
    );
  });

  it("stores Ubuntu probe-plan diagnostics as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxProbePlans: {
          waylandFrontmostApiStack:
            "focus=AT-SPI focused accessible + app_bus=AT-SPI application bus name",
          x11FrontmostApiStack:
            "focus=AT-SPI focused accessible + stable_surface=X11 _NET_ACTIVE_WINDOW",
          waylandHoveredItemApiStack:
            "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          x11HoveredItemApiStack:
            "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          semanticGuardrail:
            "Match macOS product semantics exactly; the display server changes host probing only.",
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxWaylandHoveredItemApiStack).toContain(
      "AT-SPI Component.GetAccessibleAtPoint(screen)",
    );
    expect(shell?.dataset.linuxX11FrontmostApiStack).toContain("X11 _NET_ACTIVE_WINDOW");
    expect(shell?.dataset.linuxSemanticGuardrail).toBe(
      "Match macOS product semantics exactly; the display server changes host probing only.",
    );
    expect(document.body.textContent).not.toContain("AT-SPI Component.GetAccessibleAtPoint(screen)");
    expect(document.body.textContent).not.toContain("X11 _NET_ACTIVE_WINDOW");
    expect(document.body.textContent).not.toContain(
      "Match macOS product semantics exactly; the display server changes host probing only.",
    );
  });

  it("keeps visible shell semantics identical across Wayland and X11 probe plans", async () => {
    const runtimeDiagnosticsBase = {
      frontmostGate: {
        status: "pending-live-probe",
        displayServer: "wayland",
        apiStack: "focus=AT-SPI focused accessible + app_bus=AT-SPI application bus name",
        note: "frontmost pending",
      },
      hoveredItem: {
        status: "pending-live-probe",
        displayServer: "wayland",
        apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
        note: "hover pending",
      },
      monitorSelection: {
        status: "emitted",
        selectionPolicy: "containing-work-area-then-nearest",
        note: "monitor emitted",
      },
      previewPlacement: {
        status: "emitted",
        policy: "4:3-reposition-before-shrink",
        note: "placement emitted",
      },
      editLifecycle: {
        status: "emitted",
        policy: "edit-lock-disables-blur-close",
        editing: false,
        closeOnBlurEnabled: true,
        canPersistPreviewEdits: false,
        note: "edit emitted",
      },
    };

    const waylandPayload = {
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu" as const,
        runtimeMode: "desktop" as const,
        linuxProbePlans: {
          waylandFrontmostApiStack:
            "focus=AT-SPI focused accessible + app_bus=AT-SPI application bus name",
          x11FrontmostApiStack:
            "focus=AT-SPI focused accessible + stable_surface=X11 _NET_ACTIVE_WINDOW",
          waylandHoveredItemApiStack:
            "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          x11HoveredItemApiStack:
            "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          semanticGuardrail:
            "Match macOS product semantics exactly; the display server changes host probing only.",
        },
        linuxRuntimeDiagnostics: {
          ...runtimeDiagnosticsBase,
          displayServer: "wayland",
        },
      },
    };

    const x11Payload = {
      ...waylandPayload,
      hostCapabilities: {
        ...waylandPayload.hostCapabilities,
        linuxRuntimeDiagnostics: {
          ...waylandPayload.hostCapabilities.linuxRuntimeDiagnostics,
          displayServer: "x11",
        },
      },
    };

    createApp(waylandPayload);
    await new Promise((resolve) => setTimeout(resolve, 0));
    const waylandText = document.body.textContent;
    const waylandShell = document.querySelector(".shell") as HTMLElement | null;
    const waylandGuardrail = waylandShell?.dataset.linuxSemanticGuardrail;
    app?.destroy();
    app = null;

    createApp(x11Payload);
    await new Promise((resolve) => setTimeout(resolve, 0));
    const x11Text = document.body.textContent;
    const x11Shell = document.querySelector(".shell") as HTMLElement | null;

    expect(waylandText).toBe(x11Text);
    expect(waylandShell?.dataset.linuxDisplayServer).toBe("wayland");
    expect(x11Shell?.dataset.linuxDisplayServer).toBe("x11");
    expect(waylandGuardrail).toBe(
      "Match macOS product semantics exactly; the display server changes host probing only.",
    );
    expect(x11Shell?.dataset.linuxSemanticGuardrail).toBe(waylandGuardrail);
    expect(x11Text).not.toContain("AT-SPI focused accessible");
    expect(x11Text).not.toContain("_NET_ACTIVE_WINDOW");
  });

  it("stores Ubuntu preview-placement diagnostics as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxPreviewPlacement: {
          monitorWorkAreaSource: "tauri-runtime-wry linux monitor.work_area via GDK/GNOME workarea",
          monitorSelectionPolicy: "containing-work-area-then-nearest",
          coordinateSpace: "desktop-space physical pixels",
          aspectRatio: "4:3",
          edgeInsetPx: 12,
          pointerOffsetPx: 18,
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxMonitorSelectionPolicy).toBe("containing-work-area-then-nearest");
    expect(shell?.dataset.linuxPreviewAspectRatio).toBe("4:3");
    expect(shell?.dataset.linuxEdgeInsetPx).toBe("12");
    expect(shell?.dataset.linuxPointerOffsetPx).toBe("18");
    expect(document.body.textContent).not.toContain("containing-work-area-then-nearest");
    expect(document.body.textContent).not.toContain("desktop-space physical pixels");
  });

  it("stores Ubuntu macOS-reference parity coverage as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxParityCoverage: {
          target: "Ubuntu 24.04 + GNOME Files / Nautilus",
          referenceSurface: "apps/macos",
          matchesReference: true,
          coveredFeatureCount: 20,
          referenceFeatureCount: 20,
          missingFeatures: [],
          featureLanes: [
            {
              feature:
                "Ensure preview opening is blocked while the foreground surface is not Finder / Explorer / Nautilus",
              lanes: ["shared-core", "ubuntu-adapter"],
            },
            {
              feature:
                "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy",
              lanes: ["shared-render"],
            },
          ],
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;
    const featureLanes = JSON.parse(shell?.dataset.linuxParityCoverageFeatureLanes ?? "[]") as Array<{
      feature: string;
      lanes: string[];
    }>;

    expect(shell?.dataset.linuxParityCoverageTarget).toBe(
      "Ubuntu 24.04 + GNOME Files / Nautilus",
    );
    expect(shell?.dataset.linuxParityCoverageReferenceSurface).toBe("apps/macos");
    expect(shell?.dataset.linuxParityCoverageMatchesReference).toBe("true");
    expect(shell?.dataset.linuxParityCoverageCoveredFeatureCount).toBe("20");
    expect(shell?.dataset.linuxParityCoverageReferenceFeatureCount).toBe("20");
    expect(shell?.dataset.linuxParityCoverageMissingFeatures).toBe("[]");
    expect(featureLanes).toEqual([
      {
        feature:
          "Ensure preview opening is blocked while the foreground surface is not Finder / Explorer / Nautilus",
        lanes: ["shared-core", "ubuntu-adapter"],
      },
      {
        feature:
          "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy",
        lanes: ["shared-render"],
      },
    ]);
    expect(document.body.textContent).not.toContain("ubuntu-adapter");
    expect(document.body.textContent).not.toContain("apps/macos");
  });

  it("stores Ubuntu Wayland and X11 preview-loop validation as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxPreviewLoopValidation: {
          wayland: {
            target: "Ubuntu 24.04 + GNOME Files / Nautilus",
            referenceSurface: "apps/macos",
            displayServer: "wayland",
            validationMode: "automated-shared-preview-loop",
            matchesReference: true,
            coveredFeatureCount: 20,
            referenceFeatureCount: 20,
            missingFeatures: [],
            featureLanes: [
              {
                feature:
                  "Resolve the actual hovered Markdown item instead of a nearby or first-visible candidate",
                lanes: ["shared-core", "ubuntu-adapter"],
              },
            ],
            note:
              "Automated Wayland preview-loop validation now proves that the shared core, shared render, and Ubuntu Nautilus adapter cover the full macOS reference feature list without claiming the still-open real Ubuntu 24.04 Wayland host-evidence items.",
          },
          x11: {
            target: "Ubuntu 24.04 + GNOME Files / Nautilus",
            referenceSurface: "apps/macos",
            displayServer: "x11",
            validationMode: "automated-shared-preview-loop",
            matchesReference: true,
            coveredFeatureCount: 20,
            referenceFeatureCount: 20,
            missingFeatures: [],
            featureLanes: [
              {
                feature:
                  "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy",
                lanes: ["shared-render"],
              },
            ],
            note:
              "Automated X11 preview-loop validation now proves that the shared core, shared render, and Ubuntu Nautilus adapter cover the full macOS reference feature list without claiming the still-open real Ubuntu 24.04 X11 host-evidence items.",
          },
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;
    const waylandFeatureLanes = JSON.parse(
      shell?.dataset.linuxWaylandPreviewLoopFeatureLanes ?? "[]",
    ) as Array<{ feature: string; lanes: string[] }>;
    const x11FeatureLanes = JSON.parse(
      shell?.dataset.linuxX11PreviewLoopFeatureLanes ?? "[]",
    ) as Array<{ feature: string; lanes: string[] }>;

    expect(shell?.dataset.linuxWaylandPreviewLoopTarget).toBe(
      "Ubuntu 24.04 + GNOME Files / Nautilus",
    );
    expect(shell?.dataset.linuxWaylandPreviewLoopReferenceSurface).toBe("apps/macos");
    expect(shell?.dataset.linuxWaylandPreviewLoopValidationMode).toBe(
      "automated-shared-preview-loop",
    );
    expect(shell?.dataset.linuxWaylandPreviewLoopMatchesReference).toBe("true");
    expect(shell?.dataset.linuxWaylandPreviewLoopCoveredFeatureCount).toBe("20");
    expect(shell?.dataset.linuxWaylandPreviewLoopReferenceFeatureCount).toBe("20");
    expect(shell?.dataset.linuxWaylandPreviewLoopMissingFeatures).toBe("[]");
    expect(waylandFeatureLanes).toEqual([
      {
        feature:
          "Resolve the actual hovered Markdown item instead of a nearby or first-visible candidate",
        lanes: ["shared-core", "ubuntu-adapter"],
      },
    ]);
    expect(shell?.dataset.linuxWaylandPreviewLoopNote).toContain("Wayland");

    expect(shell?.dataset.linuxX11PreviewLoopTarget).toBe(
      "Ubuntu 24.04 + GNOME Files / Nautilus",
    );
    expect(shell?.dataset.linuxX11PreviewLoopReferenceSurface).toBe("apps/macos");
    expect(shell?.dataset.linuxX11PreviewLoopValidationMode).toBe(
      "automated-shared-preview-loop",
    );
    expect(shell?.dataset.linuxX11PreviewLoopMatchesReference).toBe("true");
    expect(shell?.dataset.linuxX11PreviewLoopCoveredFeatureCount).toBe("20");
    expect(shell?.dataset.linuxX11PreviewLoopReferenceFeatureCount).toBe("20");
    expect(shell?.dataset.linuxX11PreviewLoopMissingFeatures).toBe("[]");
    expect(x11FeatureLanes).toEqual([
      {
        feature:
          "Preserve the macOS Markdown rendering surface, layout, and compact chrome copy",
        lanes: ["shared-render"],
      },
    ]);
    expect(shell?.dataset.linuxX11PreviewLoopNote).toContain("X11");
    expect(document.body.textContent).not.toContain("automated-shared-preview-loop");
    expect(document.body.textContent).not.toContain("still-open real Ubuntu 24.04 Wayland");
    expect(document.body.textContent).not.toContain("still-open real Ubuntu 24.04 X11");
  });

  it("stores live Ubuntu frontmost-gate diagnostics as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxRuntimeDiagnostics: {
          displayServer: "wayland",
          frontmostGate: {
            status: "emitted",
            displayServer: "wayland",
            backend: "live-atspi-wayland",
            apiStack:
              "focus=AT-SPI focused accessible + app_bus=AT-SPI application bus name",
            observedIdentifier: "org.gnome.Nautilus",
            stableSurfaceId: "atspi:wayland:pid=4201:name=Docs",
            windowTitle: "Docs",
            processId: 4201,
            isOpen: true,
            textInputActive: true,
            textInputRole: "entry",
            textInputName: "Report.md",
            inferredBlurCloseReason: "outside-click",
            rejection: null,
            detail: "Live Linux frontmost probing kept Nautilus as the foreground gate.",
            note:
              "Wayland frontmost-gate diagnostics now run against the live AT-SPI focus probe; Ubuntu validation evidence is still required before parity sign-off.",
          },
          hoveredItem: {
            status: "pending-live-probe",
            displayServer: "wayland",
            apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
            note: "hover pending",
          },
          monitorSelection: {
            status: "emitted",
            selectionPolicy: "containing-work-area-then-nearest",
            note: "monitor emitted",
          },
          previewPlacement: {
            status: "emitted",
            policy: "4:3-reposition-before-shrink",
            note: "placement emitted",
          },
          editLifecycle: {
            status: "emitted",
            policy: "edit-lock-disables-blur-close",
            editing: false,
            closeOnBlurEnabled: true,
            note: "edit emitted",
            canPersistPreviewEdits: false,
          },
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxFrontmostGateBackend).toBe("live-atspi-wayland");
    expect(shell?.dataset.linuxFrontmostGateObservedIdentifier).toBe("org.gnome.Nautilus");
    expect(shell?.dataset.linuxFrontmostGateStableSurfaceId).toContain("pid=4201");
    expect(shell?.dataset.linuxFrontmostGateWindowTitle).toBe("Docs");
    expect(shell?.dataset.linuxFrontmostGateProcessId).toBe("4201");
    expect(shell?.dataset.linuxFrontmostGateIsOpen).toBe("true");
    expect(shell?.dataset.linuxFrontmostGateTextInputActive).toBe("true");
    expect(shell?.dataset.linuxFrontmostGateTextInputRole).toBe("entry");
    expect(shell?.dataset.linuxFrontmostGateTextInputName).toBe("Report.md");
    expect(shell?.dataset.linuxFrontmostGateInferredBlurCloseReason).toBe("outside-click");
    expect(document.body.textContent).not.toContain("live-atspi-wayland");
    expect(document.body.textContent).not.toContain("org.gnome.Nautilus");
  });

  it("stores hot-surface routing metadata as hidden shell state", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        hotInteractionSurface: {
          windowFocusStrategy: "tauri show+set_focus on reveal and global re-open",
          domFocusTarget: ".shell root with tabindex=-1 after shell renders",
          pointerScrollRouting:
            "shared frontend wheel delta normalization routed into preview scroll",
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.getAttribute("tabindex")).toBe("-1");
    expect(shell?.dataset.hotSurfaceWindowFocusStrategy).toContain("set_focus");
    expect(shell?.dataset.hotSurfaceDomFocusTarget).toContain(".shell");
    expect(shell?.dataset.hotSurfacePointerScrollRouting).toContain(
      "wheel delta normalization",
    );
    expect(document.body.textContent).not.toContain("wheel delta normalization");
  });

  it("stores Ubuntu top-chrome drag metadata as hidden shell state and routes toolbar drags to Tauri", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        previewWindowDragSurface: {
          strategy: "shared toolbar mousedown -> Tauri WebviewWindow::start_dragging",
          dragHandleSelector: ".toolbar",
          activation: "primary-button mousedown on top chrome only",
          guardrail:
            "Ubuntu only advertises hidden top-chrome drag metadata so blur-close and edit-lock wiring stay unchanged while the preview window moves.",
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;
    const toolbar = document.querySelector('[data-role="toolbar"]') as HTMLElement | null;

    expect(shell?.dataset.previewWindowDragStrategy).toContain("start_dragging");
    expect(shell?.dataset.previewWindowDragHandleSelector).toBe(".toolbar");
    expect(shell?.dataset.previewWindowDragActivation).toContain("primary-button");
    expect(shell?.dataset.previewWindowDragGuardrail).toContain("blur-close");
    expect(toolbar?.dataset.windowDragHandle).toBe("preview-top-chrome");
    expect(toolbar?.classList.contains("is-window-drag-handle")).toBe(true);

    toolbar?.dispatchEvent(new MouseEvent("mousedown", { button: 0, bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(startPreviewWindowDragMock).toHaveBeenCalledTimes(1);

    toolbar?.dispatchEvent(new MouseEvent("mousedown", { button: 2, bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    expect(startPreviewWindowDragMock).toHaveBeenCalledTimes(1);
    expect(document.body.textContent).not.toContain("start_dragging");
  });

  it("stores shared render-surface parity metadata as hidden shell state", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        sharedRenderingSurface: {
          source: "fastmd-render::stage2_rendering_contract",
          macosReferenceRenderer: "apps/macos/Sources/FastMD/MarkdownRenderer.swift",
          supportedFeatures: [
            "heading",
            "paragraph",
            "emphasis",
            "strong",
            "fenced-code",
            "syntax-highlighted-code",
            "blockquote",
            "task-list",
            "table",
            "mermaid",
            "math",
            "image",
            "footnote",
            "html-block",
          ],
          widthTiersPx: [560, 960, 1440, 1920],
          aspectRatio: 4 / 3,
          renderPipeline: "offscreen-stage-then-atomic-swap",
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.sharedRenderSurfaceSource).toBe(
      "fastmd-render::stage2_rendering_contract",
    );
    expect(shell?.dataset.sharedRenderSurfaceMacosReferenceRenderer).toBe(
      "apps/macos/Sources/FastMD/MarkdownRenderer.swift",
    );
    expect(shell?.dataset.sharedRenderSurfaceFeatures).toContain("mermaid");
    expect(shell?.dataset.sharedRenderSurfaceFeatures).toContain("math");
    expect(shell?.dataset.sharedRenderSurfaceFeatures).toContain("html-block");
    expect(shell?.dataset.sharedRenderSurfaceWidthTiers).toBe("560,960,1440,1920");
    expect(shell?.dataset.sharedRenderSurfaceAspectRatio).toBe(String(4 / 3));
    expect(shell?.dataset.sharedRenderSurfacePipeline).toBe(
      "offscreen-stage-then-atomic-swap",
    );
    expect(document.body.textContent).not.toContain("MarkdownRenderer.swift");
    expect(document.body.textContent).not.toContain("html-block");
  });

  it("keeps the current preview visible until the staged render is ready to swap", async () => {
    let shellStateListener: ((payload: typeof demoBootstrapPayload.shellState) => void) | null = null;
    let releaseRender: (() => void) | null = null;
    const renderGate = new Promise<void>((resolve) => {
      releaseRender = resolve;
    });

    const renderImpl = markdownRenderState.defaultImplementation!;
    renderMarkdownDocumentMock.mockImplementation(async (root, markdown, backgroundMode, baseUrl) => {
      if (markdown.includes("updated")) {
        await renderGate;
      }
      await renderImpl(root, markdown, backgroundMode, baseUrl);
    });
    listenToShellStateMock.mockImplementationOnce(async (callback) => {
      shellStateListener = callback;
      return () => {};
    });

    const connectedApp = createApp({
      ...demoBootstrapPayload,
      shellState: {
        ...demoBootstrapPayload.shellState,
        documentTitle: "Old.md",
        markdown: "# old\n\nCurrent body",
      },
    });
    await connectedApp.connect();

    const renderRoot = document.querySelector('[data-role="render-root"]') as HTMLElement | null;
    const stageHost = document.querySelector('[data-role="render-stage-host"]') as HTMLElement | null;

    expect(renderRoot?.textContent).toContain("Current body");

    shellStateListener?.({
      ...demoBootstrapPayload.shellState,
      documentTitle: "Updated.md",
      markdown: "# updated\n\nNext body",
    });
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(renderRoot?.textContent).toContain("Current body");
    expect(renderRoot?.textContent).not.toContain("Next body");
    expect(renderRoot?.getAttribute("aria-busy")).toBe("true");
    expect(stageHost?.children.length).toBe(1);

    releaseRender?.();
    await new Promise((resolve) => setTimeout(resolve, 0));
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(renderRoot?.textContent).toContain("Next body");
    expect(renderRoot?.textContent).not.toContain("Current body");
    expect(renderRoot?.hasAttribute("aria-busy")).toBe(false);
    expect(stageHost?.children.length).toBe(0);
  });

  it("stores Ubuntu runtime diagnostics as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxRuntimeDiagnostics: {
          displayServer: "wayland",
          frontmostGate: {
            status: "pending-live-probe",
            displayServer: "wayland",
            apiStack:
              "focus=AT-SPI focused accessible + app_bus=AT-SPI application bus name",
            textInputActive: true,
            textInputRole: "entry",
            textInputName: "third.md",
            inferredBlurCloseReason: "focus-lost",
            note: "Wayland frontmost-gate diagnostics are emitted now.",
          },
          hoveredItem: {
            status: "emitted",
            displayServer: "wayland",
            apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
            backend: "live-atspi-wayland-hit-test",
            resolutionScope: "hovered-row-descendant",
            entityKind: "file",
            itemName: "third.md",
            path: "/home/demo/Docs/third.md",
            pathSource: "hovered-row-label+parent-directory",
            visibleMarkdownPeerCount: 3,
            accepted: false,
            rejection:
              "hovered Nautilus item failed markdown acceptance: missing hovered path from HoveredRowLabelWithParentDirectory: /home/demo/Docs/third.md",
            detail:
              "Live Linux hovered-item probing classified the AT-SPI hit-test result through the shared markdown filter and kept the rejection detail for parity review.",
            note:
              "Wayland hovered-item diagnostics now run against a live AT-SPI hit-test at the supplied hover anchor; Ubuntu validation evidence is still required before parity sign-off.",
          },
          monitorSelection: {
            status: "emitted",
            selectionPolicy: "containing-work-area-then-nearest",
            anchor: { x: 2200, y: 300 },
            selectedMonitorId: "monitor-1",
            usedNearestFallback: false,
            workArea: { x: 1920, y: 0, width: 2560, height: 1400 },
            note: "Monitor-selection diagnostics are emitted now.",
          },
          previewPlacement: {
            status: "emitted",
            policy: "4:3-reposition-before-shrink",
            requestedWidth: 960,
            appliedGeometry: { x: 1942, y: 168, width: 960, height: 720 },
            note: "Preview-placement diagnostics are emitted now.",
          },
          editLifecycle: {
            status: "emitted",
            policy: "edit-lock-disables-blur-close",
            editing: false,
            closeOnBlurEnabled: true,
            canPersistPreviewEdits: false,
            lastCloseReason: "focus-lost",
            note: "Edit-lifecycle diagnostics are emitted now.",
          },
          hoverLifecycle: {
            status: "polling",
            pollingIntervalMs: 100,
            triggerDelayMs: 1000,
            lastAnchor: { x: 2200, y: 300 },
            observedPath: "/home/demo/Docs/third.md",
            previewVisible: true,
            previewPath: "/home/demo/Docs/second.md",
            lastAction: "replaced",
            note: "Linux hover lifecycle is active.",
          },
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxDisplayServer).toBe("wayland");
    expect(shell?.dataset.linuxFrontmostGateStatus).toBe("pending-live-probe");
    expect(shell?.dataset.linuxFrontmostGateTextInputActive).toBe("true");
    expect(shell?.dataset.linuxFrontmostGateTextInputRole).toBe("entry");
    expect(shell?.dataset.linuxFrontmostGateTextInputName).toBe("third.md");
    expect(shell?.dataset.linuxHoveredItemBackend).toBe("live-atspi-wayland-hit-test");
    expect(shell?.dataset.linuxHoveredItemApiStack).toContain(
      "AT-SPI Component.GetAccessibleAtPoint(screen)",
    );
    expect(shell?.dataset.linuxHoveredItemResolutionScope).toBe("hovered-row-descendant");
    expect(shell?.dataset.linuxHoveredItemEntityKind).toBe("file");
    expect(shell?.dataset.linuxHoveredItemPath).toBe("/home/demo/Docs/third.md");
    expect(shell?.dataset.linuxHoveredItemPathSource).toBe(
      "hovered-row-label+parent-directory",
    );
    expect(shell?.dataset.linuxHoveredItemAccepted).toBe("false");
    expect(shell?.dataset.linuxHoveredItemRejection).toContain("missing hovered path");
    expect(shell?.dataset.linuxHoveredItemDetail).toContain(
      "shared markdown filter",
    );
    expect(shell?.dataset.linuxHoveredItemItemName).toBe("third.md");
    expect(shell?.dataset.linuxHoveredItemVisibleMarkdownPeerCount).toBe("3");
    expect(shell?.dataset.linuxMonitorSelectionMonitorId).toBe("monitor-1");
    expect(shell?.dataset.linuxPreviewPlacementGeometry).toBe(
      "x=1942,y=168,width=960,height=720",
    );
    expect(shell?.dataset.linuxEditLifecyclePolicy).toBe("edit-lock-disables-blur-close");
    expect(shell?.dataset.linuxEditLifecycleCanPersistPreviewEdits).toBe("false");
    expect(shell?.dataset.linuxEditLifecycleLastCloseReason).toBe("focus-lost");
    expect(shell?.dataset.linuxEditLifecycleNote).toBe("Edit-lifecycle diagnostics are emitted now.");
    expect(shell?.dataset.linuxHoverLifecycleStatus).toBe("polling");
    expect(shell?.dataset.linuxHoverLifecyclePollingIntervalMs).toBe("100");
    expect(shell?.dataset.linuxHoverLifecycleTriggerDelayMs).toBe("1000");
    expect(shell?.dataset.linuxHoverLifecycleLastAnchor).toBe("x=2200,y=300");
    expect(shell?.dataset.linuxHoverLifecycleObservedPath).toBe("/home/demo/Docs/third.md");
    expect(shell?.dataset.linuxHoverLifecyclePreviewVisible).toBe("true");
    expect(shell?.dataset.linuxHoverLifecyclePreviewPath).toBe("/home/demo/Docs/second.md");
    expect(shell?.dataset.linuxHoverLifecycleLastAction).toBe("replaced");
    expect(document.body.textContent).not.toContain("Wayland frontmost-gate diagnostics are emitted now.");
    expect(document.body.textContent).not.toContain("edit-lock-disables-blur-close");
  });

  it("stores Ubuntu outside-click and app-switch close parity reasons as hidden shell metadata", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        linuxRuntimeDiagnostics: {
          displayServer: "x11",
          frontmostGate: {
            status: "emitted",
            displayServer: "x11",
            backend: "live-atspi-x11",
            apiStack:
              "focus=AT-SPI focused accessible + stable_surface=X11 _NET_ACTIVE_WINDOW",
            observedIdentifier: "org.gnome.Terminal",
            stableSurfaceId: "x11:0x3600011",
            windowTitle: "Terminal",
            processId: 4402,
            isOpen: false,
            inferredBlurCloseReason: "app-switch",
            rejection: "frontmost surface is not Nautilus",
            detail:
              "Live Linux frontmost probing rejected the foreground surface before close-reason inference.",
            note:
              "X11 frontmost-gate diagnostics now run against the live AT-SPI plus _NET_ACTIVE_WINDOW probe path; Ubuntu validation evidence is still required before parity sign-off.",
          },
          hoveredItem: {
            status: "pending-live-probe",
            displayServer: "x11",
            apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
            note: "hover pending",
          },
          monitorSelection: {
            status: "emitted",
            selectionPolicy: "containing-work-area-then-nearest",
            note: "monitor emitted",
          },
          previewPlacement: {
            status: "emitted",
            policy: "4:3-reposition-before-shrink",
            note: "placement emitted",
          },
          editLifecycle: {
            status: "emitted",
            policy: "edit-lock-disables-blur-close",
            editing: false,
            closeOnBlurEnabled: true,
            canPersistPreviewEdits: true,
            lastCloseReason: "app-switch",
            note: "Edit-lifecycle diagnostics are emitted now.",
          },
          hoverLifecycle: {
            status: "polling",
            pollingIntervalMs: 100,
            triggerDelayMs: 1000,
            previewVisible: false,
            note: "Linux hover lifecycle is active.",
          },
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxFrontmostGateInferredBlurCloseReason).toBe("app-switch");
    expect(shell?.dataset.linuxEditLifecycleLastCloseReason).toBe("app-switch");
    expect(shell?.dataset.linuxEditLifecycleCanPersistPreviewEdits).toBe("true");
    expect(document.body.textContent).not.toContain("app-switch");
    expect(document.body.textContent).not.toContain("_NET_ACTIVE_WINDOW");
  });

  it("saves inline edits through the attached-source bridge path", async () => {
    const updatedMarkdown = demoBootstrapPayload.shellState.markdown.replace(
      "# FastMD Stage 2 Preview Shell",
      "# Saved Through Preview",
    );
    savePreviewMarkdownMock.mockResolvedValue({
      ...demoBootstrapPayload.shellState,
      markdown: updatedMarkdown,
      sourceDocumentPath: "/tmp/attached.md",
    });

    createApp({
      ...demoBootstrapPayload,
      shellState: {
        ...demoBootstrapPayload.shellState,
        sourceDocumentPath: "/tmp/attached.md",
      },
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        canPersistPreviewEdits: true,
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const block = document.querySelector(".md-block");
    expect(block).not.toBeNull();
    block?.dispatchEvent(new MouseEvent("dblclick", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));

    const textarea = document.querySelector("#inline-editor-textarea") as HTMLTextAreaElement | null;
    expect(textarea).not.toBeNull();
    if (!textarea) {
      throw new Error("missing inline editor textarea");
    }
    textarea.value = "# Saved Through Preview\n";

    const saveButton = document.querySelector("#inline-editor-save");
    saveButton?.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(savePreviewMarkdownMock).toHaveBeenCalledWith(expect.stringContaining("# Saved Through Preview"));
    expect(document.body.classList.contains("is-editing")).toBe(false);
    expect(document.body.textContent).toContain("Saved Through Preview");
    expect(setEditingStateMock).toHaveBeenCalledWith(true);
    expect(setEditingStateMock).toHaveBeenCalledWith(false);
  });

  it("uses the same paged-scroll overshoot plan as the macOS reference shell", () => {
    expect(resolvePagedScrollTargets(100, 1000, 4000, 1)).toEqual({
      target: 1020,
      overshootTarget: 1054,
    });

    expect(resolvePagedScrollTargets(3600, 1000, 4000, 1)).toEqual({
      target: 4000,
      overshootTarget: 4000,
    });
  });

  it("normalizes wheel deltas into the preview scroll model", () => {
    expect(normalizeWheelScrollDelta(18, 0, 900)).toBe(18);
    expect(normalizeWheelScrollDelta(3, 1, 900)).toBe(30);
    expect(normalizeWheelScrollDelta(1, 2, 900)).toBe(900);
    expect(normalizeWheelScrollDelta(0, 0, 900)).toBe(0);
  });

  it("requests the same escape close reason as the macOS reference shell", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        runtimeMode: "desktop",
      },
    });

    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(requestPreviewCloseMock).toHaveBeenCalledWith("escape");
  });

  it("keeps close hotkeys suppressed while edit mode is locked", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
        canPersistPreviewEdits: true,
      },
      shellState: {
        ...demoBootstrapPayload.shellState,
        sourceDocumentPath: "/tmp/attached.md",
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const block = document.querySelector(".md-block");
    expect(block).not.toBeNull();
    block?.dispatchEvent(new MouseEvent("dblclick", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));

    window.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    window.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(requestPreviewCloseMock).not.toHaveBeenCalled();
    expect(document.body.textContent).toContain("← 1/4 →");
    expect(document.body.classList.contains("is-editing")).toBe(true);
  });
});
