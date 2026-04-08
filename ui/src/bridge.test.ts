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
  exportDesktopShellValidationArtifacts,
  exportLinuxValidationReviewSignoff,
  listenToShellState,
  readLinuxFrontmostTextInputState,
  readLinuxValidationEvidenceLatestReportChecklistStatuses,
  readLinuxValidationEvidenceLatestReportByDisplayServer,
  readLinuxHoveredItemPresentationMode,
  startPreviewWindowDrag,
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
      crossSessionRequiredDisplayServers: ["wayland", "x11"],
      crossSessionCapturedDisplayServers: [],
      crossSessionMissingDisplayServers: ["wayland", "x11"],
      crossSessionReadyDisplayServerReports: [],
      checklistStatuses: [
        {
          checklistItem:
            "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
          sectionTitle: "Frontmost Nautilus evidence",
          status: "pass",
        },
      ],
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

  it("invokes the desktop validation artifact export command with the supplied anchor", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};
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
          "Single-session validation reports can only prove one live Ubuntu display server at a time.",
        requiredDisplayServers: ["wayland", "x11"],
        capturedDisplayServers: ["wayland"],
        missingDisplayServers: ["x11"],
        readyDisplayServerReports: ["wayland"],
        latestReports: [
          {
            displayServer: "wayland",
            capturedAtUnixMs: 1710000000000,
            readyToCloseDisplayServerReport: true,
            reportMarkdownPath:
              "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.md",
            reportJsonPath:
              "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.json",
            checklistStatuses: [
              {
                checklistItem:
                  "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
                sectionTitle: "Frontmost Nautilus evidence",
                status: "pass",
              },
            ],
            readyChecklistItems: [
              "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
            ],
            blockedChecklistItems: [
              "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
            ],
          },
        ],
      },
    };
    invokeMock.mockResolvedValueOnce(exportPayload);

    await expect(
      exportDesktopShellValidationArtifacts({ x: 512, y: 288 }),
    ).resolves.toEqual(exportPayload);
    expect(invokeMock).toHaveBeenCalledWith(
      "export_desktop_shell_validation_artifacts",
      { anchor: { x: 512, y: 288 } },
    );
  });

  it("invokes the Ubuntu validation review sign-off command with reviewer metadata", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};
    const signoffPayload = {
      reviewedAtUnixMs: 1710000000999,
      outputDirectory: "/repo/Docs/Test_Logs",
      reviewMarkdownPath: "/repo/Docs/Test_Logs/ubuntu-validation-review-signoff.md",
      reviewJsonPath: "/repo/Docs/Test_Logs/ubuntu-validation-review-signoff.json",
      linuxValidationEvidence: {
        status: "cross-session-reviewed-ready-to-close",
        checklistItem:
          "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
        note:
          "Wayland and X11 live Ubuntu validation reports were reviewed and explicitly signed off.",
        readyToCloseChecklistItem: true,
        requiredDisplayServers: ["wayland", "x11"],
        capturedDisplayServers: ["wayland", "x11"],
        missingDisplayServers: [],
        readyDisplayServerReports: ["wayland", "x11"],
        reviewedDisplayServers: ["wayland", "x11"],
        reviewArtifactMarkdownPath:
          "/repo/Docs/Test_Logs/ubuntu-validation-review-signoff.md",
        reviewArtifactJsonPath:
          "/repo/Docs/Test_Logs/ubuntu-validation-review-signoff.json",
        reviewedAtUnixMs: 1710000000999,
        reviewedBy: "worker-2",
        reviewNote: "Reviewed against the macOS parity checklist.",
        latestReports: [],
      },
    };
    invokeMock.mockResolvedValueOnce(signoffPayload);

    await expect(
      exportLinuxValidationReviewSignoff(
        "worker-2",
        "Reviewed against the macOS parity checklist.",
      ),
    ).resolves.toEqual(signoffPayload);
    expect(invokeMock).toHaveBeenCalledWith(
      "export_linux_validation_review_signoff",
      {
        reviewer: "worker-2",
        reviewNote: "Reviewed against the macOS parity checklist.",
      },
    );
  });

  it("invokes the preview window drag command inside the Tauri runtime", async () => {
    tauriWindow.__TAURI_INTERNALS__ = {};

    await expect(startPreviewWindowDrag()).resolves.toBeUndefined();
    expect(invokeMock).toHaveBeenCalledWith("start_preview_window_drag", undefined);
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

  it("extracts frontmost Nautilus text-input diagnostics from host capabilities", () => {
    const state = readLinuxFrontmostTextInputState({
      ...demoBootstrapPayload.hostCapabilities,
      linuxRuntimeDiagnostics: {
        displayServer: "wayland",
        frontmostGate: {
          status: "emitted",
          displayServer: "wayland",
          apiStack: "focus=AT-SPI focused accessible",
          textInputActive: true,
          textInputRole: "entry",
          textInputName: "Report.md",
          note: "frontmost note",
        },
        hoveredItem: {
          status: "pending-live-probe",
          displayServer: "wayland",
          apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          note: "hover note",
        },
        monitorSelection: {
          status: "emitted",
          selectionPolicy: "containing-work-area-then-nearest",
          note: "monitor note",
        },
        previewPlacement: {
          status: "emitted",
          policy: "4:3-reposition-before-shrink",
          note: "placement note",
        },
        editLifecycle: {
          status: "emitted",
          policy: "edit-lock-disables-blur-close",
          editing: false,
          closeOnBlurEnabled: true,
          canPersistPreviewEdits: false,
          note: "edit note",
        },
      },
    });

    expect(state).toEqual({
      textInputActive: true,
      textInputRole: "entry",
      textInputName: "Report.md",
    });
  });

  it("extracts the hovered Nautilus presentation mode from host capabilities", () => {
    const mode = readLinuxHoveredItemPresentationMode({
      ...demoBootstrapPayload.hostCapabilities,
      linuxRuntimeDiagnostics: {
        displayServer: "wayland",
        frontmostGate: {
          status: "emitted",
          displayServer: "wayland",
          apiStack: "focus=AT-SPI focused accessible",
          note: "frontmost note",
        },
        hoveredItem: {
          status: "emitted",
          displayServer: "wayland",
          apiStack: "pointer=AT-SPI Component.GetAccessibleAtPoint(screen)",
          presentationMode: "non-list",
          note: "hover note",
        },
        monitorSelection: {
          status: "emitted",
          selectionPolicy: "containing-work-area-then-nearest",
          note: "monitor note",
        },
        previewPlacement: {
          status: "emitted",
          policy: "4:3-reposition-before-shrink",
          note: "placement note",
        },
        editLifecycle: {
          status: "emitted",
          policy: "edit-lock-disables-blur-close",
          editing: false,
          closeOnBlurEnabled: true,
          canPersistPreviewEdits: false,
          note: "edit note",
        },
      },
    });

    expect(mode).toBe("non-list");
  });

  it("extracts the cached latest validation report for one display server", () => {
    const report = readLinuxValidationEvidenceLatestReportByDisplayServer(
      {
        ...demoBootstrapPayload.hostCapabilities,
        linuxValidationEvidence: {
          status: "cross-session-review-required",
          checklistItem:
            "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
          note:
            "Single-session validation reports can only prove one live Ubuntu display server at a time.",
          requiredDisplayServers: ["wayland", "x11"],
          capturedDisplayServers: ["wayland"],
          missingDisplayServers: ["x11"],
          readyDisplayServerReports: ["wayland"],
          latestReports: [
            {
              displayServer: "wayland",
              capturedAtUnixMs: 1710000000000,
              readyToCloseDisplayServerReport: true,
              reportMarkdownPath:
                "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.md",
              reportJsonPath:
                "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.json",
              checklistStatuses: [
                {
                  checklistItem:
                    "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
                  sectionTitle: "Frontmost Nautilus evidence",
                  status: "pass",
                },
              ],
              readyChecklistItems: [
                "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
              ],
              blockedChecklistItems: [
                "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
              ],
            },
          ],
        },
      },
      "wayland",
    );

    expect(report?.reportMarkdownPath).toContain("ubuntu-validation-report-wayland");
    expect(report?.readyChecklistItems).toEqual([
      "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
    ]);
    expect(report?.blockedChecklistItems).toEqual([
      "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
    ]);
  });

  it("extracts the cached checklist-status matrix for one display server", () => {
    const checklistStatuses = readLinuxValidationEvidenceLatestReportChecklistStatuses(
      {
        ...demoBootstrapPayload.hostCapabilities,
        linuxValidationEvidence: {
          status: "cross-session-review-required",
          checklistItem:
            "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
          note:
            "Single-session validation reports can only prove one live Ubuntu display server at a time.",
          requiredDisplayServers: ["wayland", "x11"],
          capturedDisplayServers: ["wayland"],
          missingDisplayServers: ["x11"],
          readyDisplayServerReports: ["wayland"],
          latestReports: [
            {
              displayServer: "wayland",
              capturedAtUnixMs: 1710000000000,
              readyToCloseDisplayServerReport: true,
              reportMarkdownPath:
                "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.md",
              reportJsonPath:
                "/repo/Docs/Test_Logs/ubuntu-validation-report-wayland-1710000000000.json",
              checklistStatuses: [
                {
                  checklistItem:
                    "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
                  sectionTitle: "Frontmost Nautilus evidence",
                  status: "pass",
                },
                {
                  checklistItem:
                    "Validate exact hovered-item resolution on a real Ubuntu 24.04 Wayland session",
                  sectionTitle: "Hovered Markdown evidence",
                  status: "fail",
                },
              ],
              readyChecklistItems: [
                "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
              ],
              blockedChecklistItems: [
                "Record Ubuntu-specific validation evidence proving one-to-one parity with macOS for each feature above",
              ],
            },
          ],
        },
      },
      "wayland",
    );

    expect(checklistStatuses).toEqual([
      {
        checklistItem:
          "Validate frontmost Nautilus detection on a real Ubuntu 24.04 Wayland session",
        sectionTitle: "Frontmost Nautilus evidence",
        status: "pass",
      },
      {
        checklistItem:
          "Validate exact hovered-item resolution on a real Ubuntu 24.04 Wayland session",
        sectionTitle: "Hovered Markdown evidence",
        status: "fail",
      },
    ]);
  });
});
