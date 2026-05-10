# Stage 1 iOS L11/L12 Renderer Path Hardening And iPhone 12 Simulator Evidence

- Generated: 2026-05-06T04:38:30Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Ownership: ios/**
- Batch scope: L11 conditional renderer gate hardening plus L12 iPhone 12 simulator validation refresh

## Implementation

- Hardened `IOSLocalRendererConditionalGateAudit.rendererAssetPathsArePlatformLocal` so future vendored renderer assets cannot satisfy local packaging/hash gates with colon-bearing paths, percent-escaped path segments, or control characters.
- Extended `testIOSL11ConditionalRendererAuditRejectsUnsafeRawAssetPaths` with percent-escaped traversal, URL-like colon, and control-character path cases.
- Current production renderer posture remains native fallback: no vendored JS/CSS/font renderer assets and no active WKWebView rich surface are required for ordinary Markdown or rich fallback cards.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-renderer-path-hardening-iphone12-sim-20260506-1238.md`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRendererAuditRejectsUnsafeRawAssetPaths` | PASS | 1 test, 0 failures |
| `swift test` | PASS | 205 tests, 0 failures |
| `xcrun simctl list devices available | rg 'iPhone 12'` | PASS | `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` |
| `xcodebuild -list` | PASS | SwiftPM-generated workspace exposes scheme `FastMDMobile` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`; 205 tests, 1 skipped, 0 failures |
| `xcrun xctrace list devices` | BLOCKED for real-device gate | Connected devices list has Mac only; `Turbulence` iPhone 15 Pro and iPad are offline; no connected physical iPhone 12-family hardware |
| `xcrun devicectl list devices` | BLOCKED for real-device gate | Only unavailable iPhone 15 Pro and unavailable iPad were listed; no connected physical iPhone 12-family hardware |

## Simulator Notes

- iPhone 12 simulator destination is available locally in this run.
- The SwiftPM-generated `FastMDMobile` scheme builds the iOS target for `arm64-apple-ios14.0-simulator`, matching the Stage 1 iOS 14.x compatibility floor.
- One XCTest is skipped under iOS Simulator: process-based shell command parity is intentionally SwiftPM/macOS-only because iOS Simulator bundles do not spawn `/bin/sh`. The same inventory model is still exercised in simulator tests.

## Open Boundary

- The iOS iPhone 12-class real-device validation gate remains open.
- Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available. Simulator validation passed, but it does not replace the required physical-device open, render, search, edit, save, and rotate flow.

## Supervisor Checklist Recommendations

The supervisor can mark these iOS-owned checklist rows complete using this report plus the cited tests:

| Blueprint checklist item | Recommendation | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Native fallback mode has no vendored renderer assets; future asset mode now rejects URL-like, escaped, and control-character paths before packaging can satisfy. Validated by focused L11 test and full SwiftPM suite. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | Native fallback mode has no active WKWebView rich surface; existing WKWebView request-policy tests remain green in SwiftPM and iPhone 12 simulator validation. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | Existing manifest/hash tests remain green, and path hardening prevents unsafe discovered paths from satisfying bundled-resource and manifest gates. |
| Run iOS iPhone 12 simulator build. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed. |
| Run iOS iPhone 12 simulator tests. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 205 tests, 1 skipped, 0 failures. |

Keep this row open:

| Blueprint checklist item | Status | Evidence |
| --- | --- | --- |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | OPEN | No connected physical iPhone 12-family hardware was available in `xcrun xctrace list devices` or `xcrun devicectl list devices`. |
