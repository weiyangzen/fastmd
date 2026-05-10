# Stage 1 iOS L12 Live Validation Batch - 2026-05-06 02:50 +0800

## Scope

Ran one bounded iOS-owned L12 validation batch against the earliest still-open iOS platform validation/report checklist items in the authoritative blueprint. This batch refreshed evidence for:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`
- `Capture iOS performance report.`
- `Capture iOS security audit report.`
- `Capture rich fixture render report.`

Changes are limited to `ios/**`. This batch did not edit Android files, top-level `Docs/**`, `.cron/**`, Swift source, XCTest source, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report only:

- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-0250.md`

Existing implementation and XCTest evidence used by this batch:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Tests/Fixtures/Markdown/rich-preview.md`
- `ios/docs/screenshots/golden/rich-preview-light-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-reader.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-reader.snapshot.txt`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 21 focused L12 tests with 0 failures. Coverage included simulator validation reports, performance report, security audit report, rich fixture render report, device parser/blocker handling, and real-device completion guards. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | Empty output. No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcrun simctl list devices available \| rg "iPhone 12\|Stage1\|iPhone 15"` from repository root | PASS | Available simulator inventory includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` and `Stage1 iPhone 15 Pro (63DAFAF1-789A-4206-8B3C-6B87048AFDF1) (Shutdown)`. |
| `xcrun xctrace list devices \| sed -n '1,120p'` from `ios/` | BLOCKER for physical-device gate | Connected physical devices listed only `Mac`. Two iOS-family devices were listed offline, and `iPhone 12 (26.4.1)` appeared under Simulators, not under connected physical Devices. |
| `swift test` from `ios/` | PASS | Executed 146 XCTest cases with 0 failures. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built the SwiftPM `FastMDMobile` scheme for `arm64-apple-ios14.0-simulator`; Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Ran on the iPhone 12 simulator destination and executed 146 tests with 0 failures. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-50-14-+0800.xcresult`. |

## Report Gate Evidence

### iOS Performance Report

`IOSStageOnePerformanceReport` remains implemented in native Swift and is covered by `testIOSL12PerformanceReportCapturesRedactedIPhone12ProfileEvidence` plus the runtime L11 performance automation test. The report captures the iPhone 12 standard profile, parse/render/search/font-tier/save operation evidence, off-main execution markers, threshold rows, simulator blocker text where applicable, and redacted diagnostics.

Refreshed evidence:

- Focused L12 tests passed.
- Full SwiftPM tests passed.
- iPhone 12 simulator test passed.

### iOS Security Audit Report

`IOSStageOneSecurityAuditReport` remains implemented in native Swift and is covered by `testIOSL12SecurityAuditReportCapturesReleaseAndFixtureSecurityEvidence`. The report captures ImageIO bounded local image decode policy, balanced security-scoped access, stale bookmark permission-loss handling, ATS/privacy/background-mode posture, malicious HTML sanitization, malicious link blocking, remote image privacy, and conditional renderer gate status.

The iOS renderer remains native fallback-only for rich Markdown blocks. This batch found no JS/CSS/font/HTML renderer assets under `ios/` and no WKWebView rich renderer runtime was introduced.

### Rich Fixture Render Report

`IOSRichFixtureRenderReport` remains implemented in native Swift and is covered by `testIOSL12RichFixtureRenderReportCapturesAllBlueprintCategories`. The report captures all 30 blueprint render categories from `ios/Tests/Fixtures/Markdown/rich-preview.md`, parser/source-range validity, layout safety, conditional renderer status, and light/dark snapshot signatures across the four Stage 1 font tiers.

## Checklist Evidence

Supervisor can mark complete:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Capture iOS performance report.`
- L12: `Capture iOS security audit report.`
- L12: `Capture rich fixture render report.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Tests/Fixtures/Markdown/rich-preview.md`
- `ios/docs/screenshots/golden/`
- `ios/docs/reports/stage1-ios-l12-live-validation-batch-20260506-0250.md`
- Xcode result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_02-50-14-+0800.xcresult`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected physical iPhone 12-family device was available in this batch. The local `xctrace` device list shows Mac as the only connected physical device; `iPhone 12` is available as a simulator only. The real-device gate remains open until a connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate validation flow.
