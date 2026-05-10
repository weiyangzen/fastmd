# Stage 1 iOS L11 Renderer Inventory Test-Prune Batch - 2026-05-06 05:48 +0800

## Scope

Ran one bounded iOS-owned L11 hardening batch for the conditional renderer gates:

- `Add local renderer packaging/offline tests if JS renderer assets are used.`
- `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

The current iOS renderer remains native Swift presentation data with native safe-card fallbacks for Mermaid/math. No JS/CSS/font/HTML renderer assets, WebKit renderer code, CDN dependency, network renderer, entitlement, privacy manifest, or background mode was introduced.

## Implementation

- Updated `IOSRendererAssetInventory.defaultInventoryCommand` to prune `ios/Tests` in addition to `ios/.build`, `ios/docs/reports`, and `ios/docs/screenshots`.
- Added `ios/Tests` to `IOSRendererAssetInventory.ignoredInventoryDirectoryPathPrefixes`.
- Expanded the L11 inventory test so renderer-like `.html` and `.css` files under `ios/Tests/Fixtures/**` are ignored as validation artifacts and do not trigger production vendored-renderer gates.
- Kept positive production coverage intact: bundled app/core renderer resources are still discovered, loose production renderer assets are still rejected, and future WKWebView rich surfaces still require explicit request-blocking policy evidence.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-inventory-test-prune-20260506-0548.md`

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test` from `ios/` | PASS | Built `FastMDMobileCore` and executed 169 XCTest cases with 0 failures. New coverage includes `testIOSL11RendererAssetInventoryIgnoresLooseRendererLikeValidationArtifacts`. |
| `find ios \( -path 'ios/.build' -o -path 'ios/Tests' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | No production JS/CSS/font/HTML renderer assets were found under `ios/`. Test fixtures, reports, screenshots, and SwiftPM build output are excluded from the production gate input set. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-renderer-inventory-test-prune-20260506-0548.md`
- `swift test` passed with 169 tests and 0 failures.
- Production renderer asset inventory found no JS/CSS/font/HTML assets under the active iOS implementation tree.

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Not run in this bounded L11 batch:

- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build`
- `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test`

Existing iPhone 12 simulator evidence is tracked in separate L12 reports. This batch only changed and validated the conditional renderer production-inventory boundary.
