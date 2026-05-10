# Stage 1 iOS L11/L12 Conditional Renderer and Simulator Evidence

- Generated: 2026-05-06 08:12 +0800
- Worker lane: iOS live lane
- Batch scope: close the earliest open iOS-owned L11 conditional renderer gates and record the iPhone 12 simulator validation run completed during this batch.
- Ownership boundary: only `ios/**` was changed. `Docs/Stage1_Mobile_Blueprint.md`, `Docs/todos_20260505.md`, `android/**`, and `.cron/**` were not edited.

## Implementation Evidence

The current iOS implementation uses native Swift/SwiftUI/UIKit contracts for ordinary Markdown and native safe-card fallbacks for Mermaid and math rich blocks.

Renderer asset inventory command:

```sh
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print | sort
```

Result: pass, no files returned.

WebKit/WKWebView source scan command:

```sh
rg -n "^\s*import\s+(?:class\s+|struct\s+|enum\s+|protocol\s+|func\s+|var\s+|let\s+|typealias\s+)?WebKit|WKWebView\s*(?:\(|\.)" ios/Sources || true
```

Result: pass, no matches returned.

Focused L11 gate test:

```sh
swift test --filter FastMDMobileCoreTests/testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems
```

Result: pass. Executed 1 XCTest case, 0 failures.

This proves the three conditional renderer checklist gates are satisfied as `notApplicableNativeFallback` for the current iOS tree:

| Checklist item | Status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | complete | No JS/CSS/font renderer assets are present in production iOS paths; native fallback renderer tests pass. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | complete | No WebKit import or WKWebView construction exists in `ios/Sources`; future WKWebView mode is still covered by request-blocking policy tests. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | complete | No vendored renderer assets are discovered, so manifest/hash locking is not required for the current native fallback runtime; manifest/hash audit tests exist for future vendored mode. |

## Validation Evidence

Required SwiftPM validation:

```sh
swift test
```

Result: pass. Executed 187 XCTest cases, 0 failures.

iPhone 12 simulator availability probe:

```sh
xcrun simctl list devices available | rg 'iPhone 12' || true
```

Result: pass. Local simulator found:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

iPhone 12 simulator build:

```sh
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: pass. `** BUILD SUCCEEDED **`

iPhone 12 simulator tests:

```sh
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: pass. Executed 187 XCTest cases, 0 failures. `** TEST SUCCEEDED **`

Xcode recorded the test result bundle at:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_08-12-35-+0800.xcresult
```

## Supervisor Completion Recommendations

The supervisor can mark these blueprint checklist items complete from this batch:

| Blueprint checklist item | Evidence path |
| --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |
| Run iOS iPhone 12 simulator build. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |
| Run iOS iPhone 12 simulator tests. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |
| Record validation reports under `ios/docs/reports/`. | `ios/docs/reports/stage1-ios-l11-l12-conditional-renderer-simulator-evidence-20260506-0812.md` |

The iOS iPhone 12-class real-device validation gate remains open. This batch did not run a connected physical iPhone 12-family manual open/render/search/edit/save/rotate flow.
