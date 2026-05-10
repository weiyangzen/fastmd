# Stage 1 iOS L11/L12 Conditional Renderer And iPhone 12 Simulator Evidence

Generated: 2026-05-06 13:14 Asia/Shanghai
Lane: FastMD Stage 1 Mobile iOS live lane
Scope: iOS-owned files only

## Batch Summary

This batch closes the earliest remaining iOS-owned open cluster from the daily todo:

- L11 conditional local renderer gates.
- L12 iPhone 12 simulator build and test validation.

The current iOS runtime remains native Swift/SwiftUI/UIKit. Rich Mermaid/math/details fallback blocks render as native safe cards. No JS/CSS/font/HTML renderer assets are present in the production iOS tree, and no WKWebView rich-rendering source is present under `ios/Sources`.

## Current Renderer Posture

| Gate input | Result |
| --- | --- |
| Vendored JS/CSS/font/HTML renderer assets | none discovered |
| WKWebView rich-rendering source | none discovered |
| Rich Markdown fallback mode | native safe cards |
| Network/CDN renderer dependency | none |
| Conditional renderer gate disposition | not applicable because native fallback is the active runtime |

## Validation Results

| Label | Command | Result | Evidence |
| --- | --- | --- | --- |
| SwiftPM full suite | `swift test` from `ios/` | PASS | 205 tests, 0 failures, 0 unexpected failures |
| Focused L11 suite | `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | 74 tests, 0 failures, 0 unexpected failures |
| Renderer asset inventory | `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repo root | PASS | no output; no production renderer assets discovered |
| WebKit source scan | `rg -n "(^|[^A-Za-z0-9_])import[[:space:]]+((class\|struct\|enum\|func\|var\|let\|protocol\|typealias)[[:space:]]+)?WebKit\|WKWebView[[:space:]]*\\(" ios/Sources` from repo root | PASS | exit 1 with no matches; no WebKit import or WKWebView construction under `ios/Sources` |
| iPhone 12 simulator build | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **` |
| iPhone 12 simulator tests | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; 205 tests, 1 skipped, 0 failures |

## iPhone 12 Simulator Notes

`xcodebuild` resolved the SwiftPM package as source package `FastMDMobile: /Users/wangweiyang/GitHub/fastmd/ios` and successfully used the requested destination string:

```text
platform=iOS Simulator,name=iPhone 12
```

There is no local blocker from a missing Xcode project or missing scheme for this batch. The project is still a SwiftPM skeleton, but Xcode generated and used the package scheme successfully.

The one skipped XCTest in simulator mode is expected: `testIOSL11RendererAssetInventoryMatchesDocumentedCommandForCurrentTree` skips process-based shell command parity under `os(iOS)` and is covered by SwiftPM-on-macOS plus the direct inventory command above.

## Supervisor Checklist Recommendations

The supervisor can mark these blueprint checklist rows complete with this report as evidence:

| Blueprint checklist item | Recommended status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | COMPLETE | Native fallback runtime; no JS/CSS/font/HTML renderer assets discovered; full and focused L11 tests passed |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | COMPLETE | Native fallback runtime; no WKWebView rich surface discovered; request-blocking policy tests are present for future WK mode and focused L11 tests passed |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | COMPLETE | Native fallback runtime; no assets require a manifest; manifest/hash tests are present for future vendored mode and focused L11 tests passed |
| Run iOS iPhone 12 simulator build. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed |
| Run iOS iPhone 12 simulator tests. | COMPLETE | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed |

Rows that should remain open from this batch:

| Blueprint checklist item | Reason |
| --- | --- |
| Run iOS iPhone 12-class real-device validation before parity-complete release claim. | This batch did not validate connected physical iPhone 12-family hardware. |

