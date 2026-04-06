import { vi } from "vitest";

const { requestPreviewCloseMock } = vi.hoisted(() => ({
  requestPreviewCloseMock: vi.fn(async () => {}),
}));

vi.mock("./bridge", async () => {
  const actual = await vi.importActual<typeof import("./bridge")>("./bridge");
  return {
    ...actual,
    requestPreviewClose: requestPreviewCloseMock,
  };
});

import { PreviewShellApp, resolvePagedScrollTargets } from "./app";
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
    requestPreviewCloseMock.mockClear();
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

  it("hides fallback-only chrome copy on desktop shells", async () => {
    createApp({
      ...demoBootstrapPayload,
      hostCapabilities: {
        ...demoBootstrapPayload.hostCapabilities,
        platformId: "ubuntu",
        runtimeMode: "desktop",
      },
    });

    await new Promise((resolve) => setTimeout(resolve, 0));
    const capabilitySummary = document.querySelector('[data-role="capability-summary"]');
    const statusBanner = document.querySelector('[data-role="status-banner"]') as HTMLElement | null;

    expect(capabilitySummary?.textContent).toBe("");
    expect((capabilitySummary as HTMLElement | null)?.hidden).toBe(true);
    expect(statusBanner?.hidden).toBe(true);
    expect(document.body.textContent).not.toContain("browser shell fallback");
    expect(document.body.textContent).not.toContain("This shell scaffold keeps inline block saves");
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
});
