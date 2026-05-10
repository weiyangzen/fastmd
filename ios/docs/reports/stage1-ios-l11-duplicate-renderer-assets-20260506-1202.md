# Stage 1 iOS L11 Conditional Renderer Duplicate Asset Hardening

Generated: 2026-05-06 12:02 Asia/Shanghai

## Scope

- Worker lane: iOS live lane
- Ownership: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot: `Docs/todos_20260505.md`
- Batch type: bounded L11 conditional renderer test-gate hardening

## Implementation

Changed iOS files:

- `ios/Sources/FastMDMobileCore/FastMDMobileCore.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-duplicate-renderer-assets-20260506-1202.md`

Behavior added:

- `LocalRichRendererRuntimeAudit` now requires vendored renderer `declaredAssetNames` to be unique before reporting `packagedLocalAssets`.
- Duplicate declared asset names now keep vendored renderer mode in `missingLocalAssets`, so a future JS/CSS/font renderer cannot satisfy packaging/offline evidence with repeated manifest rows.

Test coverage added:

- `testVendoredRichRendererRuntimeAuditRejectsDuplicateDeclaredAssets`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testVendoredRichRendererRuntimeAuditRejectsDuplicateDeclaredAssets` | PASS | 1 selected test, 0 failures |
| `swift test` from `ios/` | PASS | 204 tests, 0 failures |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | No renderer asset paths printed |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` | PASS | No matches; `rg` exited 1 because the scan found no WebKit import or WKWebView construction |
| `xcodebuild -list` from `ios/` | PASS | Scheme `FastMDMobile` is available |
| `xcrun simctl list devices available \| rg "iPhone 12"` | PASS | Available simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 204 tests, 1 skipped, 0 failures; `** TEST SUCCEEDED **`; xcresult at `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_12-01-36-+0800.xcresult` |

No xcodebuild blocker was encountered in this batch.

## Supervisor Checklist Evidence

The supervisor can use this report as additional evidence for these open blueprint rows:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: vendored renderer packaging now fails when declared local assets are duplicated.
  - Current source-tree status: not applicable native fallback, because no JS/CSS/font/HTML renderer assets are present.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: duplicate declarations cannot pass the local renderer runtime audit; existing manifest/hash tests also passed in the full suite.
  - Current source-tree status: not applicable native fallback, because no vendored JS/CSS/font assets are present.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: iPhone 12 simulator build passed in this batch.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: iPhone 12 simulator tests passed in this batch.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report.

The iOS iPhone 12-class real-device validation row remains open; this batch did not attach or validate a physical iPhone 12-family device.
