# Stage 1 iOS L11/L12 Conditional Renderer And iPhone 12 Simulator Pass - 2026-05-06 13:06 +0800

## Scope

Ran one bounded iOS live-lane batch for the earliest still-open iOS-owned rows in the authoritative blueprint:

- L11 conditional local renderer packaging/offline tests.
- L11 conditional WKWebView request-blocking tests.
- L11 conditional renderer asset manifest/hash verification tests.
- L12 iOS iPhone 12 simulator build.
- L12 iOS iPhone 12 simulator tests.

This batch stayed inside `ios/**`. It did not edit Android files, shared `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, renderer assets, WebKit rich-renderer surfaces, CDN dependencies, or network renderer behavior.

## Current Renderer Mode

FastMD iOS currently renders Mermaid, math, details/summary, generic HTML fallback, and other rich fallback blocks with native Swift safe-card/fallback presentations. The production iOS source tree does not contain a local JS/CSS/font/HTML renderer bundle and does not instantiate WebKit/WKWebView for rich block rendering.

Current command evidence:

- Production renderer asset inventory: empty.
- Production WebKit/WKWebView source scan: no matches.
- Native fallback rich blocks stay native safe cards.
- No CDN, network renderer, external navigation, `javascript:` URL, `data:` URL, iframe, or remote subresource surface is present for rich block rendering.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 74 focused L11 XCTest cases with 0 failures. Coverage includes current native-fallback conditional renderer closeout, future vendored asset packaging, future WKWebView request blocking, manifest/hash verification, SwiftPM resource declaration, inventory command parity, and WebKit source-scan guards. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repository root | PASS | Empty output; no production iOS JS/CSS/font/HTML renderer assets discovered outside ignored build, test, report, and screenshot evidence paths. |
| `rg -n "(^|[[:space:]])import[[:space:]]+((typealias\|class\|enum\|func\|let\|protocol\|struct\|var)[[:space:]]+)?WebKit\\b\|WKWebView[[:space:]]*(\\(\|\\.)" ios/Sources ios/Package.swift --glob '*.swift'` from repository root | PASS | Exit 1 with empty output; no production WebKit import or WKWebView construction matches in iOS sources or SwiftPM manifest. |
| `swift test` from `ios/` | PASS | Executed 205 XCTest cases with 0 failures. Includes L1 canonical fixture matrix, L11 conditional renderer gates, L12 reports, and real-device blocker models. |
| `xcrun simctl list devices available \| rg "iPhone 12"` from `ios/` | PASS | Available simulator set includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Built the SwiftPM scheme for iPhone 12 simulator with iPhoneSimulator SDK 26.4 and iOS 14.0 simulator deployment target. Xcode ended with `** BUILD SUCCEEDED **`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 205 XCTest cases on the iPhone 12 simulator with 0 failures and 1 expected simulator skip for process-based shell command parity. Xcode ended with `** TEST SUCCEEDED **`. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_13-05-46-+0800.xcresult`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: current production iOS inventory finds no JS/CSS/font/HTML renderer assets, so the row is not applicable for native fallback mode. Future vendored asset mode is covered by tests requiring local bundled assets, SwiftPM resource declarations, matching declared names, and no loose production renderer assets.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Evidence: current production iOS source scan finds no WebKit/WKWebView rich-renderer surface, so the row is not applicable for native fallback mode. Future WKWebView mode is covered by request policy tests that block remote subresources, external navigation, `javascript:` URLs, `data:` URLs, iframes, unsupported asset/context combinations, and non-bundled files.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: current production iOS inventory finds no renderer assets, so no manifest/hash lock is required for the native fallback build. Future vendored asset mode is covered by manifest tests requiring exact local paths, positive byte counts, valid SHA-256 hashes, no duplicate paths, no query/fragment/whitespace/traversal paths, and bundled `FastMDRenderers` resource roots.
- L12: `Run iOS iPhone 12 simulator build.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed.
- L12: `Run iOS iPhone 12 simulator tests.`
  - Evidence: `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 205 XCTest cases, 0 failures, and 1 expected simulator-only skip.
- L13: `Record validation reports under ios/docs/reports/.`
  - Evidence: this report is platform-local under `ios/docs/reports/`.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Reason:

- This batch did not run a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max validation flow. Simulator validation passed, but the real-device parity-complete gate needs separate physical-device evidence.

## Evidence Paths

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-iphone12-sim-pass-20260506-1306.md`
