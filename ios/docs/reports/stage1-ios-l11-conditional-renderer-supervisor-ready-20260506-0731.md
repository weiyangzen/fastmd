# Stage 1 iOS L11 Conditional Renderer Supervisor Evidence

- Batch: iOS live lane bounded implementation batch
- Generated: 2026-05-06 07:31 Asia/Shanghai
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot: `Docs/todos_20260505.md`

## Implementation

Added a focused current-repository gate:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- Test: `testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady`

The test builds conditional renderer evidence from the actual iOS package root and the canonical `rich-preview.md` fixture. It asserts:

- No JS/CSS/font/HTML renderer assets are discovered in the production iOS tree.
- No WKWebView rich-renderer source code is imported or constructed in production iOS sources.
- Rich Mermaid/math fallback blocks remain native safe cards.
- All three conditional L11 checklist items return supervisor completion recommendations.
- The generated conditional renderer report captures the no-assets/no-WKWebView native-fallback evidence.

Current production renderer asset inventory command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: empty output, so the conditional JS/CSS/font/HTML renderer asset gates are not applicable for the current native-fallback implementation.

## Validation

Commands run from `/Users/wangweiyang/GitHub/fastmd/ios` unless noted otherwise.

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11
```

Result: pass. Executed 54 tests, 0 failures.

```bash
swift test
```

Result: pass. Executed 181 tests, 0 failures.

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Result: pass. Available destination found:

```text
iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)
```

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result: pass. `** BUILD SUCCEEDED **`

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result: pass. Executed 181 tests, 0 failures. `** TEST SUCCEEDED **`

Xcode test result bundle:

```text
/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-30-59-+0800.xcresult
```

```bash
git -C /Users/wangweiyang/GitHub/fastmd diff --check -- ios
```

Result: pass. No whitespace errors reported.

## Supervisor Completion Recommendations

The supervisor can mark these L11 items complete for iOS, with this report and the new current-repository test as evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.

Evidence path:

```text
ios/docs/reports/stage1-ios-l11-conditional-renderer-supervisor-ready-20260506-0731.md
```

Supporting test evidence:

```text
ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift
testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady
```

## Platform Validation Notes

The iPhone 12 simulator build and test commands are not blocked in this environment; both passed in this batch. This report does not claim the physical iPhone 12-family real-device gate, which still requires a connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max and recorded manual Stage 1 flow evidence.
