# Stage 1 iOS L11/L12 Conditional Renderer Supervisor Evidence - 2026-05-06

## Batch Scope

- Lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`.
- Todo source: `Docs/todos_20260505.md`.
- Selected batch: close the remaining iOS-owned L11 conditional renderer checklist evidence for the native fallback renderer path, then refresh SwiftPM and iPhone 12 simulator validation.

## Implementation Evidence

- Added explicit supervisor completion recommendations to `IOSConditionalRendererChecklistEvidence`.
- Added those recommendations to `IOSConditionalRendererGateReport.markdown`.
- Extended the native-fallback report test so the three conditional L11 lines are surfaced as supervisor recommendations.
- Current renderer posture remains native Swift fallback:
  - No JS/CSS/font/HTML renderer assets discovered in production iOS paths.
  - No WKWebView rich renderer source imported or constructed in `ios/Sources`.
  - Rich Mermaid/math fallback blocks remain native safe cards.

## Renderer Asset Inventory

Command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result:

- PASS: command returned no production iOS renderer asset paths.

## Validation

Command:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer
```

Result:

- PASS: 16 tests executed, 0 failures, 0 unexpected failures.

Command:

```bash
swift test
```

Result:

- PASS: 169 tests executed, 0 failures, 0 unexpected failures.

Command:

```bash
xcrun simctl list devices available | rg 'iPhone 12'
```

Result:

- PASS: local iPhone 12 simulator destination exists: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`.

Command:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build
```

Result:

- PASS: `** BUILD SUCCEEDED **`.
- Note: Xcode emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` while still resolving the SwiftPM package scheme and building the iOS simulator target successfully.

Command:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

- PASS: `** TEST SUCCEEDED **`.
- PASS: 169 tests executed on the iPhone 12 simulator destination, 0 failures, 0 unexpected failures.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_05-51-48-+0800.xcresult`.

Command:

```bash
git diff --check -- ios
```

Result:

- PASS: no whitespace errors reported.

## Supervisor Checklist Recommendations

The supervisor can mark these iOS L11 checklist items complete based on this report plus the updated automated gate report surface:

- Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: native fallback path has no discovered JS/CSS/font/HTML renderer assets; `IOSConditionalRendererChecklistEvidence.supervisorCompletionRecommendations` includes this item when the gate is not applicable and satisfied.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: native fallback path has no WKWebView rich surface or WebKit renderer import; future WKWebView mode remains covered by explicit request-blocking policy tests.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: no vendored renderer assets are discovered in production iOS paths; future vendored asset mode remains covered by exact manifest and SHA-256 verification tests.

## Remaining iOS Validation Boundary

- iPhone 12 simulator build/test evidence passed in this batch.
- Physical iPhone 12-family real-device validation remains open until a connected real iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the manual open, render, search, edit, save, and rotate Stage 1 flow.
