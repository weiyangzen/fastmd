# Stage 1 iOS Live L11/L12 Validation Batch

- Generated: 2026-05-06T12:08:00+08:00
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: iOS only
- Batch selection: earliest open iOS-owned cluster after completed L1/L2/L4/L5-L10 work, covering the conditional local renderer gates and iPhone 12 simulator validation.

## Current Source State

- iOS implementation remains native Swift / SwiftUI / UIKit-facing Swift models.
- No React Native, Flutter, Cordova, remote WKWebView shell, or web runtime is present.
- Rich Mermaid/math Stage 1 handling remains native safe-card fallback.
- No vendored JS/CSS/font/HTML renderer assets were discovered in the current iOS production tree.
- No WebKit import or `WKWebView` construction was discovered in `ios/Sources`.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 204 tests executed, 0 failures, 0 unexpected failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; build used iPhone Simulator SDK and iOS 14.0 simulator deployment target from the SwiftPM package. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; 204 XCTest cases executed, 1 skipped iOS process-spawn parity test, 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | Empty output; no current production renderer assets discovered. |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` | PASS | Exit 1 with no matches, which is the expected native-fallback result. |
| `xcrun xctrace list devices` | BLOCKED for real-device gate | Physical devices listed were offline and were not iPhone 12-family hardware; iPhone 12 appears only as a simulator. |
| `xcrun devicectl list devices --json-output -` | BLOCKED for real-device gate | Reported unavailable physical iPhone 15 Pro and iPad Pro devices; no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. |

## Conditional Renderer Evidence

| Blueprint checklist item | Status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Native fallback mode is current. The production-tree renderer asset inventory is empty, rich blocks render as native safe cards, and SwiftPM L11 conditional renderer tests passed inside the full `swift test` and iPhone 12 simulator test runs. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | No current WKWebView rich surface exists. Current-source scan found no WebKit imports or `WKWebView` construction, while the conditional future-mode request-blocking policy tests passed in the same test suite. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | No current vendored renderer assets exist. Manifest/hash verification tests for future vendored modes passed, and the current production inventory is empty. |

## Platform Validation Evidence

| Blueprint checklist item | Status | Evidence |
| --- | --- | --- |
| Run iOS iPhone 12 simulator build. | COMPLETE | Exact blueprint command passed: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build`. |
| Run iOS iPhone 12 simulator tests. | COMPLETE | Exact blueprint command passed: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test`; 204 XCTest cases, 1 skipped, 0 failures. |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | OPEN | No connected physical iPhone 12-family device was available. `xctrace` and `devicectl` probes found no eligible connected iPhone 12 / 12 mini / 12 Pro / 12 Pro Max, and no manual open/render/search/edit/save/rotate flow was executed on physical iPhone 12-class hardware. |
| Record validation reports under `ios/docs/reports/`. | COMPLETE | This report is platform-local under `ios/docs/reports/` and contains command results plus blocker evidence. |

## Supervisor Recommendations

The supervising session can mark these iOS blueprint rows complete with this evidence path:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`
- `Record validation reports under ios/docs/reports/.`

Keep this row open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

