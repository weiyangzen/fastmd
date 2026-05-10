# Stage 1 iOS L11/L12 Live Batch - 2026-05-06 09:03 CST

## Scope

Ran one bounded iOS-owned validation/evidence batch for the earliest open iOS-owned
cluster in `Docs/Stage1_Mobile_Blueprint.md`: the L11 conditional renderer gates.
Because the current local simulator set also exposes an iPhone 12 destination, this
batch refreshed the adjacent L12 iPhone 12 simulator build and test evidence.

This batch stayed under `ios/**`. It did not edit Android files, root `Docs/**`,
`.cron/**`, renderer assets, app entitlements, Info.plist files, privacy manifests,
background modes, WebKit renderer code, CDN dependencies, or network renderer
behavior.

## Current iOS Renderer Posture

- Production iOS source remains native Swift/SwiftUI/UIKit core code.
- Rich Mermaid/math blocks use native safe-card fallback in the current runtime.
- No production JS, MJS, CSS, font, HTML, or HTM renderer assets are present under
  iOS after excluding `.build`, `.swiftpm`, tests, reports, and screenshot/golden
  validation artifacts.
- No production `WebKit` import or `WKWebView` construction is present under
  `ios/Sources`.
- Existing XCTest coverage verifies the current native-fallback non-applicability
  path and future-mode guardrails for vendored local assets, manifest/hash checks,
  and request-blocked WKWebView rich surfaces.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11CurrentRepositoryConditionalRendererGatesAreSupervisorReady` from `ios/` | PASS | Executed 1 focused L11 conditional renderer test with 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/.swiftpm' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -iname '*.js' -o -iname '*.mjs' -o -iname '*.css' -o -iname '*.woff' -o -iname '*.woff2' -o -iname '*.ttf' -o -iname '*.otf' -o -iname '*.html' -o -iname '*.htm' \) -print \| sort` from repository root | PASS | Empty output; no production renderer asset files discovered under iOS. |
| `rg -n '^\s*(?:@_implementationOnly\s+)?import\s+(?:class\s+\|struct\s+\|enum\s+)?WebKit\b\|\bWKWebView\s*\(' ios/Sources` from repository root | PASS | No matches; no active production WebKit rich-renderer source found. |
| `swift test` from `ios/` | PASS | Executed 189 tests with 0 failures. |
| `xcrun simctl list devices available \| rg "iPhone 12\|iPhone 15 Pro\|iPhone SE\|iPhone 16\|iPhone 17\|iPhone Air"` from `ios/` | PASS | Available simulator list includes `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | `** BUILD SUCCEEDED **`; built `FastMDMobileCore` for `arm64-apple-ios14.0-simulator` using the SwiftPM-generated `FastMDMobile` scheme. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | `** TEST SUCCEEDED **`; executed 189 tests with 0 failures. Result bundle: `/Users/wangweiyang/Library/Developer/Xcode/DerivedData/ios-ckmmglhcsnpnxxaeqbfgcrlqxgbb/Logs/Test/Test-FastMDMobile-2026.05.06_09-03-41-+0800.xcresult`. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for physical real-device gate | No connected physical iPhone 12 / 12 mini / 12 Pro / 12 Pro Max was visible. The iPhone 12 entry appeared under simulators, not physical devices. |
| `xcrun devicectl list devices --json-output -` from `ios/` | BLOCKED for physical real-device gate | Command outcome was success despite a non-fatal provisioning-provider warning. It listed unavailable physical devices only: an iPhone 15 Pro and an iPad Pro. No connected physical iPhone 12-family hardware was available. |

## Supervisor Checklist Evidence

The supervisor can mark these iOS-owned rows complete using this report plus the
existing XCTest source under `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  Evidence: current tree has no production JS/CSS/font/HTML renderer assets; focused
  and full SwiftPM tests passed; inventory tests also cover future vendored-asset
  trigger behavior.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  Evidence: current tree has no production WebKit/WKWebView rich surface; tests cover
  unsafe WKWebView rejection and request-blocked local WKWebView acceptance.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  Evidence: no current vendored renderer assets are discovered; manifest/hash tests
  verify exact bundled local manifests and reject missing, tampered, duplicate,
  remote, query/fragment, whitespace, and loose local asset paths.
- L12: `Run iOS iPhone 12 simulator build.`
  Evidence: iPhone 12 simulator destination is available and the exact blueprint
  build command passed in this batch.
- L12: `Run iOS iPhone 12 simulator tests.`
  Evidence: the exact blueprint test command passed on iPhone 12 simulator with 189
  tests and 0 failures.
- L13: `Record validation reports under ios/docs/reports/.`
  Evidence: this report is platform-local under `ios/docs/reports/`.

## Still Open

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
  Blocker: no connected physical iPhone 12-family device was available. Simulator
  validation cannot satisfy this physical-device gate.

