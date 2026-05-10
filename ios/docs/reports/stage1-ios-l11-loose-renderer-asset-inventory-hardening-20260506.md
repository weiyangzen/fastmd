# Stage 1 iOS L11 Loose Renderer Asset Inventory Hardening - 2026-05-06

## Scope

Ran one bounded iOS-owned implementation batch for the earliest still-open iOS-owned checklist cluster in the Stage 1 blueprint: L11 conditional renderer gates.

Changes are limited to `ios/**`. This batch did not edit Android files, root `Docs/**`, `.cron/**`, app entitlements, Info.plist files, privacy manifests, background modes, production WebKit renderer code, CDN dependencies, or network renderer behavior.

## Implementation

- Hardened `IOSRendererAssetInventory` so production-side renderer-like files with `.js`, `.mjs`, `.css`, `.woff`, `.woff2`, `.ttf`, `.otf`, `.html`, or `.htm` extensions are discovered even when they are outside the approved bundled renderer roots.
- Kept platform-local validation artifacts out of the production renderer asset signal by pruning `ios/docs/reports/` and `ios/docs/screenshots/`.
- Updated the canonical inventory command to match the Swift inventory behavior:

```bash
find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

- Added `testIOSL11RendererAssetInventoryDetectsLooseProductionRendererAssets` to prove loose production renderer assets under `ios/Sources/**` are detected and cause the conditional packaging and manifest/hash gates to fail until the assets are moved under an approved bundled resource path with exact manifest/hash evidence.
- Updated existing evidence-string tests to assert that the inventory command includes report/screenshot pruning.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventory` from `ios/` | PASS | Executed 10 focused renderer inventory tests with 0 failures, including the new loose production asset detection/rejection case. |
| `git diff --check -- ios` from repo root | PASS | No whitespace errors. |
| `swift test` from `ios/` | PASS | Executed 163 XCTest cases with 0 failures after updating the inventory command assertion. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repo root | PASS | Empty output. No production-side JS/CSS/font/HTML renderer assets are currently present under `ios/`. |
| `rg -n '^\s*import\s+WebKit\b|\bWKWebView\s*\(' ios/Sources` from repo root | PASS | Empty output. No production iOS source imports WebKit or constructs `WKWebView`. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from `ios/` | PASS | Found available simulator `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' build` from `ios/` | PASS | SwiftPM-generated Xcode scheme built `FastMDMobileCore`; Xcode reported `BUILD SUCCEEDED`. |
| `xcodebuild -scheme FastMDMobile -destination 'platform=iOS Simulator,name=iPhone 12' test` from `ios/` | PASS | Executed 163 XCTest cases with 0 failures on the iPhone 12 simulator; Xcode reported `TEST SUCCEEDED`. |

## Checklist Evidence For Supervisor

The supervisor can use this report, together with the updated XCTest coverage, as additional evidence for these L11 items:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Current runtime: satisfied as not applicable because the production inventory is empty and rich Markdown fallback remains native.
  - Future unsafe path: loose production JS/HTML renderer assets are now detected and fail the packaging gate.
- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Current runtime: satisfied as not applicable because no production `import WebKit` / `WKWebView(` use is present.
  - Existing tests still cover request-blocked WKWebView mode and unsafe WKWebView rejection.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current runtime: satisfied as not applicable because no production renderer assets are present.
  - Future unsafe path: loose production renderer assets fail manifest/hash verification because they are not under approved bundled renderer resource roots.

Adjacent L12 evidence refreshed in this batch:

- L12: `Run iOS iPhone 12 simulator build.`
- L12: `Run iOS iPhone 12 simulator tests.`

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-loose-renderer-asset-inventory-hardening-20260506.md`

