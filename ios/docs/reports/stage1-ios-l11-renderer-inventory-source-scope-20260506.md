# Stage 1 iOS L11 Renderer Inventory Source Scope Report - 2026-05-06

## Scope

Advanced one bounded iOS-owned L11 automated-test hardening batch for the conditional local renderer gates.

Changes are limited to `ios/**`. This batch did not edit Android files, top-level Docs checklist files, `.cron/**`, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, CDN dependencies, or network renderer behavior.

## Changed Files

Implementation:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`

Test coverage:

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

Report:

- `ios/docs/reports/stage1-ios-l11-renderer-inventory-source-scope-20260506.md`

## Implementation Notes

- Widened `IOSRendererAssetInventory.discover(iosRoot:)` so its default Swift source scan covers all `ios/Sources`, not only `ios/Sources/FastMDMobileCore`.
- This makes the conditional WKWebView/WebKit gate fail closed if future rich-renderer code is added in another iOS target or feature module under `ios/Sources`.
- Added `testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault`, which builds a temporary iOS package shape with both `FastMDMobileCore` and `FastMDMobile` source trees and proves that WebKit usage in the non-core target is detected.
- The current iOS runtime remains native fallback-only. Mermaid and math rich blocks continue to use native safe-card fallback presentation; no JS/CSS/font/HTML renderer assets or WKWebView rich-renderer surface were introduced.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 27 focused L11 tests with 0 failures. New coverage includes `testIOSL11RendererAssetInventoryScansAllIOSTargetSourcesByDefault`. |
| `swift test` from `ios/` | PASS | Executed 136 tests with 0 failures. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |
| `find ios -maxdepth 5 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |

## Checklist Evidence

Supervisor can mark complete or keep complete with stronger evidence:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-inventory-source-scope-20260506.md`
- Focused L11 XCTest gate passed.
- Full SwiftPM test gate passed.
- Renderer asset inventory command returned no JS/CSS/font/HTML files under `ios/`.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`
