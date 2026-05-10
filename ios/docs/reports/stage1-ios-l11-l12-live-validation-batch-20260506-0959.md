# Stage 1 iOS L11/L12 Live Validation Batch - 2026-05-06 09:59 +0800

## Scope

Ran one bounded iOS-owned implementation/evidence batch for the earliest still-open iOS rows in the current todo snapshot:

- L11 conditional renderer packaging/offline tests when JS renderer assets are used.
- L11 conditional WKWebView request-blocking tests when local JS renderer surfaces are used.
- L11 conditional renderer asset manifest/hash tests when JS/CSS/font assets are vendored.
- L12 iOS iPhone 12 simulator build.
- L12 iOS iPhone 12 simulator tests.

No Android files, shared Docs files, or cron files were edited.

## Current iOS Renderer State

The active iOS implementation remains native Swift with SwiftUI/UIKit-compatible core contracts:

- Ordinary Markdown rendering stays native through `MarkdownParserAdapter` and `MarkdownNativeRenderer`.
- Mermaid/math/details/generic HTML rich blocks render as native safe fallback cards.
- No production JS/CSS/font/HTML renderer assets are present under `ios/` after pruning `.build`, `.swiftpm`, tests, reports, and screenshots.
- No production Swift source imports `WebKit` or constructs `WKWebView` for rich rendering.
- The future vendored-asset path is already guarded by native Swift tests for local bundle packaging, request blocking, SwiftPM resource declaration, and exact SHA-256 manifest matching.

## Evidence Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | 68 selected L11 tests, 0 failures. Covers conditional renderer current-source closeout, vendored-asset future gates, WKWebView request policy gates, renderer inventory, manifest/hash audit, and existing L11 automation gates. |
| `swift test` from `ios/` | PASS | 195 tests, 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repository root | PASS | No production renderer asset files were found under `ios/`. |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` from repository root | PASS | Exit 1 with no matches. No production WebKit/WKWebView rich renderer source was detected. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from repository root | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`. Built the SwiftPM package scheme for iPhone Simulator with iOS deployment target 14.0. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`. Ran 195 tests with 0 failures on iPhone 12 simulator. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_09-59-06-+0800.xcresult`. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-l12-live-validation-batch-20260506-0959.md`
- `ios/docs/screenshots/golden/rich-preview-light-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-light-reader.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-compact.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-default.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-large.snapshot.txt`
- `ios/docs/screenshots/golden/rich-preview-dark-reader.snapshot.txt`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- No connected iPhone 12-family physical device was validated in this batch. The simulator gates passed, but the real-device parity-complete release gate still requires connected hardware plus manual flow evidence.
