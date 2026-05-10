# Stage 1 iOS L11 Case-Insensitive Renderer Inventory Batch

- Generated: 2026-05-06T00:09:11Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only

## Batch Selection

The daily todo snapshot shows L1 through L10 complete for iOS. The earliest open iOS-owned checklist cluster remains the conditional L11 local renderer gates:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

This batch hardens the renderer asset inventory evidence path. The Swift inventory already detects asset extensions case-insensitively through `url.pathExtension.lowercased()`, but the documented inventory command used lowercase-only `find -name` patterns. The command now uses `-iname` so fresh evidence cannot miss uppercase `.JS`, `.CSS`, `.HTML`, `.WOFF2`, or similar renderer files.

## Implementation Evidence

- Updated `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `IOSRendererAssetInventory.defaultInventoryCommand` now uses case-insensitive `find -iname` extension matching while preserving ignored paths for `.build`, `.swiftpm`, tests, reports, and screenshots.
- Updated `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Added `testIOSL11RendererAssetInventoryCommandMatchesCaseInsensitiveDiscovery`.
  - The test creates uppercase local renderer asset filenames under a bundled `FastMDRenderers` root, verifies discovery finds all four assets, verifies the command advertises `-iname`, and verifies manifest/hash audit acceptance.

No Android files, root `Docs/**`, `.cron/**`, renderer assets, app entitlements, privacy manifests, Info.plist files, background modes, CDN dependencies, or production WKWebView renderer surfaces were edited.

## Current Renderer Asset Inventory

Command from repository root:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result: PASS, empty output. No production JS/CSS/font/HTML renderer assets are currently vendored under `ios/` outside ignored build/test/report/screenshot paths.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 60 L11 XCTest cases with 0 failures. Includes the new case-insensitive renderer inventory command/discovery regression test. |
| `swift test` from `ios/` | PASS | Executed 187 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | SwiftPM generated Xcode scheme built for iPhone 12 simulator; `** BUILD SUCCEEDED **`. No checked-in `.xcodeproj` or `.xcworkspace` exists, but Xcode generated the package scheme successfully. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 187 XCTest cases with 0 failures on the iPhone 12 simulator destination; `** TEST SUCCEEDED **`. |
| renderer asset inventory command above | PASS | Empty output. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported. |

## Supervisor Checklist Evidence

The supervisor can use this report as fresh evidence for:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current runtime is native fallback-only with no production renderer assets; future renderer asset detection now covers uppercase extensions consistently between Swift discovery and the shell evidence command.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: new regression verifies uppercase bundled renderer assets are discovered and included in manifest/hash verification.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed in this batch.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed in this batch with 187 tests and 0 failures.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is under `ios/docs/reports/`.

The iOS real-device validation gate remains open unless separately reconciled from valid physical iPhone 12-family evidence.
