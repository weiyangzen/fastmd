# Stage 1 iOS L11/L12 Live Evidence Refresh

- Generated: 2026-05-06 09:24 Asia/Shanghai
- Worker scope: iOS live lane, `ios/**` only
- Batch type: fresh validation and supervisor evidence refresh for already-implemented iOS L11/L12 gates
- Source implementation posture: native Swift/SwiftUI/UIKit-oriented core; no production JS/CSS/font/HTML renderer assets; no production WebKit/WKWebView rich renderer surface

## Changed Files

- `ios/docs/reports/stage1-ios-l11-l12-live-evidence-refresh-20260506-0924.md`

No Android files, root `Docs/**`, `.cron/**`, Swift source files, XCTest source files, renderer assets, entitlements, privacy manifests, background modes, or WebKit runtime code were edited in this batch.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built the SwiftPM package and executed 191 XCTest cases with 0 failures. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Xcode built the SwiftPM-generated `FastMDMobile` scheme for the iPhone 12 simulator and ended with `BUILD SUCCEEDED`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Xcode executed 191 XCTest cases on the iPhone 12 simulator with 0 failures and ended with `TEST SUCCEEDED`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_09-23-24-+0800.xcresult`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production-side local JS/CSS/font/HTML renderer assets are currently vendored under `ios/`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKER for physical iPhone 12-family gate only | Listed an iPhone 12 simulator and offline physical devices, but no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKER for physical iPhone 12-family gate only | Command outcome was success, but physical candidates were unavailable and not iPhone 12-family hardware: `iPhone 15 Pro (iPhone16,1)` and `iPad Pro (11-inch) (4th generation) (iPad14,4)`. |

## L11 Evidence

The current iOS runtime remains native fallback-only for Mermaid/math-like rich Markdown blocks. The fresh SwiftPM and iPhone 12 simulator test runs include the conditional renderer gates:

- Native fallback is not using vendored JS/CSS/font/HTML renderer assets.
- Production renderer asset inventory is empty outside ignored build/test/report/screenshot paths.
- Current production source does not import WebKit or construct WKWebView rich renderer surfaces.
- Future vendored-asset mode remains covered by tests for local packaging/offline requirements, bundled `FastMDRenderers` roots, manifest path/hash matching, and unsafe asset rejection.
- Future WKWebView mode remains covered by tests for network requests, external navigation, `javascript:` URLs, `data:` URLs, iframes, non-bundled file URLs, and unsupported bundled asset types.

Supervisor can mark these L11 checklist items complete:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence path: `ios/docs/reports/stage1-ios-l11-l12-live-evidence-refresh-20260506-0924.md`

## L12 Evidence

The exact iPhone 12 simulator destination is available locally and both required Xcode gates passed in this batch.

Supervisor can mark these L12 checklist items complete:

- `Run iOS iPhone 12 simulator build.`
- `Run iOS iPhone 12 simulator tests.`

Evidence path: `ios/docs/reports/stage1-ios-l11-l12-live-evidence-refresh-20260506-0924.md`

This L12 item must stay open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker: no connected physical iPhone 12-family hardware is currently available. The visible physical devices are unavailable and are not iPhone 12-family hardware, so the real-device open, render, search, edit, save, and rotate flow was not completed in this batch.
