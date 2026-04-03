# FastMD Layer 1 Blueprint

This document is the single execution checklist for FastMD.

## Fixed Product Defaults

These are locked for Layer 1 and do not need further debate:

- Layer 1 app form: macOS menu bar app
- Layer 1 host surface: Finder only
- Layer 1 supported Finder view: list view first
- Layer 1 trigger: hover over local `.md` file for 1 second
- Layer 1 permission model: Accessibility only
- Layer 1 preview rendering: Markdown -> HTML -> `WKWebView`
- Layer 1 preview behavior: auto-show near cursor, auto-hide on move-away/app switch/Escape
- Layer 1 packaging target: installable local `.app`

## Closed-Loop End State

Layer 1 is done only when all of the following are true on the same machine:

1. FastMD launches as a menu bar app.
2. Finder is frontmost in list view.
3. Mouse hovers over a visible local `.md` file item for 1 second.
4. FastMD resolves the hovered Finder item to a real file path.
5. FastMD reads the file and renders readable preview content.
6. FastMD shows a floating preview panel near the cursor.
7. Moving the cursor away, switching apps, or pressing Escape closes the preview.
8. The loop can be repeated across many files without restarting the app.

## Current Seed State

- [x] Create private repository `weiyangzen/fastmd`
- [x] Clone repository to `/Users/wangweiyang/Github/fastmd`
- [x] Initialize Swift package scaffold
- [x] Add menu bar app shell
- [x] Add Accessibility permission helper
- [x] Add hover debounce monitor
- [x] Add first-pass Finder hover resolver
- [x] Add floating preview panel shell
- [x] Add lightweight Markdown renderer prototype
- [x] Make `swift build` pass
- [x] Make `swift test` pass

## Required Artifact Outputs

These files and folders are mandatory deliverables for Layer 1:

- [ ] Create `Docs/Notes/`
- [ ] Create `Docs/Test_Logs/`
- [ ] Create `Docs/Screenshots/`
- [ ] Create `Docs/Support_Matrix.md`
- [ ] Create `Docs/Manual_Test_Plan.md`
- [ ] Create `Docs/Architecture_Notes.md`
- [ ] Create `Docs/Release_Checklist.md`
- [ ] Create `Tests/Fixtures/Markdown/`
- [ ] Create `Tests/Fixtures/RenderedHTML/`
- [ ] Create `Tests/Fixtures/FinderAX/`
- [ ] Create `Scripts/run_local_checks.sh`
- [ ] Create `Scripts/run_manual_smoke.sh`
- [ ] Create `Scripts/capture_finder_ax_snapshot.swift` or equivalent debug capture script

## Layer 1A — Repository and Project Baseline

- [ ] Add `.swiftlint.yml` or explicitly document no-linter baseline in `README.md`
- [ ] Update `README.md` to match the fixed product defaults in this blueprint
- [ ] Add a `make`/`just`/script entry for local build and run
- [ ] Make the repository build cleanly from a fresh clone with one documented command sequence
- [ ] Add a single local verification entrypoint that runs build + tests + smoke checks
- [ ] Record the exact local verification command in `README.md`

## Layer 1B — App Shell Completion

- [x] Create SwiftUI app entrypoint
- [x] Create `AppDelegate`
- [ ] Replace menu bar text-only status item with a stable symbol or app icon
- [ ] Add menu items for `Pause Monitoring`, `Resume Monitoring`, `Request Accessibility Permission`, `Open Test Notes`, and `Quit`
- [ ] Keep menu titles synchronized with current monitoring state
- [ ] Add app version string display in the menu
- [ ] Make the app run as accessory/menu-bar-only and not rely on a Dock workflow
- [ ] Make app startup idempotent so repeated launches do not create duplicate monitors

## Layer 1C — Accessibility Permission Flow

- [x] Add runtime Accessibility trust check
- [x] Add explicit permission prompt trigger
- [ ] Add a dedicated permission state object
- [ ] Add a visible “permission missing” status in the menu
- [ ] Add a one-time explanatory copy block for why Accessibility is required
- [ ] Suppress preview attempts when Accessibility permission is missing
- [ ] Verify the app continues running safely after user denies permission
- [ ] Verify the app recovers correctly after permission is later granted without reinstall

## Layer 1D — Hover Detection Core

- [x] Add global mouse movement monitoring
- [x] Add local mouse movement monitoring
- [x] Add 1-second hover debounce
- [ ] Track the last screen coordinate that armed the hover timer
- [ ] Track the last resolved Finder item identity
- [ ] Cancel preview immediately on mouse motion after preview is shown
- [ ] Cancel preview when scroll wheel events are detected
- [ ] Cancel preview when drag gestures are detected
- [ ] Add Escape-key dismissal
- [ ] Ensure hover timer does not reopen the same preview repeatedly while the cursor is stationary

## Layer 1E — Finder Frontmost and Context Gating

- [x] Detect frontmost application bundle identifier
- [ ] Suppress hover resolution when Finder is not frontmost
- [ ] Hide preview immediately when Finder loses focus
- [ ] Re-arm monitoring when Finder becomes frontmost again
- [ ] Ignore Desktop hover for Layer 1 unless it is confirmed to resolve through the same list-view path
- [ ] Record supported Finder context assumptions in `Docs/Support_Matrix.md`

## Layer 1F — Finder List View Path Resolution

- [x] Perform AX hit-test at mouse coordinates
- [ ] Record the raw AX role/subrole/title/value chain for hovered Finder elements into debug logs
- [ ] Capture and save real Finder list-view AX snapshots into `Tests/Fixtures/FinderAX/`
- [ ] Identify the actual Finder list row/container roles used on this machine
- [ ] Implement parent-chain walking specifically for Finder list rows
- [ ] Extract the visible file name from the AX tree for a hovered Finder list row
- [ ] Query the current front Finder window target directory via AppleScript
- [ ] Reconstruct full path from `window target directory + hovered file name`
- [ ] Verify that reconstructed path exists on disk
- [ ] Return only local `.md` files from the resolver
- [ ] Reject directories, aliases that cannot be resolved, and non-Markdown files
- [ ] Log path-resolution failures with enough detail to debug the exact AX chain

## Layer 1G — Finder List View Real-World Hardening

- [ ] Test the resolver on file names with spaces
- [ ] Test the resolver on file names with Chinese characters
- [ ] Test the resolver on deeply nested directories
- [ ] Test the resolver on hidden-dot markdown files
- [ ] Test the resolver on duplicated names in different directories after switching windows
- [ ] Test the resolver on symlinked markdown files
- [ ] Test the resolver on iCloud-downloaded markdown files
- [ ] Test the resolver on very long file names
- [ ] Document all confirmed-supported list-view cases in `Docs/Support_Matrix.md`
- [ ] Document all confirmed-broken list-view cases in `Docs/Support_Matrix.md`

## Layer 1H — Markdown File Loading

- [ ] Move file loading behind a dedicated `MarkdownDocumentLoader`
- [ ] Read file contents off the main thread
- [ ] Support UTF-8 files directly
- [ ] Add fallback handling for common decode failures
- [ ] Add file size guardrail
- [ ] Add safe handling for unreadable files
- [ ] Add safe handling for deleted files between hover and read
- [ ] Add safe handling for files that change while preview is visible
- [ ] Add fixture markdown files covering tiny, normal, long, malformed, and CJK-heavy content

## Layer 1I — Markdown Rendering

- [x] Add lightweight prototype Markdown-to-HTML renderer
- [ ] Split renderer into block parsing and inline parsing helpers
- [ ] Render headings correctly
- [ ] Render paragraphs correctly
- [ ] Render inline code correctly
- [ ] Render fenced code blocks correctly
- [ ] Render blockquotes correctly
- [ ] Render unordered lists correctly
- [ ] Render ordered lists correctly
- [ ] Render links correctly
- [ ] Render simple tables correctly
- [ ] Add CSS tuned for readable preview density
- [ ] Add dark-mode-aware CSS
- [ ] Add scrollable layout for long documents
- [ ] Add truncation rule for extremely large Markdown files
- [ ] Add “file too large” fallback view
- [ ] Add “read failed” fallback view
- [ ] Save expected rendering snapshots or HTML fixtures for core markdown cases

## Layer 1J — Preview Panel Behavior

- [x] Add floating panel shell
- [x] Add cursor-relative placement
- [ ] Clamp preview position to screen visible frame
- [ ] Clamp preview position across multiple displays
- [ ] Keep preview size consistent and readable
- [ ] Add title bar metadata showing file name
- [ ] Add optional path line in debug mode
- [ ] Add smooth content replacement when hovering from one markdown file to another
- [ ] Prevent preview from stealing focus
- [ ] Prevent preview from flickering during quick hover transitions
- [ ] Ensure preview hides on Escape
- [ ] Ensure preview hides on app switch
- [ ] Ensure preview hides when Finder window closes

## Layer 1K — Performance and Caching

- [ ] Add cache keyed by file path + modification date
- [ ] Reuse cached HTML for repeated hover on unchanged files
- [ ] Add render queue so only the latest hover request wins
- [ ] Drop stale render jobs when the cursor has moved away
- [ ] Move expensive parsing and HTML generation off the main thread
- [ ] Measure latency from hover trigger to preview visible
- [ ] Record latency samples in `Docs/Test_Logs/`
- [ ] Keep average visible-preview latency within a documented budget for normal files

## Layer 1L — Automated Test Closure

- [ ] Add unit tests for Markdown rendering of headings
- [ ] Add unit tests for Markdown rendering of lists
- [ ] Add unit tests for Markdown rendering of fenced code blocks
- [ ] Add unit tests for Markdown rendering of blockquotes
- [ ] Add unit tests for Markdown rendering of links
- [ ] Add unit tests for Markdown rendering of simple tables
- [ ] Add unit tests for very large markdown truncation behavior
- [ ] Add unit tests for file loading success and read-failure cases
- [ ] Add unit tests for cache key behavior using file path plus modification time
- [ ] Add unit tests for hover debounce timing state transitions
- [ ] Add unit tests for preview dismissal state transitions
- [ ] Add tests for Finder path reconstruction using recorded AX fixtures
- [ ] Add tests for rejecting non-`.md` targets from recorded AX fixtures
- [ ] Add tests for Finder frontmost gating logic
- [ ] Make `swift test` cover all non-UI core logic paths added in Layer 1
- [ ] Add `Scripts/run_local_checks.sh` that runs `swift build` and `swift test`
- [ ] Make `Scripts/run_local_checks.sh` return non-zero on any failure
- [ ] Run `Scripts/run_local_checks.sh` successfully and record the output in `Docs/Test_Logs/`

## Layer 1M — Diagnostics and Debugging

- [ ] Add debug mode toggle in the menu
- [ ] Add logging for Finder frontmost transitions
- [ ] Add logging for AX hit-test results
- [ ] Add logging for path reconstruction
- [ ] Add logging for file loading failures
- [ ] Add logging for render failures
- [ ] Add menu action to copy latest debug snapshot
- [ ] Write one real debug snapshot example to `Docs/Test_Logs/`

## Layer 1N — Manual Validation

- [ ] Run and record test: hover one markdown file in Finder list view and get preview
- [ ] Run and record test: hover ten different markdown files sequentially without restart
- [ ] Run and record test: hover non-markdown file and confirm no preview
- [ ] Run and record test: move cursor away and confirm preview closes
- [ ] Run and record test: switch to another app and confirm preview closes
- [ ] Run and record test: press Escape and confirm preview closes
- [ ] Run and record test: switch Finder directory and confirm preview still works
- [ ] Save screenshots or notes for each test in `Docs/Test_Logs/`

## Layer 1O — Layer-1 Completion Work

- [ ] Update `Docs/Architecture_Notes.md` with the actual implemented Finder list-view resolution strategy
- [ ] Update `Docs/Support_Matrix.md` with “supported / unsupported” entries
- [ ] Update `Docs/Manual_Test_Plan.md` with the final repeatable manual smoke sequence
- [ ] Update `Docs/Release_Checklist.md` with the exact Layer 1 release steps
- [ ] Update `README.md` with the exact current behavior and limitations
- [ ] Remove or downgrade prototype-only comments that no longer reflect implementation reality
- [ ] Run local verification command successfully one final time before marking Layer 1 complete
- [ ] Commit the full Layer 1 list-view closed loop implementation

## Layer 2 — Expansion to Additional Finder Views

- [ ] Add icon view AX structure capture logs
- [ ] Implement icon view path resolution
- [ ] Test icon view hover preview on real files
- [ ] Add column view AX structure capture logs
- [ ] Implement column view path resolution
- [ ] Test column view hover preview on real files
- [ ] Add gallery view AX structure capture logs
- [ ] Implement gallery view support or explicitly mark gallery view unsupported in docs
- [ ] Update `Docs/Support_Matrix.md` after each view-mode addition

## Layer 3 — Product Polish

- [ ] Add launch-at-login support
- [ ] Add preview width configuration
- [ ] Add preview height configuration
- [ ] Add hover delay configuration
- [ ] Add preview theme selection
- [ ] Add “pin current preview” action
- [ ] Add “open file in default editor” action from preview
- [ ] Add “open parent folder” action from preview
- [ ] Add stable app icon assets
- [ ] Add About window or compact info panel

## Layer 4 — Packaging and Release

- [ ] Add bundle identifier
- [ ] Add app versioning
- [ ] Add release build settings
- [ ] Add entitlements required by the chosen app packaging route
- [ ] Build a runnable `.app`
- [ ] Test launch and permission flow from the built `.app`
- [ ] Test a clean install on a second machine or clean user environment
- [ ] Write install steps into `README.md`
- [ ] Write release checklist completion into `Docs/Release_Checklist.md`

## Quality Checklist

- [ ] Make `swift build` pass after every major phase
- [ ] Make `swift test` pass after every major phase
- [ ] Keep `Scripts/run_local_checks.sh` green after every major phase
- [ ] Keep the app crash-free when hovering unsupported Finder elements
- [ ] Keep the app crash-free when reading empty Markdown files
- [ ] Keep the app crash-free when reading large Markdown files
- [ ] Keep the app crash-free when file resolution fails
- [ ] Keep the app crash-free when permission is absent
- [ ] Keep the app crash-free when Finder is closed or relaunched

## Final Product Checklist

- [ ] Ship a menu bar app that starts and stays running
- [ ] Ship a reliable Finder list-view `.md` hover closed loop
- [ ] Ship readable Markdown preview rendering
- [ ] Ship automated local verification for the non-UI core logic
- [ ] Ship manual smoke instructions for the real Finder loop
- [ ] Ship clean dismissal behavior on move-away, app switch, and Escape
- [ ] Ship documented support boundaries
- [ ] Ship a runnable local `.app`
- [ ] Ship clear install and permission instructions
