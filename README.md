# FastMD

FastMD is a macOS menu bar app prototype for previewing Markdown files directly from Finder hover.

## Current goal

The first pass focuses on the narrowest viable path:

- Finder must be frontmost
- Accessibility permission must be granted
- Hover over a Finder item for 1 second
- If the hovered item resolves to a local `.md` file, show a floating preview panel near the cursor

## Current implementation status

This repository currently contains:

- a menu bar app shell
- accessibility permission prompting
- global mouse hover debounce
- a first-pass Finder hover resolver based on AX hit-testing
- a floating preview panel backed by `WKWebView`
- a lightweight Markdown-to-HTML renderer for prototype use

## Known limitations

- The hover resolver is intentionally conservative and currently targets Finder list-like item structures first.
- Finder icon view, column view, and gallery view may require additional AX mapping work.
- The renderer is a lightweight prototype, not a full GitHub-flavored Markdown engine.
- Packaging as a polished `.app` bundle and adding entitlements/signing is not done yet.

## Run

Open the package in Xcode or build from Terminal:

```bash
cd /Users/wangweiyang/Github/fastmd
swift build
swift run
```

On first run, grant Accessibility permission when macOS prompts for it.
