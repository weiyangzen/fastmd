# Stage 1 iOS L11 Completion Evidence Path Hardening

- Generated: 2026-05-06 09:55:52 +0800
- Worker: FastMD Stage 1 Mobile iOS live lane
- Scope: `ios/**` only
- Blueprint source: `Docs/Stage1_Mobile_Blueprint.md`
- Todo snapshot: `Docs/todos_20260505.md`

## Batch Summary

This batch tightened the L11 conditional renderer completion evidence guard so a completion claim must point at a concrete Markdown report file under `ios/docs/reports/`.

The previous guard accepted any path below `ios/docs/reports/`, including directory-like paths or non-Markdown placeholders. The new guard requires:

- exact trimmed path text
- `ios/docs/reports/` prefix
- `.md` suffix
- no URI scheme
- no `..` traversal
- no backslashes
- no whitespace

## Changed iOS Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-completion-evidence-path-hardening-20260506-0955.md`

## Validation Results

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11CurrentSourceConditionalRendererCompletionEvidence` | PASS | 3 tests, 0 failures |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` | PASS | no renderer asset paths returned |
| `rg -n "^[[:space:]]*import[[:space:]]+(@[A-Za-z0-9_]+[[:space:]]+)*(typealias\|class\|enum\|func\|let\|protocol\|struct\|var[[:space:]]+)?WebKit\\b\|\\bWKWebView[[:space:]]*(\\(\|\\.)" ios/Sources --glob '*.swift'` | PASS | no WebKit/WKWebView source matches returned |
| `swift test` | PASS | 195 tests, 0 failures |
| `find . -maxdepth 3 \( -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name 'Package.swift' \) -print \| sort` | PASS | SwiftPM skeleton present at `./Package.swift`; no Xcode project/workspace needed for this SwiftPM scheme |
| `xcrun simctl list devices available \| rg 'iPhone 12'` | PASS | `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)` |
| `xcodebuild -list` | PASS | SwiftPM-backed `FastMDMobile` scheme is available |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` | PASS | `** BUILD SUCCEEDED **` |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` | PASS | 195 tests, 0 failures; result bundle `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_09-54-54-+0800.xcresult` |
| `xcrun xctrace list devices` | BLOCKED for real-device gate | no connected physical iPhone 12-family device; only Mac connected, non-iPhone-12 devices offline |
| `xcrun devicectl list devices` | BLOCKED for real-device gate | no available physical iPhone 12-family device; listed devices were unavailable and not iPhone 12-family |

## Supervisor Checklist Recommendations

The supervisor can use this report as additional evidence for these L11 rows:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence basis:

- Current source inventory has no vendored JS/CSS/font/HTML renderer assets outside ignored validation artifacts.
- Current source scan has no WebKit import or `WKWebView` construction in `ios/Sources`.
- Rich Markdown fallback mode remains native safe-card only for Stage 1.
- Completion-evidence paths are now guarded so these rows can only be reconciled from concrete iOS-local Markdown report files.

The supervisor can also preserve these L12 results from this batch:

- `Run iOS iPhone 12 simulator build.`: PASS
- `Run iOS iPhone 12 simulator tests.`: PASS

Keep this L12 row open:

- `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`: BLOCKED because no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was available in the local device probes.
