# FastMD Manual Test Plan

## Scope

This plan validates the FastMD prototype behavior that exists in the repository today. It is intentionally limited to the current implementation and should not be treated as evidence for later blueprint items that are not yet built.

## Preconditions

- macOS 14 or newer with the Swift 6.3 toolchain installed
- Finder available and able to switch to list view
- Local repository checkout at `/Users/wangweiyang/Github/fastmd/.cron/automation_repo_slot2`
- Manual smoke fixtures present under `Tests/Fixtures/Markdown/`
- Accessibility permission may be requested on first launch

## Test Assets

- Manual smoke helper: `Scripts/run_manual_smoke.sh`
- Local verification helper: `Scripts/run_local_checks.sh`
- Primary positive fixture: `Tests/Fixtures/Markdown/basic.md`
- CJK fixture: `Tests/Fixtures/Markdown/cjk.md`
- Negative fixture: `Tests/Fixtures/Markdown/not-markdown.txt`
- Evidence directory for notes: `Docs/Test_Logs/`
- Evidence directory for screenshots: `Docs/Screenshots/`

## Environment Setup

1. Run `Scripts/run_local_checks.sh` to confirm the package still builds and tests.
2. Run `Scripts/run_manual_smoke.sh` or open Finder to `Tests/Fixtures/Markdown/`.
3. Confirm Finder is in list view and that `basic.md`, `cjk.md`, and `not-markdown.txt` are visible.
4. If Accessibility permission has not already been granted, be ready to approve it when FastMD prompts.

## Smoke Cases

### 1. Launch and status item

Steps:

1. Run `Scripts/run_manual_smoke.sh`.
2. Wait for Finder to open and for the FastMD process to launch.
3. Inspect the menu bar.

Expected result:

- A `FastMD` menu bar item appears.
- The app runs without showing a Dock-based workflow.

### 2. Monitoring toggle menu

Steps:

1. Open the `FastMD` menu bar menu.
2. Click `Pause Monitoring`.
3. Reopen the menu.
4. Click `Resume Monitoring`.

Expected result:

- The first click stops monitoring and changes the menu item label to `Resume Monitoring`.
- The second click restarts monitoring and changes the menu item label back to `Pause Monitoring`.

### 3. Accessibility permission request entrypoint

Steps:

1. Open the `FastMD` menu.
2. Click `Request Accessibility Permission`.

Expected result:

- The action completes without crashing the app.
- If the app is not trusted yet, macOS presents or re-opens the Accessibility approval flow.

### 4. Positive preview for a local Markdown file

Steps:

1. Ensure Finder is frontmost and still in list view.
2. Hover the pointer over `basic.md` for at least 1 second without moving.

Expected result:

- A floating preview panel appears near the cursor.
- The preview contains the `FastMD Smoke Fixture` heading.
- The preview renders inline code and a fenced code block.

### 5. UTF-8 Markdown preview

Steps:

1. Hover the pointer over `cjk.md` for at least 1 second without moving.

Expected result:

- A floating preview panel appears.
- Chinese text is readable and not replaced with mojibake.

### 6. Reject non-Markdown files

Steps:

1. In Finder list view, hover `not-markdown.txt` for at least 1 second.

Expected result:

- No preview panel is shown.

### 7. Dismiss on mouse movement

Steps:

1. Show a preview for `basic.md`.
2. Move the pointer away or scroll the mouse wheel.

Expected result:

- The preview hides immediately after further mouse activity.

### 8. Dismiss when Finder is no longer frontmost

Steps:

1. Show a preview for `basic.md`.
2. Switch to another app with `Command-Tab`.

Expected result:

- The preview hides when Finder loses focus.

## Evidence Capture

- Save result notes as `Docs/Test_Logs/manual-smoke-YYYYMMDD-HHMMSS.md`.
- Save screenshots as `Docs/Screenshots/manual-smoke-YYYYMMDD-HHMMSS-<case>.png`.
- Record the macOS version, Xcode or Swift toolchain version, and whether Accessibility trust was already granted before the run started.

## Known Limits for This Plan

- This plan only assumes Finder list view.
- `Scripts/run_manual_smoke.sh` attempts to switch Finder to list view automatically, but manual correction may still be needed if macOS ignores the request.
- It does not validate icon view, column view, gallery view, or Desktop hover.
- It does not validate packaging, signing, or a final `.app` bundle flow.
- It does not validate automated AX fixture capture because that capture script is a later deliverable.
