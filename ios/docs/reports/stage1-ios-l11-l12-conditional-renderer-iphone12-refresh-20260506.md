# Stage 1 iOS L11/L12 Conditional Renderer And iPhone 12 Refresh - 2026-05-06

## Scope

Ran one bounded iOS-owned validation batch for the earliest still-open iOS checklist cluster in the authoritative blueprint, then opportunistically refreshed the adjacent iPhone 12 simulator gates because an `iPhone 12` simulator is now available locally.

Changes are limited to `ios/**`. This batch did not edit Android files, top-level `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Current iOS Renderer Posture

The Stage 1 iOS renderer remains native Swift model rendering with SwiftUI/UIKit presentation contracts. Mermaid, math, and unsafe HTML surfaces use native safe-card or sanitized native fallback presentation. No JS/CSS/font/HTML renderer asset is vendored under `ios/`, and no WKWebView rich renderer surface is active in the iOS package.

The conditional renderer checklist gates are therefore satisfied as not applicable for the current native fallback runtime, with future asset-present coverage already implemented:

- `IOSRendererAssetInventory` scans the package for JS/CSS/font/HTML renderer assets and Swift source for WebKit rich renderer usage.
- `IOSLocalRendererConditionalGateAudit` maps local packaging/offline, WKWebView request blocking, and manifest/hash statuses.
- `IOSRendererAssetManifestHashAudit` accepts exact platform-local bundled-resource manifests and rejects missing, tampered, remote, or loose local asset paths when renderer assets exist.
- XCTest coverage includes current native fallback evidence plus future vendored-asset and unsafe-path cases.

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 26 focused L11 tests with 0 failures. Covered conditional renderer native fallback gates, future vendored asset gates, renderer asset inventory, manifest/hash verification, WKWebView-not-applicable evidence, parser/source-range/snapshot/layout, file/save/security, performance, memory, accessibility, log redaction, and recovery gates. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `swift test` from `ios/` | PASS | Executed 126 tests with 0 failures. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM workspace exposes the `FastMDMobile` scheme. Xcode also logs `Supported platforms for the buildables in the current scheme is empty`, but the scheme resolves and builds/tests on the iPhone 12 simulator destination below. |
| `xcrun simctl list devices available \| rg "iPhone 12\|iPhone 15\|Stage1"` from repository root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build resolved the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator` and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 126 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-06-51-+0800.xcresult`. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-refresh-20260506.md`
- Xcode result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_00-06-51-+0800.xcresult`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12-family device validation was performed in this batch. Simulator build/test passed, but the real-device gate remains open until a connected iPhone 12-class device completes the Stage 1 open, render, search, edit, save, and rotate flow.
