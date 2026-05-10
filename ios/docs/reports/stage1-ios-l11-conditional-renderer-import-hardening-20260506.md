# Stage 1 iOS L11 Conditional Renderer Import Hardening

- Generated: 2026-05-06T00:21:10Z
- Lane: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Daily snapshot source: `Docs/todos_20260505.md`

## Batch Summary

This batch advanced the earliest still-open iOS-owned checklist cluster: L11 conditional renderer gates.

The current iOS renderer path remains native Swift fallback only for Mermaid/math rich blocks. No JS/CSS/font/HTML renderer assets are present in production iOS paths, and no WKWebView rich rendering surface is active. This batch tightened the repository scanner that backs that claim so attributed and scoped Swift WebKit imports cannot bypass native-fallback evidence:

- `@_implementationOnly import WebKit`
- `import struct WebKit.WKWebView`

## Implementation Evidence

- Hardened `IOSRendererAssetInventory` WebKit import detection to skip Swift import attributes and scoped import kind tokens before matching the WebKit module.
- Added `testIOSL11RendererInventoryDetectsAttributedAndScopedWebKitImports`.
- Confirmed the current repository still reports native fallback evidence:
  - Uses vendored renderer assets: false
  - Uses WKWebView rich surface: false
  - Imports WebKit rich renderer code: false
  - Discovered renderer asset paths: none

## Validation Evidence

Commands were run from `ios/` unless noted otherwise.

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` | PASS | 61 XCTest cases, 0 failures |
| `swift test` | PASS | 188 XCTest cases, 0 failures |
| `git -C .. diff --check -- ios` | PASS | no whitespace errors |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print` + `sort` | PASS | no production iOS renderer asset paths printed |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 188 XCTest cases, 0 failures; `** TEST SUCCEEDED **`; result bundle `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_08-20-49-+0800.xcresult` |

The iPhone 12 simulator Xcode commands used SwiftPM's generated package scheme from the existing `Package.swift`; there is still no checked-in `.xcodeproj` or `.xcworkspace` under `ios/`.

## Supervisor Checklist Recommendations

The supervisor can mark the following L11 checklist items complete for the current iOS native-fallback implementation, using this report plus the tests listed above as evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Rationale: the conditional gates are not applicable in the current native-fallback iOS implementation because no JS/CSS/font/HTML renderer assets are discovered and no WKWebView rich surface is active. Future introduction of vendored renderer assets or WKWebView rich surfaces is covered by failing/satisfied-path tests in `FastMDMobileCoreTests`.

## Remaining Platform Validation Boundary

This batch did not claim the physical iPhone 12-family real-device gate. That L12 item remains open until a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 open, render, search, edit, save, and rotate flow with manual evidence.
