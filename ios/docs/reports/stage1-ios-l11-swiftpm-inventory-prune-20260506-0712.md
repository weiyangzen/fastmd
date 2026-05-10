# Stage 1 iOS L11 SwiftPM Inventory Prune - 2026-05-06 07:12 +0800

## Scope

Ran one bounded iOS-owned implementation batch for the earliest still-open iOS-owned cluster: L11 conditional local renderer packaging/offline and renderer manifest/hash gates.

Changes stayed inside `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, renderer assets, WebKit renderer surfaces, CDN dependencies, or network renderer behavior.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-swiftpm-inventory-prune-20260506-0712.md`

## Implementation

- Added `ios/.swiftpm` to `IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes`.
- Updated `IOSRendererAssetInventory.defaultInventoryCommand` so SwiftPM workspace metadata is pruned alongside `.build`, `Tests`, `docs/reports`, and `docs/screenshots`.
- Extended `testIOSL11RendererAssetInventoryIgnoresLooseRendererLikeValidationArtifacts` with a renderer-like `.css` file under `.swiftpm/configuration`.
- Extended `testIOSL11ConditionalRendererEvidenceBuilderKeepsGeneratedArtifactsOutOfCurrentGateInputs` with a renderer-like `.html` file under `.swiftpm/workspace-state`.

This prevents SwiftPM-generated workspace artifacts from being misclassified as production iOS renderer assets. Production loose renderer assets under `ios/Sources/**` are still detected and rejected by the existing loose-production tests.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventory` from `ios/` | PASS | Executed 10 selected renderer inventory tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 178 XCTest cases with 0 failures. |
| `find . -maxdepth 2 \( -name '*.xcodeproj' -o -name '*.xcworkspace' \) -print \| sort` from `ios/` | PASS | Empty output. The local iOS tree remains a SwiftPM package, and Xcode used SwiftPM's generated package project for simulator build/test. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build succeeded for `FastMDMobileCore` on the iPhone 12 simulator destination. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Test succeeded on the iPhone 12 simulator destination. Executed 178 XCTest cases with 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-11-36-+0800.xcresult`. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production JS/CSS/font/HTML/HTM renderer assets are present under `ios/`. |

## Checklist Evidence

Supervisor can use this batch as implementation and validation evidence for:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: the local renderer inventory now prunes SwiftPM workspace metadata and still detects production bundled or loose renderer assets.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: SwiftPM workspace artifacts cannot create false discovered-asset inputs for the manifest/hash gate; existing bundled, duplicate, tampered, loose, remote, query, fragment, whitespace, `.mjs`, and `.htm` manifest tests still pass.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: exact `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: exact `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 178 XCTest cases and 0 failures.

This batch also preserves existing current-native-fallback evidence for:

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- This batch did not run on a connected physical iPhone 12-family device. Simulator build/test evidence is not physical-device validation.
