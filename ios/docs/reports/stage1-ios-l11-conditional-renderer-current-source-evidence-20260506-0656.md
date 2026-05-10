# Stage 1 iOS L11 Conditional Renderer Current-Source Evidence - 2026-05-06 06:56 +0800

## Batch Scope

- Lane: FastMD Stage 1 Mobile iOS live lane.
- Ownership: `ios/**` only.
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`.
- Todo source: `Docs/todos_20260505.md`.
- Selected batch: L11 iOS conditional renderer gates for the current native-fallback source tree.

## Implementation Evidence

- Added `testIOSL11CurrentNativeFallbackEvidenceClosesAllConditionalRendererChecklistItems` in `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`.
- The new test builds a current-source `IOSConditionalRendererGateEvidenceBuilder` bundle from `rich-preview.md`.
- The test requires:
  - zero discovered production JS/CSS/font/HTML renderer assets;
  - no real WebKit rich renderer import or `WKWebView(...)` construction in `ios/Sources`;
  - no vendored renderer asset mode;
  - no WKWebView rich surface mode;
  - all three L11 conditional renderer checklist lines exposed as satisfied supervisor recommendations.

## Source Tree Inventory

Command:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result:

- PASS: command returned no production iOS renderer asset paths.

Command:

```bash
rg -n "^[[:space:]]*import[[:space:]]+WebKit|WKWebView[[:space:]]*\(" ios/Sources
```

Result:

- PASS: no real WebKit rich renderer import or `WKWebView(...)` construction found in `ios/Sources`.

## Validation

Command:

```bash
swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer
```

Result:

- PASS: 18 tests executed, 0 failures, 0 unexpected failures.

Command:

```bash
swift test
```

Result:

- PASS: 178 tests executed, 0 failures, 0 unexpected failures.

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
- Note: Xcode emitted `IDERunDestination: Supported platforms for the buildables in the current scheme is empty.` while still resolving and building the SwiftPM package scheme for the iOS simulator destination.

Command:

```bash
xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test
```

Result:

- PASS: `** TEST SUCCEEDED **`.
- PASS: 178 tests executed on the iPhone 12 simulator destination, 0 failures, 0 unexpected failures.
- Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_06-55-46-+0800.xcresult`.

Command:

```bash
git diff --check -- ios
```

Result:

- PASS: no whitespace errors reported.

## Supervisor Checklist Recommendations

The supervisor can mark these iOS L11 checklist items complete based on this report and the updated XCTest evidence:

- Add local renderer packaging/offline tests if JS renderer assets are used.
  - Evidence: current source tree has no production JS/CSS/font/HTML renderer assets; the current-source evidence bundle reports the gate as `notApplicableNativeFallback` and checklist-satisfied.
- Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.
  - Evidence: current source tree has no WebKit rich renderer import and no WKWebView rich surface; the current-source evidence bundle reports the gate as `notApplicableNativeFallback` and checklist-satisfied. Future WKWebView mode remains covered by explicit request-blocking policy tests.
- Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.
  - Evidence: current source tree has no vendored renderer assets; the current-source evidence bundle reports the gate as `notApplicableNativeFallback` and checklist-satisfied. Future vendored asset mode remains covered by platform-local manifest and SHA-256 verification tests.

## Remaining Boundary

- Physical iPhone 12-family real-device validation remains open until a connected iPhone 12, iPhone 12 mini, iPhone 12 Pro, or iPhone 12 Pro Max completes the manual Stage 1 open, render, search, edit, save, and rotate flow.
