# FastMD

FastMD is a macOS menu bar app for previewing and editing Markdown directly from Finder hover.

Markdown won.

It is the de-facto documentation standard whether people like it or not. Specs, RFCs, READMEs, runbooks, design notes, changelogs, research notes, private notes, public notes, startup notes, enterprise notes, all of it keeps collapsing into `.md`.

And yet the desktop still treats Markdown like a dead file on disk instead of a living surface you should be able to read and fix instantly.

That is the thing FastMD is angry at.

Hover a file and you should see it. Double-click a rendered block and you should edit the source right there. OS-native inline editing is so f**king important because documentation work is not a separate ceremony. It is part of thinking, reviewing, debugging, shipping, and surviving.

FastMD is built out of dissatisfaction with how much friction the current world still puts between a human and a Markdown document, and out of the belief that this can be made dramatically better with a smaller, sharper tool.

## How To Use

If you want the shortest path to "does this actually work on my Mac?", do this first:

1. Launch the app.
2. If macOS blocks it, open `System Settings -> Privacy & Security` and confirm that the app is safe / allow it to open.
3. Then go to `System Settings -> Privacy & Security -> Accessibility` and allow FastMD to control the computer.
4. Bring Finder to the front, switch to list view, and hover a local `.md` file for 1 second.

If the preview opens normally, immediately try the core interactions:

- `Space`
- `Tab`
- `Left Arrow` / `Right Arrow`
- double-click a rendered block

That is the real smoke test. If those actions do not work, the app is not set up correctly yet.

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
- a Stage 2 Rust workspace rooted at `Cargo.toml`
- shared Rust crates for contracts, core semantics, render contracts, and platform traits under `crates/`

## Stage 2 shared Rust workspace

Stage 2 now uses one repository-root Cargo workspace for the shared product-semantic layers, the platform adapter crates, and the future desktop shell:

- `apps/desktop-tauri/src-tauri`
  Shared Tauri shell entrypoint for the cross-platform desktop app.
- `crates/fastmd-contracts`
  Shared DTOs, commands, events, preview state, validation metadata, and host error envelopes.
- `crates/fastmd-core`
  Shared hover/open/replace/close/edit/paging semantics derived from the current macOS app.
- `crates/fastmd-render`
  Shared width tiers, theme variables, hint-chip contract, render DTOs, diagnostics DTOs, and block-mapping contracts.
- `crates/fastmd-platform`
  Shared host traits for front-surface detection, preview windows, and document loading/saving.
- `crates/fastmd-platform-macos`
  macOS Finder adapter lane.
- `crates/fastmd-platform-windows`
  Windows 11 Explorer adapter lane.
- `crates/fastmd-platform-linux-nautilus`
  Ubuntu 24.04 GNOME Files adapter lane.

Cross-platform direction stays strict:

- `apps/macos` remains the behavioral reference implementation during Stage 2.
- Shared contracts, core, and render logic define the product semantics every desktop target must reproduce.
- Windows 11 + Explorer and Ubuntu 24.04 + GNOME Files stay isolated behind adapter crates instead of leaking OS-specific behavior into the shared core.
- Real-machine validation evidence is still required before any non-macOS platform can be claimed as parity-complete.

## Stage 2 validation commands

These are the repo-root validation commands that currently anchor Stage 2 work:

```bash
cargo check -p fastmd-contracts -p fastmd-core -p fastmd-render
cargo test -p fastmd-contracts -p fastmd-core -p fastmd-render
swift build --package-path apps/macos
xcodebuild -project apps/macos/FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' build
xcodebuild -project apps/macos/FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' test
```

The shared-crate commands above validate the current Stage 2 contracts/core/render lane without over-claiming full desktop-shell or per-platform host parity. Windows and Ubuntu parity still require their adapter-owned checks plus real-machine evidence capture before those lanes can be called complete.

## Known limitations

- Finder list-like structures are the primary target. Other Finder view modes may still need more AX mapping work.
- Rich preview rendering now vendors its browser-side libraries locally inside the app bundle. The remaining network activity comes from Markdown documents that themselves reference remote images, links, or other remote assets.
- Inline editing currently works at the smallest detected rendered block boundary, not arbitrary freeform text selections.
- Packaging as a polished `.app` bundle with full signing/notarization is not done yet.

## Run with SwiftPM

The macOS Swift package now lives under `apps/macos/`. Build it from the repository root like this:

```bash
git clone https://github.com/weiyangzen/fastmd.git
cd fastmd
swift build --package-path apps/macos
swift run --package-path apps/macos
```

On first run, grant Accessibility permission when macOS prompts for it.

If macOS quarantines or blocks the app, you may also need to manually approve it in `System Settings -> Privacy & Security` before the preview loop will work at all.

## Preview Controls

When the preview is visible and hot:

- `Left Arrow` and `Right Arrow` change preview width tiers
- `Tab` toggles pure white and pure black preview backgrounds
- `Up Arrow`, `Down Arrow`, mouse wheel, and touchpad scrolling move through the preview
- Double-clicking a rendered block enters inline edit mode for that block's original Markdown source

Do not use `Space`, `Shift+Space`, `Page Up`, or `Page Down` for preview paging on macOS, Linux, or Windows. Keep Space-based behavior reserved for host file-manager actions such as the Finder preview toggle.

## Run with Xcode

This repository now also includes a checked-in macOS project at `apps/macos/FastMD.xcodeproj`, plus a generator script to keep the project in sync with the app-local `Sources/` and `Tests/` tree.

Open the project directly in Xcode:

```bash
open apps/macos/FastMD.xcodeproj
```

Or regenerate it from Terminal:

```bash
Scripts/generate_xcodeproj.rb
```

Useful Xcode build commands:

```bash
xcodebuild -list -project apps/macos/FastMD.xcodeproj
xcodebuild -project apps/macos/FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' build
xcodebuild -project apps/macos/FastMD.xcodeproj -scheme FastMD -destination 'platform=macOS,arch=arm64' test
xcodebuild -project apps/macos/FastMD.xcodeproj -scheme FastMD -destination 'generic/platform=macOS' archive -archivePath build/FastMD.xcarchive
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
