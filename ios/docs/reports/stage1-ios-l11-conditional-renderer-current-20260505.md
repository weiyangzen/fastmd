# Stage 1 iOS L11 Conditional Renderer Current Evidence - 2026-05-05

## Scope

Ran one bounded iOS-owned L11 evidence refresh for the three conditional renderer checklist items that are still open in the authoritative Stage 1 Mobile blueprint.

Changes are limited to `ios/**`. This batch did not edit Android files, top-level Docs files, `.cron/**`, Swift source, tests, renderer assets, app entitlements, Info.plist files, privacy manifests, background modes, WebKit renderer code, CDN dependencies, or network renderer behavior.

## Changed Files

Report:

- `ios/docs/reports/stage1-ios-l11-conditional-renderer-current-20260505.md`

No Swift source files or XCTest files were changed in this batch. The implementation and tests already exist in:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`

## Current Implementation Evidence

The iOS Stage 1 renderer remains native Swift model rendering with native safe-card fallbacks for rich blocks such as Mermaid and math. No local JavaScript/CSS/font/HTML renderer asset is currently vendored under `ios/`, and no active WebKit rich-rendering surface is present in `ios/Sources/FastMDMobileCore`.

Existing L11 implementation coverage includes:

- `IOSRendererAssetInventory`, which scans the iOS package for JS/CSS/font/HTML renderer asset files and scans Swift source for active `import WebKit` / `WKWebView(` usage.
- `IOSRendererAssetManifestHashAudit`, which requires exact path matching, local iOS paths, positive byte counts, valid SHA-256 values, and hash equality when renderer assets are discovered.
- `IOSLocalRendererConditionalGateAudit`, which reports the conditional packaging/offline, WKWebView request-blocking, and manifest/hash gate statuses.
- XCTest coverage for the current native-fallback path and future asset-present paths, including manifest acceptance, tamper rejection, remote-path rejection, and missing-manifest rejection.

## Conditional Gate Evidence

| Blueprint checklist item | Current status | Evidence |
| --- | --- | --- |
| Add local renderer packaging/offline tests if JS renderer assets are used. | PASS / not applicable for native fallback | `IOSRendererAssetInventory.discover(iosRoot:)` found no JS/CSS/font/HTML renderer assets under `ios/`; current runtime does not use vendored renderer assets. |
| Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used. | PASS / not applicable for native fallback | `rg -n "^(import WebKit)|WKWebView\\(" ios/Sources/FastMDMobileCore` returned no matches; current rich fallback blocks render as native safe cards. |
| Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored. | PASS / not applicable for current runtime, with future asset coverage present | `IOSRendererAssetManifestHashAudit` tests pass for exact manifests and reject missing, tampered, and remote-path entries when assets exist. No asset manifest is required while the discovered asset set is empty. |

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 22 focused L11 tests with 0 failures. Covered conditional renderer native-fallback gates, renderer asset inventory, renderer manifest/hash audit, and checklist item mapping. |
| `swift test` from `ios/` | PASS | Executed 122 XCTest cases with 0 failures. |
| `find ios -maxdepth 6 -type f \( -name '*.js' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' \) \| sort` from repository root | PASS | No JS/CSS/font/HTML renderer asset files were found under `ios/`. |
| `rg -n "^(import WebKit)\|WKWebView\\(" ios/Sources/FastMDMobileCore` from repository root | PASS | No active WebKit rich-rendering source usage was found. |
| `xcrun xctrace list devices` from `ios/` | BLOCKED for real-device gate | The only connected physical device was `Mac`; two iOS-family devices were listed offline, and `iPhone 12 (26.4.1)` appeared under Simulators, not physical devices. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can mark complete:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`

Evidence paths:

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-conditional-renderer-current-20260505.md`

Keep open:

- L12: `Run iOS iPhone 12-class real-device validation before parity-complete release claim.`

Residual blocker:

- This batch did not have a connected iPhone 12-family physical device to validate the full Stage 1 open, render, search, edit, save, and rotate flow.
