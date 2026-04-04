# FastMD

FastMD is a macOS menu bar app for previewing and editing Markdown directly from Finder hover.

Markdown won.

It is the de-facto documentation standard whether people like it or not. Specs, RFCs, READMEs, runbooks, design notes, changelogs, research notes, private notes, public notes, startup notes, enterprise notes, all of it keeps collapsing into `.md`.

And yet the desktop still treats Markdown like a dead file on disk instead of a living surface you should be able to read and fix instantly.

That is the thing FastMD is angry at.

Hover a file and you should see it. Double-click a rendered block and you should edit the source right there. OS-native inline editing is so f**king important because documentation work is not a separate ceremony. It is part of thinking, reviewing, debugging, shipping, and surviving.

FastMD is built out of dissatisfaction with how much friction the current world still puts between a human and a Markdown document, and out of the belief that this can be made dramatically better with a smaller, sharper tool.

## Why

- Markdown is the de-facto documentation standard.
- Documentation is not secondary work. It is core operational work.
- Finder already knows where the file is; the OS should help you read it immediately.
- Inline editing should feel native, not like context switching into another app for every tiny fix.
- Good tools should remove friction, not teach you to tolerate it.

## Current goal

The first pass focuses on the narrowest viable path that still feels like a real product:

- Finder must be frontmost
- Accessibility permission must be granted
- Hover over a Finder item for 1 second
- If the hovered item resolves to a local `.md` file, show a floating preview panel near the cursor
- Keep the chosen preview size stable unless the screen truly cannot fit it
- Allow inline block editing without forcing the user into another editor

## Current implementation status

This repository currently contains:

- a menu bar app shell
- accessibility permission prompting
- hover-based Finder resolution using AX hit-testing
- internal-display and external-display coordinate handling for Finder hover resolution
- a floating preview panel backed by `WKWebView`
- four preview width tiers, with the largest tier targeting `1920x1440` at `4:3`
- preview hotkeys for width changes, background toggling, and paging/scrolling
- rich Markdown preview rendering inside the panel
- inline block editing that writes Markdown back to the source file
- runtime diagnostics and Finder AX capture tooling

## Known limitations

- Finder list-like structures are the primary target. Other Finder view modes may still need more AX mapping work.
- Rich preview rendering now vendors its browser-side libraries locally inside the app bundle. The remaining network activity comes from Markdown documents that themselves reference remote images, links, or other remote assets.
- Inline editing currently works at the smallest detected rendered block boundary, not arbitrary freeform text selections.
- Packaging as a polished `.app` bundle with full signing/notarization is not done yet.

## Run with SwiftPM

Open the package in Xcode or build from Terminal:

```bash
git clone https://github.com/weiyangzen/fastmd.git
cd fastmd
swift build
swift run
```

On first run, grant Accessibility permission when macOS prompts for it.

## Preview Controls

When the preview is visible and hot:

- `Left Arrow` and `Right Arrow` change preview width tiers
- `Tab` toggles pure white and pure black preview backgrounds
- `Space`, `Shift+Space`, `Page Up`, `Page Down`, arrow keys, mouse wheel, and touchpad scrolling page through the preview
- Double-clicking a rendered block enters inline edit mode for that block's original Markdown source

## Run with Xcode

This repository now also includes a checked-in `FastMD.xcodeproj` for macOS app packaging, plus a generator script to keep the project in sync with the `Sources/` and `Tests/` tree.

Open the project directly in Xcode:

```bash
open FastMD.xcodeproj
```

Or regenerate it from Terminal:

```bash
Scripts/generate_xcodeproj.rb
```

Useful Xcode build commands:

```bash
xcodebuild -list -project FastMD.xcodeproj
xcodebuild -project FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' build
xcodebuild -project FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' test
xcodebuild -project FastMD.xcodeproj -scheme FastMD -destination 'generic/platform=macOS' archive -archivePath build/FastMD.xcarchive
```

The generated archive lands at `build/FastMD.xcarchive`. The project is configured to build and archive locally without requiring immediate code signing setup; signing and notarization can be added later if you want to distribute the app outside local development.

## Finder Hover Debugging

The app now writes runtime diagnostics to:

```bash
~/Library/Logs/FastMD/runtime.log
```

You can also trigger a delayed AX capture while you manually switch back to Finder:

```bash
Scripts/capture_finder_ax_snapshot.swift --delay 5
```

That script writes a JSON snapshot under `Tests/Fixtures/FinderAX/` by default. The payload now includes the raw hit-tested lineage, a row-subtree or fallback subtree, an expanded ancestor-context search, and a small `analysis` block showing whether any direct path or Markdown-looking file name was discovered.

## Contributing

Contribution guidelines live in `CONTRIBUTING.md`. Security reporting guidance lives in `SECURITY.md`.

## License

FastMD is released under the MIT License. See `LICENSE`.
