# Stage 1 iOS L11 Batch Evidence - HTM Renderer Asset Inventory

## Scope

Ran one bounded iOS-owned implementation batch for the earliest open iOS cluster: L11 conditional local renderer gates.

This batch keeps the current iOS implementation native Swift/SwiftUI/UIKit with native fallback cards for Mermaid, math, and sanitized HTML surfaces. It does not add WKWebView rich rendering, JavaScript/CSS/font/HTML assets, CDN loading, network renderer behavior, app entitlements, privacy manifests, background modes, Android changes, root `Docs/**` changes, or `.cron/**` changes.

## Implementation

- Updated `IOSRendererAssetInventory.rendererAssetFileExtensions` to include `.htm` in addition to `.html`.
- Updated `IOSRendererAssetInventory.defaultInventoryCommand` so reproducible audits scan `*.htm` files.
- Added `testIOSL11RendererAssetInventoryTreatsHTMDocumentsAsRendererAssets`.
- The new test creates a temporary bundled `ios/Resources/FastMDRenderers/details/details-renderer.htm`, verifies discovery, platform-local bundled resource classification, byte count, SHA-256 hash, and manifest/hash audit satisfaction.

## Renderer Asset Inventory

Command from repository root:

```sh
find ios -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print | sort
```

Result: PASS, empty output. No vendored JS/CSS/font/HTML/HTM renderer assets are currently present in `ios/`.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11RendererAssetInventory` from `ios/` | PASS | Executed 9 focused renderer inventory XCTest cases with 0 failures. Includes the new `.htm` bundled asset manifest/hash test. |
| `swift test` from `ios/` | PASS | Executed 162 XCTest cases with 0 failures. Coverage includes L1 fixture matrix, L11 conditional renderer gates, WKWebView request-blocking policy contracts, renderer asset inventory/hash audits, rich fixture snapshots, and L12 report contracts. |
| `find ios -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output; current runtime remains native fallback only and has no vendored renderer assets. |
| `git diff --check -- ios` from repository root | PASS | No whitespace errors reported for iOS changes. |

## Checklist Evidence

Supervisor can use this report as additional completion evidence for:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Evidence: renderer asset inventory now includes `.htm` files in the same bundled-resource discovery path as `.html`, `.mjs`, `.js`, `.css`, and font assets.
- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Evidence: `testIOSL11RendererAssetInventoryTreatsHTMDocumentsAsRendererAssets` proves future `.htm` renderer documents produce manifest entries with exact byte count and SHA-256 verification.

Current native-fallback state still makes the conditional asset gates not applicable for release unless a future Mermaid/math renderer vendors local assets. If that happens, `.htm` files now enter the same offline packaging and hash-lock path instead of being invisible to the audit.

## Changed Files

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
- `ios/docs/reports/stage1-ios-l11-htm-renderer-asset-inventory-20260506.md`
