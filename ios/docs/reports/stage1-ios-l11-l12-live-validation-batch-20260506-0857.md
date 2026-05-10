# Stage 1 iOS L11/L12 Live Validation Batch

- Generated: 2026-05-06 08:57:10 +0800
- Worker scope: iOS live lane
- Ownership: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily todo source: `Docs/todos_20260505.md`

## Batch Scope

This bounded batch refreshed the earliest still-open iOS-owned validation evidence:

- L11 conditional local renderer gates for the native fallback path.
- L12 iPhone 12 simulator build and test gates.
- L12 physical iPhone 12-family validation blocker evidence.
- L13 iOS-local validation report evidence.

No Android files, root Docs checklist files, or cron files were edited.

## Implementation State Under Test

- iOS implementation remains native Swift through `FastMDMobileCore`.
- Ordinary Markdown rendering remains native.
- Mermaid and math rich blocks render as native safe fallback cards in Stage 1.
- No vendored JS/CSS/font/HTML renderer assets are present under `ios/**`.
- No WKWebView rich renderer surface is active for Stage 1 native fallback.
- iPhone 12 simulator exists locally:
  - `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` | PASS | 189 tests, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` | PASS | 62 tests, 0 failures |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` | PASS | 28 tests, 0 failures |
| `xcrun simctl list devices available | rg 'iPhone 12'` | PASS | iPhone 12 simulator `1B6FEADC-308B-4069-B734-3C9C207E633F` found |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 189 tests, 0 failures, `** TEST SUCCEEDED **` |
| `xcrun xctrace list devices` | BLOCKED for real-device gate | No connected physical iPhone 12-family device; physical iPhone 15 Pro and iPad entries are offline |
| `xcrun devicectl list devices --json-output -` | BLOCKED for real-device gate | Only unavailable physical iPhone 15 Pro `iPhone16,1` and iPad `iPad14,4` candidates were listed |
| `git -C .. diff --check -- ios` | PASS | No whitespace errors reported |

Xcode simulator test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_08-56-42-+0800.xcresult
```

## Conditional Renderer Evidence

The current iOS runtime is native fallback only:

- `usesVendoredRendererAssets`: false
- `usesWKWebViewRichSurface`: false
- `importsWebKitRichRendererCode`: false, as covered by the L11 source inventory tests
- `discoveredRendererAssetPaths`: none

The following blueprint rows can be reconciled as complete for the current native fallback path:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: L11 filtered suite passed, including native fallback and future vendored-asset packaging gate tests.
  - Status: not applicable for current runtime, with automated guard coverage for future asset mode.
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: L11 filtered suite passed, including WKWebView request-policy tests for blocked remote network, external navigation, `javascript:`, `data:`, iframe, non-bundled file, and context mismatch requests.
  - Status: not applicable for current runtime, with automated guard coverage for future WKWebView mode.
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: L11 filtered suite passed, including manifest hash acceptance and rejection tests for missing, tampered, remote, duplicate, loose, query, fragment, and whitespace paths.
  - Status: not applicable for current runtime, with automated guard coverage for future vendored asset mode.

## Platform Validation Evidence

The following L12 iOS rows can be reconciled as complete:

- `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` succeeded.
- `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` executed 189 tests with 0 failures.
- `Capture iOS performance report.`
  - Evidence: existing report `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md`, revalidated by `swift test --filter FastMDMobileCoreTests/testIOSL12`.
- `Capture iOS security audit report.`
  - Evidence: existing report `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md`, revalidated by `swift test --filter FastMDMobileCoreTests/testIOSL12`.
- `Capture rich fixture render report.`
  - Evidence: existing report `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md` and golden snapshots under `ios/docs/screenshots/golden/`, revalidated by `swift test --filter FastMDMobileCoreTests/testIOSL12`.

The following L12 iOS row must remain open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max is available in the local probes.
  - Observed physical hardware candidates are unavailable and not iPhone 12-family hardware.
  - Simulator validation does not complete this real-device row.

## Supervisor Reconciliation Recommendations

The supervisor can use this report as iOS-local evidence for:

- L11 local renderer packaging/offline tests conditional row.
- L11 WebView/WKWebView request-blocking tests conditional row.
- L11 renderer asset manifest/hash verification tests conditional row.
- L12 iOS iPhone 12 simulator build.
- L12 iOS iPhone 12 simulator tests.
- L13 record validation reports under `ios/docs/reports/`.

Keep open:

- L12 iOS iPhone 12-class real-device validation.
