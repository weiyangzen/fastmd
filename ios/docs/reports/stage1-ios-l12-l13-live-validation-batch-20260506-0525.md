# Stage 1 iOS L12/L13 Live Validation Batch - 2026-05-06 05:25 CST

## Scope

Ran one bounded iOS-owned live-lane batch for the remaining iOS validation and documentation evidence cluster:

- L11 conditional renderer gate refresh for the native fallback path.
- L12 iPhone 12 simulator build and test validation.
- L12 current real-device probe evidence.
- L13 iOS README command audit.

No Android files, root `Docs/**`, `.cron/**`, source code, renderer assets, entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior were changed.

## Changed Files

- `ios/docs/reports/stage1-ios-l12-l13-live-validation-batch-20260506-0525.md`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Executed 166 tests with 0 failures. |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 45 focused L11 tests with 0 failures, including conditional renderer packaging/offline, WKWebView request-blocking, and renderer manifest/hash gate models. |
| `swift test --filter FastMDMobileCoreTests/testIOSL12` from `ios/` | PASS | Executed 26 focused L12 tests with 0 failures, including simulator report, performance/security/rich fixture reports, and real-device gate blockers. |
| `swift test --filter FastMDMobileCoreTests/testIOSL13ReadmeDocumentsFinalBuildTestCommands` from `ios/` | PASS | Executed 1 focused README command audit test with 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | No production JS/CSS/font/HTML renderer assets were found under `ios/`. The L11 conditional renderer gates remain not-applicable/satisfied for the native fallback path. |
| `xcrun simctl list devices available \| rg -n "iPhone 12\|iPhone 15\|Stage1\|iPhone"` from repository root | PASS | The local simulator inventory includes an available `iPhone 12` destination. |
| `xcodebuild -list` from `ios/` | PASS | SwiftPM exposes the `FastMDMobile` scheme. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode built `FastMDMobileCore` for the iPhone 12 simulator destination and ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode ran 166 tests on the iPhone 12 simulator destination with 0 failures and ended with `** TEST SUCCEEDED **`. |
| `xcrun xctrace list devices` from repository root | PASS command, real-device gate BLOCKED | Connected physical devices list contained only `Mac`; offline physical devices were not connected. The simulator inventory included `iPhone 12`, but simulator evidence does not satisfy the physical-device gate. |
| `xcrun devicectl list devices --json-output -` from repository root | PASS command, real-device gate BLOCKED | Physical devices reported by CoreDevice were unavailable and were not iPhone 12-family hardware. Private identifiers, serials, UDIDs, and ECIDs are intentionally omitted from this report. |

## Checklist Evidence

The supervising session can reconcile the following blueprint checklist items as complete from current iOS evidence:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: no production JS/CSS/font/HTML renderer assets were discovered; native Swift safe-card fallback is active; `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: no WKWebView rich renderer source is active; request-blocking policy tests for future vendored WKWebView mode pass; `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: no vendored renderer assets are present in production iOS paths; manifest/hash verification tests for future asset mode pass; `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 166 tests and 0 failures.
- L12: `Capture iOS performance report.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL12` passed; prior report anchor `ios/docs/reports/stage1-ios-l12-performance-report-20260505.md` remains valid.
- L12: `Capture iOS security audit report.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL12` passed; prior report anchor `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md` remains valid.
- L12: `Capture rich fixture render report.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL12` passed; prior report anchor `ios/docs/reports/stage1-ios-l12-security-rich-render-report-20260505.md` remains valid.
- L13: `Update ios/README.md with final build/test commands after iOS skeleton lands.`
  - Evidence: `swift test --filter FastMDMobileCoreTests/testIOSL13ReadmeDocumentsFinalBuildTestCommands` passed against `ios/README.md`.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

## Still Open

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

The real-device gate remains blocked because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available during this batch. The available `iPhone 12` simulator is valid simulator evidence only. The physical gate should close only after real iPhone 12-family hardware completes the Stage 1 open, rich fixture render, search, full source edit, block source edit, save, and rotate flow with current manual evidence.
