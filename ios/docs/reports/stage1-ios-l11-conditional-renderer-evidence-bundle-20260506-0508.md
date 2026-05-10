# Stage 1 iOS L11 Conditional Renderer Evidence Bundle

- Generated: 2026-05-06 05:08 Asia/Shanghai
- Batch scope: L11 automated conditional renderer gates
- Ownership: iOS only

## Scope

This batch hardened the iOS conditional renderer evidence bundle so a checklist claim must keep the live renderer asset inventory, conditional renderer audit, and generated report in sync.

The current iOS runtime remains native Swift/SwiftUI/UIKit with native rich fallback cards for Mermaid/math-like blocks. No JS/CSS/font/HTML renderer assets were added, no WebKit runtime code was added, and no Android, root `Docs/**`, or `.cron/**` files were edited.

## Implementation Evidence

- `ios/Sources/FastMDMobileCore/IOSAutomatedValidationGates.swift`
  - `IOSConditionalRendererGateEvidenceBundle.satisfiesStageOneConditionalRendererChecklist` now requires `inventoryMatchesAudit`.
  - Added `inventoryMatchesAudit` to require:
    - Swift source scanning actually ran.
    - discovered renderer asset paths match the audit paths exactly.
    - WebKit source inventory matches the audit's WKWebView-rich-surface claim.
    - vendored renderer assets, when present, are platform-local and under bundled `FastMDRenderers` resource roots.
    - native fallback mode still proves the live no-asset/no-WebKit inventory.
  - The bundle also requires the report evidence to equal the audit checklist evidence.

- `ios/Tests/FastMDMobileCoreTests/FastMDMobileCoreTests.swift`
  - Added `testIOSL11ConditionalRendererEvidenceBundleAcceptsSatisfiedBundledWKWebViewMode`.
  - Added `testIOSL11ConditionalRendererEvidenceBundleRejectsInventoryAuditMismatch`.
  - Existing native-fallback evidence builder coverage remains unchanged and passing.

## Validation

| Command | Result | Evidence |
| --- | --- | --- |
| `swift test --filter FastMDMobileCoreTests/testIOSL11ConditionalRenderer` from `ios/` | PASS | Executed 14 focused conditional-renderer tests with 0 failures. Includes native fallback, future vendored WKWebView mode, unsafe WKWebView rejection, report evidence, manifest/hash, and the new mismatch rejection. |
| `swift test --filter FastMDMobileCoreTests/testIOSL11` from `ios/` | PASS | Executed 44 focused L11 tests with 0 failures. |
| `swift test` from `ios/` | PASS | Executed 165 tests with 0 failures. |
| `find ios \( -path 'ios/.build' -o -path 'ios/docs/reports' -o -path 'ios/docs/screenshots' \) -prune -o -type f \( -name '*.js' -o -name '*.mjs' -o -name '*.css' -o -name '*.woff' -o -name '*.woff2' -o -name '*.ttf' -o -name '*.otf' -o -name '*.html' -o -name '*.htm' \) -print \| sort` from repository root | PASS | Empty output. No production-side JS/CSS/font/HTML renderer assets are present under `ios/`. |
| `rg -n '^\s*import\s+WebKit\b|\bWKWebView\s*\(' ios/Sources` from repository root | PASS | No matches. `rg` exited 1 because no production iOS source imports WebKit or constructs `WKWebView`. |
| `git -C .. diff --check -- ios` from `ios/` | PASS | No whitespace errors. |
| `xcodebuild -list` from `ios/` | PASS | Scheme `FastMDMobile` is visible. Xcode reported an empty supported-platform warning for the SwiftPM workspace, but listing succeeded. |
| `xcrun simctl list devices available \| rg 'iPhone 12'` from repository root | PASS | Found available simulator: `iPhone 12 (1B6FEADC-308B-4069-B734-3C9C207E633F) (Shutdown)`. |

## Checklist Items For Supervisor

The supervisor can use this report as fresh iOS evidence for the three L11 conditional renderer items:

- L11: `Add local renderer packaging/offline tests if JS renderer assets are used.`
  - Current runtime: satisfied as not applicable because no JS/CSS/font/HTML renderer assets are present.
  - Future asset-present path: executable tests accept only platform-local bundled renderer resources with offline packaging evidence.

- L11: `Add WebView/WKWebView request-blocking tests if local JS renderer surfaces are used.`
  - Current runtime: satisfied as not applicable because no production WebKit import or `WKWebView` construction is present.
  - Future WKWebView-present path: executable tests require vendored assets plus request-blocked local surface flags and reject unsafe network/remote-subresource surfaces.

- L11: `Add renderer asset manifest/hash verification tests if JS/CSS/font assets are vendored.`
  - Current runtime: satisfied as not applicable because no vendored renderer assets are discovered.
  - Future asset-present path: executable tests require exact platform-local manifest paths, byte counts, SHA-256 hashes, and reject loose, duplicate, missing, tampered, or remote entries.

## Remaining Open Gates

- iPhone 12 simulator build/test gates were not run in this L11-only batch.
- iPhone 12-family physical-device validation remains open until a real iPhone 12 / 12 mini / 12 Pro / 12 Pro Max completes the Stage 1 manual flow with recorded evidence.
