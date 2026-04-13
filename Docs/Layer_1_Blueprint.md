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
- Layer 1 preview behavior: auto-show near cursor, replace only when a different hovered `.md` resolves, close on outside click/app switch/Escape
- Layer 1 packaging target: installable local `.app`

## Mandatory Clarifications From Live Testing

These are mandatory Layer 1 requirements and must be treated as non-optional checklist items:

- The resolver must open the actually hovered `.md` row in Finder list view and must not fall back to the first visible `.md` in the list when multiple Markdown files are present.
- The preview must stay visible during ordinary mouse movement within Finder; it must close only when a different Markdown file replaces it, when the user clicks outside the preview, when Finder loses focus, or when Escape is pressed.
- The full hover-to-preview loop must work on both the built-in display and external displays. Multi-display coordinate conversion for AX hit-testing and preview placement is a required part of Layer 1, not a later enhancement.
- The Markdown preview must cover a practical minimum syntax surface, including multi-level headings, emphasis, strong text, tables, syntax-highlighted fenced code blocks, Mermaid diagrams, math formulas, and other core readability blocks listed in Layer 1I.
- The preview panel must support four explicit width tiers, with the current width shown by default at the narrowest tier, the widest tier reaching 1920 pixels with a 1920:1440 4:3 target size, and left/right arrow hotkeys for stepwise width changes while the preview is hot.
- The preview must support inline block editing: double-clicking a rendered block enters edit mode for the smallest source Markdown block that produced it, the editor must show the original Markdown source for that block, saving must write back to the file and return to preview mode, and edit mode must lock the panel against hover replacement or outside-click dismissal until the edit is completed or canceled.
- Preview typography must stay readable at the narrowest width tier using a smaller fixed text scale rather than adaptive enlargement.
- The inline editor must align left, use about 60 percent of the current preview width, and size its edit box height to match the rendered block height it replaces.
- Preview placement may stay cursor-biased, but the selected width and height for the current tier have higher priority than keeping the popup's starting corner near the cursor. If the selected size still fits within the current screen, the popup must preserve that size and move position instead of shrinking. If the selected size cannot fit, it must still expand to the largest 4:3 size that can fit on the current screen rather than shrinking to an arbitrarily small fallback.
- Once the preview is visible it must become the active hot interaction surface so left/right arrows, Tab, mouse wheel scrolling, touchpad scrolling, and ordinary arrow-key scrolling operate on the preview without requiring the user to chase the hover state.
- The top-right preview chrome must stay minimal: any helper copy must avoid Space-based paging guidance, must not duplicate itself in a separate native overlay, must not keep always-visible pixel-resolution text, and must not spell out verbose helper words such as “明暗” and “翻页”.
- Preview motion must feel smooth: showing, hiding, width-tier switching, and Tab-based background switching must animate rather than snap abruptly.
- The current motion spec for Layer 1 is: popup entrance about 270ms ease-in-out, popup exit about 210ms ease-in-out, width-tier transitions about 360ms ease-in-out, Markdown-to-Markdown content crossfade using about 210ms fade-out plus 270ms fade-in, and Tab background transitions using short CSS-level color/opacity easing rather than hard snaps.
- Width-tier switching must animate both the native window frame and a subtle content-surface transition so small-to-medium tier jumps do not read as hard snaps.
- Space, Shift+Space, Page Up, and Page Down must not be used for preview paging on macOS, Linux, or Windows.

## Closed-Loop End State

Layer 1 is done only when all of the following are true on the same machine:

1. FastMD launches as a menu bar app.
2. Finder is frontmost in list view.
3. Mouse hovers over a visible local `.md` file item for 1 second.
4. FastMD resolves the actually hovered Finder item to a real file path.
5. FastMD reads the file and renders readable preview content.
6. FastMD shows a floating preview panel near the cursor on the correct display.
7. Hovering onto a different `.md` replaces the existing preview without requiring a restart or manual reset.
8. The preview supports stepwise width changes across four tiers from its narrowest default width up to a 1920:1440 4:3 maximum tier, driven by left/right arrow hotkeys while the preview is hot.
9. Double-clicking a rendered block enters inline edit mode for that block's original Markdown source and saving returns to preview mode without corrupting surrounding content.
10. Once visible, the preview accepts scrolling input directly from mouse wheel, touchpad, and directional scrolling keys without using keyboard paging keys.
11. Showing, hiding, width changes, and Tab-based background changes animate smoothly enough to avoid jarring snaps.
12. Clicking outside the preview, switching apps, or pressing Escape closes the preview when the panel is not in edit mode.
13. The loop can be repeated across many files and across both internal and external displays without restarting the app.

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

- [x] Create `Docs/Notes/`
- [ ] Create `Docs/Test_Logs/`
- [ ] Create `Docs/Screenshots/`
- [x] Create `Docs/Support_Matrix.md`
- [ ] Create `Docs/Manual_Test_Plan.md`
- [x] Create `Docs/Architecture_Notes.md`
- [x] Create `Docs/Release_Checklist.md`
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

- [ ] Create SwiftUI app entrypoint
- [ ] Create `AppDelegate`
- [ ] Replace menu bar text-only status item with a stable symbol or app icon
- [ ] Add menu items for `Pause Monitoring`, `Resume Monitoring`, `Request Accessibility Permission`, `Open Test Notes`, and `Quit`
- [ ] Keep menu titles synchronized with current monitoring state
- [ ] Add app version string display in the menu
- [ ] Make the app run as accessory/menu-bar-only and not rely on a Dock workflow
- [ ] Make app startup idempotent so repeated launches do not create duplicate monitors

## Layer 1C — Accessibility Permission Flow

- [ ] Add runtime Accessibility trust check
- [ ] Add explicit permission prompt trigger
- [ ] Add a dedicated permission state object
- [ ] Add a visible “permission missing” status in the menu
- [ ] Add a one-time explanatory copy block for why Accessibility is required
- [ ] Suppress preview attempts when Accessibility permission is missing
- [ ] Verify the app continues running safely after user denies permission
- [ ] Verify the app recovers correctly after permission is later granted without reinstall

## Layer 1D — Hover Detection Core

- [ ] Add global mouse movement monitoring
- [ ] Add local mouse movement monitoring
- [ ] Add 1-second hover debounce
- [ ] Track the last screen coordinate that armed the hover timer
- [ ] Track the last resolved Finder item identity
- [ ] Do not dismiss preview on ordinary mouse movement alone once a preview is visible
- [ ] Route scroll wheel and touchpad scrolling into the preview when it is visible instead of dismissing it
- [ ] Cancel preview when drag gestures are detected
- [ ] Add Escape-key dismissal
- [ ] Ensure hover timer does not reopen the same preview repeatedly while the cursor is stationary

## Layer 1E — Finder Frontmost and Context Gating

- [ ] Detect frontmost application bundle identifier
- [ ] Suppress hover resolution when Finder is not frontmost
- [ ] Hide preview immediately when Finder loses focus
- [ ] Re-arm monitoring when Finder becomes frontmost again
- [ ] Ignore Desktop hover for Layer 1 unless it is confirmed to resolve through the same list-view path
- [ ] Record supported Finder context assumptions in `Docs/Support_Matrix.md`

## Layer 1F — Finder List View Path Resolution

- [ ] Perform AX hit-test at mouse coordinates
- [ ] Convert hover coordinates correctly for Finder AX hit-testing on both internal and external displays
- [ ] Record the raw AX role/subrole/title/value chain for hovered Finder elements into debug logs
- [ ] Capture and save real Finder list-view AX snapshots into `Tests/Fixtures/FinderAX/`
- [ ] Identify the actual Finder list row/container roles used on this machine
- [ ] Implement parent-chain walking specifically for Finder list rows
- [ ] Select the nearest hovered Finder row or cell instead of scanning the list and taking the first visible Markdown candidate
- [ ] Extract the visible file name from the AX tree for a hovered Finder list row
- [ ] Query the current front Finder window target directory via AppleScript
- [ ] Reconstruct full path from `window target directory + hovered file name`
- [ ] Verify that reconstructed path exists on disk
- [ ] Return only local `.md` files from the resolver
- [ ] Reject directories, aliases that cannot be resolved, and non-Markdown files
- [ ] Log path-resolution failures with enough detail to debug the exact AX chain

## Layer 1G — Finder List View Real-World Hardening

- [ ] Verify that three or more visible `.md` files in the same Finder list resolve to the correct hovered file instead of the first visible `.md`
- [ ] Test the resolver on file names with spaces
- [ ] Test the resolver on file names with Chinese characters
- [ ] Test the resolver on deeply nested directories
- [ ] Test the resolver on hidden-dot markdown files
- [ ] Test the resolver on duplicated names in different directories after switching windows
- [ ] Test the resolver on symlinked markdown files
- [ ] Test the resolver on iCloud-downloaded markdown files
- [ ] Test the resolver on very long file names
- [ ] Test the resolver and preview loop on an external display with Finder frontmost
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

- [ ] Add lightweight prototype Markdown-to-HTML renderer
- [ ] Split renderer into block parsing and inline parsing helpers
- [ ] Render multi-level headings correctly
- [ ] Render paragraphs correctly
- [ ] Render emphasis and strong emphasis correctly
- [ ] Render combined bold+italic text correctly
- [ ] Render strikethrough correctly
- [ ] Render inline code correctly
- [ ] Render inline highlight correctly
- [ ] Render subscript and superscript correctly
- [ ] Render fenced code blocks correctly
- [ ] Add syntax highlighting for fenced code blocks with language hints
- [ ] Render blockquotes correctly
- [ ] Render nested blockquotes correctly
- [ ] Render unordered lists correctly
- [ ] Render ordered lists correctly
- [ ] Render task lists correctly
- [ ] Render links correctly
- [ ] Render simple tables correctly
- [ ] Render horizontal rules correctly
- [ ] Render images correctly
- [ ] Render Mermaid flowchart blocks correctly
- [ ] Render Mermaid gantt blocks correctly
- [ ] Render Mermaid sequence diagram blocks correctly
- [ ] Render inline math formulas correctly
- [ ] Render block math formulas correctly
- [ ] Render footnotes correctly
- [ ] Render HTML blocks correctly
- [ ] Render escaping cases correctly, including escaped leading marker characters that should remain literal text
- [ ] Add CSS tuned for readable preview density
- [ ] Keep preview typography fixed and small enough for the narrowest width tier
- [ ] Add dark-mode-aware CSS
- [ ] Add scrollable layout for long documents
- [ ] Add truncation rule for extremely large Markdown files
- [ ] Add “file too large” fallback view
- [ ] Add “read failed” fallback view
- [ ] Add a rich Markdown fixture that exercises headings, emphasis, tables, highlighted code, Mermaid, math, images, and mixed CJK text
- [ ] Save expected rendering snapshots or HTML fixtures for core markdown cases

## Layer 1J — Preview Panel Behavior

- [ ] Add floating panel shell
- [ ] Add cursor-relative placement
- [ ] Clamp preview position to screen visible frame
- [ ] Clamp preview position across multiple displays
- [ ] Add four explicit preview width tiers with the current width as the narrowest default tier
- [ ] Make the widest preview width tier 1920 pixels with a 1920:1440 4:3 target size
- [ ] Add left/right arrow hotkeys for width step-down and step-up while the preview is hot
- [ ] Keep preview size consistent and readable
- [x] Preserve the selected tier width and height whenever that size can still fit somewhere within the current screen by moving the popup instead of shrinking it
- [x] When the selected size cannot fit within the current screen, expand to the largest 4:3 size that fits instead of using an arbitrarily small fallback
- [x] Keep all fallback sizing on the same 4:3 ratio instead of distorting width and height independently
- [ ] Add title bar metadata showing file name
- [ ] Add optional path line in debug mode
- [x] Add smooth content replacement when hovering from one markdown file to another
- [x] Make preview replacement on a new hovered `.md` explicitly crossfade from old content to new content instead of snapping
- [ ] Prevent preview from stealing focus
- [x] Prevent preview from flickering during quick hover transitions
- [x] Add animated popup entrance
- [x] Add animated popup exit
- [x] Animate width-tier transitions instead of snapping between sizes
- [x] Add a subtle content-surface transition during width-tier changes so adjacent tiers still read as smooth motion
- [x] Animate Tab-based white/black background switches instead of snapping colors instantly
- [x] Use approximately 270ms entrance, 210ms exit, and 360ms width-transition timings with ease-in-out easing
- [x] Keep the top-right preview chrome minimal and avoid reintroducing any Space-based paging guidance, duplicate overlays, persistent resolution labels, or verbose helper words
- [ ] Add outside-click dismissal for the preview panel
- [ ] Keep preview visible while the user moves the cursor within Finder unless a replacement or dismissal condition is met
- [x] Make the visible preview become the active hot interaction surface without requiring the user to re-hover inside it
- [x] Add Tab hotkey to switch between pure white and pure black preview backgrounds while the preview is hot
- [x] Explicitly forbid Space / Shift+Space / Page Up / Page Down preview paging
- [x] Add mouse wheel and touchpad scrolling support for the preview while it is hot
- [x] Make keyboard paging use sticky eased motion with a slight settle instead of a hard jump
- [ ] Add inline block editing triggered by double-clicking a rendered block
- [ ] Restore the selected block to its original Markdown source when entering edit mode
- [ ] Keep the inline editor aligned left at roughly 60 percent of the current preview width
- [ ] Size the inline editor text area to the rendered block height it is replacing
- [ ] Save inline edits back into the source file and return to preview mode without replacing unrelated blocks
- [ ] Lock the preview in edit mode so hover replacement, outside-click dismissal, and similar interruptions cannot interfere until save or cancel
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
- [ ] Run and record test: hover multiple visible `.md` files in the same Finder window and confirm each hover opens the correct file rather than the first visible `.md`
- [ ] Run and record test: use left/right arrow hotkeys to move through all four width tiers and confirm the widest tier reaches 1920:1440
- [ ] Run and record test: confirm the fixed preview text scale stays comfortable on the narrowest width tier
- [ ] Run and record test: confirm Tab switches the preview between pure white and pure black backgrounds
- [ ] Run and record test: confirm popup show and hide are animated rather than abrupt
- [ ] Run and record test: confirm width-tier changes animate smoothly when using left/right arrows
- [ ] Run and record test: confirm switching from one hovered Markdown file to another crossfades old content out and new content in
- [ ] Run and record test: confirm Tab-based background switches animate smoothly rather than snapping
- [ ] Run and record test: confirm the top-right preview chrome stays collapsed into one compact hint chip without duplicate overlays, persistent pixel-resolution text, or verbose helper words
- [ ] Run and record test: hover non-markdown file and confirm no preview
- [ ] Run and record test: move cursor within Finder after preview opens and confirm the preview remains visible until a replacement or dismissal action occurs
- [ ] Run and record test: click outside the preview and confirm preview closes
- [ ] Run and record test: confirm mouse wheel and touchpad scrolling move the preview content without dismissing it
- [ ] Run and record test: confirm Space / Shift+Space / Page Up / Page Down do not trigger preview paging while the preview is hot
- [ ] Run and record test: confirm keyboard paging uses sticky eased motion instead of a hard jump
- [ ] Run and record test: double-click a rendered block, edit the original Markdown for that block, save, and confirm the preview updates while edit locking prevents outside interference
- [ ] Run and record test: confirm the inline editor stays left-aligned at about 60 percent width and its edit box height matches the replaced block height
- [ ] Run and record test: switch to another app and confirm preview closes
- [ ] Run and record test: press Escape and confirm preview closes
- [ ] Run and record test: switch Finder directory and confirm preview still works
- [ ] Run and record test: hover and preview on an external display and confirm both resolution and placement work there
- [ ] Run and record test: confirm the chosen tier size is preserved by repositioning whenever it still fits within the current screen
- [ ] Run and record test: confirm only true screen-size overflow triggers size reduction and that the reduced size is still the largest 4:3 fit for the current screen
- [ ] Run and record test: confirm the fallback path still preserves 4:3 rather than distorting width and height independently
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
