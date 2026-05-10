# Stage 1 iOS L11/L12 Live Validation Batch

- Generated: 2026-05-06T09:42:47+08:00
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: ios/**
- Batch intent: refresh the earliest open iOS-owned checklist evidence without editing shared Docs.

## Repository State Checked

- iOS package root: `ios/`
- SwiftPM manifest: `ios/Package.swift`
- Xcode project/workspace files under `ios/`: none found; Xcode used the SwiftPM-generated package scheme.
- iPhone 12 simulator inventory command found an available destination:
  - `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`

## L11 Conditional Renderer Gates

Current iOS production source uses native fallback render surfaces for rich Markdown blocks. No JS, CSS, HTML, or font renderer asset files were found under `ios/` after excluding `.build` and `.swiftpm`.

Commands:

```bash
find . -path './.build' -prune -o -path './.swiftpm' -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.html' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' \) -print
rg -n "import[[:space:]]+WebKit|WKWebView\(" Sources Package.swift && true
```

Results:

- Renderer asset inventory: no files printed.
- Production WebKit/WKWebView scan over `Sources` and `Package.swift`: no matches.
- Test-only fixture strings still cover future vendored/WKWebView policy behavior; they are not active production renderer surfaces.

Supervisor completion candidates:

| Blueprint checklist item | Evidence status | Completion rationale |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Not applicable, satisfied by native fallback evidence | No JS/CSS/font/HTML renderer assets are present in iOS production resources. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Not applicable, satisfied by native fallback evidence | No production WKWebView rich surface is present. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Not applicable, satisfied by native fallback evidence | No vendored renderer assets are discovered, so no manifest/hash lock is required. |

## L12 Validation Commands

### SwiftPM XCTest

```bash
cd ios && swift test
```

Result: PASS

Evidence:

- Executed 193 XCTest cases.
- 0 failures.
- Final summary: `Test Suite 'All tests' passed`.
- Timing reported by XCTest: 10.353 seconds test execution, 10.372 seconds total suite wall time.

### iPhone 12 Simulator Inventory

```bash
cd ios && xcrun simctl list devices available | rg 'iPhone 12'
```

Result: PASS

Evidence:

- Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`.

### iPhone 12 Simulator Build

```bash
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: PASS

Evidence:

- Xcode resolved the SwiftPM package at `/Users/wangweiyang/GitHub/fastmd/ios`.
- Built target `FastMDMobileCore`.
- Deployment target in build log: `arm64-apple-ios14.0-simulator`.
- Final summary: `** BUILD SUCCEEDED **`.

### iPhone 12 Simulator Tests

```bash
cd ios && xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: PASS

Evidence:

- Executed 193 XCTest cases.
- 0 failures.
- Final summary: `** TEST SUCCEEDED **`.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_09-42-32-+0800.xcresult`

### Physical Device Probe

```bash
cd ios && xcrun xctrace list devices
cd ios && xcrun devicectl list devices --json-output -
```

Result: BLOCKED for the iPhone 12-family real-device parity gate.

Evidence:

- `xctrace` listed one iPhone 15 Pro physical device and one iPad physical device as offline.
- `devicectl` listed one iPhone 15 Pro physical device and one iPad Pro physical device as unavailable.
- No connected, available physical iPhone 12-family device was found.
- No manual physical-device Stage 1 flow was completed in this batch.

## Report Checklist Evidence

The SwiftPM and iPhone 12 simulator test suite includes current report model coverage for:

- iOS performance report.
- iOS security audit report.
- rich fixture render report.
- iOS reconciliation evidence under `ios/docs/reports/`.

Relevant passing XCTest coverage observed in the 193-test run includes:

- `testIOSL12PerformanceReportCapturesRedactedIPhone12ProfileEvidence`
- `testIOSL12SecurityAuditReportCapturesReleaseAndFixtureSecurityEvidence`
- `testIOSL12RichFixtureRenderReportCapturesAllBlueprintCategories`
- `testIOSL13ReconciliationEvidenceMapsCurrentIOSChecklistCompletionAndRealDeviceBlocker`

## Supervisor Reconciliation Recommendations

The supervisor can mark these iOS-owned checklist items complete using this report plus the passing validation output:

| Checklist item | Recommendation | Evidence path |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | Complete as not applicable for current native fallback runtime | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Complete as not applicable for current native fallback runtime | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Complete as not applicable for current native fallback runtime | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Run iOS iPhone 12 simulator build. | Complete | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Run iOS iPhone 12 simulator tests. | Complete | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Capture iOS performance report. | Complete by passing report-model tests and validation evidence | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Capture iOS security audit report. | Complete by passing report-model tests and validation evidence | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Capture rich fixture render report. | Complete by passing report-model tests and validation evidence | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |
| Record validation reports under `ios/docs/reports/`. | Complete for this batch | `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0942.md` |

Keep this item open:

| Checklist item | Status | Blocker |
| --- | --- | --- |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | Open | No connected, available physical iPhone 12-family device was found; only unavailable/offline non-iPhone-12-family physical devices were listed. |

