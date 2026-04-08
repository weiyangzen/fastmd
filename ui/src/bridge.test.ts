import { vi } from "vitest";

const { invokeMock, listenMock } = vi.hoisted(() => ({
  invokeMock: vi.fn(async () => null),
  listenMock: vi.fn(async () => () => {}),
}));

vi.mock("@tauri-apps/api/core", () => ({
  invoke: invokeMock,
}));

vi.mock("@tauri-apps/api/event", () => ({
  listen: listenMock,
}));

import {
  SHELL_STATE_EVENT,
  bootstrapShell,
  captureDesktopShellValidationSnapshot,
  captureLinuxValidationReport,
  listenToShellState,
} from "./bridge";
import { demoBootstrapPayload } from "./fixtures";

const tauriWindow = window as Window & {
  __TAURI_INTERNALS__?: Record<string, unknown>;
  __TAURI__?: Record<string, unknown>;
};

describe("FastMD Tauri bridge", () => {
  afterEach(() => {
    delete tauriWindow.__TAURI_INTERNALS__;
    delete tauriWindow.__TAURI__;
    invokeMock.mockReset();
    listenMock.mockReset();
  });

  it("falls back to null outside the Tauri runtime", async () => {
    await expect(bootstrapShell()).resolves.toBeNull();
    expect(invokeMock).not.toHaveBeenCalled();
  });

  it("invokes the desktop shell validation snapshot command with the supplied anchor", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};
    const snapshot = {
      capturedAtUnixMs: 1710000000123,
      shellState: demoBootstrapPayload.shellState,
      hostCapabilities: demoBootstrapPayload.hostCapabilities,
      linuxValidationReport: null,
    };
    invokeMock.mockResolvedValueOnce(snapshot);

    await expect(
      captureDesktopShellValidationSnapshot({ x: 240, y: 180 }),
    ).resolves.toEqual(snapshot);
    expect(invokeMock).toHaveBeenCalledWith(
      "capture_desktop_shell_validation_snapshot",
      { anchor: { x: 240, y: 180 } },
    );
  });

  it("invokes the linux validation report command with the supplied anchor", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};
    const report = {
      target: "Ubuntu 24.04 + GNOME Files / Nautilus",
      referenceSurface: "apps/macos",
      displayServer: "wayland",
      capturedAtUnixMs: 1710000000000,
      anchor: { x: 400, y: 220 },
      readyToCloseDisplayServerReport: true,
      crossSessionParityEvidenceReady: false,
      crossSessionParityEvidenceNote:
        "Single-session validation reports can only prove one live Ubuntu display server at a time.",
      readyChecklistItems: [],
      blockedChecklistItems: [],
      sections: [],
      notes: [],
      markdown: "# Ubuntu 24.04 GNOME Files Validation Evidence Report",
    };
    invokeMock.mockResolvedValueOnce(report);

    await expect(captureLinuxValidationReport({ x: 400, y: 220 })).resolves.toEqual(report);
    expect(invokeMock).toHaveBeenCalledWith(
      "capture_linux_validation_report",
      { anchor: { x: 400, y: 220 } },
    );
  });

  it("forwards shell-state events through the Tauri listener bridge", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};
    const payload = {
      ...demoBootstrapPayload.shellState,
      documentTitle: "Bridge.md",
    };
    listenMock.mockImplementationOnce(async (_event, handler) => {
      handler({ payload });
      return () => {};
    });

    const callback = vi.fn();
    const unlisten = await listenToShellState(callback);

    expect(listenMock).toHaveBeenCalledWith(SHELL_STATE_EVENT, expect.any(Function));
    expect(callback).toHaveBeenCalledWith(payload);
    expect(typeof unlisten).toBe("function");
  });
});
