# Stage 1 iOS L11 Bundle Resource Declaration Gate

- Generated: 2026-05-06T07:42:00+08:00
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: one bounded iOS-owned implementation batch
- Ownership: `ios/**` only

## Implementation

This batch tightened the iOS conditional local renderer gates for any future vendored JS/CSS/font/HTML renderer mode.

- Added `IOSRendererBundleResourceDeclarationAudit`.
- Extended `IOSRendererAssetInventory` to read SwiftPM `Package.swift` `.process(...)` / `.copy(...)` declarations that mention `FastMDRenderers`.
- Required vendored renderer assets to be covered by a declared bundled renderer resource root before `local renderer packaging/offline` can report `requiredAndSatisfied`.
- Kept the current native fallback runtime unchanged: no vendored renderer assets are discovered in the current iOS source tree and no WKWebView rich surface is active.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` | PASS | 57 tests, 0 failures |
| `swift test` | PASS | 184 tests, 0 failures |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 184 tests, 0 failures, `** TEST SUCCEEDED **` |
| `xcrun xctrace list devices` | BLOCKER for real device only | No connected iPhone 12-family physical device; listed physical devices were offline/unavailable |
| `xcrun devicectl list devices --json-output -` | BLOCKER for real device only | Output succeeded, but devices were unavailable and not iPhone 12-family hardware |
| `git diff --check -- ios` | PASS | No whitespace errors reported |

## Supervisor Checklist Recommendations

The supervisor can consider the following Stage 1 blueprint items supported by this batch plus the existing iOS conditional renderer evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current native fallback mode remains not applicable; future vendored renderer mode now requires local bundled resource declaration, local asset names, local paths, and no network/navigation surfaces.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: focused L11 suite includes WKWebView future-mode request blocking pass/fail coverage; current runtime remains no WKWebView rich surface.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: L11 manifest/hash tests still pass and now combine with SwiftPM bundle resource declaration coverage for vendored asset mode.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

- `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

- `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 184 tests and 0 failures.
  - Evidence path: `ios/docs/reports/stage1-ios-l11-bundle-resource-declaration-20260506.md`

Keep the iOS real-device validation item open. This batch did not validate on connected physical iPhone 12-family hardware.
