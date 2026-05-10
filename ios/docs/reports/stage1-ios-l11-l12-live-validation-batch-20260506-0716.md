# Stage 1 iOS L11/L12 Live Validation Batch

- Generated: 2026-05-06T07:16:00+08:00
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint source read: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot read: `Docs/todos_20260505.md`

## Batch Selection

The daily todo snapshot marks L1-L10 complete and leaves the earliest iOS-owned open work in L11 conditional renderer gates and L12 platform validation. This batch records fresh validation evidence for:

- L11 local renderer packaging/offline tests, conditional on JS/CSS/font renderer assets
- L11 WKWebView request-blocking tests, conditional on local JS renderer surfaces
- L11 renderer asset manifest/hash verification tests, conditional on vendored renderer assets
- L12 iOS iPhone 12 simulator build
- L12 iOS iPhone 12 simulator tests
- L13 iOS-local validation report recording

## Implementation Evidence

The current iOS implementation remains native Swift under `ios/Sources/FastMDMobileCore/**`.

Relevant automated gate implementations are present in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/screenshots/golden/*.snapshot.txt`

The conditional renderer path is native fallback only:

- No discovered production JS/CSS/font/HTML renderer assets are required for the current native fallback path.
- No WKWebView rich-rendering surface is active for current rich Markdown fallback blocks.
- Rich Mermaid/math fallback blocks render as native safe cards.
- Future vendored asset and WKWebView modes are covered by failing-closed tests for packaging, request blocking, bundled resource paths, and SHA-256 manifest checks.

## Validation Commands

All commands were run from `ios/` on 2026-05-06.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` | PASS | 178 XCTest cases, 0 failures, completed in 7.574 seconds. |
| `xcrun simctl list devices available | rg 'iPhone 12'` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **`; SwiftPM package scheme `FastMDMobile` built for iPhone Simulator SDK 26.4, deployment target iOS 14.0 simulator. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | `** TEST SUCCEEDED **`; 178 XCTest cases, 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-15-24-+0800.xcresult`. |
| `xcrun xctrace list devices` | BLOCKED for physical iPhone 12 gate | No connected physical iPhone 12-family device was listed. Physical devices seen were a Mac plus unavailable non-iPhone-12 devices; simulators included iPhone 12. |
| `xcrun devicectl list devices --json-output -` | BLOCKED for physical iPhone 12 gate | Command outcome was success, but listed physical devices were unavailable and not iPhone 12-family hardware: iPhone 15 Pro (`iPhone16,1`) and iPad Pro (`iPad14,4`). |

## Checklist Evidence

| Blueprint checklist item | Suggested status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | `swift test` passed L11 conditional renderer tests, including native fallback not-applicable evidence and future vendored-asset packaging tests. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | `swift test` passed L11 WKWebView request policy tests that block network, external navigation, `javascript:`, `data:`, iframes, and unknown bundled files. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | `swift test` passed manifest/hash tests for exact platform-local bundled asset paths, duplicate rejection, remote path rejection, and tampered hash rejection. |
| Run iOS iPhone 12 simulator build. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed. |
| Run iOS iPhone 12 simulator tests. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 178 XCTest cases and 0 failures. |
| Record validation reports under `ios/docs/reports/`. | COMPLETE | This report is under `ios/docs/reports/`. |

## Gates To Keep Open

| Blueprint checklist item | Status | Blocker |
| --- | --- | --- |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | OPEN | No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available. Simulator validation passed, but the real-device manual open, render, search, edit, save, and rotate flow has not been completed on eligible hardware. |

