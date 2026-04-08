# FastMD Support Matrix

This matrix records the current Layer 1 support boundary for the repository as it exists today. It distinguishes between behavior that is implemented in code, behavior that is intentionally unsupported, and behavior that still needs real-world validation.

## Status Legend

- `Supported`: implemented and aligned with the current prototype path.
- `Implemented, needs validation`: code exists, but the repository does not yet contain manual test evidence for it.
- `Unsupported`: intentionally out of scope for the current prototype or not implemented yet.

## Core App Behavior

| Area | Status | Notes |
| --- | --- | --- |
| Menu bar app startup | Supported | `FastMDApp` launches through `AppDelegate`, sets activation policy to `.accessory`, and creates an `NSStatusItem`. |
| Accessibility-gated startup | Supported | Monitoring starts only if `AccessibilityPermissionManager.ensureTrusted(prompt: true)` succeeds. |
| Finder-only monitoring | Supported | Hover resolution immediately returns `nil` unless Finder is the frontmost app. |
| Auto-hide when Finder loses focus | Supported | `FinderHoverCoordinator` listens for front-app changes and hides the preview when Finder is no longer active. |
| Hover debounce | Supported | Hover resolution arms after 1.0 second of no mouse motion, drag, or scroll activity. |
| Repeated hover over the same resolved item | Supported | The coordinator suppresses reopening when the newly resolved item matches the current one. |
| Escape-to-dismiss | Unsupported | No key monitor or Escape handler exists yet. |

## Finder Contexts

| Context | Status | Notes |
| --- | --- | --- |
| Finder frontmost, list-style item hit-testing | Implemented, needs validation | The resolver performs an AX hit-test at the mouse location and walks the parent chain when it cannot read a direct path attribute. |
| Finder icon view | Implemented, needs validation | When the hit-tested element is an `AXImage`, the resolver anchors on its parent group and BFSs siblings for a `.md` filename or direct path attribute. Real-machine validation in icon view is still pending. |
| Finder column view | Unsupported | No column-view-specific AX mapping exists. |
| Finder gallery view | Unsupported | No gallery-view-specific AX mapping exists. |
| Desktop hover | Unsupported | The code gates on Finder frontmost, but there is no explicit Desktop support path or validation. |
| No Finder windows open | Unsupported | Directory reconstruction depends on the front Finder window target directory returned from AppleScript. |

## File Resolution and File Types

| Case | Status | Notes |
| --- | --- | --- |
| Direct AX path attributes (`AXFilename`, `AXPath`, `AXDocument`) | Implemented, needs validation | The resolver accepts the first absolute path it finds and treats `.md` / `.MD` as Markdown based on the lowercased extension. |
| Fallback resolution via window target directory + AX title/value/description | Implemented, needs validation | The resolver walks up to 10 parent elements, takes the first non-empty `AXTitle`, `AXValue`, or `AXDescription`, and joins it with the front Finder window target directory. |
| Local `.md` files | Supported | `.md` files are the only extension class explicitly allowed by the resolver. |
| Non-Markdown files | Supported | Files without the `.md` extension do not produce a preview. |
| `.markdown` extension | Unsupported | The current resolver only accepts `.md`. |
| Directories | Unsupported | The current implementation does not positively confirm that the resolved path is a regular file. |
| Finder aliases | Unsupported | There is no alias-specific resolution or safety handling yet. |
| Symlinked Markdown files | Implemented, needs validation | They may work if Finder exposes a usable path or filename, but the repository has no validation evidence yet. |
| iCloud placeholders / not-yet-downloaded files | Unsupported | There is no download-state handling or retry path. |
| Deleted or moved files during preview | Unsupported | The preview layer fails closed by hiding the panel if file reads fail, but there is no dedicated recovery logic. |

## Content Loading and Rendering

| Area | Status | Notes |
| --- | --- | --- |
| UTF-8 Markdown loading | Supported | `PreviewPanelController` reads files using `String(contentsOf:encoding: .utf8)`. |
| Non-UTF-8 Markdown loading | Unsupported | No fallback decoder exists yet. |
| Headings | Supported | `MarkdownRenderer` renders ATX headings `#` through `######`. |
| Paragraphs | Supported | Non-empty lines render as paragraphs. |
| Inline code | Supported | Backtick-delimited inline spans render as `<code>`. |
| Fenced code blocks | Supported | Triple-backtick fences render as `<pre><code>`. |
| Blockquotes | Supported | Lines beginning with `>` render as blockquotes. |
| Unordered lists | Supported | `- ` and `* ` lines render as `<ul><li>`. |
| Ordered lists | Unsupported | No ordered-list parser exists yet. |
| Tables | Unsupported | No table parser exists yet. |
| HTML sanitization | Partially supported | Raw source text is escaped before the lightweight inline transformations run, but the renderer is still a prototype, not a hardened Markdown engine. |

## Validation Status

- The repository currently contains one automated renderer test in `apps/macos/Tests/FastMDTests/FastMDTests.swift`.
- `swift build` passed on 2026-04-03 for this batch.
- `swift test` passed on 2026-04-03 for this batch.
- The repository does not yet contain committed Finder manual test logs, AX snapshots, or screenshot evidence.
- Any row marked `Implemented, needs validation` should be treated as provisional until corresponding manual test notes are added under `Docs/Notes/` or a future test-log directory.
