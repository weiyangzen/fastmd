# Stage 1 iOS Live Lane Batch Evidence - 2026-05-06 08:31 CST

## Batch Scope

- Lane: FastMD Stage 1 Mobile iOS live lane worker.
- Ownership: `ios/**` only.
- Selected earliest open iOS-owned items from `Docs/todos_20260505.md`: L11 conditional renderer gates.
- Secondary validation advanced in the same bounded batch: L12 iPhone 12 simulator build/test gates.

## Implementation Evidence

The current iOS implementation remains native Swift/SwiftUI/UIKit core code through the SwiftPM target `FastMDMobileCore`.

Conditional rich renderer state:

- Production renderer asset inventory command:
  `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort`
- Result: no production JS/CSS/font/HTML renderer assets under the owned iOS app source tree.
- Current rich fallback mode: native safe cards for Mermaid/math/rich fallback blocks.
- Current WKWebView rich renderer surface: not present in production source.
- Guard tests present and passing for the future vendored/WKWebView path:
  - local renderer packaging/offline gate
  - WKWebView request-blocking gate
  - renderer asset manifest/hash gate
  - bundled resource declaration coverage
  - loose asset rejection
  - WebKit import/WKWebView construction detection
  - network/navigation/data/javascript/iframe request blocking policy

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 188 tests, 0 failures, 0 unexpected failures. |
| `find ios ... renderer asset inventory ...` | PASS | Empty output; no production JS/CSS/font/HTML renderer assets discovered outside ignored validation/build paths. |
| `xcrun simctl list devices available | rg 'iPhone 12'` | PASS | `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` is available. |
| `xcodebuild -list -json` from `ios/` | PASS | SwiftPM workspace exposes scheme `FastMDMobile`. Xcode logs the package warning `Supported platforms for the buildables in the current scheme is empty`, but the scheme resolves. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`; 188 tests, 0 failures, 0 unexpected failures. |
| `xcrun xctrace list devices` | BLOCKED for real device gate | Physical devices reported offline: `Turbulence (26.1)` and `王威扬的iPad (26.3.1)`. No connected physical iPhone 12-family hardware. |
| `xcrun devicectl list devices` | BLOCKED for real device gate | Listed unavailable `iPhone 15 Pro (iPhone16,1)` and unavailable `iPad Pro (11-inch) (4th generation) (iPad14,4)`; no connected physical iPhone 12-family hardware. |

## Supervisor Completion Recommendations

The supervising session can mark these blueprint checklist items complete with this report plus the passing SwiftPM/Xcode test evidence:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: native fallback inventory has no production JS/CSS/font/HTML renderer assets, and the passing L11 tests validate both not-applicable native mode and future vendored local asset mode.
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: production source has no WKWebView rich renderer surface; passing tests validate blocked network, external navigation, `javascript:` URLs, `data:` URLs, iframe attempts, remote subresources, and unsafe WKWebView mode rejection.
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: production inventory is empty, while passing tests validate exact platform-local manifest paths, SHA-256 hashes, byte counts, duplicate rejection, loose path rejection, and tamper/missing-entry failures for future vendored assets.
- `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 188 tests and 0 failures.
- `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is recorded under `ios/docs/reports/`.

Keep this item open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  - Blocker: live probes found no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max device. The available physical devices are offline or not iPhone 12-family hardware, so no parity-complete real-device claim is made in this batch.

