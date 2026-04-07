import { vi } from "vitest";

const {
  replacePreviewMarkdownMock,
  requestPreviewCloseMock,
  savePreviewMarkdownMock,
  setEditingStateMock,
} = vi.hoisted(() => ({
  replacePreviewMarkdownMock: vi.fn(async () => null),
  requestPreviewCloseMock: vi.fn(async () => {}),
  savePreviewMarkdownMock: vi.fn(async () => null),
  setEditingStateMock: vi.fn(async () => {}),
}));

vi.mock("./bridge", async () => {
  const actual = await vi.importActual<typeof import("./bridge")>("./bridge");
  return {
    ...actual,
    replacePreviewMarkdown: replacePreviewMarkdownMock,
    requestPreviewClose: requestPreviewCloseMock,
    savePreviewMarkdown: savePreviewMarkdownMock,
    setEditingState: setEditingStateMock,
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
    replacePreviewMarkdownMock.mockClear();
    requestPreviewCloseMock.mockClear();
    savePreviewMarkdownMock.mockClear();
    setEditingStateMock.mockClear();
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
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxWaylandHoveredItemApiStack).toContain(
      "AT-SPI Component.GetAccessibleAtPoint(screen)",
    );
    expect(shell?.dataset.linuxX11FrontmostApiStack).toContain("X11 _NET_ACTIVE_WINDOW");
    expect(document.body.textContent).not.toContain("AT-SPI Component.GetAccessibleAtPoint(screen)");
    expect(document.body.textContent).not.toContain("X11 _NET_ACTIVE_WINDOW");
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
            note: "Wayland frontmost-gate diagnostics are emitted now.",
          },
          hoveredItem: {
            status: "pending-live-probe",
            displayServer: "wayland",
            apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
            itemName: "third.md",
            pathSource: "hovered-row-label+parent-directory",
            visibleMarkdownPeerCount: 3,
            note: "Wayland hovered-item diagnostics are emitted now.",
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
        },
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const shell = document.querySelector(".shell") as HTMLElement | null;

    expect(shell?.dataset.linuxDisplayServer).toBe("wayland");
    expect(shell?.dataset.linuxFrontmostGateStatus).toBe("pending-live-probe");
    expect(shell?.dataset.linuxHoveredItemApiStack).toContain(
      "AT-SPI Component.GetAccessibleAtPoint(screen)",
    );
    expect(shell?.dataset.linuxHoveredItemPathSource).toBe(
      "hovered-row-label+parent-directory",
    );
    expect(shell?.dataset.linuxHoveredItemItemName).toBe("third.md");
    expect(shell?.dataset.linuxHoveredItemVisibleMarkdownPeerCount).toBe("3");
    expect(shell?.dataset.linuxMonitorSelectionMonitorId).toBe("monitor-1");
    expect(shell?.dataset.linuxPreviewPlacementGeometry).toBe(
      "x=1942,y=168,width=960,height=720",
    );
    expect(shell?.dataset.linuxEditLifecycleLastCloseReason).toBe("focus-lost");
    expect(document.body.textContent).not.toContain("Wayland frontmost-gate diagnostics are emitted now.");
    expect(document.body.textContent).not.toContain("edit-lock-disables-blur-close");
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
