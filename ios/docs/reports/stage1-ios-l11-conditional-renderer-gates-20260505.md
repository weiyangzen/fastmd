# Stage 1 iOS L11 Conditional Renderer Gates Report - 2026-05-05

## Scope

Advanced one bounded iOS-owned L11 automated-test batch for the three conditional local renderer gates that remain open in the authoritative Stage 1 Mobile blueprint.

Changes are limited to `ios/**`.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-gates-20260505.md`

## Implementation Notes

- Added `IOSRendererAssetInventory`, a reusable native Swift validation model that scans the iOS package for renderer asset files with JS/CSS/font/HTML extensions.
- The inventory also scans iOS core Swift sources for active WebKit rich-renderer code by detecting an actual `import WebKit` line or `WKWebView(` construction.
- `IOSConditionalRendererGateReport` now records the Swift source scan count and requires a positive source scan before native-fallback conditional evidence is considered captured.
- The existing iOS renderer remains native Swift model rendering. Mermaid and math continue to render as readable native safe cards, not JS/WKWebView surfaces.
- No Android files, top-level Docs files, WebKit renderer, JS/CSS/font asset, CDN dependency, network renderer, Info.plist, entitlement, privacy manifest, or background mode was introduced.

## Conditional Gate Evidence

| Gate | Status | Evidence |
| --- | --- | --- |
| Local renderer packaging/offline tests if JS renderer assets are used | PASS / not applicable | `IOSRendererAssetInventory.discover(iosRoot:)` found no JS/CSS/font/HTML renderer assets under `ios/`; `IOSLocalRendererConditionalGateAudit.localRendererPackagingGateStatus == .notApplicableNativeFallback`. |
| WKWebView request-blocking tests if local JS renderer surfaces are used | PASS / not applicable | `IOSRendererAssetInventory.importsWebKitRichRendererCode == false`; rendered rich fallbacks use `.nativeSafeCard`; `IOSLocalRendererConditionalGateAudit.wkWebViewRequestBlockingGateStatus == .notApplicableNativeFallback`. |
| Renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored | PASS / not applicable | `IOSLocalRendererConditionalGateAudit.rendererAssetManifestHashGateStatus == .notApplicableNativeFallback`; discovered renderer asset paths list is empty, so no manifest/hash lock is required for iOS in this native-fallback Stage 1 build. |

Report-model output asserted by XCTest:

```text
# Stage 1 iOS Conditional Renderer Gate Report
- Uses vendored renderer assets: false
- Uses WKWebView rich surface: false
- Imports WebKit rich renderer code: false
- Scanned Swift source files: >0
- Discovered renderer asset paths: none
- Native fallback reason: iOS renders rich Markdown fallback blocks as native safe cards; no JS/CSS/font assets or WKWebView rich surface are present.
```

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 17 focused L11 tests with 0 failures, including `testIOSL11RendererAssetInventoryScansPackageForConditionalGateInputs`, conditional gate audit, and conditional report evidence tests. |
| `swift test` from `ios/` | PASS | Executed 111 tests with 0 failures. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | BLOCKED | Exit 70. Xcode reported: `Unable to find a device matching the provided destination specifier: { platform:iOS Simulator, OS:latest, name:iPhone 12 }`. The `FastMDMobile` scheme resolves, but no installed available simulator destination is named `iPhone 12`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | BLOCKED | Exit 70. Xcode reported the same missing `iPhone 12` simulator destination. Available iOS simulator destinations include `Stage1 iPhone 15 Pro`, iPhone 16 family, iPhone 17 family, iPhone Air, iPhone SE, and iPads, but no iPhone 12 simulator. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-conditional-renderer-gates-20260505.md`
- `swift test --filter FastMDMobileCoreTests/testIOSL11` passed.
- `swift test` passed.
- Renderer asset inventory command returned no files.

Keep open:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`
- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Blocker:

- The exact iPhone 12 simulator destination required by the blueprint is not installed locally, so mandatory iPhone 12 simulator build/test gates remain blocked in this environment.
