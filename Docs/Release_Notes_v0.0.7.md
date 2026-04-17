# FastMD macOS Native v0.0.7

This release ships the current native macOS app as `v0.0.7`.

The main focus of this build is a stronger native preview surface on macOS, with better layering behavior and another round of real-world rendering and interaction performance improvements.

## Highlights

- Preview panel layering on macOS was tightened so the native preview stays readable and better behaved across Finder, hover, and interaction transitions.
- Preview hosting and panel-control code was reworked in `PreviewPanelController.swift`, with substantial changes to how the native panel coordinates rendering, visibility, and event flow.
- Finder hover, selection, and resolver behavior were refined across the macOS lane so preview triggering is more stable when Finder state shifts.
- Runtime diagnostics were expanded again, which helps validate real-machine behavior for rendering, focus changes, and preview lifecycle edges.
- Markdown preview rendering received another performance-focused pass, building on the `v0.0.6` render-path improvements.
- Space-key and hover monitoring paths were updated to reduce accidental conflicts and improve native preview responsiveness.

## User-facing effect

- More reliable native preview presentation on macOS.
- Better preview stability while switching Finder context or interacting near the preview surface.
- Improved responsiveness for the rendered Markdown panel under heavier usage.
- Cleaner release packaging that matches the `v0.0.6` standard: compiled app zip, dSYM zip, and SHA256 sums.
