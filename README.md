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

## Run with SwiftPM

Open the package in Xcode or build from Terminal:

```bash
git clone https://github.com/weiyangzen/fastmd.git
cd fastmd
swift build
swift run
```

On first run, grant Accessibility permission when macOS prompts for it.

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
