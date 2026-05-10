# Stage 1 iOS L11/L12 Batch Evidence - iPhone 12 Simulator Pass

Date: 2026-05-06 07:46 Asia/Shanghai

## Scope

- Worker lane: iOS live lane.
- Ownership boundary: changed files stay under `ios/**`.
- Batch intent: refresh the earliest open iOS-owned validation cluster after L1-L10, preserving L11 conditional renderer evidence and closing the L12 iPhone 12 simulator build/test gates where local tools now support them.
- Production runtime: native Swift/SwiftUI/UIKit-oriented core. No React Native, Flutter, Cordova, remote WKWebView shell, or web runtime was added.
- Renderer status: native fallback-only for rich Markdown escape hatches. No JS/CSS/font/HTML renderer assets are present under production iOS paths.

## Changed Files

- `ios/docs/reports/stage1-ios-l11-l12-iphone12-simulator-pass-20260506-0746.md`

No Android files, root `Docs/**`, `.cron/**`, production Swift source, XCTest source, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior were changed in this batch.

## Validation Commands

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | 184 XCTest cases, 0 failures. Includes canonical fixture matrix, L11 conditional renderer gates, L12 simulator/report/security/performance/rich fixture report models, and L13 reconciliation models. |
| `xcodebuild -list` from `ios/` | PASS | Resolved SwiftPM package and listed scheme `FastMDMobile`. Xcode logged `IDERunDestination: Supported platforms for the buildables in the current scheme is empty`, but scheme discovery succeeded. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from repo root | PASS | Found `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | Build succeeded for iPhone Simulator SDK 26.4 with deployment target iOS 14.0. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Test succeeded on the iPhone 12 simulator. Executed 184 XCTest cases, 0 failures. XCResult path: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_07-46-38-+0800.xcresult`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repo root | PASS | Empty output. No production iOS JS/CSS/font/HTML renderer assets were found. |
| `xcrun xctrace list devices` from repo root | BLOCKED for real-device parity | Connected physical devices reported by xctrace are offline and are not iPhone 12-family hardware. iPhone 12 appears only as a simulator. |
| `xcrun devicectl list devices --json-output -` from repo root | BLOCKED for real-device parity | Command succeeded with a provisioning provider warning. It listed unavailable physical devices including iPhone 15 Pro and iPad Pro; no connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was present. |

## Existing Implementation Evidence Exercised

- L1 canonical fixture matrix exists and is seeded: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`, `testCanonicalMarkdownFixtureMatrixExistsAndIsSeeded`.
- L11 current conditional renderer gates are supervisor-ready: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`, `testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady`.
- L12 simulator report model captures iPhone 12 build and test gates: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`, `testIOSL12SimulatorValidationReportCapturesIPhone12BuildAndTestGates`.
- L12 rich fixture report model captures all blueprint categories: `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`, `testIOSL12RichFixtureRenderReportCapturesAllBlueprintCategories`.

## Supervisor Checklist Recommendations

| Blueprint checklist item | Recommended status | Evidence |
| --- | --- | --- |
| L11: Add local renderer packaging/offline tests if JS renderer assets are used. | Complete / not applicable for current native fallback runtime | The current production iOS tree has no JS/CSS/font/HTML renderer assets, and `swift test` passed the implemented future-trigger packaging/offline gate tests. |
| L11: Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | Complete / not applicable for current native fallback runtime | The current production iOS tree has no active WKWebView rich surface, and `swift test` passed the implemented future-trigger WKWebView request-blocking policy tests. |
| L11: Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | Complete / not applicable for current native fallback runtime | No production renderer assets were discovered, and `swift test` passed the implemented manifest/hash verification tests for future vendored assets. |
| L12: Run iOS iPhone 12 simulator build. | Complete | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` passed. |
| L12: Run iOS iPhone 12 simulator tests. | Complete | `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` passed with 184 tests and 0 failures. |
| L12: Run iOS iPhone 12-class real-device validation before parity-complete release claim. | Keep open / blocked | No connected physical iPhone 12-family device is available. Only an iPhone 12 simulator is available. |
| L13: Record validation reports under `ios/docs/reports/`. | Complete for this iOS batch | This report is platform-local under `ios/docs/reports/`. |

## Notes

- Earlier daily snapshot text said the iPhone 12 simulator destination was unavailable. This run found an available iPhone 12 simulator with identifier `1B6FEADC-308B-4069-B734-3C9C207E633F`, and both build and test gates passed against it.
- The Xcode package scheme emits an `IDERunDestination` warning during `xcodebuild -list`, `build`, and `test`, but the iPhone Simulator build and test actions complete successfully.
- Real-device parity remains blocked until a connected physical iPhone 12-family device is available and the full open, render, search, edit, save, and rotate flow is executed on hardware.
